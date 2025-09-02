module utopia_tx (
    Utopia_if.CoreTransmit Tx
);
    import utopia_tx_state_pkg::*;
    TxStateType UtopiaStatus;

    // Listen to the interface, collecting byte
    // A complete cell is then copied to the cell buffer
    // $clog2(48) = 6
    logic [0:5] PayloadIndex;

    // 25MHz Tx clk out
    assign Tx.clk_out = Tx.clk_in;

    always_ff @(posedge Tx.clk_in or negedge Tx.reset) begin
        if (Tx.reset) begin
            Tx.soc <= 1'b0;
            Tx.en <= 1'b1;
            Tx.ready <= 1'b1;
            UtopiaStatus <= reset;
            PayloadIndex <= 6'd0;
            // output Tx.data should be initialized as well, suggested value is '0 otherwise it will be 'x
        end
        else begin
            Tx.en <= !Tx.clav;                  // default values
            unique case (UtopiaStatus)
                reset: begin
                    Tx.en <= 1'b1;
                    Tx.ready <= 1'b1;
                    if (Tx.valid) begin
                        Tx.ready <= 1'b0;
                        UtopiaStatus <= soc;
                    end
                end
                soc: begin
                    if (Tx.clav) begin
                        Tx.soc <= 1'b1;
                        Tx.data <= Tx.ATMcell.nni.VPI[11:4];
                        UtopiaStatus <= vpi_vci;
                    end
                end
                vpi_vci: begin
                    Tx.soc <= 1'b0;
                    if (Tx.clav) begin
                        Tx.data <= {Tx.ATMcell.nni.VPI[3:0], Tx.ATMcell.nni.VCI[15:12]};
                        UtopiaStatus <= vci;
                    end
                end
                vci: begin
                    if (Tx.clav) begin
                        Tx.data <= Tx.ATMcell.nni.VCI[11:4];
                        UtopiaStatus <= vci_clp_pt;
                    end
                end
                vci_clp_pt: begin
                    if (Tx.clav) begin
                        Tx.data <= {Tx.ATMcell.nni.VCI[3:0], Tx.ATMcell.nni.CLP, Tx.ATMcell.nni.PT};
                        UtopiaStatus <= hec;
                    end
                end
                hec: begin
                    if (Tx.clav) begin
                        Tx.data <= Tx.ATMcell.nni.HEC;
                        UtopiaStatus <= payload;
                        PayloadIndex <= 6'd0;    // Blocking Assignment, due to blocking increment in payload state, indicating next payload's index
                    end
                end
                payload: begin
                    if (Tx.clav) begin
                        Tx.data <= Tx.ATMcell.nni.Payload[PayloadIndex];
                        if (PayloadIndex == 6'd47)
                            UtopiaStatus <= ack;
                        else
                            PayloadIndex <= PayloadIndex + 1'b1;
                    end
                end
                ack: begin
                    Tx.en <= 1'b1;
                    if (!Tx.valid) begin        // waiting for the valid receiver
                        Tx.ready <= 1'b1;       // send the ready signal to the valid receiver to let it read data
                        UtopiaStatus <= done;
                    end
                end
                done: begin
                    Tx.en <= 1'b1;              // same with ack status
                    if (!Tx.valid) begin        // still for the valid receiver
                        Tx.ready <= 1'b0;       // clean up the ready signal
                        UtopiaStatus <= reset;
                    end
                end
                default: UtopiaStatus <= reset;
            endcase
        end
    end
endmodule
