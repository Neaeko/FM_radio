import uvm_pkg::*;


// Reads data from output fifo to scoreboard
class my_uvm_monitor_output extends uvm_monitor;
    `uvm_component_utils(my_uvm_monitor_output)

    uvm_analysis_port#(my_uvm_transaction) mon_ap_output;

    virtual my_uvm_if vif;
    int right_out_file;
    int left_out_file;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual my_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_output = new(.name("mon_ap_output"), .parent(this));

        right_out_file = $fopen(RIGHT_OUT_NAME, "wb");
        left_out_file = $fopen(LEFT_OUT_NAME, "wb");
        if ( !right_out_file ) begin
            `uvm_fatal("MON_OUT_BUILD", $sformatf("Failed to open output file %s...", RIGHT_OUT_NAME));
        end
        if ( !left_out_file ) begin
            `uvm_fatal("MON_OUT_BUILD", $sformatf("Failed to open output file %s...", LEFT_OUT_NAME));
        end
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        int n_bytes;

        my_uvm_transaction tx_out;

        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_out = my_uvm_transaction::type_id::create(.name("tx_out"), .contxt(get_full_name()));

        vif.out_rd_en = 1'b0;

        forever begin
            @(negedge vif.clk)
            begin
                if (vif.out_empty == 1'b0) begin
                    $fwrite(left_out_file, "%08h\n", vif.left_dout);
                    tx_out.iq_in = vif.left_dout;
                    mon_ap_output.write(tx_out);
                    $fwrite(right_out_file, "%08h\n", vif.right_dout);
                    tx_out.iq_in = vif.right_dout;
                    mon_ap_output.write(tx_out);
                    vif.out_rd_en = 1'b1;
                end else begin
                    vif.out_rd_en = 1'b0;
                end
            end
        end
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("LEFT_MON_OUT_FINAL", $sformatf("Closing file %s...", LEFT_OUT_NAME), UVM_LOW);
        $fclose(left_out_file);
        `uvm_info("RIGHT_MON_OUT_FINAL", $sformatf("Closing file %s...", RIGHT_OUT_NAME), UVM_LOW);
        $fclose(right_out_file);
    endfunction: final_phase

endclass: my_uvm_monitor_output


// Reads data from compare file to scoreboard
class my_uvm_monitor_compare extends uvm_monitor;
    `uvm_component_utils(my_uvm_monitor_compare)

    uvm_analysis_port#(my_uvm_transaction) mon_ap_compare;
    virtual my_uvm_if vif;
    int left_cmp_file, right_cmp_file, n_bytes;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual my_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_compare = new(.name("mon_ap_compare"), .parent(this));
        left_cmp_file = $fopen(LEFT_CMP_NAME, "rb");
        right_cmp_file = $fopen(RIGHT_CMP_NAME, "rb");
        if ( !left_cmp_file ) begin
            `uvm_fatal("LEFT_MON_CMP_BUILD", $sformatf("Failed to open file %s...", LEFT_CMP_NAME));
        end
        if ( !right_cmp_file ) begin
            `uvm_fatal("RIGHT_MON_CMP_BUILD", $sformatf("Failed to open file %s...", RIGHT_CMP_NAME));
        end

        // store the BMP header as packed array
        // n_bytes = $fread(pcap_header, cmp_file, 0, PCAP_HEADER_SIZE);
        // uvm_config_db#(logic[0:PCAP_HEADER_SIZE-1][7:0])::set(null, "*", "pcap_header", {>> 8{pcap_header}});
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        int left_int=0, right_int=0, i=0, total_ints=65536; 
        logic [31:0] left_dout, right_dout;
        my_uvm_transaction tx_cmp;

        // extend the run_phase 20 clock cycles
        phase.phase_done.set_drain_time(this, (CLOCK_PERIOD*20));

        // notify that run_phase has started
        phase.raise_objection(.obj(this));

        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_cmp = my_uvm_transaction::type_id::create(.name("tx_cmp"), .contxt(get_full_name()));

        i = 0;

        // syncronize file read with fifo data
        while ( i < total_ints) begin
            @(negedge vif.clk)
            begin
                if ( vif.out_empty == 1'b0 ) begin
                    left_int = $fscanf(left_cmp_file,"%08h", left_dout);
                    tx_cmp.iq_in = left_dout;
                    mon_ap_compare.write(tx_cmp);
                    right_int = $fscanf(right_cmp_file, "%08h", right_dout);
                    tx_cmp.iq_in = right_dout;
                    mon_ap_compare.write(tx_cmp);
                    i += 1;
                end
            end
        end

        // notify that run_phase has completed
        phase.drop_objection(.obj(this));
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("LEFT_MON_CMP_FINAL", $sformatf("Closing file %s...", LEFT_CMP_NAME), UVM_LOW);
        $fclose(left_cmp_file);
        `uvm_info("RIGHT_MON_CMP_FINAL", $sformatf("Closing file %s...", RIGHT_CMP_NAME), UVM_LOW);
        $fclose(right_cmp_file);
    endfunction: final_phase

endclass: my_uvm_monitor_compare
