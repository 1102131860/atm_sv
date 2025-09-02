`ifndef INCLUDE_SVH
`define INCLUDE_SVH

`define SV_RAND_CHECK(r) \
    do begin \
        if (!(r)) begin \
            $fatal("%s: %0d: Randomization failed \"%s\"", \
            `__FILE__, `__LINE__, `"r`"); \
            $finish; \
        end \
    end while (0)

`define SV_CAST_CHECK(r) \
    do begin \
        if (!(r)) begin \
            $fatal("%s: %0d: Dynamic cast failed \"%s\"", \
            `__FILE__, `__LINE__, `"r`"); \
            $finish; \
        end \
    end while (0)

`endif
