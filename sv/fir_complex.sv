module fir_complex#(
    // inverse filter coefficients with buffer to ensure correct convolution
    parameter [19:0][31:0] REAL_COEFF = {
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
    },

    parameter [19:0][31:0] IMAG_COEFF = {
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
    },

    parameter DECIMATION = 10,
    parameter DATA_WIDTH = 32,
    parameter TAP_NUMBER = 20
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

// r/w control signals
logic in_empty, out_full;
logic in_rd_en, out_wr_en;
assign in_empty = i_empty && q_empty;
assign out_full = real_full || imag_full;
assign i_rd_en = in_rd_en;
assign q_rd_en = in_rd_en;
assign real_wr_en = out_wr_en;
assign imag_wr_en = out_wr_en;


// shift buffer to store samples
// invert the order of the samples to ensure correct convolution
// input sequence:
// 
//x_in(t):  9 8 7 6 5 4 3 2 1 0         
//buffer(i):0 1 2 3 4 5 6 7 8 9
//COEFF     9 8 7 6 5 4 3 2 1 0
logic [0 : TAP_NUMBER - 1][DATA_WIDTH-1:0] x_real_buffer, x_real_buffer_c;
logic [0 : DECIMATION - 1][DATA_WIDTH-1:0] x_real_buffer_run, x_real_buffer_run_c;

logic [0 : TAP_NUMBER - 1][DATA_WIDTH-1:0] x_imag_buffer, x_imag_buffer_c;
logic [0 : DECIMATION - 1][DATA_WIDTH-1:0] x_imag_buffer_run, x_imag_buffer_run_c;

logic [5:0] read_in_counter, read_in_counter_c;
logic [5:0] run_counter, run_counter_c;

logic [DATA_WIDTH-1:0] real_sum, imag_sum, real_sum_c, imag_sum_c;

logic [5:0] run_read_full, run_read_full_c;
logic run_read_full_flag, run_read_full_flag_c;


typedef enum logic[2:0] {READ, RUN, WRITE, CONVERT} state_types;
state_types state, state_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        real_sum <= 0;
        imag_sum <= 0;
        read_in_counter <= 0;

        x_real_buffer <= 0;
        x_real_buffer_run <= 0;
        x_imag_buffer <= 0;
        x_imag_buffer_run <= 0;

        run_counter <= 0;
        run_read_full <= 0;

        run_read_full_flag <= 0;
        state <= READ;

    end else begin
        real_sum <= real_sum_c;
        imag_sum <= imag_sum_c;
        read_in_counter <= read_in_counter_c;

        x_real_buffer <= x_real_buffer_c;
        x_real_buffer_run <= x_real_buffer_run_c;
        x_imag_buffer <= x_imag_buffer_c;
        x_imag_buffer_run <= x_imag_buffer_run_c;

        run_counter <= run_counter_c;
        run_read_full <= run_read_full_c;
        run_read_full_flag <= run_read_full_flag_c;
        state <= state_c;

    end
end


always_comb begin
    in_rd_en = 0;
    out_wr_en = 0;
    //valid_postiton =0;
    //valid_shift_position = 0;
    state_c = state;
    real_sum_c = real_sum;
    imag_sum_c = imag_sum;

    run_read_full_c = run_read_full;
    run_read_full_flag_c = run_read_full_flag;

    x_real_buffer_c = x_real_buffer;
    x_imag_buffer_c = x_imag_buffer;
    x_real_buffer_run_c = x_real_buffer_run;
    x_imag_buffer_run_c = x_imag_buffer_run;
    read_in_counter_c = read_in_counter;
    run_counter_c = run_counter;

    real_out = 0;
    imag_out = 0;

    case(state)
        READ: begin
            if (in_empty == 1'b0) begin
                real_sum_c = 0;
                imag_sum_c = 0;
                run_read_full_c = 0;

                in_rd_en = 1'b1;
                // updateb newest sample at 0th index
                x_real_buffer_c[0 : TAP_NUMBER - 1] = {i_in, x_real_buffer[0: TAP_NUMBER - 2] };
                x_imag_buffer_c[0 : TAP_NUMBER - 1] = {q_in, x_imag_buffer[0: TAP_NUMBER - 2] };

                // calculate every DECIMATION times
                read_in_counter_c = (read_in_counter + 1) % DECIMATION;
                if (read_in_counter == DECIMATION - 1) begin // next set to 0
                    state_c = RUN;

                end
            end else begin
                in_rd_en = 1'b0;
                state_c = READ;
            end
        
        end



        RUN: begin
            // calculation state
            // takes TAP_NUMBER cycles to finish
            // for decimation:tap_number = 10:20, take extra buffers to store the samples
            real_sum_c = real_sum + mul_frac10_32b(REAL_COEFF[run_counter], x_real_buffer[run_counter]) - mul_frac10_32b(IMAG_COEFF[run_counter], x_imag_buffer[run_counter]);
            imag_sum_c = imag_sum + mul_frac10_32b(REAL_COEFF[run_counter], x_imag_buffer[run_counter]) - mul_frac10_32b(IMAG_COEFF[run_counter], x_real_buffer[run_counter]);
            // higher priority for calculation
            run_counter_c = (run_counter + 1) % TAP_NUMBER;
            
            if (run_counter == TAP_NUMBER - 1) begin
                state_c = WRITE;
            end else begin
                state_c = RUN;
            end

            // fill buffer with size of DECIMATION
            if (in_empty == 1'b0 && run_read_full_flag == 1'b0 ) begin

                in_rd_en = 1'b1;
                // update newest sample at 0th index
                x_real_buffer_run_c[0 : DECIMATION - 1] = {i_in, x_real_buffer_run[0: DECIMATION - 2] };
                x_imag_buffer_run_c[0 : DECIMATION - 1] = {q_in, x_imag_buffer_run[0: DECIMATION - 2] };

                run_read_full_c = (run_read_full + 1) % DECIMATION;
                if (run_read_full == DECIMATION - 1) begin // finish reading DECIMATION samples
                    run_read_full_flag_c = 1;
                end
            end else begin
                in_rd_en = 1'b0;
                
            end


        end


        WRITE: begin
            if (!out_full && run_read_full_flag == 1) begin
                out_wr_en = 1'b1;
                real_out = real_sum;
                imag_out = imag_sum;

                // shift for a complete buffer
                x_real_buffer_c[0 : TAP_NUMBER - 1] = {x_real_buffer_run_c[0 : DECIMATION - 1], x_real_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
                x_imag_buffer_c[0 : TAP_NUMBER - 1] = {x_imag_buffer_run_c[0 : DECIMATION - 1], x_imag_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
                // empty buffer for next RUN
                x_real_buffer_run_c = 0;
                x_imag_buffer_run_c = 0;

                run_read_full_flag_c = 0;

                real_sum_c = 0;
                imag_sum_c = 0;
                
                state_c = RUN;
            end else if(!out_full && run_read_full_flag == 0) begin
                out_wr_en = 1'b1;
                real_out = real_sum;
                imag_out = imag_sum;
                // go back to fill the buffer

                state_c = CONVERT;

            end else begin
                out_wr_en = 1'b0;
                real_out = 0;
                imag_out = 0;
                state_c = WRITE;
            end

        end



        CONVERT: begin
            // fill buffer with size of DECIMATION
            if (in_empty == 1'b0) begin

                in_rd_en = 1'b1;
                // update newest sample at 0th index
                x_real_buffer_run_c[0 : DECIMATION - 1] = {i_in, x_real_buffer_run[0: DECIMATION - 2] };
                x_imag_buffer_run_c[0 : DECIMATION - 1] = {q_in, x_imag_buffer_run[0: DECIMATION - 2] };
                
                run_read_full_c = (run_read_full + 1) % DECIMATION;
                if (run_read_full == DECIMATION - 1) begin // finish reading DECIMATION samples
                    x_real_buffer_c[0 : TAP_NUMBER - 1] = {x_real_buffer_run_c[0 : DECIMATION - 1], x_real_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
                    x_imag_buffer_c[0 : TAP_NUMBER - 1] = {x_imag_buffer_run_c[0 : DECIMATION - 1], x_imag_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
                    x_real_buffer_run_c = 0;
                    x_imag_buffer_run_c = 0;

                    run_read_full_flag_c = 0;

                    real_sum_c = 0;
                    imag_sum_c = 0;
                    
                    state_c = RUN;
                end
            end else begin
                in_rd_en = 1'b0;
                state_c = CONVERT;
                
            end
        end



    endcase


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