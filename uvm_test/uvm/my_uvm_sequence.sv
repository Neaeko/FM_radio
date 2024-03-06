import uvm_pkg::*;


class my_uvm_transaction extends uvm_sequence_item;
    logic [63:0]    iq_in;
    logic           wr_en;


    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(my_uvm_transaction)
        `uvm_field_int(iq_in, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: my_uvm_transaction


class my_uvm_sequence extends uvm_sequence#(my_uvm_transaction);
    `uvm_object_utils(my_uvm_sequence)

    function new(string name = "");
        super.new(name);
    endfunction: new

    task body();        
        my_uvm_transaction tx;
        int in_file, left_cmp_file, right_cmp_file, iq_lines;
        logic [63:0] din;
        int i, j, count;

        `uvm_info("SEQ_RUN", $sformatf("Loading file %s...", IQ_IN_NAME), UVM_LOW);

        in_file = $fopen(IQ_IN_NAME, "rb");
        left_cmp_file = $fopen(LEFT_CMP_NAME, "rb");
        right_cmp_file = $fopen(RIGHT_CMP_NAME, "rb");


        if ( !in_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open file %s...", IQ_IN_NAME));
        end
        if ( !left_cmp_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open comparison file %s...", LEFT_CMP_NAME));
        end
        if ( !right_cmp_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open comparison file %s...", RIGHT_CMP_NAME));
        end

        iq_lines = 524288;

        i = 0;
        while ( i < iq_lines) begin
            tx = my_uvm_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));
            start_item(tx);
            count = $fscanf(in_file, "%016h", din);
            // tx.wr_en = 1'b1;
            tx.iq_in = din;
            //`uvm_info("SEQ_RUN", tx.sprint(), UVM_LOW);
            finish_item(tx);
            i++;
        end

        `uvm_info("SEQ_RUN", $sformatf("Closing file %s...", IQ_IN_NAME), UVM_LOW);
        $fclose(in_file);
    endtask: body
endclass: my_uvm_sequence

typedef uvm_sequencer#(my_uvm_transaction) my_uvm_sequencer;
