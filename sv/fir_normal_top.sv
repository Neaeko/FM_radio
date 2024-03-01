module fir_normal_top(
    input  logic clock,
    input  logic reset,

    input  logic [31:0] in_din,

    output  logic in_full,
    input   logic in_wr_en,

    output  logic [31:0] out_dout,
    input   logic out_rd_en,
    output  logic out_empty

);

logic in_rd_en, out_wr_en;
logic [31:0] out_din, in_dout;


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
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



fir_normal fir_normal_inst(
    .clock(clock),
    .reset(reset),

    .in_dout(in_dout),
    .in_empty(in_empty),
    .in_rd_en(in_rd_en),

    .out_din(out_din),
    .out_wr_en(out_wr_en),
    .out_full(out_full)

);


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
) out_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .full(out_full),
    .din(out_din),

    .rd_clk(clock),
    .rd_en(out_rd_en),
    .empty(out_empty),
    .dout(out_dout)
);

endmodule