// Callback class connects driver and scoreboard
class Scb_Driver_cbs extends Driver_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
        this.scb = scb;
    endfunction : new

    // @Override
    // Send received cell to scoreboard
    virtual task post_tx(input Driver drv,
                         input UNI_cell c);
        scb.save_expected(c);
    endtask : post_tx
endclass // Scb_Driver_cbs

// Callback class connects monitor and scoreboard
class Scb_Monitor_cbs extends Monitor_cbs;
    Scoreboard scb;

    function new(input Scoreboard scb);
        this.scb = scb;
    endfunction : new

    // @Override
    // Send received cell to scoreboard
    virtual task post_rx(input Monitor mon,
                         input NNI_cell c);
        scb.check_actual(c, mon.PortID);
    endtask : post_rx
endclass // Scb_Monitor_cbs

// Callback class connects the monitor and coverage
class Cov_Monitor_cbs extends Monitor_cbs;
    Coverage cov;

    function new(input Coverage cov);
        this.cov = cov;
    endfunction : new

    // @Override
    // Send received cell to coverage
    virtual task post_rx(input Monitor mon,
                         input NNI_cell c);
        data_pkg::CellCfgType Cellcfg = top.squat.lut.read(c.VPI);
        cov.sample(mon.PortID, Cellcfg.FWD);
    endtask : post_rx
endclass // Cov_Monitor_cbs
