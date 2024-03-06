import uvm_pkg::*;

`uvm_analysis_imp_decl(_output)
`uvm_analysis_imp_decl(_compare)

class my_uvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_uvm_scoreboard)

    uvm_analysis_export #(my_uvm_transaction) sb_export_left;
    uvm_analysis_export #(my_uvm_transaction) sb_export_right;
    uvm_analysis_export #(my_uvm_transaction) sb_export_compare_left;
    uvm_analysis_export #(my_uvm_transaction) sb_export_compare_right;

    uvm_tlm_analysis_fifo #(my_uvm_transaction) left_fifo;
    uvm_tlm_analysis_fifo #(my_uvm_transaction) right_fifo;
    uvm_tlm_analysis_fifo #(my_uvm_transaction) left_compare_fifo;
    uvm_tlm_analysis_fifo #(my_uvm_transaction) right_compare_fifo;

    my_uvm_transaction tx_left;
    my_uvm_transaction tx_right;
    my_uvm_transaction tx_cmp_left;
    my_uvm_transaction tx_cmp_right;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        tx_left      = new("tx_left");
        tx_right      = new("tx_right");
        tx_cmp_left  = new("tx_cmp_left");
        tx_cmp_right  = new("tx_cmp_right");
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sb_export_left    = new("sb_export_left", this);
        sb_export_right    = new("sb_export_right", this);
        sb_export_compare_left   = new("sb_export_compare_left", this);
        sb_export_compare_right   = new("sb_export_compare_right", this);

        left_fifo        = new("left_fifo", this);
        right_fifo        = new("right_fifo", this);
        left_compare_fifo    = new("left_compare_fifo", this);
        right_compare_fifo    = new("right_compare_fifo", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        sb_export_left.connect(left_fifo.analysis_export);
        sb_export_right.connect(right_fifo.analysis_export);
        sb_export_compare_left.connect(left_compare_fifo.analysis_export);
        sb_export_compare_right.connect(right_compare_fifo.analysis_export);
    endfunction: connect_phase

    virtual task run();
        forever begin
            left_fifo.get(tx_left);
            right_fifo.get(tx_right);
            left_compare_fifo.get(tx_cmp_left);
            right_compare_fifo.get(tx_cmp_right);            
            comparison();
        end
    endtask: run

    virtual function void comparison();
        if (tx_left.iq_in != tx_cmp_left.iq_in) begin
            // use uvm_error to report errors and continue
            // use uvm_fatal to halt the simulation on error
            `uvm_info("SB_CMP", tx_left.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp_left.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Test: Failed! Expecting: %08h, Received: %08h", tx_cmp_left.iq_in, tx_left.iq_in))
        end
        if (tx_right.iq_in != tx_cmp_right.iq_in) begin
            // use uvm_error to report errors and continue
            // use uvm_fatal to halt the simulation on error
            `uvm_info("SB_CMP", tx_right.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp_right.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Test: Failed! Expecting: %08h, Received: %08h", tx_cmp_right.iq_in, tx_right.iq_in))
        end
    endfunction: comparison
endclass: my_uvm_scoreboard
