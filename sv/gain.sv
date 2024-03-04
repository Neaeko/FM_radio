module gain_32_mono#(
    parameter GAIN = 1
)(
    input  logic [31:0] in_dout,
    output  logic [31:0] out_din
);

logic [63:0] buffer;

always_comb begin
    buffer[63:0]  = $signed(in_dout) * $signed(GAIN);
    out_din [31:0] = buffer << (14-10);
end



endmodule
