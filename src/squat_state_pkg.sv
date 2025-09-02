package squat_state_pkg;
    // squat state definition
    typedef enum logic [0:1] {
        wait_rx_valid,
        wait_rx_not_valid,
        wait_tx_ready,
        wait_tx_not_ready
    } StateType;
endpackage
