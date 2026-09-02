// ============================================================================
// File: tb_ascon_permutation.v
// Description: Testbench to verify masked permutation for D=1 (3 shares)
//              and D=2 (4 shares) against unmasked permutation.
// ============================================================================

`timescale 1ns / 1ps

module tb_ascon_permutation;

    reg clk;
    reg reset;

    // Control
    reg [4:0] rounds;
    reg start_d1, start_d2;
    wire done_d1, done_d2;
    wire [4:0] ctr_d1, ctr_d2;

    // States
    reg [319:0] S_unmasked;
    reg [319:0] S_d1_0, S_d1_1, S_d1_2;
    reg [319:0] S_d2_0, S_d2_1, S_d2_2, S_d2_3;

    wire [319:0] out_d1_0, out_d1_1, out_d1_2;
    wire [319:0] out_d2_0, out_d2_1, out_d2_2, out_d2_3;

    wire [319:0] out_d1 = out_d1_0 ^ out_d1_1 ^ out_d1_2;
    wire [319:0] out_d2 = out_d2_0 ^ out_d2_1 ^ out_d2_2 ^ out_d2_3;

    // Round counters
    ascon_roundcounter rc_d1 (
        .clk(clk), .rst(reset),
        .permutation_start(start_d1),
        .permutation_ready(done_d1),
        .counter(ctr_d1)
    );

    ascon_roundcounter rc_d2 (
        .clk(clk), .rst(reset),
        .permutation_start(start_d2),
        .permutation_ready(done_d2),
        .counter(ctr_d2)
    );

    // Permutation D=1
    ascon_permutation_d1 u_perm_d1 (
        .clk(clk),
        .reset(reset),
        .ctr(ctr_d1),
        .S_0(S_d1_0), .S_1(S_d1_1), .S_2(S_d1_2),
        .rounds(rounds),
        .start(start_d1),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0),
        .out_0(out_d1_0), .out_1(out_d1_1), .out_2(out_d1_2),
        .done(done_d1)
    );

    // Permutation D=2
    ascon_permutation_d2 u_perm_d2 (
        .clk(clk),
        .reset(reset),
        .ctr(ctr_d2),
        .S_0(S_d2_0), .S_1(S_d2_1), .S_2(S_d2_2), .S_3(S_d2_3),
        .rounds(rounds),
        .start(start_d2),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .out_0(out_d2_0), .out_1(out_d2_1), .out_2(out_d2_2), .out_3(out_d2_3),
        .done(done_d2)
    );

    // Clock generator (100MHz)
    always #5 clk = ~clk;

    integer test_num;
    integer errors = 0;

    initial begin
        clk = 0;
        reset = 1;
        start_d1 = 0;
        start_d2 = 0;
        rounds = 12;

        #20;
        reset = 0;
        #10;

        for (test_num = 0; test_num < 10; test_num = test_num + 1) begin
            // Generate random 320-bit initial state
            S_unmasked = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};

            // Split into 3 shares for D=1
            S_d1_0 = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};
            S_d1_1 = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};
            S_d1_2 = S_unmasked ^ S_d1_0 ^ S_d1_1;

            // Split into 4 shares for D=2
            S_d2_0 = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};
            S_d2_1 = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};
            S_d2_2 = {$random, $random, $random, $random, $random, $random, $random, $random, $random, $random};
            S_d2_3 = S_unmasked ^ S_d2_0 ^ S_d2_1 ^ S_d2_2;

            rounds = (test_num % 2 == 0) ? 5'd12 : 5'd6;

            @(posedge clk);
            start_d1 = 1;
            start_d2 = 1;

            // Wait for both to complete
            wait (done_d1 && done_d2);
            @(posedge clk);

            // Compare outputs
            if (out_d1 !== out_d2) begin
                $display("[FAIL] Test %0d (rounds=%0d): D=1 and D=2 outputs MISMATCH!", test_num, rounds);
                $display("  D1 out: %h", out_d1);
                $display("  D2 out: %h", out_d2);
                errors = errors + 1;
            end else begin
                $display("[PASS] Test %0d (rounds=%0d): D=1 and D=2 match!", test_num, rounds);
                $display("  Output: %h", out_d1);
            end

            start_d1 = 0;
            start_d2 = 0;
            @(posedge clk);
            #10;
        end

        if (errors == 0) begin
            $display("=================================================");
            $display("   ALL MASKED PERMUTATION TESTS PASSED (D=1 & D=2)!");
            $display("=================================================");
        end else begin
            $display("=================================================");
            $display("   TESTS FAILED with %0d errors", errors);
            $display("=================================================");
        end

        $finish;
    end

endmodule
