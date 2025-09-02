interface LUT_if #(
    parameter int Asize = 8,
    parameter int Arange = 1 << Asize,      // 2 ^ Asize
    parameter type dType = logic
);
    dType Mem [0:Arange-1];                 // unpacked array

    // Function to perform write
    function void write (input [Asize-1:0] addr, input dType data);
        Mem[addr] = data;
    endfunction

    // Function to perform read
    function dType read (input logic [Asize-1:0] addr);
        return (Mem[addr]);
    endfunction
endinterface //LUT_if
