module gain_32_top#(
    parameter GAIN = 10,
    parameter DATA_WIDTH = 32
)(
    input  logic clock,
    input  logic reset,


    input  logic [DATA_WIDTH-1:0] in_din,
    input  logic in_wr_en,
    output logic in_full,

    output  logic [DATA_WIDTH-1:0] out_dout,
    input   logic out_rd_en,
    output   logic out_empty
);

logic in_rd_en, out_wr_en, in_empty, out_full;
logic [DATA_WIDTH-1:0] in_dout, out_din;


assign in_rd_en =  ~in_empty ;
assign out_wr_en = ~in_empty ;

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) in_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .full(in_full),
    .din(in_din),

    .rd_clk(clock),
    .rd_en(in_rd_en),
    .dout(in_dout),
    .empty(in_empty)
);


gain_32_mono#(
        .GAIN(GAIN)
) gain_32_mono_inst(
    .in_dout(in_dout),
    .out_din(out_din)
);




fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) out_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .full(out_full),
    .din(out_din),

    .rd_clk(clock),
    .rd_en(out_rd_en),
    .dout(out_dout),
    .empty(out_empty)
);



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