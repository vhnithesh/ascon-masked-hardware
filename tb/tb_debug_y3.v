`timescale 1ns / 1ps

module tb_debug_y3;
    reg [63:0] x0, x1, x2, x3, x4;
    wire [63:0] sl3_ref = (x4 & x0) ^ (x3 & x0) ^ x4 ^ x3 ^ x2 ^ x1 ^ x0;

    reg [63:0] x0_0, x1_0, x2_0, x3_0, x4_0;
    reg [63:0] x0_1, x1_1, x2_1, x3_1, x4_1;
    reg [63:0] x0_2, x1_2, x2_2, x3_2, x4_2;
    reg [63:0] x0_3, x1_3, x2_3, x3_3, x4_3;

    wire [63:0] y3_0 = (x4_0 & x0_3) ^ (x4_1 & x0_0) ^ (x4_1 & x0_1) ^ (x4_3 & x0_0) ^ x4_3 ^ (x3_0 & x0_1) ^ (x3_0 & x0_3) ^ (x3_1 & x0_0) ^ (x3_1 & x0_3) ^ x1_0 ^ x0_0 ^ x0_3;
    wire [63:0] y3_1 = (x4_0 & x0_1) ^ (x4_0 & x0_2) ^ (x4_1 & x0_2) ^ x4_1 ^ (x4_2 & x0_2) ^ (x3_0 & x0_0) ^ (x3_0 & x0_2) ^ x3_0 ^ (x3_1 & x0_1) ^ (x3_1 & x0_2) ^ x3_1 ^ (x3_2 & x0_1) ^ (x3_2 & x0_2) ^ x2_0 ^ x1_1;
    wire [63:0] y3_2 = (x4_0 & x0_0) ^ x4_0 ^ (x4_2 & x0_0) ^ (x4_2 & x0_3) ^ (x4_3 & x0_3) ^ (x3_2 & x0_0) ^ (x3_3 & x0_0) ^ x3_3 ^ x2_3 ^ x1_3 ^ x0_2;
    wire [63:0] y3_3 = (x4_1 & x0_3) ^ (x4_2 & x0_1) ^ x4_2 ^ (x4_3 & x0_1) ^ (x4_3 & x0_2) ^ (x3_2 & x0_3) ^ x3_2 ^ (x3_3 & x0_1) ^ (x3_3 & x0_2) ^ (x3_3 & x0_3) ^ x2_1 ^ x2_2 ^ x1_2 ^ x0_1;

    wire [63:0] y3_sum = y3_0 ^ y3_1 ^ y3_2 ^ y3_3;

    initial begin
        x0 = 64'h1111111111111111;
        x1 = 64'h2222222222222222;
        x2 = 64'h3333333333333333;
        x3 = 64'h4444444444444444;
        x4 = 64'h5555555555555555;

        // Try unshared (share 0 has all, others 0)
        x0_0 = x0; x0_1 = 0; x0_2 = 0; x0_3 = 0;
        x1_0 = x1; x1_1 = 0; x1_2 = 0; x1_3 = 0;
        x2_0 = x2; x2_1 = 0; x2_2 = 0; x2_3 = 0;
        x3_0 = x3; x3_1 = 0; x3_2 = 0; x3_3 = 0;
        x4_0 = x4; x4_1 = 0; x4_2 = 0; x4_3 = 0;

        #1;
        $display("Unshared test:");
        $display("  sl3_ref: %h", sl3_ref);
        $display("  y3_sum:  %h", y3_sum);
        $display("  Diff:    %h", y3_sum ^ sl3_ref);

        // Try share 1 has all
        x0_0 = 0; x0_1 = x0; x0_2 = 0; x0_3 = 0;
        x1_0 = 0; x1_1 = x1; x1_2 = 0; x1_3 = 0;
        x2_0 = 0; x2_1 = x2; x2_2 = 0; x2_3 = 0;
        x3_0 = 0; x3_1 = x3; x3_2 = 0; x3_3 = 0;
        x4_0 = 0; x4_1 = x4; x4_2 = 0; x4_3 = 0;

        #1;
        $display("Share 1 only test:");
        $display("  sl3_ref: %h", sl3_ref);
        $display("  y3_sum:  %h", y3_sum);
        $display("  Diff:    %h", y3_sum ^ sl3_ref);

        // Try share 2 has all
        x0_0 = 0; x0_1 = 0; x0_2 = x0; x0_3 = 0;
        x1_0 = 0; x1_1 = 0; x1_2 = x1; x1_3 = 0;
        x2_0 = 0; x2_1 = 0; x2_2 = x2; x2_3 = 0;
        x3_0 = 0; x3_1 = 0; x3_2 = x3; x3_3 = 0;
        x4_0 = 0; x4_1 = 0; x4_2 = 0; x4_3 = 0;

        #1;
        $display("Share 2 only test:");
        $display("  sl3_ref: %h", sl3_ref);
        $display("  y3_sum:  %h", y3_sum);
        $display("  Diff:    %h", y3_sum ^ sl3_ref);

        // Try share 3 has all
        x0_0 = 0; x0_1 = 0; x0_2 = 0; x0_3 = x0;
        x1_0 = 0; x1_1 = 0; x1_2 = 0; x1_3 = x1;
        x2_0 = 0; x2_1 = 0; x2_2 = 0; x2_3 = x2;
        x3_0 = 0; x3_1 = 0; x3_2 = 0; x3_3 = x3;
        x4_0 = 0; x4_1 = 0; x4_2 = 0; x4_3 = x4;

        #1;
        $display("Share 3 only test:");
        $display("  sl3_ref: %h", sl3_ref);
        $display("  y3_sum:  %h", y3_sum);
        $display("  Diff:    %h", y3_sum ^ sl3_ref);

        $finish;
    end
endmodule
