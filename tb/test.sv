program automatic test #(
    parameter int NumRx = 4,
    parameter int NumTx = 4
) (
    Utopia_if.TB_RX Rx[0:NumRx-1],
    Utopia_if.TB_TX Tx[0:NumTx-1],
    CPU_if.Test     mif,
    input logic     rst
);
    Environment env;

    //---------------------------------------------------------------------------------
    // Extensions could be added in this test.sv with extended class and implemenation

    // class Config_1_cell extends Config;
    //     constraint one_cells {
    //         nCells == 4;
    //     }

    //     // @Override
    //     function new(input bit [31:0] numRx, numTx);
    //         super.new(numRx, numTx);
    //     endfunction : new
    // endclass // Config_1_cell

    // Callback class used to drop some transactions
    // class Driver_cbs_drop extends Driver_cbs;
    //     // @Override
    //     virtual task pre_tx(input Driver drv,
    //                         input UNI_cell c,
    //                         inout bit drop);
    //         // Randomly drop 1 out of every 100 transcations
    //         drop = ($urandom_range(0,99) == 0);
    //     endtask : pre_tx
    // endclass // Driver_cbs_drop

    initial begin
        env = new(Rx, Tx, NumRx, NumTx, mif);

        // assign a new constrianted cfg after env is constructed and before generate a new cfg 
        // begin
        //     Config_1_cell c1 = new(NumRx, NumTx);
        //     env.cfg = c1;
        // end

        env.gen_cfg();
        env.build();

        // Add Drop callbacks after env is configurated and before sending cells
        // begin
        //     Driver_cbs_drop dcd = new();
        //     foreach (drv[i])
        //         drv[i].cbsq.push_back(dcd);
        // end

        env.run();
        env.wrap_up();
    end
endprogram  // test
