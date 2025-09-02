// A label for Monitor Class to refer
typedef class Monitor_cbs;

class Monitor;
    vUtopiaTx Tx;                               // Virtual interface with output of DUT
    Monitor_cbs cbsq[$];                        // Deque of callback objects
    int PortID;                                 // the original is bit [1:0], which Tx port are we monitoring?

    function new(input vUtopiaTx Tx, input int PortID);
        this.Tx     = Tx;
        this.PortID = PortID;
    endfunction : new

    // run(): Run the mointor
    task run();
        NNI_cell c;

        forever begin
            receive(c);
            foreach (cbsq[i])
                cbsq[i].post_rx(this, c);       // Post-receive callback
        end
    endtask : run

    // receive(): Read cell from the DUT, pack into a NNI cell
    task receive(output NNI_cell c);
        data_pkg::ATMCellType Pkt;

        Tx.cbt.clav <= '1;
        // wait until Start of Cell and enabled (active-low)
        while (Tx.cbt.soc !== 1'b1 && Tx.cbt.en !== 1'b0) @(Tx.cbt);
        for (int i = 0; i <= 52; i++) begin     // a package has 53 bytes
            // If not enabled, loop
            while (Tx.cbt.en !== 1'b0) @(Tx.cbt);
            // sample output with blocking-assignment
            Pkt.Mem[i] = Tx.cbt.data;
            @(Tx.cbt);
        end

        Tx.cbt.clav <= '0;
        c = new();
        c.unpack(Pkt);
        c.display($sformatf("@%0t: Mon%0d: ", $time, PortID));
    endtask : receive
endclass // Monitor

// A Monitor_cbs base class with virtual functions
class Monitor_cbs;
    virtual task post_rx(input Monitor mon,
                         input NNI_cell c);
    endtask : post_rx
endclass // Monitor_cbs
