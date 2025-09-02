module top #(
    parameter int NumRx = `RxPorts,
    parameter int NumTx = `TxPorts,
    parameter int PeriodClk = 10,
    parameter real Duty_Cycle = 0.5 
);
    logic rst, clk;
    // System Clock and Reset
    initial begin
        rst = '0; clk = '0;
        #(PeriodClk - (PeriodClk * Duty_Cycle)) rst = '1;
        #(PeriodClk - (PeriodClk * Duty_Cycle)) clk = '1;
        #(PeriodClk * Duty_Cycle) rst = '0; clk = '0;
        forever begin
            #(PeriodClk - (PeriodClk * Duty_Cycle)) clk = '1;
            #(PeriodClk * Duty_Cycle) clk = '0;
        end
    end

    Utopia_if Rx[0:NumRx-1]();              // NumRx x Level 1 Utopia Rx Interface
    Utopia_if Tx[0:NumTx-1]();              // NumTx x Level 1 Utopia Tx Interface
    CPU_if    mif();                        // Utopia management interface
    squat #(NumRx, NumTx) squat(Rx, Tx, mif, rst, clk); // DUT
    test  #(NumRx, NumTx) t1(Rx, Tx, mif, rst);         // Test        
endmodule
