class Environment;
    UNI_generator gen[];
    mailbox gen2drv[];
    event   drv2gen[];
    Driver  drv[];
    Monitor mon[];
    Config  cfg;
    Scoreboard scb;
    Coverage cov;
    vUtopiaRx Rx[];
    vUtopiaTx Tx[];
    int numRx, numTx;
    vCPU_T    mif;
    CPU_driver cpu;

    //---------------------------------------------------------------------
    // Construct an environment instance
    function new(input vUtopiaRx Rx[],
                 input vUtopiaTx Tx[],
                 input int numRx, numTx,
                 input vCPU_T mif);
        this.Rx = new[Rx.size()];
        foreach (Rx[i])
            this.Rx[i] = Rx[i];
        this.Tx = new[Tx.size()];
        foreach (Tx[i])
            this.Tx[i] = Tx[i];
        this.numRx = numRx;
        this.numTx = numTx;
        this.mif = mif;
        cfg = new(numRx, numTx);

        if ($test$plusargs("ntb_random_seed")) begin
            int seed;
            $value$plusargs("ntb_random_seed=%d", seed);
            $display("Simulation run with random seed = %0d", seed);
        end
        else
            $display("Simulation run with default random seed");
    endfunction : new

    //---------------------------------------------------------------------
    // Randomize the configuration descriptor
    function void gen_cfg();
        `SV_RAND_CHECK(cfg.randomize());
        cfg.display();
    endfunction : gen_cfg

    //---------------------------------------------------------------------
    // Build the environment objects for this test
    // Note that objects are built for every channel,
    // even if they are not used. This reduces null handle bugs.
    function void build();
        gen = new[numRx];
        drv = new[numRx];
        gen2drv = new[numRx];
        drv2gen = new[numRx];
        mon = new[numTx];
        scb = new(cfg);
        cov = new();
        cpu = new(mif);

        // Build generators
        foreach (gen[i]) begin
            // event doesn't need to new()
            gen2drv[i] = new();         // infinite depth of mailbox: new()
            gen[i] = new(gen2drv[i], drv2gen[i], cfg.cells_per_chan[i], i);
            drv[i] = new(gen2drv[i], drv2gen[i], Rx[i], i);
        end

        // Build monitors
        foreach (mon[i])
            mon[i] = new(Tx[i], i);

        // Connect scoreboard to drivers & monitors with callbacks
        begin
            Scb_Driver_cbs  sdc = new(scb);
            Scb_Monitor_cbs smc = new(scb);
            foreach (drv[i])
                drv[i].cbsq.push_back(sdc);
            foreach (mon[i])
                mon[i].cbsq.push_back(smc);
        end

        // Connect coverage to monitor with callbacks
        begin
            Cov_Monitor_cbs cmc = new(cov);
            foreach (mon[i])
                mon[i].cbsq.push_back(cmc);
        end
    endfunction : build

    //---------------------------------------------------------------------
    // Start the transactors: generators, drivers, monitors
    // Channels that are not in use don't get started
    task run();
        int num_gen_running;
        
        // The CPU interface initialize before anyone else
        cpu.run();

        num_gen_running = numRx;

        // For each input Rx channel, start generator and driver
        foreach (gen[i]) begin
            int j = i;                  // Automatic var holds index in spawned threads
            fork
                begin
                    if (cfg.in_use_Rx[j])
                        gen[j].run();   // Wait for generator to finish
                    num_gen_running--;  // Decrement driver count
                end
                if (cfg.in_use_Rx[j])
                    drv[j].run();
            join_none
        end

        // For each output Tx channel, start monitor
        foreach (gen[i]) begin
            int j = i;                  // Automatic var holds index in spawned threads
            fork
                mon[j].run();
            join_none
        end

        // Wait for all generators to finish, or time-out
        fork : timeout_block
            wait (num_gen_running == 0);
            begin
                repeat(1_0000_000) @(Rx[0].cbr);
                $display("@%0t: %m ERROR: Generator timeout ", $time);
                cfg.nErrors++;
            end
        join_any
        disable timeout_block;

        // Wait for the data to flow through switch, into monitors,
        // and scoreboards
        repeat(1_000) @(Rx[0].cbr); 
    endtask : run

    //---------------------------------------------------------------------
    // Post-run cleanup / reporting
    function void wrap_up();
        $display("@%0t: End of sim, %0d errors, %0d warnings", $time, cfg.nErrors, cfg.nWarnings);
        scb.wrap_up();
    endfunction : wrap_up
endclass // Environment
