interface CPU_if;
    import data_pkg::CellCfgType;

    logic        BusMode;                   // indicate bus cycle type, active-high, 1 indicates CPU master (Tx) Peripheral salve (Rx)
    logic [11:0] Addr;                      // peripheral/register file' address
    logic        Sel;                       // chip-select/access enable, active-low, 0 indicates starting access
    CellCfgType  DataIn;                    // data sent to CPU
    CellCfgType  DataOut;                   // data sent out from CPU
    logic        Rd_DS;                     // read data strobe, active-low, 0 indicates reading
    logic        Wr_RW;                     // write / read-write, active-low, 0 indicates writing
    logic        Rdy_Dtack;                 // Ready / Data acknowledge, active-low, 0 indicates ack

    modport Peripheral (
        input  BusMode, Addr, Sel, DataIn, Rd_DS, Wr_RW,
        output DataOut, Rdy_Dtack
    );

    modport Test (
        output BusMode, Addr, Sel, DataIn, Rd_DS, Wr_RW,
        input  DataOut, Rdy_Dtack
    );
endinterface // CPU_if

typedef virtual CPU_if.Test vCPU_T;
