package functs;



function logic[31:0] DEQUANTIZE; 
input logic[31:0] i;
    begin
	logic [31:0] result;
        //return int'($signed(i) / $signed(1 << 10));
	result = (i[31] == 1'b1) ? (($signed(i) + (1 << 10) - 1) >> 10) : (i >> 10);
	return result;
    end
endfunction

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


/*
function automatic logic [31:0] mul_frac10_32b (
    input logic [31:0] ina,
    input logic [31:0] inb
);
  // Define BITS and QUANT_VAL as local parameters with the same values as in the C++ macro
  localparam int BITS = 10;
  localparam int QUANT_VAL = 1 << BITS;
  // Define RECIP_QUANT_VAL as a fixed-point value with 10 bits for the fractional part and 22 bits for the integer part
  localparam bit [31:0] RECIP_QUANT_VAL = 32'h40000000 / QUANT_VAL;

  // Perform the multiplication using fixed-point arithmetic
  logic [63:0] product = $signed(ina) * $signed(inb);

  // Dequantize the product by multiplying it with the reciprocal of QUANT_VAL
  logic [31:0] dequantized_product = $round(product * RECIP_QUANT_VAL);

  // Quantize the result by multiplying it with QUANT_VAL and rounding to the nearest integer
  logic [31:0] quantized_result = $round(dequantized_product * QUANT_VAL);

  return quantized_result;
endfunction
*/
// very slow, for debug only
/*
function automatic logic [31:0] mul_frac10_32b (
    input logic [31:0] ina,
    input logic [31:0] inb
);
    // Perform the multiplication
    longint product = $signed(ina) * $signed(inb);

    return int'($signed(product) / $signed(1 << 10));
endfunction
*/

// very slow, for debug only




endpackage



