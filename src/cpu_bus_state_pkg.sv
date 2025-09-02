package cpu_bus_state_pkg;
    // CPU bus mode cycle definition
    typedef enum logic [0:1] {
        ReadCycle  = 2'b01,
        WriteCycle = 2'b10,
        IdleCycle  = 2'b11
    } BusCycleType; 
endpackage
