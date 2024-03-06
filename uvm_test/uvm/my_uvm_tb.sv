
import uvm_pkg::*;
import my_uvm_package::*;

`include "my_uvm_if.sv"

`timescale 1 ns / 1 ns

module my_uvm_tb;

    my_uvm_if vif();
    // integer cycle;


    fm_radio_top dut (
        .clock(vif.clk),
        .reset(vif.reset),

        .i_din(vif.iq_in[63:32]),
        .q_din(vif.iq_in[31:0]),
        .in_wr_en(vif.in_wr_en),
        .in_full(vif.in_full),
        .out_rd_en(vif.out_rd_en),
        .left_out(vif.left_dout),
        .right_out(vif.right_dout),
        .out_empty(vif.out_empty)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual my_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("my_uvm_test");        
    end

    // reset
    initial begin
        vif.clk <= 1'b1;
        vif.reset <= 1'b0;
        @(posedge vif.clk);
        vif.reset <= 1'b1;
        @(posedge vif.clk);
        vif.reset <= 1'b0;
    end

    // 10ns clock
    always begin
        #(CLOCK_PERIOD/2) vif.clk = ~vif.clk;
    end
endmodule






