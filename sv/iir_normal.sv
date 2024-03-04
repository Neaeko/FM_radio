//`include "functions.svh"

import functs::*;

module iir_normal#(
    parameter TAP_NUMBER = 2,
    // inverse filter coefficients with buffer to ensure correct convolution
    parameter DATA_WIDTH = 32,
    //Concole output:
    //IIR_X_COEFFS: 00B2 00B2 
    //IIR_Y_COEFFS: 0000 FFFFFD66 
    /*parameter [0:TAP_NUMBER-1][DATA_WIDTH-1:0] CONV_X_COEFF = {
	            32'h000000B2, 32'h000000B2
    //static const int IIR_X_COEFFS[] = {QUANTIZE_F(W_PP / (1.0f + W_PP)), QUANTIZE_F(W_PP / (1.0f + W_PP))};
    },
    parameter [0:TAP_NUMBER-1][DATA_WIDTH-1:0] CONV_Y_COEFF = {
                32'h00000000, 32'hFFFFFFD6
	//static const int IIR_Y_COEFFS[] = {QUANTIZE_F(0.0f), QUANTIZE_F((W_PP - 1.0f) / (W_PP + 1.0f))};
    },
    parameter int CONV_X_COEFF [0:TAP_NUMBER-1]= {
	            178,178
    },
    parameter int CONV_Y_COEFF [TAP_NUMBER-1:0] = {
                0,-666
    },*/
    parameter DECIMATION = 1

)(
    input  logic clock,
    input  logic reset,

    input  logic [DATA_WIDTH-1:0] in_dout,
    input  logic in_empty,
    output logic in_rd_en,


    output logic [DATA_WIDTH-1:0] out_din,
    output logic out_wr_en,
    input  logic out_full

);


	 localparam int CONV_X_COEFF[2] = '{178, 178};
	 localparam int CONV_Y_COEFF[2] = '{-666, 0};
	 


// shift buffer to store samples
// invert the order of the samples to ensure correct convolution
// input sequence:
// 
//x_in(t):  9 8 7 6 5 4 3 2 1 0         
//buffer(i):0 1 2 3 4 5 6 7 8 9
//COEFF     9 8 7 6 5 4 3 2 1 0
logic [0 : TAP_NUMBER - 1][DATA_WIDTH-1:0] x_real_buffer, x_real_buffer_c /* synthesis syn_srlstyle="registers" */;
logic [0 : TAP_NUMBER - 1][DATA_WIDTH-1:0] y_real_buffer, y_real_buffer_c /* synthesis syn_srlstyle="registers" */;

logic [DATA_WIDTH-1:0] x_buffer, x_coeff, y_buffer, y_coeff;
logic [DATA_WIDTH-1:0] dout_buffer, dout_buffer_c;

logic [5:0] read_in_counter, read_in_counter_c;
logic [5:0] run_counter, run_counter_c;

logic [DATA_WIDTH-1:0] x_sum,x_sum_c;
logic [DATA_WIDTH-1:0] y_sum,y_sum_c;

logic [5:0] run_read_full, run_read_full_c;
logic run_read_full_flag, run_read_full_flag_c;


typedef enum logic[2:0] {READ, RUN, WRITE, CONVERT} state_types;
state_types state, state_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        x_sum <= 0;
        y_sum <= 0;
        read_in_counter <= 0;

        x_real_buffer <= 0;
        y_real_buffer <= 0;
        run_counter <= 0;
        state <= READ;
        dout_buffer <= 0;
        


    end else begin
        x_sum <= x_sum_c;
        y_sum <= y_sum_c;
        read_in_counter <= read_in_counter_c;
        dout_buffer <= dout_buffer_c;

        x_real_buffer <= x_real_buffer_c;
        y_real_buffer <= y_real_buffer_c;
        run_counter <= run_counter_c;
        state <= state_c;
        
       

    end
end


always_comb begin
    in_rd_en = 0;
    out_wr_en = 0;
    out_din = 0;

    state_c = state;
    x_sum_c = x_sum;
    y_sum_c = y_sum;

    x_buffer = 0;
    x_coeff = 0;
    y_buffer = 0;
    y_coeff = 0;
    
    dout_buffer_c = dout_buffer;
    x_real_buffer_c = x_real_buffer;
    y_real_buffer_c = y_real_buffer;

    read_in_counter_c = read_in_counter;
    run_counter_c = run_counter;

    


    case(state)
        READ: begin
            if (in_empty == 1'b0) begin
                x_sum_c = 0;
                y_sum_c = 0;

                in_rd_en = 1'b1;
                // updateb newest sample at 0th index
                x_real_buffer_c[0 : TAP_NUMBER - 1] = {in_dout, x_real_buffer[0: TAP_NUMBER - 2] };
                y_real_buffer_c[0 : TAP_NUMBER - 1] = {dout_buffer, y_real_buffer[0: TAP_NUMBER - 2] };

                
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
            case(run_counter)
                0: begin
                    x_buffer =  x_real_buffer[0];
                    x_coeff  =  CONV_X_COEFF[0];
                    y_buffer =  y_real_buffer[0];
                    y_coeff  =  CONV_Y_COEFF[0];
                end
                1: begin
                    x_buffer =  x_real_buffer[1];
                    x_coeff  =  CONV_X_COEFF[1];
                    y_buffer =  y_real_buffer[1];
                    y_coeff  =  CONV_Y_COEFF[1];
                end
            endcase

            /*
            case(run_counter)
            generate for (genvar i = 0; i < TAP_NUMBER; i++) begin
                i: begin
                    x_buffer =  x_real_buffer[i];
                    x_coeff  =  CONV_X_COEFF[i];
                    y_buffer =  y_real_buffer[i];
                    y_coeff  =  CONV_Y_COEFF[i];
                end
            end
            endgenerate
            endcase
            */

            x_sum_c = x_sum + mul_frac10_32b(x_buffer , x_coeff);
            y_sum_c = y_sum + mul_frac10_32b(y_buffer , y_coeff);
            // higher priority for calculation
            run_counter_c = (run_counter + 1) % TAP_NUMBER;
            
            if (run_counter == TAP_NUMBER - 1) begin
                state_c = WRITE;
            end else begin
                state_c = RUN;
            end



        end


        WRITE: begin
            
                if (!out_full && in_empty == 1'b0) begin
                    out_wr_en = 1'b1;
                    out_din = y_real_buffer[TAP_NUMBER - 2];

                    // read from buffer
		            dout_buffer_c = x_sum+y_sum;
                    x_sum_c = 0;
                    y_sum_c = 0;

                    in_rd_en = 1'b1;
                    // updateb newest sample at 0th index
                    x_real_buffer_c[0 : TAP_NUMBER - 1] = {in_dout, x_real_buffer[0: TAP_NUMBER - 2] };
                    y_real_buffer_c[0 : TAP_NUMBER - 1] = {dout_buffer_c, y_real_buffer[0: TAP_NUMBER - 2] };

                    state_c = RUN;

                end else if (!out_full && in_empty == 1'b1) begin
                    out_wr_en = 1'b1;
                    out_din = y_real_buffer[TAP_NUMBER - 2];
                    dout_buffer_c = x_sum+y_sum;
                    state_c = READ;
                
                end else begin
                    out_wr_en = 1'b0;
                    out_din = 0;
                    state_c = WRITE;
                end



        end

    endcase


end


endmodule