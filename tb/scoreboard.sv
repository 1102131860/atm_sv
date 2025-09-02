class Expect_cells;
    NNI_cell q[$];
    int iexpect, iactual;
endclass // Expect_cells

class Scoreboard;
    Config cfg;
    Expect_cells expect_cells[];
    int iexpect, iactual;

    function new (input Config cfg);
        this.cfg     = cfg;
        expect_cells = new[cfg.numTx];
        foreach (expect_cells[i])
            expect_cells[i] = new();
    endfunction : new

    function void save_expected(input UNI_cell ucell);
        NNI_cell ncell = ucell.to_NNI();
        data_pkg::CellCfgType CellCfg = top.squat.lut.read(ncell.VPI);

        $display("@%0t: Scb save: VPI=%0x, Forward=%b", $time, ncell.VPI, CellCfg.FWD);
        ncell.display($sformatf("@%0t: Scb save: ", $time));

        // Find all Tx ports where this cell will be forwarded
        for (int i = 0; i < cfg.numTx; i++)
            if (CellCfg.FWD[i]) begin
                expect_cells[i].q.push_back(ncell);     // Save cell in this q
                expect_cells[i].iexpect++;
                iexpect++;
            end
    endfunction : save_expected

    function void check_actual(input NNI_cell c,
                               input int portn);
        c.display($sformatf("@%0t: Scb check: ", $time));
        if (expect_cells[portn].q.size() == 0) begin
            $display("@%0t: ERROR: %m cell not found, SCB TX%0d empty", $time, portn);
            c.display("Not Found: ");
            cfg.nErrors++;
            return;                                     // empty: breaks
        end

        expect_cells[portn].iactual++;
        iactual++;

        foreach (expect_cells[portn].q[i]) begin
            if (expect_cells[portn].q[i].compare(c)) begin
                $display("@%0t: Match found for cell", $time);
                expect_cells[portn].q.delete(i);
                return;                                 // successfully match
            end
        end

        $display("@%0t: ERROR: %m cell not found", $time);
        c.display("Not Found: ");
        cfg.nErrors++;                                  // not empty but fail to match
    endfunction : check_actual

    // Print end of simulation report
    function void wrap_up();
        $display("@%0t: %m %0d expected cells, %0d actual cells received", $time, iexpect, iactual);

        // Look for leftover cells
        foreach (expect_cells[i]) begin
            // after check_actual, expect_cells[i].q should be empty
            if (expect_cells[i].q.size()) begin
                $display("@%0t: %m cells in Scoreboard Tx[%0d] at end of test", $time, i);
                this.display("Unclaimed: ");
                cfg.nErrors++;
            end
        end
    endfunction : wrap_up

    // Print the contents of the scoreboard, mainly for debugging
    function void display(input string prefix="");
        $display("@%0t: %m so far %0d expected cells, %0d actual received", $time, iexpect, iactual);
        foreach (expect_cells[i]) begin
            $display("Tx[%0d]: exp=%0d, act=%0d", i, expect_cells[i].iexpect, expect_cells[i].iactual);
            foreach (expect_cells[i].q[j])
                expect_cells[i].q[j].display($sformatf("%sScoreboard: Tx%0d: ", prefix, i));
        end
    endfunction : display
endclass
