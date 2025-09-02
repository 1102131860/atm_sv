interface Utopia_if #(
    parameter IFWidth = 8
);
    import data_pkg::ATMCellType;
    
    logic clk_in;                           // input clock used to connect with clocker
    logic clk_out;                          // output clock used for testbench sampling
    logic [IFWidth-1:0] data;               // main data bus depending on IfWidth
    logic soc;                              // start of cell, pulse high to mark the start of an ATM cell
    logic en;                               // enable
    logic clav;                             // cell available, indicates that data is available in FIFO/buffer to read out
    logic valid;                            // source side asserts when the data bus carries valid information this cycle
    logic ready;                            // destination side asserts when it is ready to accept data this cycle
    logic reset;                            // reset internal state machines, counters, FIFO/buffer
    logic selected;                         // used when multiple devices share a bus, high means this interface is current granted by arbitor
    ATMCellType ATMcell;                    // union of structure for ATM cells

    modport TopReceive (
        input  data, soc, clav,
        output clk_in, reset, ready, clk_out, en, ATMcell, valid
    );

    modport TopTransmit (
        input  clav,
        inout  selected,
        output clk_in, clk_out, ATMcell, data, soc, en, valid, reset, ready
    );

    modport CoreReceive (
        input  clk_in, data, soc, clav, ready, reset,
        output clk_out, en, ATMcell, valid
    );

    modport CoreTransmit (
        input  clk_in, clav, ATMcell, valid, reset,
        output clk_out, data, soc, en, ready
    );

    clocking cbr @(negedge clk_out); // sample output clk_out for stimulus
        input  clk_in, clk_out, ATMcell, valid, reset, en, ready;
        output data, soc, clav;
    endclocking : cbr
    modport TB_RX (
        clocking cbr
    );

    clocking cbt @(negedge clk_out); // sample output clk_out for mointor
        input  clk_out, clk_in, ATMcell, soc, en, valid, reset, data, ready;
        output clav;
    endclocking : cbt
    modport TB_TX (
        clocking cbt
    );

endinterface // Utopia_if

typedef virtual Utopia_if vUtopia;
typedef virtual Utopia_if.TB_RX vUtopiaRx;
typedef virtual Utopia_if.TB_TX vUtopiaTx;
