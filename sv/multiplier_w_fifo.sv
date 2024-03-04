//`include "functions.svh"
import functs::*;

module multiplier_w_fifo(
    input  logic reset,
    input  logic clock,

    input  logic    [31:0] ina,
    input  logic ina_empty,
    output logic ina_rd_en,

    input  logic    [31:0] inb,
    input  logic inb_empty,
    output logic inb_rd_en,


    output logic    [31:0] out,
    output logic out_empty,
    input  logic out_rd_en
);

logic [31:0] fifo_din;
logic fifo_wr_en, fifo_full;


    fifo #(
        .FIFO_BUFFER_SIZE(256),
        .FIFO_DATA_WIDTH(32)
    ) fifo_output(
        .reset(reset),
        .wr_clk(clock),
        .wr_en(fifo_wr_en),
        .din(fifo_din),
        .full(fifo_full),

        .rd_clk(clock),
        .rd_en(out_rd_en),
        .dout(out),
        .empty(out_empty)
    );

typedef enum logic[0:0] {IDLE, WRITE} state_types;
state_types state, state_c;


logic [31:0] out_buffer, out_buffer_c;



always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        out_buffer <= 0;
        state <= IDLE;

    end else begin
        out_buffer <= out_buffer_c;
        state <= state_c;

    end
end


always_comb begin
    ina_rd_en = 0;
    inb_rd_en = 0;
    fifo_wr_en = 0;
    out_buffer_c = out_buffer;
    state_c = state;
    fifo_din = 0;

    case(state)
        IDLE: begin
            // synchoronous read
            if(!ina_empty && !inb_empty) begin
                
                out_buffer_c = mul_frac10_32b(ina, inb);
                ina_rd_en = 1;
                inb_rd_en = 1;
                
                state_c = WRITE;
                
            end else begin
                state_c = IDLE;
               
            end
        end

        WRITE: begin
            if(!fifo_full) begin
                fifo_din = out_buffer;
                fifo_wr_en = 1;

                state_c = IDLE;
            end else begin
                
                fifo_wr_en = 0;
                state_c = WRITE;
            end
        end
    endcase
end



endmodule