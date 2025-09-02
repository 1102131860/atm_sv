package utopia_rx_state_pkg;
    // totally 8 states
    typedef enum logic [0:2] {
        reset,
        soc,
        vpi_vci,
        vci,
        vci_clp_pt,
        hec,
        payload,
        ack
    } RxStateType;
endpackage
