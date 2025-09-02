// A label for Driver class to refer
typedef class Driver_cbs;

class Driver;
    mailbox gen2drv;                            // For cells sent from generator
    event   drv2gen;                            // Tell generator when I am done with cell
    vUtopiaRx Rx;                               // Virtual ifc for transmitting cells
    Driver_cbs cbsq[$];                         // deque of callback objects
    int PortID;

    function new(input mailbox gen2drv,
                 input event drv2gen,
                 input vUtopiaRx Rx,
                 input int PortID);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
        this.Rx      = Rx;
        this.PortID  = PortID;
    endfunction : new

    // run(): Run the driver
    // Get transaction from generator, send into DUT
    task run();
        UNI_cell c;
        bit drop = '0;

        // Initialize ports
        Rx.cbr.data <= '0;
        Rx.cbr.soc  <= '0;
        Rx.cbr.clav <= '0;

        forever begin
            // Read the Cell at the front of the mailbox
            gen2drv.peek(c);
            begin : Tx
                // Pre-transmit callbacks
                foreach(cbsq[i]) begin
                    cbsq[i].pre_tx(this, c, drop);
                    if (drop) disable Tx;       // Don't transmit this cell
                end
                // Transmit
                c.display($sformatf("@%0t: Drv%0d: ", $time, PortID));
                send(c);
                // Post-transmit callbacks
                foreach(cbsq[i])
                    cbsq[i].post_tx(this, c);
            end : Tx
            // Remove cell from the mailbox
            gen2drv.get(c);
            // Tell the generator we are done with this cell
            ->drv2gen;
        end
    endtask : run

    // send(): Send a cell into the DUT
    task send(input UNI_cell c);
        data_pkg::ATMCellType Pkt;
        c.pack(Pkt);
        
        $write("Sending cell: ");
        foreach (Pkt.Mem[i])
            $write("%x ", Pkt.Mem[i]);
        $display();

        // Iterate through bytes of cell
        @(Rx.cbr);
        Rx.cbr.clav <= '1;
        for (int i = 0; i <= 52; i++) begin     // a package has 53 bytes
            // If not enabled (active-low), loop
            while (Rx.cbr.en === 1'b1) @(Rx.cbr);

            // Assert Start Of Cell (soc), assert enable, send byte 0 (i==0)
            Rx.cbr.soc <= (i == 0);
            Rx.cbr.data <= Pkt.Mem[i];
            @(Rx.cbr);
        end

        // Clean up
        Rx.cbr.soc <= 'z;
        Rx.cbr.data <= 'x;
        Rx.cbr.clav <= '0;
    endtask : send
endclass // Driver

// A Driver_cbs base class with virtual functions
class Driver_cbs;
    virtual task pre_tx(input Driver drv,
                        input UNI_cell c,
                        inout bit drop);
    endtask : pre_tx

    virtual task post_tx(input Driver drv,
                         input UNI_cell c);
    endtask : post_tx
endclass // Driver_cbs
