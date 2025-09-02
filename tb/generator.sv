class UNI_generator;
    UNI_cell blueprint;             // Blueprint for generator
    mailbox  gen2drv;               // Mailbox to driver for cells
    event    drv2gen;               // Event from driver when done with cell
    int      nCells;                // Num cells for this generator to create
    int      PortID;                // Which Rx port are we generating?

    function new(input mailbox gen2drv,
                 input event drv2gen,
                 input int nCells, PortID);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
        this.nCells  = nCells;
        this.PortID  = PortID;
        blueprint    = new(); 
    endfunction : new

    task run();
        UNI_cell c;
        repeat (nCells) begin
            `SV_RAND_CHECK(blueprint.randomize());
            `SV_CAST_CHECK($cast(c, blueprint.copy()));
            c.display($sformatf("@%0t: Gen%0d: ", $time, PortID));
            gen2drv.put(c);
            @drv2gen;               // wait for driver to finish with it
        end
    endtask : run
endclass // UNI_generator
