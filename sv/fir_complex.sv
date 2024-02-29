module fir_complex#(
    parameter [19:0][31:0] REAL_COEFF = {0x00000001,},
    parameter [19:0][31:0] IMAG_COEFF = {0x00000002,},

    parameter DATA_WIDTH = 16,
    parameter STAGE_NUMBER = 20
)(
    input  logic clock,
    input  logic reset,

    input  logic [DATA_WIDTH-1:0] i_in,
    input  logic i_empty,
    output logic i_rd_en,


    input  logic [DATA_WIDTH-1:0] q_in,
    input  logic q_empty,
    output logic q_rd_en,

    output logic [DATA_WIDTH-1:0] real_out,
    output logic real_wr_en,
    input  logic real_full,

    output logic [DATA_WIDTH-1:0] imag_out,
    output logic imag_wr_en,
    input  logic imag_full

);

logic [DATA_WIDTH-1:0] real_acc;
logic [DATA_WIDTH-1:0] imag_acc;

logic [STAGE_NUMBER-1:0][DATA_WIDTH-1:0] real_buffer;
logic [STAGE_NUMBER-1:0][DATA_WIDTH-1:0] imag_buffer;
logic [DATA_WIDTH-1:0] real_sum, imag_sum, real_sum_c, imag_sum_c;



always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        real_sum <= 0;
        imag_sum <= 0;
        valid_out <= 0;
    end else begin
        real_out <= real_acc + i_in * REAL_COEFF;
        imag_out <= imag_acc + q_in * IMAG_COEFF;
        valid_out <= valid_c;
    end
end


always_comb begin
    valid_c = valid_in;




end





endmodule