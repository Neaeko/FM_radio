`timescale 1ns / 1ps

module divider_tb;

// Testbench parameters should match the divider module parameters
parameter DIVIDEND_WIDTH = 32;
parameter DIVISOR_WIDTH = 32;

// Testbench signals
reg clk;
reg start;
reg [DIVIDEND_WIDTH-1:0] dividend;
reg [DIVISOR_WIDTH-1:0] divisor;
wire [DIVIDEND_WIDTH-1:0] quotient;
wire [DIVISOR_WIDTH-1:0] remainder;
wire overflow;
wire done;
// Instantiate the Unit Under Test (UUT)
divider #(
    .DIVIDEND_WIDTH(DIVIDEND_WIDTH),
    .DIVISOR_WIDTH(DIVISOR_WIDTH)
) uut (
    .clk(clk),
    .start(start),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder),
    .overflow(overflow),
    .done(done)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // Generate a clock with a period of 10 ns
end

// Test sequences
initial begin
    // Initialize Inputs
    start = 0;
    dividend = 0;
    divisor = 0;

    // Wait for global reset to finish
    #100;
    
    // Test Case 1: Simple division
    start = 1; dividend = 100; divisor = 10; #10; start = 0; #1000;
    
    // Test Case 2: Division by zero
    start = 1; dividend = 50; divisor = 0; #10; start = 0; #1000;
    
    // Test Case 3: Overflow condition (if applicable based on your logic)
    start = 1; dividend = 32'hFFFFFFFF; divisor = 1; #10; start = 0; #1000;
    
    // Add more test cases as needed
// Continue from the previous initial block
    // ...

    // Test Case 4: Dividing the maximum possible value by the minimum non-zero value
    start = 1; dividend = {DIVIDEND_WIDTH{1'b1}}; divisor = 1; #10; start = 0; #1000;

    // Test Case 5: Dividend is less than divisor
    start = 1; dividend = 10; divisor = 100; #10; start = 0; #1000;

    // Assuming the design supports signed numbers, add tests for negative values
    // Note: Actual support for negative numbers depends on the implementation of the divider

    // Test Case 6: Negative dividend
    start = 1; dividend = -50; divisor = 10; #10; start = 0; #1000;

    // Test Case 7: Negative divisor
    start = 1; dividend = 50; divisor = -10; #10; start = 0; #1000;

    // Test Case 8: Both dividend and divisor are negative
    start = 1; dividend = -50; divisor = -10; #10; start = 0; #1000;

    // Test Case 9: Large dividend, small divisor
    start = 1; dividend = 32'h7FFFFFFF; divisor = 2; #10; start = 0; #1000;

    // Test Case 10: Small dividend, large divisor
    start = 1; dividend = 2; divisor = 32'h7FFFFFFF; #10; start = 0; #1000;

    // Test Case 11: Divisor is 1 (edge case for some implementations)
    start = 1; dividend = 12345678; divisor = 1; #10; start = 0; #1000;

    // Test Case 12: Dividend is 0 (should always result in 0 quotient and 0 remainder)
    start = 1; dividend = 0; divisor = 12345; #10; start = 0; #1000;

    // Add more specific cases as necessary to thoroughly test your design

    // Finish simulation
    $finish;

end

endmodule
