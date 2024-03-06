//`include "functions.svh"
import functs::*;


module fir_normal#(
    parameter TAP_NUMBER = 32,
    // inverse filter coefficients with buffer to ensure correct convolution
    parameter [TAP_NUMBER-1:0][31:0] CONV_COEFF = {
	32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
	32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
	32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
	32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
    },


    parameter DECIMATION = 8,
    parameter DATA_WIDTH = 32

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
//`include "functions.svh"

// shift buffer to store samples
// invert the order of the samples to ensure correct convolution
// input sequence:
// 
//x_in(t):  9 8 7 6 5 4 3 2 1 0         
//buffer(i):0 1 2 3 4 5 6 7 8 9
//COEFF     9 8 7 6 5 4 3 2 1 0
logic [0 : TAP_NUMBER - 1][DATA_WIDTH-1:0] x_real_buffer, x_real_buffer_c /* synthesis syn_srlstyle="registers" */;
logic [0 : DECIMATION - 1][DATA_WIDTH-1:0] x_real_buffer_run, x_real_buffer_run_c;

logic [5:0] read_in_counter, read_in_counter_c;
logic [5:0] run_counter, run_counter_c;

logic [DATA_WIDTH-1:0] real_sum,real_sum_c;

logic [5:0] run_read_full, run_read_full_c;
logic run_read_full_flag, run_read_full_flag_c;

logic [DATA_WIDTH-1:0] mul,mul_c;

typedef enum logic[2:0] {READ, START,RUN,FINISH, WRITE, CONVERT} state_types;
state_types state, state_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        real_sum <= 0;
        read_in_counter <= 0;

        x_real_buffer <= 0;;
        run_counter <= 0;
        state <= READ;
        mul<='0;
        if(DECIMATION > 1) begin: with_decimation1
            x_real_buffer_run <= 0;

            run_read_full <= 0;

            run_read_full_flag <= 0;
        end


    end else begin
        real_sum <= real_sum_c;
        read_in_counter <= read_in_counter_c;

        x_real_buffer <= x_real_buffer_c;
        run_counter <= run_counter_c;
        state <= state_c;
        mul<=mul_c;
        if(DECIMATION > 1) begin: with_decimation2
            x_real_buffer_run <= x_real_buffer_run_c;

            run_read_full <= run_read_full_c;
            run_read_full_flag <= run_read_full_flag_c;
            
        end

    end
end


always_comb begin
    in_rd_en = 0;
    out_wr_en = 0;
    out_din = 0;

    state_c = state;
    real_sum_c = real_sum;

    x_real_buffer_c = x_real_buffer;

    read_in_counter_c = read_in_counter;
    run_counter_c = run_counter;
    mul_c=mul;
    if(DECIMATION > 1) begin: with_decimation3
        run_read_full_c = run_read_full;
        run_read_full_flag_c = run_read_full_flag;

        x_real_buffer_run_c = x_real_buffer_run;
    end
    


    case(state)
        READ: begin
            if (in_empty == 1'b0) begin
                real_sum_c = 0;

                if(DECIMATION > 1) begin: with_decimation4
                    run_read_full_c = 0;
                    run_read_full_flag_c = 0;
                    x_real_buffer_run_c = 0;
                end

                in_rd_en = 1'b1;
                // updateb newest sample at 0th index
                x_real_buffer_c[0 : TAP_NUMBER - 1] = {in_dout, x_real_buffer[0: TAP_NUMBER - 2] };

                // calculate every DECIMATION times
                read_in_counter_c = (read_in_counter + 1) % DECIMATION;
                if (read_in_counter == DECIMATION - 1) begin // next set to 0
                    state_c = START;

                end
            end else begin
                in_rd_en = 1'b0;
                state_c = READ;
            end
        
        end

        START: begin
            mul_c=mul_frac10_32b(CONV_COEFF[run_counter] , x_real_buffer[run_counter]);
            run_counter_c = (run_counter + 1) % TAP_NUMBER;
            state_c=RUN;
        end

        RUN: begin
            // calculation state
            // takes TAP_NUMBER cycles to finish
            // for decimation:tap_number = 10:20, take extra buffers to store the samples
            mul_c= mul_frac10_32b(CONV_COEFF[run_counter] , x_real_buffer[run_counter]);
            real_sum_c = real_sum +mul;
            // higher priority for calculation
            run_counter_c = (run_counter + 1) % TAP_NUMBER;
            
            if (run_counter == TAP_NUMBER - 1) begin
                state_c = FINISH;
            end else begin
                state_c = RUN;
            end

            // if(DECIMATION > 1) begin: with_decimation5
            //     // fill buffer with size of DECIMATION
            //     if (in_empty == 1'b0 && run_read_full_flag == 1'b0 ) begin

            //         in_rd_en = 1'b1;
            //         // update newest sample at 0th index
            //         x_real_buffer_run_c[0 : DECIMATION - 1] = {in_dout, x_real_buffer_run[0: DECIMATION - 2] };

            //         run_read_full_c = (run_read_full + 1) % DECIMATION;
            //         if (run_read_full == DECIMATION - 1) begin // finish reading DECIMATION samples
            //             run_read_full_flag_c = 1;
            //         end
            //     end else begin
            //         in_rd_en = 1'b0;
                    
            //     end
            // end


        end

        FINISH: begin
            real_sum_c = real_sum +mul;
            state_c=WRITE;
            //run_counter_c = (run_counter + 1) % TAP_NUMBER;
            // if(DECIMATION > 1) begin: with_decimation5
            //     // fill buffer with size of DECIMATION
            //     if (in_empty == 1'b0 && run_read_full_flag == 1'b0 ) begin

            //         in_rd_en = 1'b1;
            //         // update newest sample at 0th index
            //         x_real_buffer_run_c[0 : DECIMATION - 1] = {in_dout, x_real_buffer_run[0: DECIMATION - 2] };

            //         run_read_full_c = (run_read_full + 1) % DECIMATION;
            //         if (run_read_full == DECIMATION - 1) begin // finish reading DECIMATION samples
            //             run_read_full_flag_c = 1;
            //         end
            //     end else begin
            //         in_rd_en = 1'b0;
                    
            //     end
            // end
        end
        WRITE: begin
                if (!out_full) begin
                    out_wr_en = 1'b1;
                    out_din = real_sum;
                    state_c = READ;
                end else begin
                    out_wr_en = 1'b0;
                    out_din = 0;
                    state_c = WRITE;
                end


            // if(DECIMATION > 1) begin: with_decimation6
            //     if (!out_full && run_read_full_flag == 1) begin
            //         out_wr_en = 1'b1;
            //         out_din = real_sum;

            //         // shift for a complete buffer
            //         x_real_buffer_c[0 : TAP_NUMBER - 1] = {x_real_buffer_run_c[0 : DECIMATION - 1], x_real_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
            //         // empty buffer for next RUN
            //         x_real_buffer_run_c = 0;

            //         run_read_full_flag_c = 0;

            //         real_sum_c = 0;
                    
            //         state_c = RUN;
            //     end else if(!out_full && run_read_full_flag == 0) begin
            //         out_wr_en = 1'b1;
            //         out_din = real_sum;

            //         // go back to fill the buffer

            //         state_c = CONVERT;

            //     end else begin
            //         out_wr_en = 1'b0;
            //         out_din = 0;
            //         state_c = WRITE;
            //     end
            // end

        end


            CONVERT: begin
                if(DECIMATION > 1) begin: with_decimation7
                    // fill buffer with size of DECIMATION
                    if (in_empty == 1'b0) begin

                        in_rd_en = 1'b1;
                        // update newest sample at 0th index
                        x_real_buffer_run_c[0 : DECIMATION - 1] = {in_dout, x_real_buffer_run[0: DECIMATION - 2] };
                        
                        run_read_full_c = (run_read_full + 1) % DECIMATION;
                        if (run_read_full == DECIMATION - 1) begin // finish reading DECIMATION samples
                            x_real_buffer_c[0 : TAP_NUMBER - 1] = {x_real_buffer_run_c[0 : DECIMATION - 1], x_real_buffer[0 : TAP_NUMBER - DECIMATION - 1]};
                            x_real_buffer_run_c = 0;


                            run_read_full_flag_c = 0;

                            real_sum_c = 0;
                            
                            state_c = RUN;
                        end
                    end else begin
                        in_rd_en = 1'b0;
                        state_c = CONVERT;
                        
                    end
                end
        end
    endcase


end


endmodule