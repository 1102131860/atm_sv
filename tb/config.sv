class Config;
    int nErrors, nWarnings;         // Number of errors, warnings (this could be referring data for the entire test)
    bit [31:0] numRx, numTx;        // Copy of parameters
    
    rand bit [31:0] nCells;         // Total cells
    rand bit in_use_Rx[];           // Input / output channel enabled （mask)
    rand bit [31:0] cells_per_chan[];// cells for different channels
    
    constraint c_nCells_valid {
        nCells > 0;
    }
    constraint c_nCells_reasonable {
        nCells < 1000;
    }
    // At least one Rx is enabled
    constraint c_in_use_valid {
        in_use_Rx.sum() > 0;
    }
    // Split cells over all channels
    constraint c_sum_ncells_sum {
        cells_per_chan.sum() == nCells; // Total number of cells
    }
    // Set the cell count to zero for any channel not in use
    constraint zero_unused_channels {
        foreach (cells_per_chan[i]) {
            solve in_use_Rx[i] before cells_per_chan[i];
            if (in_use_Rx[i])
                cells_per_chan[i] inside {[1:nCells]};
            else
                cells_per_chan[i] == 0;
        }
    }

    // new() firstly, then randomize()
    function new(input bit [31:0] numRx, numTx);
        this.numRx = numRx;
        this.numTx = numTx;
        in_use_Rx = new[numRx];
        cells_per_chan = new[numRx];
    endfunction : new

    function void display(input string prefix="");
        $write("%sConfig: numRx=%0d, numTx=%0d, nCells=%0d (", prefix, numRx, numTx, nCells);
        foreach (cells_per_chan[i])
            $write("%0d ", cells_per_chan[i]);
        $write("), enabled Rx: %s", prefix);
        foreach(in_use_Rx[i])
            if (in_use_Rx[i]) $write("%0d ", i);
        $display();
    endfunction : display
endclass // Config
