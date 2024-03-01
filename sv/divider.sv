// Assuming DIVIDEND_WIDTH and DIVISOR_WIDTH are defined elsewhere

module divider#(
    parameter DIVIDEND_WIDTH=32,
    parameter DIVISOR_WIDTH=16
)(
    input logic clk,
    input logic start,
    input logic [DIVIDEND_WIDTH-1:0] dividend,
    input logic [DIVISOR_WIDTH-1:0] divisor,
    output logic [DIVIDEND_WIDTH-1:0] quotient,
    output logic [DIVISOR_WIDTH-1:0] remainder,
    output logic overflow
);

localparam DATA_WIDTH = DIVISOR_WIDTH;

// Comparator module definition needs to be available
logic cmp_ge;

logic [DATA_WIDTH:0] cmp_dinl_reg;
logic [DATA_WIDTH-1:0] cmp_dinr_reg,cmp_dout;
logic [DIVIDEND_WIDTH-1:0]dividend_in;
logic [DIVIDEND_WIDTH-1:0] quotient_reg;
logic [DIVISOR_WIDTH-1:0] remainder_reg;
int count = 0;

comparator #(
    .DATA_WIDTH(DATA_WIDTH)
)compare_inst (
    .dinl(cmp_dinl_reg),
    .dinr(cmp_dinr_reg),
    .dout(cmp_dout),
    .isGreaterEq(cmp_ge)
);

// sign
assign cmp_dinr_reg = (divisor[DIVISOR_WIDTH-1]==1'b1)? ~divisor+1'b1:divisor;
assign dividend_in=(dividend[DIVIDEND_WIDTH-1]==1'b1) ? ~dividend+1'b1:dividend;
always_comb begin 
    if ((divisor[DIVISOR_WIDTH-1]==1'b1 && dividend[DIVIDEND_WIDTH-1]==1'b0) || (divisor[DIVISOR_WIDTH-1]==1'b0 && dividend[DIVIDEND_WIDTH-1]==1'b1)) begin
        quotient=~quotient_reg + 1'b1;
        remainder= ~ remainder_reg +1'b1;
    end
    else begin
        quotient=quotient_reg;
        remainder=remainder_reg;
    end
end
//calculation
always @(posedge clk or posedge start) begin
    if (start) begin
        count <= 0;
        cmp_dinl_reg <= '0;
        remainder_reg <= '0;
        quotient_reg <= '0;
        overflow <= '0;
    end 
    else begin
        if (divisor == '0) begin
            overflow <= '1;
        end 
        else begin
            if (count < DIVIDEND_WIDTH) begin
                cmp_dinl_reg <= {cmp_dout, dividend_in[DIVIDEND_WIDTH-count-1]};
                count <= count + 1;
            end
            if (count > 0 && count <= DIVIDEND_WIDTH) begin
                remainder_reg <= cmp_dout;
                quotient_reg[DIVIDEND_WIDTH-count] <= cmp_ge;
            end
        end
    end
end

endmodule


module comparator #(
    parameter DATA_WIDTH = 16
)(
    // Inputs
    input logic [DATA_WIDTH:0] dinl,
    input logic [DATA_WIDTH-1:0] dinr,

    // Outputs
    output logic [DATA_WIDTH-1:0] dout,
    output logic isGreaterEq
);

// Compare process
always @(*) begin
    if ($signed(dinl) >= $signed( dinr)) begin // Adjusting for bit-widths during comparison
        dout = $signed(dinl) - $signed(dinr);
        isGreaterEq = 1'b1;
    end 
    else begin
        dout = dinl[DATA_WIDTH-1:0]; // Adjusted to match the output bit-width
        isGreaterEq = 1'b0;
    end
end

endmodule

