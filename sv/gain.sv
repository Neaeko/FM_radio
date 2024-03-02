module fir_complex_top#(
    parameter GAIN = 1
)(
    input  logic clock,
    input  logic reset,

    input  logic [31:0] left_in_dout,
    input  logic [31:0] right_in_dout,

    output  logic in_full,
    input   logic in_wr_en,

    output  logic [31:0] right_out_din,
    output  logic [31:0] left_out_din,
    input   logic out_rd_en,
    output  logic out_empty

);




endmodule