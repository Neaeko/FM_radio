module fir_complex_top#(
    parameter FIFO_BUFFER_SIZE_IN = 512,
    parameter FIFO_BUFFER_SIZE_OUT = 256
)(
    input  logic clock,
    input  logic reset,

    input  logic [31:0] i_in,
    input  logic [31:0] q_in,

    output  logic in_full,
    input   logic in_wr_en,

    output  logic [31:0] real_dout,
    output  logic [31:0] imag_dout,
    input   logic out_rd_en,
    output  logic out_empty

);

logic i_full, q_full, i_empty, q_empty, i_rd_en, q_rd_en;
logic real_empty, imag_empty;
assign in_full = i_full || q_full;
assign out_empty = real_empty && imag_empty;
logic [31:0] real_out, imag_out, i_dout, q_dout;
logic real_wr_en, imag_wr_en, real_full, imag_full;



fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE_IN),
    .FIFO_DATA_WIDTH(32)
) i_in_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .full(i_full),
    .din(i_in),

    .rd_clk(clock),
    .rd_en(i_rd_en),
    .dout(i_dout),
    .empty(i_empty)
);

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE_IN),
    .FIFO_DATA_WIDTH(32)
) q_in_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .full(q_full),
    .din(q_in),

    .rd_clk(clock),
    .rd_en(q_rd_en),
    .dout(q_dout),
    .empty(q_empty)
);


fir_complex fir_cmplx(
    .clock(clock),
    .reset(reset),

    .i_in(i_dout),
    .i_empty(i_empty),
    .i_rd_en(i_rd_en),


    .q_in(q_dout),
    .q_empty(q_empty),
    .q_rd_en(q_rd_en),

    .real_out(real_out),
    .real_wr_en(real_wr_en),
    .real_full(real_full),

    .imag_out(imag_out),
    .imag_wr_en(imag_wr_en),
    .imag_full(imag_full)

);


fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE_OUT),
    .FIFO_DATA_WIDTH(32)
) out_real_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(real_wr_en),
    .full(real_full),
    .din(real_out),

    .rd_clk(clock),
    .rd_en(out_rd_en),
    .empty(real_empty),
    .dout(real_dout)
);

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE_OUT),
    .FIFO_DATA_WIDTH(32)
) out_imag_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(imag_wr_en),
    .full(imag_full),
    .din(imag_out),

    .rd_clk(clock),
    .rd_en(out_rd_en),
    .empty(imag_empty),
    .dout(imag_dout)
);

endmodule