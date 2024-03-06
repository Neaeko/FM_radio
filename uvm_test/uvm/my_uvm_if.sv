import uvm_pkg::*;

interface my_uvm_if;
    logic           clk;
    logic           reset;
    logic   [63:0]  iq_in;
    logic           in_full;
    logic           in_wr_en;
    logic           out_empty;
    logic           out_rd_en;
    logic   [31:0]  right_dout;
    logic   [31:0]  left_dout;
endinterface
