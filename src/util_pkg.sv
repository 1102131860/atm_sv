package util_pkg;
    /////////////////////////////////////////////////////
    // Helper Function to compute the HEC value
    /////////////////////////////////////////////////////
    typedef logic [7:0] table_t [0:255];

    function table_t initialize_syndrom();
        static logic [7:0] sndrm;
        table_t t;
        int i;
        for (i = 0; i < 256; i++) begin
            sndrm = i;
            repeat (8) begin
                if (sndrm[7]) sndrm = (sndrm << 1) ^ 8'h07;
                else          sndrm = (sndrm << 1);
            end
            t[i] = sndrm;
        end
        return t;
    endfunction

    localparam table_t syndrom = initialize_syndrom();
    function automatic logic [7:0] hec(input logic [31:0] hdr);
        // Generate CRC
        logic [ 7:0] RtnCode;                           // initialize when calling function every time
        logic [31:0] h;

        RtnCode = 8'h00;
        h = hdr;
        repeat (4) begin
            RtnCode = syndrom[RtnCode ^ h[31:24]];
            h <<= 8;
        end
        return RtnCode ^ 8'h55;                         // 8'h55 is coset leader but it won't affecting error detecting
    endfunction
endpackage

// // Fibonacci LFSR with 0x07 polynomial: x^8 + x^2 + x^1 + x^0 (1)
// function automatic logic [7:0] hec_fib (input logic [31:0] hdr);
//     logic [7:0] crc;
//     logic [7:0] byte;
//     logic       fb;
    
//     crc = 8'h00;
//     for (int b = 4; b >= 1; b--) begin
//         byte = hdr32[b*8 - 1 -: 8]; // [31:24], [23:16], [15:8], [7:0]
//         for (int i = 7; i >= 0; i--) begin
//             fb = crc[7] ^ byte[i];          // 1. compute feedback bit: MSB XOR input_bit (x^8)
//             crc = {crc[6:0], 1'b0};         // 2. shift left by 1 bit
//             if (fb) crc ^= 8'h07;           // 8'b0000_0111, 3. if feedback, feedback XOR residual (x^2 + x^1 + x^0)
//         end 
//     end

//     return crc ^ 8'h55;                     // crc encoding with 0x55
// endfunction

// // Galois LFSR with 0x07 polynomial: x^8 + x^2 + x^1 + x^0 = 8'h07
// function automatic logic [7:0] hec_gal (input logic [31:0] hdr);
//     logic [7:0] crc;
//     logic [7:0] byte;
//     logic       fb;
    
//     crc = 8'h00;
//     for (int b = 4; b >= 1; b--) begin
//         byte = hdr32[b*8 - 1 -: 8]; // [31:24], [23:16], [15:8], [7:0]
//         for (int i = 7; i >= 0; i--) begin
//             fb = crc[7] ^ byte[i];          // 1. compute feedback bit: MSB XOR input_bit (x^7)
//             crc = {                         // 2. shift left by 1 bit and may xor with feedback
//                 crc[6:2],                   // crc[7] = crc[6]; crc[6] = crc[5]; crc[5] = crc[4]; crc[4] = crc[3]; crc[3] = crc[2];
//                 crc[1]^fb,                  // crc[2] = crc[1] ^ fb;
//                 crc[0]^fb,                  // crc[1] = crc[0] ^ fb;
//                 fb                          // crc[0] = fb;
//             };
//         end 
//     end

//     return crc ^ 8'h55;                     // crc encoding with 0x55
// endfunction
