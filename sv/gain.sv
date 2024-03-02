module gain_32_mono#(
    parameter GAIN = 1
)(
    input  logic [31:0] in_dout,
    output  logic [31:0] out_din
);


always_comb begin
    out_din = mul_frac10_32b(in_dout, GAIN) << (14-10);
end


// fixed point multiplication
function automatic logic [31:0] mul_frac10_32b (
    input logic [31:0] ina,
    input logic [31:0] inb
);
    // Perform the multiplication
    logic [63:0] product = $signed(ina) * $signed(inb);

    // Shift the product right by 10 bits to maintain the 10-bit fractional part
    logic [31:0] result = product >> 10;

    return result;
endfunction

endmodule