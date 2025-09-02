// The example is a description of a quaduratic or hexdecimal Asynchoronous 
// Transfer Mode (ATM) user-to-network interface and forwarding node

// The top level of the design is called squat
// This module can process an array of receiver and transmitter Utopia interface
// and provide a program CPU interface

/////////////////////////////////////////////////////////////////
//              ---------------
//              |    Squat    |
//              ---------------
// Rx_Utopia -> | RewriteCell | -> Tx_Utopia
//   ...        |     |       |      ...
// Rx_Utopia -> |    LUT      | -> Tx_Utopia
//              ---------------
//                    ↕
//                  CPU_if
/////////////////////////////////////////////////////////////////

module squat #(
    parameter int NumRx = 4,
    parameter int NumTx = 4
) (
    Utopia_if/*.TopReceive*/  Rx[0:NumRx-1],    // NumRx x Level 1 Utopia ATM layer Rx Interfaces
    Utopia_if/*.TopTransmit*/ Tx[0:NumTx-1],    // NumTx x Level 1 Utopia ATM layer Tx Interfaces
    CPU_if.Peripheral mif,                      // Utopia Level 2 parallel management interface; Intel-style Utopia parallel management interface
    input logic rst, clk                        // Miscellaneous control interfaces
);
    import data_pkg::*;
    import util_pkg::*;                         // import helper function
    import cpu_bus_state_pkg::*;
    import squat_state_pkg::*;
    
    // below wires are used to connect with CoreTxs and CoreRxs
    logic [0:NumTx-1] Txready;
    logic [0:NumTx-1] Txvalid;          
    logic [0:NumTx-1] Txsel_in;
    logic [0:NumTx-1] Txsel_out;
    logic [0:NumRx-1] Rxvalid;
    logic [0:NumRx-1] Rxready;
    ATMCellType [0:NumTx-1] TxATMcell;          // CoreTxs
    ATMCellType [0:NumRx-1] RxATMcell;          // CoreRxs
    
    // synchronize buffer/register
    logic reset;
    // cpu bus state variable
    BusCycleType buscycle;
    // there will be 2*8 CellCfgType in LUT (Register file)
    LUT_if #(.Asize(8), .dType(CellCfgType)) lut();
    // ATMcell buffer/register
    ATMCellType ATMcell;
    // FSM state variable
    StateType SquatState;
    // fowarding ports register (MSB to LSB) "logic [`TxPorts-1:0] FWD;" in CellCfgType
    logic [NumTx-1:0] forward;
    // round-robin arbitor register
    logic [0:NumRx-1] RoundRobin;

    /////////////////////////////////////////////////////
    // Assgin buscyle wires with {mif.Rd_DS, mif.Wr_RW}
    /////////////////////////////////////////////////////
    assign buscycle = {mif.Rd_DS, mif.Wr_RW};
    
    /////////////////////////////////////////////////////
    // Fully connecting and module initiation
    /////////////////////////////////////////////////////
    generate
        for (genvar TxIter = 0; TxIter < NumTx; TxIter++) begin : GenTx
            // ATM-layer Utopia interface transmitters
            assign Tx[TxIter].clk_in = clk;
            assign Tx[TxIter].reset  = reset;
            utopia_tx atm_tx(Tx[TxIter].CoreTransmit);
            // inner connections with interface
            assign Tx[TxIter].valid    = Txvalid[TxIter];
            assign Txready[TxIter]     = Tx[TxIter].ready;
            assign Tx[TxIter].ATMcell  = TxATMcell[TxIter];         // connect top signal into interface
            // inner Txsel_out -> interface Tx.selected -> inner Txsel_in
            assign Txsel_in[TxIter]    = Tx[TxIter].selected;       // only transmitter (multiple bus line driving) needs to use 'selected' to arbit
            assign Tx[TxIter].selected = Txsel_out[TxIter];         // receiver doesn't have the situation mutiple bus lines driving
        end
    endgenerate
    generate
        for (genvar RxIter = 0; RxIter < NumRx; RxIter++) begin : GenRx
            // ATM-layer Utopia interface receivers
            assign Rx[RxIter].clk_in = clk;
            assign Rx[RxIter].reset  = reset;
            utopia_rx atm_rx(Rx[RxIter].CoreReceive);
            // inner connections with interface
            assign Rxvalid[RxIter]   = Rx[RxIter].valid;
            assign Rx[RxIter].ready  = Rxready[RxIter];
            assign RxATMcell[RxIter] = Rx[RxIter].ATMcell;         // connect top signal into interface
        end
    endgenerate

    /////////////////////////////////////////////////////
    // Hardware reset
    /////////////////////////////////////////////////////
    always_ff @(posedge clk) begin
        reset <= rst;
    end

    /////////////////////////////////////////////////////
    // Configure the latched look-up table
    /////////////////////////////////////////////////////
    // use always_latch to keep LUT's state
    always_latch begin
        if ({mif.BusMode, mif.Sel} == 2'b10) begin
            unique case (buscycle)
                WriteCycle: lut.write(mif.Addr, mif.DataIn);
                default: ;
            endcase
        end
    end

    /////////////////////////////////////////////////////
    // Aasynchronous outputs to interace CPU
    /////////////////////////////////////////////////////
    // unique ensure must has one and only has one condition hits
    // can avoid priority decision modifing circuit, which may make circuit more complex
    always_comb begin
        mif.Rdy_Dtack = 1'bz;                   // default value are given at the beginning
        mif.DataOut  = 'z;
        if ({mif.BusMode, mif.Sel} == 2'b10) begin
            unique case (buscycle)
                IdleCycle: ;
                WriteCycle: mif.Rdy_Dtack = 1'b0;
                ReadCycle : begin
                    mif.Rdy_Dtack = 1'b0;
                    mif.DataOut  = lut.read(mif.Addr);
                end
                default: $error("@%0t: Unknown condition of CPU Bus Cycle State", $time);
            endcase
        end
    end

    /////////////////////////////////////////////////////
    // Rewriting and forwarding process
    /////////////////////////////////////////////////////
    always_ff @(posedge clk or negedge reset) begin
        logic breakVar;
        if (reset) begin
            Rxready    <= '1;
            Txvalid    <= '0;
            Txsel_out  <= '0;
            SquatState <= wait_rx_valid;
            forward    <= '0;                        // default no forward ports
            RoundRobin <= {1'b1, {(NumRx-1){1'b0}}}; // round arbitor token given to port 0, blocking assignment
        end
        else begin
            unique case (SquatState)
                wait_rx_valid: begin
                    Rxready <= '1;
                    breakVar = 1'b1;                            // local variable updating with blocking assignment
                    for (int j = 0; j < NumRx; j++) begin       // round-robin arbitor with shifting robin
                        for (int i = 0; i < NumRx; i++) begin
                            if (Rxvalid[i] && RoundRobin[i] && breakVar) begin  // find the port given robin and check if that port is valid or not 
                                ATMcell    <= RxATMcell[i];
                                Rxready[i] <= 1'b0;
                                SquatState <= wait_rx_not_valid;
                                breakVar   = 1'b0;
                            end
                        end
                        if (breakVar)
                            RoundRobin <= {RoundRobin[1:NumRx-1], RoundRobin[0]}; // give the token to next one through round shifting
                    end
                end
                wait_rx_not_valid: begin
                    if (ATMcell.uni.HEC != hec(ATMcell.Mem[0:3])) begin
                        SquatState <= wait_rx_valid;
                        `ifndef SYNTHESIS
                            $display("Bad HEC: ATMcell.uni.Hec(0x%h) != ATMcell.Mem[0:3](0x%h)", ATMcell.uni.HEC, hec(ATMcell.Mem[0:3]));
                        `endif
                    end
                    else begin
                        // Get the forward ports & new VPI
                        {forward, ATMcell.nni.VPI} <= lut.read(ATMcell.uni.VPI); // uni format converts to nni
                        // Recompute the HEC
                        ATMcell.nni.HEC <= hec(ATMcell.Mem[0:3]);
                        SquatState  <= wait_tx_ready;
                    end
                end
                wait_tx_ready: begin
                    if (forward) begin
                        for (int i = 0; i < NumTx; i++) begin
                            if (forward[i] && Txready[i]) begin
                                TxATMcell[i] <= ATMcell;
                                Txvalid[i]   <= 1'b1;
                                Txsel_out[i] <= 1'b1;
                            end
                        end
                        SquatState <= wait_tx_not_ready;
                    end
                    else begin
                        SquatState <= wait_rx_valid;
                    end
                end
                wait_tx_not_ready: begin
                    for (int i = 0; i < NumTx; i++) begin
                        if (forward[i] && !Txready[i] && Txsel_in[i]) begin
                            Txvalid[i]   <= 1'b0;
                            Txsel_out[i] <= 1'b0;
                            forward[i]   <= 1'b0;
                        end
                    end
                    if (forward)
                        SquatState <= wait_tx_ready;
                    else
                        SquatState <= wait_rx_valid;
                end
                default: begin
                    SquatState <= wait_rx_valid;
                    `ifndef SYNTHESIS
                        // $error("@%0t: Unknown condition of SquatState", $time);
                        // $finish();
                    `endif
                end
            endcase
        end
    end
endmodule
