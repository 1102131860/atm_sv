package data_pkg;
    //////////////////////////////////////////////////////////////////
    // Data Abstraction
    //////////////////////////////////////////////////////////////////
    // The two ATM formats used in this ATM design are the `UNT` format
    // and the `NNI` format

    // An ATM cell simply consists of 53 bytes of data (5-byte head + 48-byte payload)
    // UNI Cell Format
    // |7           4|3            0|
    // |GFC          |   VPI_{7-4}  |
    // |VPI_{3-0}    |   VCI_{15-12}|
    // |        VCI_{11-4}          |
    // |VCI_{3-0}    |CLP|    PT    |
    // |        HEC                 |
    // |        Payload 0           |
    // |        ......              |
    // |        Payload 47          |

    // NNI Cell Format
    // |7           4|3            0|
    // |        VPI_{11-4}          |
    // |VPI_{3-0}    |   VCI_{15-12}|
    // |        VCI_{11-4}          |
    // |VCI_{3-0}    |CLP|    PT    |
    // |        HEC                 |
    // |        Payload 0           |
    // |        ......              |
    // |        Payload 47          |

    // Using packed structure definitions for the two different formats
    // is easy in Systemverilog and makes each cell member easily identifiable
    typedef struct packed {                 // for systhesis, must use packed struct
        logic        [ 3:0] GFC;            // Generic Flow Control; For local access control at the user-network interface, usually 0
        logic        [ 7:0] VPI;            // Virtual Path Identifier; Groups many VCs into a Path; used for coarse routing/switching
        logic        [15:0] VCI;            // Virtual Channel Identifier; Fine-grained connection ID within a VPI; used for per-connection switching
        logic               CLP;            // Cell Loss Priority. 0 = high priority (prefer to keep); 1 = low priority (drop first under congestion)
        logic        [ 2:0] PT;             // Payload Type Indicator; bit 1 (MSB): User Data (0) or Control (1); bit 2: not last segment (0) or is (1); bit 3: not congested (0) or is (1)
        logic        [ 7:0] HEC;            // Header Error Control. CRC-8 over the first 4 header bytes; used for header error detection/correction
        logic [0:47] [ 7:0] Payload;        // for union, must use packed array 
    } uniType;

    typedef struct packed {
        logic        [11:0] VPI;
        logic        [15:0] VCI;
        logic               CLP;
        logic        [ 2:0] PT;
        logic        [ 7:0] HEC;
        logic [0:47] [ 7:0] Payload;
    } nniType;

    // // Used only for testbenches
    // typedef struct packed {
    //     logic [0:4 ] [7:0] Header;
    //     logic [0:3 ] [7:0] PortID;
    //     logic [0:3 ] [7:0] PacketID;
    //     logic [0:39] [7:0] Padding;
    // } tstType;

    // 53 byte array of data can now be easily treadted as though it
    // were either of these formats, or as a simple array of bytes
    typedef union packed {
        uniType uni;
        nniType nni;
        // tstType tst;
        logic [0:52] [7:0] Mem;         // can also be viewed as a 53 bytes memoery
    } ATMCellType;

    //////////////////////////////////////////////////////////////////
    // CPU Configuratuion Definition
    //////////////////////////////////////////////////////////////////
    // CPU peripheral configuration Packet
    typedef struct packed {
        logic [`TxPorts-1:0] FWD;       // forwarding; each bit corresponds to one port (1 to forward to that port), `TxPorts shoud be equal to NumTx
        logic [11:0]         VPI;
    } CellCfgType;
endpackage