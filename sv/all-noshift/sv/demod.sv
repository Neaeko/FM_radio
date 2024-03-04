//`include "functions.svh"
import functs::*;

module demod #(
    parameter DATA_WIDTH= 32,
    // parameter SAMPLE_NUM = 65536*4,
    parameter GAIN=758
    )(
    input logic clk,
    input logic rst,
    input int rl,
    output logic rd_en_rl,
    input logic empty_rl,
    input int img,
    output logic rd_en_img,
    input logic empty_img,
    output int demod_out,
    input logic full_demod,
    output logic wr_en_demod

);
int quad1;
int quad3;
int rl_pre,rl_pre_c;
int img_pre,img_pre_c;
int r,r_c,i,i_c,i_abs;
logic start,start_c,overflow;
int dividend,dividend_c,divisor,divisor_c,quotient;
int remainder;
int angle,angle_c;
int imm32;
logic done;
typedef enum logic[2:0] {READ, RUN,DIVIDE, WRITE} state_types;
state_types state, state_c;
assign quad1=804;
assign quad3=2412;
function automatic int abs;
    input int value; // Assume a 32-bit signed integer
    begin
        // Check if value is negative (MSB is 1)
        if (value[DATA_WIDTH-1] == 1'b1) begin
            // If negative, calculate two's complement (invert and add 1)
            abs = (~value) + 1;
        end else begin
            // If not negative, the absolute value is the same as the input
            abs = value;
        end
    end
endfunction
 divider #( //new divider
        .DIVIDEND_WIDTH(DATA_WIDTH),
        .DIVISOR_WIDTH(DATA_WIDTH)
    ) my_divider (
        .clk(clk),
	.reset(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .overflow(overflow),
        .done(done)
    );

always_ff @( posedge clk or posedge rst ) begin : blockName
    if (rst) begin
        state<=READ;
        rl_pre<='0;
        img_pre<='0;
        r<='0;
        i<='0;
        angle<='0;
        dividend<='0;
        divisor<='0;
        start<='0;
    end
    else begin
        state<=state_c;
        rl_pre<=rl_pre_c;
        img_pre<=img_pre_c;
        r<=r_c;
        i<=i_c;
        angle<=angle_c;
        dividend<=dividend_c;
        divisor<=divisor_c;
        start<=start_c;
    end
end

always_comb begin
	 i_abs = 0;
	 imm32 = 0;
	 demod_out = 0;
    state_c=state;
    rd_en_img=1'b0;
    rd_en_rl=1'b0;
    wr_en_demod=1'b0;
    rl_pre_c=rl_pre;
    img_pre_c=img_pre;
    angle_c=angle;
    start_c=1'b0;
    r_c=r;
    i_c=i;
    dividend_c=dividend;
    divisor_c=divisor;
    case (state)
        READ: begin
            if (empty_rl==1'b0 && empty_img==1'b0) begin
                rd_en_img=1'b1;
                rd_en_rl=1'b1;
		        //r_c= DEQUANTIZE(rl_pre*rl) -  DEQUANTIZE((-img_pre)*img);
		        //i_c= DEQUANTIZE(rl_pre*img) +  DEQUANTIZE((-img_pre)*rl);
                r_c=mul_frac10_32b(rl_pre,rl) - mul_frac10_32b((-img_pre),img);
                i_c=mul_frac10_32b(rl_pre,img) + mul_frac10_32b((-img_pre),rl);
                state_c=RUN;
                //store for next calcluate
                rl_pre_c=rl;
                img_pre_c=img;
            end
        end
        RUN: begin
            i_abs=abs(i)+1'b1;
            if(r>=0) begin
                dividend_c=(r-i_abs)<<10;
                divisor_c=(r+i_abs);
            end
            else begin
                dividend_c=(r+i_abs)<<10;
                divisor_c=(i_abs-r);
            end
            state_c=DIVIDE;
            start_c=1'b1;
        end
        DIVIDE: begin
            if (done==1'b1) begin
                imm32=DEQUANTIZE(quad1*quotient);
                if(r>=0) begin
                    angle_c=quad1-imm32;
                end
                else begin
                    angle_c=quad3-imm32;
                end

                if (i[DATA_WIDTH-1]==1'b1) begin
                    angle_c=~angle_c+1;
                end
                state_c=WRITE;
            end
        end
        WRITE: begin
            if (full_demod==1'b0) begin
                wr_en_demod=1'b1;
                demod_out=DEQUANTIZE(GAIN*angle);
                state_c=READ;
            end
        end
        default: begin
                state_c=state;
                rd_en_img=1'b0;
                rd_en_rl=1'b0;
                rl_pre_c=rl_pre;
                img_pre_c=img_pre;
                angle_c=1'b1;
                start_c=1'b0;
        end 
    endcase
end



endmodule