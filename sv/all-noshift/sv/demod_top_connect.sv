module demod_top_connect #(
    parameter FIFO_BUFFER_SIZE = 128
)(
    input logic clk,
    input logic reset,
    input logic [31:0] real_in,
    input logic [31:0] img_in,
    input logic in_fifo_wr_en,
    input logic out_fifo_rd_en,
    output logic [31:0] data_out,
    output logic in_fifos_full,
    output logic out_fifo_empty
);
logic real_rd_en,img_rd_en;
logic real_empty,img_empty;
logic [31:0]real_out,img_out;
logic in_real_full,in_img_full;
logic [31:0]demod_out;
logic full_demod,wr_en_demod;
assign in_fifos_full=in_real_full|in_img_full;
fifo #(
    .FIFO_BUFFER_SIZE(32),
    .FIFO_DATA_WIDTH(32)
) fifo_real (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(in_fifo_wr_en),
    .full(in_real_full),
    .din(real_in),

    .rd_clk(clk),
    .rd_en(real_rd_en),
    .dout(real_out),
    .empty(real_empty)
);
fifo #(
    .FIFO_BUFFER_SIZE(32),
    .FIFO_DATA_WIDTH(32)
) fifo_img (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(in_fifo_wr_en),
    .full(in_img_full),
    .din(img_in),

    .rd_clk(clk),
    .rd_en(img_rd_en),
    .dout(img_out),
    .empty(img_empty)
);

demod #(
    .DATA_WIDTH(32),
    .GAIN(758)
) demod (
    .clk(clk),
    .rst(reset),
    .rl(real_out),
    .rd_en_rl(real_rd_en),
    .empty_rl(real_empty),
    .img(img_out),
    .rd_en_img(img_rd_en),
    .empty_img(img_empty),
    .demod_out(demod_out),
    .full_demod(full_demod),
    .wr_en_demod(wr_en_demod)
);
fifo #(
    .FIFO_BUFFER_SIZE(32),
    .FIFO_DATA_WIDTH(32)
) fifo_demod (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(wr_en_demod),
    .full(full_demod),
    .din(demod_out),

    .rd_clk(clk),
    .rd_en(out_fifo_rd_en),
    .dout(data_out),
    .empty(out_fifo_empty)
);
endmodule