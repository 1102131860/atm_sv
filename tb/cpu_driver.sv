class CPU_driver;
    vCPU_T mif;
    data_pkg::CellCfgType lookup [255:0];                                   // copy of look-up table (suppose a fix size of 2^8)

    function new(input vCPU_T mif);
        this.mif = mif;
    endfunction : new

    task Initialize_Host();
        mif.BusMode <= '1;
        mif.Addr    <= '0;
        mif.DataIn  <= '0;
        mif.Sel     <= '1;
        mif.Rd_DS   <= '1;
        mif.Wr_RW   <= '1;
    endtask : Initialize_Host

    task HostWrite(input int a,                                             // configure
                    input data_pkg::CellCfgType d);
        @(negedge top.clk) mif.Addr <= a; mif.DataIn <= d; mif.Sel <= '0;   // deassert Sel after 1 cycle to select
        @(negedge top.clk) mif.Wr_RW <= '0;                                 // deassert Wr_Rw after 1 cycle to write
        while (mif.Rdy_Dtack !== 1'b0) @(negedge top.clk);                  // waiting Rdy_Dtack is deasserted to indicate writing finished
        @(negedge top.clk) mif.Wr_RW <= '1; mif.Sel <= '1;                  // assert Wr_Rw and Sel to clean up signal
        while (mif.Rdy_Dtack == 1'b0) @(negedge top.clk);                   // waiting Rdy_Dtack no longer deasserts to indicate clean up
    endtask : HostWrite

    task HostRead(input int a,
                  output data_pkg::CellCfgType d);
        @(negedge top.clk) mif.Addr <= a; mif.Sel <= '0;
        @(negedge top.clk) mif.Rd_DS <= '0;                                 // deassert Rd_Ds after 1 cycle to write
        while (mif.Rdy_Dtack !== 1'b0) @(negedge top.clk);                  // waiting Rdy_Dtack is deasserted to indicate reading finished
        @(negedge top.clk) d = mif.DataOut; mif.Rd_DS <= '1; mif.Sel <= '1; // assert Rd_Ds and Sel to clean up signal
        while (mif.Rdy_Dtack == 1'b0) @(negedge top.clk);
    endtask : HostRead

    task run();
        data_pkg::CellCfgType CellFwd;
        Initialize_Host();

        // Configure through Host interface
        repeat (10) @(negedge top.clk);
        $write("Memory: Loading ... ");
        for (int i = 0; i <= 255; i++) begin
            CellFwd.FWD = $urandom();
            `ifdef FWDALL
                CellFwd.FWD = '1;
            `endif
            CellFwd.VPI = i;
            HostWrite(i, CellFwd);                                          // write data to squt's lut
            lookup[i] = CellFwd;                                            // record for verifying
        end
        $display("Loaded");

        // Verify memory
        $write("Memory: Verifying ... ");
        for (int i = 0; i <= 255; i++) begin
            HostRead(i, CellFwd);                                           // read data from squat's lut
            if (lookup[i] != CellFwd) begin
                $display("FATAL, Mem Loc 0x%x contains 0x%x, expected 0x%x", i, CellFwd, lookup[i]);
                $finish;
            end
        end
        $display("Verified");
    endtask : run
endclass // CPU_driver
