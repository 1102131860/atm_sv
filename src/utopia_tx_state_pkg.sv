package utopia_tx_state_pkg;
    // totally 9 states
    typedef enum logic [0:3] {
        reset,
        soc,
        vpi_vci,
        vci,
        vci_clp_pt,
        hec,
        payload,
        ack,
        done
    } TxStateType;
endpackage
