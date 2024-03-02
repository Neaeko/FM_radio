`include "para.svh"
`include "functions.svh"


import para::*;
import functions::*;



module fm_radio_top(
    input   logic   clock,
    input   logic   reset,
    input   logic   [31:0]  i_din,
    input   logic   [31:0]  q_din,
    input   logic   in_wr_en,
    output  logic   in_full,


    input   logic   out_rd_en,
    output  logic   out_empty,
    output  logic   [31:0]  left_out,
    output  logic   [31:0]  right_out

);






// FIR Complex: input stage (1,1)
logic wr_en_input_i_fifo, wr_en_input_q_fifo;
logic rd_en_input_i_fifo, rd_en_input_q_fifo;
logic full_input_i_fifo, full_input_q_fifo;
logic empty_input_i_fifo, empty_input_q_fifo;
logic [31:0] dout_input_i_fifo, dout_input_q_fifo;

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
) input_i_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_input_i_fifo),
    .din(i_din),
    .full(full_input_i_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_input_i_fifo),
    .dout(dout_input_i_fifo),
    .empty(empty_input_i_fifo)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
) input_q_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_input_q_fifo),
    .din(q_din),
    .full(full_input_q_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_input_q_fifo),
    .dout(dout_input_q_fifo),
    .empty(empty_input_q_fifo)
);


fir_complex #(
    .TAP_NUMBER(20),
    .REAL_COEFF(CHANNEL_COEFFS_REAL),
    .IMAG_COEFF(CHANNEL_COEFFS_IMAG),
    .DECIMATION(1),
    .DATA_WIDTH(32)
)fir_cmplx(
    .clock(clock),
    .reset(reset),

    .i_in(dout_input_i_fifo),
    .i_empty(empty_input_i_fifo),
    .i_rd_en(rd_en_input_i_fifo),


    .q_in(dout_input_q_fifo),
    .q_empty(empty_input_q_fifo),
    .q_rd_en(rd_en_input_q_fifo),

    .real_out(din_fir_cmplx_real_fifo),
    .real_wr_en(wr_en_fir_cmplx_real_fifo),
    .real_full(full_fir_cmplx_real_fifo),

    .imag_out(din_fir_cmplx_imag_fifo),
    .imag_wr_en(wr_en_fir_cmplx_imag_fifo),
    .imag_full(full_fir_cmplx_imag_fifo)

);

logic [31:0] din_fir_cmplx_real_fifo, din_fir_cmplx_imag_fifo;
logic [31:0] dout_fir_cmplx_real_fifo, dout_fir_cmplx_imag_fifo;
logic wr_en_fir_cmplx_real_fifo, wr_en_fir_cmplx_imag_fifo;
logic rd_en_fir_cmplx_real_fifo, rd_en_fir_cmplx_imag_fifo;
logic full_fir_cmplx_real_fifo, full_fir_cmplx_imag_fifo;
logic empty_fir_cmplx_real_fifo, empty_fir_cmplx_imag_fifo;


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
) fir_cmplx_real_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_fir_cmplx_real_fifo),
    .din(din_fir_cmplx_real_fifo),
    .full(full_fir_cmplx_real_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_fir_cmplx_real_fifo),
    .dout(dout_fir_cmplx_real_fifo),
    .empty(empty_fir_cmplx_real_fifo)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(32)
) fir_cmplx_imag_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_fir_cmplx_imag_fifo),
    .din(din_fir_cmplx_imag_fifo),
    .full(full_fir_cmplx_imag_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_fir_cmplx_imag_fifo),
    .dout(dout_fir_cmplx_imag_fifo),
    .empty(empty_fir_cmplx_imag_fifo)
);


// DEMODULATION stage: (1,2)








// DEEMPHASIS stage: (1,7)
logic [31:0] din_iir_left_fifo, dout_iir_left_fifo;
logic wr_en_iir_left_fifo, rd_en_iir_left_fifo;
logic full_iir_left_fifo, empty_iir_left_fifo;

iir_normal#(
    .TAP_NUMBER(IIR_COEFF_TAPS),
    .DATA_WIDTH(32),
    .CONV_X_COEFF(IIR_X_COEFF),
    .CONV_Y_COEFF(IIR_Y_COEFF),
    .DECIMATION(1)

)IIR_left(
    .clock(clock)
    .reset(reset),

    .in_dout(),
    .in_empty(),
    .in_rd_en(),


    .out_din(din_iir_left_fifo),
    .out_wr_en(wr_en_iir_left_fifo),
    .out_full(full_iir_left_fifo)

);

fifo #(
    .FIFO_BUFFER_SIZE(128),
    .FIFO_DATA_WIDTH(32)
) iir_left_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_iir_left_fifo),
    .din(din_iir_left_fifo),
    .full(full_iir_left_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_iir_left_fifo),
    .dout(dout_iir_left_fifo),
    .empty(empty_iir_left_fifo)
);




// DEEMPHASIS stage: (2,7)
logic [31:0] din_iir_right_fifo, dout_iir_right_fifo;
logic wr_en_iir_right_fifo, rd_en_iir_right_fifo;
logic full_iir_right_fifo, empty_iir_right_fifo;


iir_normal#(
    .TAP_NUMBER(IIR_COEFF_TAPS),
    .DATA_WIDTH(32),
    .CONV_X_COEFF(IIR_X_COEFF),
    .CONV_Y_COEFF(IIR_Y_COEFF),
    .DECIMATION(1)

)IIR_right(
    .clock(clock)
    .reset(reset),

    .in_dout(),
    .in_empty(),
    .in_rd_en(),


    .out_din(din_iir_right_fifo),
    .out_wr_en(wr_en_iir_right_fifo),
    .out_full(full_iir_right_fifo)

);

fifo #(
    .FIFO_BUFFER_SIZE(128),
    .FIFO_DATA_WIDTH(32)
) iir_right_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_iir_right_fifo),
    .din(din_iir_right_fifo),
    .full(full_iir_right_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_iir_right_fifo),
    .dout(dout_iir_right_fifo),
    .empty(empty_iir_right_fifo)
);




// (1,8) and (2,8): output stage

logic [31:0] din_gain_32_left_out_fifo, din_gain_32_right_out_fifo;
logic [31:0] dout_gain_32_left_out_fifo, dout_gain_32_right_out_fifo;
logic wr_en_gain_32_left_out_fifo, wr_en_gain_32_right_out_fifo;
logic rd_en_gain_32_left_out_fifo, rd_en_gain_32_right_out_fifo;
logic full_gain_32_left_out_fifo, full_gain_32_right_out_fifo;
logic empty_gain_32_left_out_fifo, empty_gain_32_right_out_fifo;


gain_32_mono#(
    .GAIN(1)
)gain_32_left(
    .in_dout(dout_iir_left_fifo),
    .out_din(din_gain_32_left_out_fifo)
);

fifo #(
    .FIFO_BUFFER_SIZE(128),
    .FIFO_DATA_WIDTH(32)
) gain_32_left_out_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_gain_32_left_out_fifo),
    .din(din_gain_32_left_out_fifo),
    .full(full_gain_32_left_out_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_gain_32_left_out_fifo),
    .dout(dout_gain_32_left_out_fifo),
    .empty(empty_gain_32_left_out_fifo)
);



gain_32_mono#(
    .GAIN(1)
)gain_32_right(
    .in_dout(dout_iir_right_fifo),
    .out_din(din_gain_32_right_out_fifo)
);

fifo #(
    .FIFO_BUFFER_SIZE(128),
    .FIFO_DATA_WIDTH(32)
) gain_32_right_out_fifo(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_gain_32_right_out_fifo),
    .din(din_gain_32_right_out_fifo),
    .full(full_gain_32_right_out_fifo),

    .rd_clk(clock),
    .rd_en(rd_en_gain_32_right_out_fifo),
    .dout(dout_gain_32_right_out_fifo),
    .empty(empty_gain_32_right_out_fifo)
);

// output wires
assign left_out = dout_gain_32_left_out_fifo;
assign right_out = dout_gain_32_right_out_fifo;
assign out_empty = empty_gain_32_left_out_fifo || empty_gain_32_right_out_fifo;
// output controls
assign rd_en_gain_32_left_out_fifo = out_rd_en;
assign rd_en_gain_32_right_out_fifo = out_rd_en;


endmodule
