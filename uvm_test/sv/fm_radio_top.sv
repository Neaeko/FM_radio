`include "para.svh"
`include "functions.svh"

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

import para::*;
import functs::*;



/*
localparam int IIR_X_COEFF [0:IIR_COEFF_TAPS-1]= {
	            178,178
};
localparam int IIR_Y_COEFF [IIR_COEFF_TAPS-1:0]= {
                0,-666
};
*/



// FIR Complex: input stage (1,1)
    logic wr_en_input_i_fifo, wr_en_input_q_fifo;
    logic rd_en_input_i_fifo, rd_en_input_q_fifo;
    logic full_input_i_fifo, full_input_q_fifo;
    logic empty_input_i_fifo, empty_input_q_fifo;
    logic [31:0] dout_input_i_fifo, dout_input_q_fifo;
	 
	 assign in_full = full_input_i_fifo || full_input_q_fifo;

    fifo #(
        .FIFO_BUFFER_SIZE(512),
        .FIFO_DATA_WIDTH(32)
    ) input_i_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(in_wr_en),
        .din(i_din),
        .full(full_input_i_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_input_i_fifo),
        .dout(dout_input_i_fifo),
        .empty(empty_input_i_fifo)
    );

    fifo #(
        .FIFO_BUFFER_SIZE(512),
        .FIFO_DATA_WIDTH(32)
    ) input_q_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(in_wr_en),
        .din(q_din),
        .full(full_input_q_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_input_q_fifo),
        .dout(dout_input_q_fifo),
        .empty(empty_input_q_fifo)
    );
    
    logic [31:0] din_fir_cmplx_real_fifo, din_fir_cmplx_imag_fifo;
    logic [31:0] dout_fir_cmplx_real_fifo, dout_fir_cmplx_imag_fifo;
    logic wr_en_fir_cmplx_real_fifo, wr_en_fir_cmplx_imag_fifo;
    logic rd_en_fir_cmplx_real_fifo, rd_en_fir_cmplx_imag_fifo;
    logic full_fir_cmplx_real_fifo, full_fir_cmplx_imag_fifo;
    logic empty_fir_cmplx_real_fifo, empty_fir_cmplx_imag_fifo;

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


// DEMODULATION 
// stage: (1,2), with 3 fifos to write

    logic [31:0] din_demod_result; // fed to 3 fifo write
    logic full_demod;  // received from 3 fifo full
    logic wr_en_demod; // fed to 3 fifo write

    demod #(
        .DATA_WIDTH(32),
        .GAIN(758)
    )demodulation_inst (
        .clk(clock),
        .rst(reset),

        .rl(dout_fir_cmplx_real_fifo),
        .rd_en_rl(rd_en_fir_cmplx_real_fifo),
        .empty_rl(empty_fir_cmplx_real_fifo),

        .img(dout_fir_cmplx_imag_fifo),
        .empty_img(empty_fir_cmplx_imag_fifo),
        .rd_en_img(rd_en_fir_cmplx_imag_fifo),

        .demod_out(din_demod_result),
        .full_demod(full_demod),           //input
        .wr_en_demod(wr_en_demod)          //output

    );


// FIR_normal: First feedin from DEMODULATION stage
// L-R Channel Filter, Band-pass 32-tap FIR filter, Extracts the L-R (23-53 kHz) sub-carrier frequencies
// position (1,3)

    logic [31:0] din_fir_lmr_unfiltered_fifo, dout_fir_lmr_unfiltered_fifo;
    logic wr_en_fir_lmr_unfiltered_fifo, rd_en_fir_lmr_unfiltered_fifo;
    logic full_fir_lmr_unfiltered_fifo, empty_fir_lmr_unfiltered_fifo;
    assign din_fir_lmr_unfiltered_fifo = din_demod_result;
    assign wr_en_fir_lmr_unfiltered_fifo = wr_en_demod;

    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
    ) fir_lmr_unfiltered_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_lmr_unfiltered_fifo),
        .din(din_fir_lmr_unfiltered_fifo),
        .full(full_fir_lmr_unfiltered_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_lmr_unfiltered_fifo),
        .dout(dout_fir_lmr_unfiltered_fifo),
        .empty(empty_fir_lmr_unfiltered_fifo)
    );

    
    logic [31:0] din_fir_bp_lmr_out_fifo, dout_fir_bp_lmr_out_fifo;
    logic wr_en_fir_bp_lmr_out_fifo, rd_en_fir_bp_lmr_out_fifo;
    logic full_fir_bp_lmr_out_fifo, empty_fir_bp_lmr_out_fifo;


    fir_normal#(
        .TAP_NUMBER(BP_LMR_COEFF_TAPS),
        // inverse filter coefficients with buffer to ensure correct convolution
        .CONV_COEFF(BP_LMR_COEFFS),
        .DECIMATION(1),
        .DATA_WIDTH(32)

    )fir_bp_lmr(
        .clock(clock),
        .reset(reset),

        .in_dout(dout_fir_lmr_unfiltered_fifo),
        .in_empty(empty_fir_lmr_unfiltered_fifo),
        .in_rd_en(rd_en_fir_lmr_unfiltered_fifo),


        .out_din(din_fir_bp_lmr_out_fifo),
        .out_wr_en(wr_en_fir_bp_lmr_out_fifo),
        .out_full(full_fir_bp_lmr_out_fifo)

    );


    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
    ) fir_bp_lmr_out_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_bp_lmr_out_fifo),
        .din(din_fir_bp_lmr_out_fifo),
        .full(full_fir_bp_lmr_out_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_bp_lmr_out_fifo),
        .dout(dout_fir_bp_lmr_out_fifo),
        .empty(empty_fir_bp_lmr_out_fifo)
    );






/*
    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
    ) fir_lmr_unfiltered_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_),
        .din(din_),
        .full(full_),

        .rd_clk(clock),
        .rd_en(rd_en_),
        .dout(dout_),
        .empty(empty_)
    );
*/



// FIR_normal: Second feedin from DEMODULATION stage
// Pilot tone band-pass filter @ 19kHz
// position (2,1)
    logic [31:0] din_fir_pilot_bp_in_fifo, dout_fir_pilot_bp_in_fifo;
    logic wr_en_fir_pilot_bp_in_fifo, rd_en_fir_pilot_bp_in_fifo;
    logic full_fir_pilot_bp_in_fifo, empty_fir_pilot_bp_in_fifo;
    assign din_fir_pilot_bp_in_fifo = din_demod_result;
    assign wr_en_fir_pilot_bp_in_fifo = wr_en_demod;

        fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
        ) fir_pilot_bp_in_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_pilot_bp_in_fifo),
        .din(din_fir_pilot_bp_in_fifo),
        .full(full_fir_pilot_bp_in_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_pilot_bp_in_fifo),
        .dout(dout_fir_pilot_bp_in_fifo),
        .empty(empty_fir_pilot_bp_in_fifo)
    );
    
    logic [31:0] din_fir_piolet_19;
    logic wr_en_fir_piolet_19, full_fir_piolet_19;

    fir_normal#(
        .TAP_NUMBER(BP_PILOT_COEFF_TAPS),
        // inverse filter coefficients with buffer to ensure correct convolution
        .CONV_COEFF(BP_PILOT_COEFFS),
        .DECIMATION(1),
        .DATA_WIDTH(32)

    )fir_piolet_19(
        .clock(clock),
        .reset(reset),

        .in_dout(dout_fir_pilot_bp_in_fifo),
        .in_empty(empty_fir_pilot_bp_in_fifo),
        .in_rd_en(rd_en_fir_pilot_bp_in_fifo),


        .out_din(din_fir_piolet_19),
        .out_wr_en(wr_en_fir_piolet_19),
        .out_full(full_fir_piolet_19)

    );

// Multiplication stage: (2,2)
    logic [31:0] din_fir_piolet_19_mult;
    assign din_fir_piolet_19_mult = mul_frac10_32b(din_fir_piolet_19, din_fir_piolet_19);




// FIR stage: High pass filter @ 0Hz removes noise after pilot tone is squared
// position: (2,3)

    logic [31:0] din_fir_pilot_end_in_fifo, dout_fir_pilot_end_in_fifo;
    logic wr_en_fir_pilot_end_in_fifo, rd_en_fir_pilot_end_in_fifo;
    logic full_fir_pilot_end_in_fifo, empty_fir_pilot_end_in_fifo;

    assign din_fir_pilot_end_in_fifo = din_fir_piolet_19_mult;
    assign wr_en_fir_pilot_end_in_fifo = wr_en_fir_piolet_19;
    assign  full_fir_piolet_19 = full_fir_pilot_end_in_fifo;
    
    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
        ) fir_pilot_end_in_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_pilot_end_in_fifo),
        .din(din_fir_pilot_end_in_fifo),
        .full(full_fir_pilot_end_in_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_pilot_end_in_fifo),
        .dout(dout_fir_pilot_end_in_fifo),
        .empty(empty_fir_pilot_end_in_fifo)
    );

    logic [31:0] din_fir_pilot_end_out_fifo, dout_fir_pilot_end_out_fifo;
    logic wr_en_fir_pilot_end_out_fifo, rd_en_fir_pilot_end_out_fifo;
    logic full_fir_pilot_end_out_fifo, empty_fir_pilot_end_out_fifo;


    fir_normal#(
        .TAP_NUMBER(HP_COEFF_TAPS),
        // inverse filter coefficients with buffer to ensure correct convolution
        .CONV_COEFF(HP_COEFFS),
        .DECIMATION(1),
        .DATA_WIDTH(32)

    )fir_piolet_hp(
        .clock(clock),
        .reset(reset),

        .in_dout(dout_fir_pilot_end_in_fifo),
        .in_empty(empty_fir_pilot_end_in_fifo),
        .in_rd_en(rd_en_fir_pilot_end_in_fifo),


        .out_din(din_fir_pilot_end_out_fifo),
        .out_wr_en(wr_en_fir_pilot_end_out_fifo),
        .out_full(full_fir_pilot_end_out_fifo)

    );

    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
        ) fir_pilot_end_out_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_pilot_end_out_fifo),
        .din(din_fir_pilot_end_out_fifo),
        .full(full_fir_pilot_end_out_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_pilot_end_out_fifo),
        .dout(dout_fir_pilot_end_out_fifo),
        .empty(empty_fir_pilot_end_out_fifo)
    );




    logic [31:0] in_fir_normal_lmr;
    logic empty_fir_normal_lmr, in_rd_en_fir_normal_lmr;


// MULTIPLIER, position (1,4)
// data in from fir_bp_lmr
multiplier_w_fifo mult(
    .reset(reset),
    .clock(clock),
    // two output from fifo
    .ina(dout_fir_bp_lmr_out_fifo),
    .ina_empty(empty_fir_bp_lmr_out_fifo),
    .ina_rd_en(rd_en_fir_bp_lmr_out_fifo),

    .inb(dout_fir_pilot_end_out_fifo),
    .inb_empty(empty_fir_pilot_end_out_fifo),
    .inb_rd_en(rd_en_fir_pilot_end_out_fifo),
    // also expose outputs
    .out(in_fir_normal_lmr),
    .out_empty(empty_fir_normal_lmr),
    .out_rd_en(in_rd_en_fir_normal_lmr)
);




// FIR stage: LMR (L-R) filter (1,5)
    logic [31:0] din_fir_lmr_fifo, dout_fir_lmr_fifo;
    logic wr_en_fir_lmr_fifo, rd_en_fir_lmr_fifo;
    logic full_fir_lmr_fifo, empty_fir_lmr_fifo;


    fir_normal#(
        .TAP_NUMBER(AUDIO_LMR_COEFF_TAPS),
        // inverse filter coefficients with buffer to ensure correct convolution
        .CONV_COEFF(AUDIO_LMR_COEFFS),
        .DECIMATION(8),
        .DATA_WIDTH(32)

    )fir_normal_lmr(
        .clock(clock),
        .reset(reset),

        .in_dout(in_fir_normal_lmr),
        .in_empty(empty_fir_normal_lmr),
        .in_rd_en(in_rd_en_fir_normal_lmr),


        .out_din(din_fir_lmr_fifo),
        .out_wr_en(wr_en_fir_lmr_fifo),
        .out_full(full_fir_lmr_fifo)

    );

    fifo #(
        .FIFO_BUFFER_SIZE(128),
        .FIFO_DATA_WIDTH(32)
    ) fir_lmr_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_lmr_fifo),
        .din(din_fir_lmr_fifo),
        .full(full_fir_lmr_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_lmr_fifo),
        .dout(dout_fir_lmr_fifo),
        .empty(empty_fir_lmr_fifo)
    );




// FIR stage: LPR (L+R)
// position: (2,5)
// third feedin from demodulation stage
    logic [31:0] din_fir_lpr_fifo, dout_fir_lpr_fifo;
    logic wr_en_fir_lpr_fifo, rd_en_fir_lpr_fifo;
    logic full_fir_lpr_fifo, empty_fir_lpr_fifo;

    logic [31:0] din_fir_lpr_in_fifo, dout_fir_lpr_in_fifo;
    logic wr_en_fir_lpr_in_fifo, rd_en_fir_lpr_in_fifo;
    logic full_fir_lpr_in_fifo, empty_fir_lpr_in_fifo;
    assign din_fir_lpr_in_fifo = din_demod_result;
    assign wr_en_fir_lpr_in_fifo = wr_en_demod;

    assign full_demod = full_fir_lpr_in_fifo || full_fir_pilot_bp_in_fifo || full_fir_lmr_unfiltered_fifo;

    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
    ) fir_lpr_in_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_lpr_in_fifo),
        .din(din_fir_lpr_in_fifo),
        .full(full_fir_lpr_in_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_lpr_in_fifo),
        .dout(dout_fir_lpr_in_fifo),
        .empty(empty_fir_lpr_in_fifo)
    );


    fir_normal#(
        .TAP_NUMBER(AUDIO_LPR_COEFF_TAPS),
        // inverse filter coefficients with buffer to ensure correct convolution
        .CONV_COEFF(AUDIO_LPR_COEFFS),
        .DECIMATION(8),
        .DATA_WIDTH(32)

    )fir_normal_lpr(
        .clock(clock),
        .reset(reset),

        .in_dout(dout_fir_lpr_in_fifo),
        .in_empty(empty_fir_lpr_in_fifo),
        .in_rd_en(rd_en_fir_lpr_in_fifo),


        .out_din(din_fir_lpr_fifo),
        .out_wr_en(wr_en_fir_lpr_fifo),
        .out_full(full_fir_lpr_fifo)

    );

    fifo #(
        .FIFO_BUFFER_SIZE(128),
        .FIFO_DATA_WIDTH(32)
    ) fir_lpr_fifo(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(wr_en_fir_lpr_fifo),
        .din(din_fir_lpr_fifo),
        .full(full_fir_lpr_fifo),

        .rd_clk(clock),
        .rd_en(rd_en_fir_lpr_fifo),
        .dout(dout_fir_lpr_fifo),
        .empty(empty_fir_lpr_fifo)
    );









// add and substages
    logic dummy_empty, double_L_dummy_empty, double_R_dummy_empty;
    logic dummy_rd_en, double_L_dummy_rd_en, double_R_dummy_rd_en;
// add: (L+R) + (L-R) = 2L  (1,6)
    logic [31:0] double_L;
    assign double_L = $signed(dout_fir_lpr_fifo) + $signed(dout_fir_lmr_fifo);


// sub: (L+R) - (L-R) = 2R  (2,6)
    logic [31:0] double_R;
    assign double_R = $signed(dout_fir_lpr_fifo) - $signed(dout_fir_lmr_fifo);
// set control signals
    assign dummy_empty = empty_fir_lpr_fifo || empty_fir_lmr_fifo;
    assign double_L_dummy_empty = dummy_empty;
    assign double_R_dummy_empty = dummy_empty;

    assign rd_en_fir_lmr_fifo = double_L_dummy_rd_en;
    assign rd_en_fir_lpr_fifo = double_R_dummy_rd_en;


// DEEMPHASIS stage: (1,7)
    logic [31:0] din_iir_left_fifo, dout_iir_left_fifo;
    logic wr_en_iir_left_fifo, rd_en_iir_left_fifo;
    logic full_iir_left_fifo, empty_iir_left_fifo;

    iir_normal#(
        .TAP_NUMBER(IIR_COEFF_TAPS),
        .DATA_WIDTH(32),
        //.CONV_X_COEFF(IIR_X_COEFF),
        //.CONV_Y_COEFF(IIR_Y_COEFF),
        .DECIMATION(1)

    )IIR_left(
        .clock(clock),
        .reset(reset),

        .in_dout(double_L),
        .in_empty(double_L_dummy_empty),
        .in_rd_en(double_L_dummy_rd_en),


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
        //.CONV_X_COEFF(IIR_X_COEFF),
        //.CONV_Y_COEFF(IIR_Y_COEFF),
        .DECIMATION(1)

    )IIR_right(
        .clock(clock),
        .reset(reset),

        .in_dout(double_R),
        .in_empty(double_R_dummy_empty),
        .in_rd_en(double_R_dummy_rd_en),


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

    logic dummy_out_empty;
    assign dummy_out_empty = empty_iir_left_fifo || empty_iir_right_fifo || full_gain_32_left_out_fifo || full_gain_32_right_out_fifo;
    // wr/rd control signals
    assign wr_en_gain_32_left_out_fifo = ~empty_iir_left_fifo & ~full_gain_32_left_out_fifo;
    assign wr_en_gain_32_right_out_fifo = ~empty_iir_right_fifo & ~full_gain_32_right_out_fifo;
    
    assign rd_en_iir_left_fifo = ~dummy_out_empty;
    assign rd_en_iir_right_fifo = ~dummy_out_empty;

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