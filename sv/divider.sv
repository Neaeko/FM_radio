//`include "functions.svh"
`define s0 2'b00
`define s1 2'b01
`define s2 2'b10
`define s3 2'b11
// import functs::*;

module divider #(
    parameter DIVIDEND_WIDTH=32,
    parameter DIVISOR_WIDTH=32
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [DIVIDEND_WIDTH-1:0] dividend,
    input wire [DIVISOR_WIDTH-1:0] divisor,
    output reg [DIVIDEND_WIDTH-1:0] quotient,
    output reg [DIVISOR_WIDTH-1:0] remainder,
    output reg overflow,
    output reg done
);

	
    reg [1:0] state, next_state;
    reg [DIVIDEND_WIDTH-1:0] a, a_c, b, b_c,q, q_c;
    reg [DIVISOR_WIDTH-1:0] r, r_c;
    reg o, o_c, done_o, done_c;
    int p,p_c;
    // int a_pos,b_pos;
    // wire found_a,found_b;
    reg sign;
    function integer get_msb_pos;
        input [31:0] val; // Adjust the size as needed
        integer i;
        begin
            get_msb_pos = 0;
            for (i = 31; i >=0; i = i -1) begin
                if (val[i] == 1'b1) begin
                    get_msb_pos = i;  
                    break; 
                end 

            end
        end
    endfunction
    // function automatic integer get_msb_pos_rec;
    //     input [DIVIDEND_WIDTH-1:0] val;
    //     input int length;
    //  // Recursive case: Split the vector into two halves
    //     int mid = length >> 1;
    //     logic [mid-1:0] lower_half;
    //     logic [length-1:mid] upper_half;
    //     int msb_lower;
    //     int msb_upper;
    //     begin
    //         // Assign values to halves
    //         lower_half = val[mid-1:0];
    //         upper_half = val[length-1:mid];

    //         // Recursive calls for each half
    //         msb_lower = get_msb_pos_rec(lower_half,length>>1);
    //         msb_upper = get_msb_pos_rec(upper_half,length>>1);

    //         // Determine and return the MSB position
    //         if (msb_upper != -1) begin // If the upper half has a set bit
    //             return mid + msb_upper;
    //         end else if (msb_lower != -1) begin // If only the lower half has a set bit
    //             return msb_lower;
    //         end else begin // If no bits are set
    //             return -1;
    //         end
    //     end
    // endfunction

    // Clock process
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a <= 0;
            b <= 0;
            q <= 0;
            r <= 0;
            o <= 0;
            p<='0;
            done_o <= 0;
            state <= `s0;
        end 
        else begin
            a <= a_c;
            b <= b_c;
            q <= q_c;
            r <= r_c;
            o <= o_c;
            done_o <= done_c;
            state <= next_state;
            p<=p_c;
        end
    end

    // Combinational FSM process
    always @(*) begin
        // Default assignments to avoid latches
        a_c = a;
        b_c = b;
        q_c = q;
        r_c = r;
        o_c = o;
        p_c = p;
        done_c = done_o;
        next_state = state;
        sign = 0;

        case (state)
            `s0: begin
                done_c = 0;
                if (start) begin
                    // Assuming if_cond is a ternary operator in Verilog
                    a_c = (dividend[DIVIDEND_WIDTH-1] ? ~dividend + 1'b1 : dividend);
                    b_c = (divisor[DIVISOR_WIDTH-1] ? ~divisor + 1'b1 : divisor);
                    q_c = '0;
                    o_c = 0;

                    next_state = `s1;
                end
            end
            `s1: begin
                if (b == 0) begin
                    o_c = 1;
                    next_state = `s3;
                end else if (b == 1) begin
                    q_c = a;
                    a_c = 0;
                    next_state = `s3;
                end else if (a >= b) begin
                    p_c = get_msb_pos(a) - get_msb_pos(b);

                    // Implement get_msb_pos_rec logic or equivalent iterative approach
                    // p calculation and adjustment
                    // q_c and a_c adjustment
                    next_state = `s2;
                end else begin
                    next_state = `s3;
                end
            end
            `s2: begin
                if ((b<<p) > a) begin
                    p_c=p-1;
                end
                else begin
                    p_c=p;
                end
                q_c=$unsigned(q)+$unsigned(1<<p_c);
                a_c=$unsigned(a)-$unsigned(b<<p_c);
                next_state=`s1;
            end
            `s3: begin
                sign = dividend[DIVIDEND_WIDTH-1] ^ divisor[DIVISOR_WIDTH-1];
                q_c = sign ? ~q + 1'b1 : q;
                r_c = dividend[DIVIDEND_WIDTH-1] ? ~a + 1'b1 : a;
                done_c = 1;
                next_state = `s0;
            end
            default: begin
                a_c = 'x; //{DIVIDEND_WIDTH{'bx}};
                b_c = 'x;//{DIVIDEND_WIDTH{'bx}};
                q_c = 'x;//{DIVIDEND_WIDTH{'bx}};
                r_c = 'x;//{DIVISOR_WIDTH{'bx}};
                o_c = 'bx;
                done_c = 'bx;
                next_state = `s0;
                p_c=p;
            end
        endcase
    end
    assign quotient=q;
    assign remainder=r;
    assign overflow=o;
    assign done=done_o;
endmodule