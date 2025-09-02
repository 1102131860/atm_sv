module utopia_rx (
    Utopia_if.CoreReceive Rx
);
    import utopia_rx_state_pkg::*;
    RxStateType UtopiaStatus;

    // Listen to the interface, collecting byte
    // A complete cell is then copied to the cell buffer
    // $clog2(48) = 6
    logic [0:5] PayloadIndex;

    // 25MHz Rx clk out
    assign Rx.clk_out = Rx.clk_in;

    always_ff @(posedge Rx.clk_in or negedge Rx.reset) begin
        if (Rx.reset) begin
            Rx.valid <= 1'b0;
            Rx.en <= 1'b1;
            UtopiaStatus <= reset;
            PayloadIndex <= 6'd0;
            // output Rx.ATMcell should be initialized as well, suggested value is '0 otherwise it will be 'x
        end
        else begin
            unique case (UtopiaStatus)
                reset: begin
                    if (Rx.ready) begin
                        UtopiaStatus <= soc;
                        Rx.en        <= 1'b0;
                    end
                end
                soc: begin
                    if (Rx.soc && Rx.clav) begin
                        {Rx.ATMcell.uni.GFC, Rx.ATMcell.uni.VPI[7:4]} <= Rx.data;
                        UtopiaStatus <= vpi_vci;
                    end
                end
                vpi_vci: begin
                    if (Rx.clav) begin
                        {Rx.ATMcell.uni.VPI[3:0], Rx.ATMcell.uni.VCI[15:12]} <= Rx.data;
                        UtopiaStatus <= vci;
                    end
                end
                vci: begin
                    if (Rx.clav) begin
                        Rx.ATMcell.uni.VCI[11:4] <= Rx.data;
                        UtopiaStatus <= vci_clp_pt;
                    end
                end
                vci_clp_pt: begin
                    if (Rx.clav) begin
                        {Rx.ATMcell.uni.VCI[3:0], Rx.ATMcell.uni.CLP, Rx.ATMcell.uni.PT} <= Rx.data;
                        UtopiaStatus <= hec;
                    end
                end
                hec: begin
                    if (Rx.clav) begin
                        Rx.ATMcell.uni.HEC <= Rx.data;
                        UtopiaStatus <= payload;
                        PayloadIndex <= 6'd0;    // Blocking Assignment, due to blocking increment in payload state, indicating next payload's index
                    end
                end
                payload: begin
                    if (Rx.clav) begin
                        Rx.ATMcell.uni.Payload[PayloadIndex] <= Rx.data;
                        if (PayloadIndex == 6'd47) begin
                            UtopiaStatus <= ack;
                            Rx.valid <= 1'b1;
                            Rx.en <= 1'b1;
                        end
                        else
                            PayloadIndex <= PayloadIndex + 1'b1;
                    end
                end
                ack: begin
                    if (!Rx.ready) begin    // waiting for Transmitter firstly deassert ready signal
                        UtopiaStatus <= reset;
                        Rx.valid <= 1'b0;   // clean up the valid signal
                    end
                end
                default: UtopiaStatus <= reset;
            endcase
        end
    end
endmodule
