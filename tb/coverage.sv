class Coverage;
    localparam IndexWidth = (`TxPorts > 1) ? $clog2(`TxPorts) : 1;
    bit [IndexWidth-1:0] src;                   // the Tx port are we monitoring
    bit [`TxPorts-1:0] fwd;                     // all possible forwarded ports mask

    covergroup CG_Forward;
        option.per_instance = 1;

        cp_src: coverpoint src {
            bins bin_src[] = {[0:`TxPorts-1]};
        }
        cp_fwd: coverpoint fwd {
            bins bin_fwd[] = {[1:((1 << `TxPorts) - 1)]}; // if drop is enabled, [0:((1 << `TxPorts) - 1)]
        }
        cp_src_fwd: cross cp_src, cp_fwd {
            // option.weight = 0;                  // Don't count this coverpoint
        }
    endgroup : CG_Forward
    
    function new();
        CG_Forward = new();                     // Instantiate the covergroup
    endfunction : new

    // Sample input data
    function void sample(input int src,
                         input logic [`TxPorts-1:0] fwd);
        this.src = src[IndexWidth-1:0];    // {IndexWidth{1'b1}} & src;
        this.fwd = fwd;
        $display("@%0t: Coverage: src = %d. fwd = %b", $time, this.src, this.fwd);
        // sample input data
        CG_Forward.sample();
    endfunction : sample
endclass // Coverage
