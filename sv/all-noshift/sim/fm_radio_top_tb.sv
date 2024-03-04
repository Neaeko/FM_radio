`timescale 1ns/1ns

module fm_radio_top_tb;

/* files */
localparam string IN_FILE_NAME = "1.0_read_IQ_output.txt";
localparam string CMP_RIGHT_FILE_NAME = "2.8_out_right.txt";
localparam string CMP_LEFT_FILE_NAME = "1.8_out_left.txt";

localparam DATA_WIDTH = 64;
localparam DATA_SIZE = 524288;
localparam CLOCK_PERIOD = 10;

    
/* signals for tb */
logic start, out_read_done, in_write_done;
logic in_wr_en;
logic q_in_full, i_in_full, in_full;
logic out_rd_en;
logic left_out_empty, right_out_empty, out_empty;
integer out_errors = 0;

logic clock, reset;
logic [DATA_WIDTH-1:0] din;
logic [(DATA_WIDTH/2)-1:0] dout_right, dout_left;

/* fir instance */
fm_radio_top dut (
    .clock(clock),
    .reset(reset),

    .i_din(din[63:32]),
    .q_din(din[31:0]),
    .in_wr_en(in_wr_en),
    .in_full(in_full),


    .left_out(dout_left),
    .right_out(dout_right),
    .out_rd_en(out_rd_en),
    .out_empty(out_empty)
);

assign left_out_empty = out_empty;
assign right_out_empty = out_empty;
assign q_in_full = in_full;
assign i_in_full = in_full;


/* clock */
always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
end

/* reset */
initial begin
    @(posedge clock);
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clock);
    start_time = $time;

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;

    wait(out_read_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : read_process
    int i, r;
    int in_file;
    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, IN_FILE_NAME);
    in_write_done = 1'b0;

    in_file = $fopen(IN_FILE_NAME, "r");
    in_wr_en = 1'b0;
    i = 0;
    while (i < DATA_SIZE) begin
        @(negedge clock);
        if (q_in_full == 1'b0 & i_in_full == 1'b0) begin
            r = $fscanf(in_file, "%16h", din);
            in_wr_en = 1'b1;
            i++;
        end else begin
            in_wr_en = 1'b0;
        end
    end

    @(negedge clock);
    in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : cmp_process
    int i, r;
    int cmp_file_left;
    int cmp_file_right;
    logic [DATA_WIDTH/2-1:0] cmp_dout_left;
    logic [DATA_WIDTH/2-1:0] cmp_dout_right;

    @(negedge reset);
    @(posedge clock);

    $display("@ %0t: Comparing file %s and %s...", $time, CMP_RIGHT_FILE_NAME, CMP_LEFT_FILE_NAME);
    out_read_done = 1'b0;

    cmp_file_right = $fopen(CMP_RIGHT_FILE_NAME, "r");
    cmp_file_left = $fopen(CMP_LEFT_FILE_NAME, "r");
    out_rd_en = 1'b0;

    i = 0;
    while (i < 50) begin
        @(negedge clock);
        out_rd_en = 1'b0;
            if (left_out_empty == 1'b0 & right_out_empty == 1'b0) begin
                out_rd_en = 1'b1;
                r = $fscanf(cmp_file_right, "%08h", cmp_dout_right);
                r = $fscanf(cmp_file_left, "%08h", cmp_dout_left);
                if (cmp_dout_left != dout_left | cmp_dout_right != dout_right) begin
                    out_errors++;
                    $write("@ %0t: %s(%0d): ERROR: %x %x != %x %x at address 0x%x.\n", $time, "out file", i+1, dout_left, dout_right, cmp_dout_left, cmp_dout_right, i);
                end
                i++;
            end 
        end

    @(negedge clock);
    out_rd_en = 1'b0;
    $fclose(cmp_file_right);
    $fclose(cmp_file_left);
    out_read_done = 1'b1;
end

endmodule
