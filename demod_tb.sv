module demod_tb;

/* files */
localparam string IN_FILE_NAME = "./fir_complx_n.txt";
localparam string CMP_FILE_NAME = "./demodulate_n.txt";

localparam int DATA_WIDTH = 32;
localparam int DATA_SIZE = 30;
localparam int CLOCK_PERIOD = 10;

logic clk, reset;
logic [63:0] in_din;
logic [31:0] real_in;
logic [31:0] imag_in;
logic [31:0] data_out;

logic in_fifo_wr_en, out_fifo_rd_en, in_fifos_full, out_fifo_empty;
logic out_rd_done = '0;
logic in_write_done = '0;

integer out_errors = 0;

demod_top uut (
    .clk(clk),
    .reset(reset),
    .real_in(real_in),
    .img_in(imag_in),
    .in_fifo_wr_en(in_fifo_wr_en),
    .out_fifo_rd_en(out_fifo_rd_en),
    .data_out(data_out),
    .in_fifos_full(in_fifos_full),
    .out_fifo_empty(out_fifo_empty)
);

always begin
    clk = 1'b0;
    #(CLOCK_PERIOD/2);
    clk = 1'b1;
    #(CLOCK_PERIOD/2);
end

/* reset */
initial begin
    @(posedge clk);
    reset = 1'b1;
    @(posedge clk);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clk);
    start_time = $time;

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    @(posedge clk);

    wait(out_rd_done && in_write_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : read_process

    int i, in_file, count;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, IN_FILE_NAME);

    in_file = $fopen(IN_FILE_NAME, "r");
    in_fifo_wr_en = 1'b0;
    i = 0;

    // Read data from input angles text file
    while ( i < DATA_SIZE ) begin
        @(negedge clk);
        if (in_fifos_full == 1'b0) begin
            count = $fscanf(in_file,"%h", in_din);
            real_in = in_din[63:32];
            imag_in = in_din[31:0];
            in_fifo_wr_en = 1'b1;
        end else begin
            in_fifo_wr_en = 1'b0;
        end
        i++;
        // $display("din:%016h",in_din);
        // $display("i:%d",i);
    end

    @(negedge clk);
    in_fifo_wr_en = 1'b0;
    $display("CLOSING IN FILE");
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : comp_process
    int i, r;
    int cmp_file;
    logic [DATA_WIDTH-1:0] cmp_dout;

    @(negedge reset);
    @(posedge clk);

    $display("@ %0t: Comparing file %s...", $time, CMP_FILE_NAME);
    
    cmp_file = $fopen(CMP_FILE_NAME, "r");
    out_fifo_rd_en = 1'b0;
    i = 0;
    while (i < (DATA_SIZE)) begin
        @(negedge clk);
        out_fifo_rd_en = 1'b0;
            if (out_fifo_empty == 1'b0) begin
                out_fifo_rd_en = 1'b1;
                r = $fscanf(cmp_file, "%08h", cmp_dout);
                if (cmp_dout != data_out) begin
                    out_errors++;
                    $write("@ %0t: %s(%0d): ERROR: %x != %x at address 0x%x.\n", $time, "out file", i+1, {data_out}, cmp_dout, i);
                end
                i++;
            end 
        end

    @(negedge clk);
    out_fifo_rd_en = 1'b0;
    $display("CLOSING COMP FILE");
    $fclose(cmp_file);
    out_rd_done = 1'b1;
end

endmodule;