// ============================================================================
// File: tb_ascon128.v
// Description: Comprehensive Vivado Testbench for Masked Ascon-128 (D=1 and D=2)
//              Tests both Authenticated Encryption and Authenticated Decryption
//              against known reference test vectors with random share splitting.
// ============================================================================

`timescale 1ns / 1ps

module tb_ascon128;

    parameter PERIOD = 10;

    reg clk;
    reg rst;

    // Test Vector 1: AD="ASCON" (40 bits), PT="ascon" (40 bits)
    localparam [127:0] V1_KEY   = 128'hb7234a4db9fb8b7c2aa5735ebef1180c;
    localparam [127:0] V1_NONCE = 128'h8ebb295da81c74b58306d4e8362e2242;
    localparam [39:0]  V1_AD    = 40'h4153434f4e;
    localparam [39:0]  V1_PT    = 40'h6173636f6e;
    localparam [39:0]  V1_CT    = 40'h80cdf888e3;
    localparam [127:0] V1_TAG   = 128'h741c60eea203c9449aa7f6b9adde1dee;

    // Signals for D=1 instance
    reg         start_d1;
    reg         decrypt_d1;
    wire        ready_d1;
    wire        auth_valid_d1;

    reg  [127:0] key_d1_0, key_d1_1, key_d1_2;
    reg  [127:0] nonce_d1_0, nonce_d1_1, nonce_d1_2;
    reg  [39:0]  ad_d1_0, ad_d1_1, ad_d1_2;
    reg  [39:0]  din_d1_0, din_d1_1, din_d1_2;
    reg  [127:0] tag_in_d1;

    wire [39:0]  dout_d1_0, dout_d1_1, dout_d1_2, dout_d1;
    wire [127:0] tag_out_d1_0, tag_out_d1_1, tag_out_d1_2, tag_out_d1;

    // Signals for D=2 instance
    reg         start_d2;
    reg         decrypt_d2;
    wire        ready_d2;
    wire        auth_valid_d2;

    reg  [127:0] key_d2_0, key_d2_1, key_d2_2, key_d2_3;
    reg  [127:0] nonce_d2_0, nonce_d2_1, nonce_d2_2, nonce_d2_3;
    reg  [39:0]  ad_d2_0, ad_d2_1, ad_d2_2, ad_d2_3;
    reg  [39:0]  din_d2_0, din_d2_1, din_d2_2, din_d2_3;
    reg  [127:0] tag_in_d2;

    wire [39:0]  dout_d2_0, dout_d2_1, dout_d2_2, dout_d2_3, dout_d2;
    wire [127:0] tag_out_d2_0, tag_out_d2_1, tag_out_d2_2, tag_out_d2_3, tag_out_d2;

    // Instantiate Top-level D=1
    ascon128_top #(
        .ORDER(1), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)
    ) dut_d1 (
        .clk(clk), .rst(rst),
        .start(start_d1), .decrypt(decrypt_d1),
        .ready(ready_d1), .auth_valid(auth_valid_d1),
        .key_0(key_d1_0), .key_1(key_d1_1), .key_2(key_d1_2), .key_3(128'd0),
        .nonce_0(nonce_d1_0), .nonce_1(nonce_d1_1), .nonce_2(nonce_d1_2), .nonce_3(128'd0),
        .ad_0(ad_d1_0), .ad_1(ad_d1_1), .ad_2(ad_d1_2), .ad_3(40'd0),
        .data_in_0(din_d1_0), .data_in_1(din_d1_1), .data_in_2(din_d1_2), .data_in_3(40'd0),
        .tag_in(tag_in_d1),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(dout_d1_0), .data_out_1(dout_d1_1), .data_out_2(dout_d1_2), .data_out_3(),
        .data_out(dout_d1),
        .tag_out_0(tag_out_d1_0), .tag_out_1(tag_out_d1_1), .tag_out_2(tag_out_d1_2), .tag_out_3(),
        .tag_out(tag_out_d1)
    );

    // Instantiate Top-level D=2
    ascon128_top #(
        .ORDER(2), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)
    ) dut_d2 (
        .clk(clk), .rst(rst),
        .start(start_d2), .decrypt(decrypt_d2),
        .ready(ready_d2), .auth_valid(auth_valid_d2),
        .key_0(key_d2_0), .key_1(key_d2_1), .key_2(key_d2_2), .key_3(key_d2_3),
        .nonce_0(nonce_d2_0), .nonce_1(nonce_d2_1), .nonce_2(nonce_d2_2), .nonce_3(nonce_d2_3),
        .ad_0(ad_d2_0), .ad_1(ad_d2_1), .ad_2(ad_d2_2), .ad_3(ad_d2_3),
        .data_in_0(din_d2_0), .data_in_1(din_d2_1), .data_in_2(din_d2_2), .data_in_3(din_d2_3),
        .tag_in(tag_in_d2),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(dout_d2_0), .data_out_1(dout_d2_1), .data_out_2(dout_d2_2), .data_out_3(dout_d2_3),
        .data_out(dout_d2),
        .tag_out_0(tag_out_d2_0), .tag_out_1(tag_out_d2_1), .tag_out_2(tag_out_d2_2), .tag_out_3(tag_out_d2_3),
        .tag_out(tag_out_d2)
    );

    // Clock generator
    always #(PERIOD/2) clk = ~clk;

    integer total_errors = 0;

    initial begin
        clk = 0;
        rst = 1;
        start_d1 = 0;
        decrypt_d1 = 0;
        start_d2 = 0;
        decrypt_d2 = 0;
        tag_in_d1 = 128'd0;
        tag_in_d2 = 128'd0;

        #20;
        rst = 0;
        #10;

        $display("===============================================================");
        $display("   RUNNING MASKED ASCON-128 AEAD TESTS IN VIVADO");
        $display("===============================================================");

        // --------------------------------------------------------------------
        // TEST 1: ENCRYPTION (D = 1, 3 shares)
        // --------------------------------------------------------------------
        $display("\n--- [TEST 1] Ascon-128 Encryption (Order D = 1, 3 shares) ---");
        key_d1_0   = {$random, $random, $random, $random};
        key_d1_1   = {$random, $random, $random, $random};
        key_d1_2   = V1_KEY ^ key_d1_0 ^ key_d1_1;

        nonce_d1_0 = {$random, $random, $random, $random};
        nonce_d1_1 = {$random, $random, $random, $random};
        nonce_d1_2 = V1_NONCE ^ nonce_d1_0 ^ nonce_d1_1;

        ad_d1_0    = {$random, $random};
        ad_d1_1    = {$random, $random};
        ad_d1_2    = V1_AD ^ ad_d1_0 ^ ad_d1_1;

        din_d1_0   = {$random, $random};
        din_d1_1   = {$random, $random};
        din_d1_2   = V1_PT ^ din_d1_0 ^ din_d1_1;

        @(posedge clk);
        start_d1   = 1;
        decrypt_d1 = 0;

        @(posedge clk);
        wait (ready_d1);
        @(posedge clk);

        $display("Key:          %h", V1_KEY);
        $display("Nonce:        %h", V1_NONCE);
        $display("AD:           %h", V1_AD);
        $display("PT:           %h", V1_PT);
        $display("Ciphertext:   %h (Expected: %h)", dout_d1, V1_CT);
        $display("Tag:          %h (Expected: %h)", tag_out_d1, V1_TAG);

        if (dout_d1 === V1_CT && tag_out_d1 === V1_TAG) begin
            $display("[PASS] D=1 Encryption MATCHES Reference Test Vector!");
        end else begin
            $display("[FAIL] D=1 Encryption Output MISMATCH!");
            total_errors = total_errors + 1;
        end

        start_d1 = 0;
        @(posedge clk);
        #20;

        // --------------------------------------------------------------------
        // TEST 2: ENCRYPTION (D = 2, 4 shares)
        // --------------------------------------------------------------------
        $display("\n--- [TEST 2] Ascon-128 Encryption (Order D = 2, 4 shares) ---");
        key_d2_0   = {$random, $random, $random, $random};
        key_d2_1   = {$random, $random, $random, $random};
        key_d2_2   = {$random, $random, $random, $random};
        key_d2_3   = V1_KEY ^ key_d2_0 ^ key_d2_1 ^ key_d2_2;

        nonce_d2_0 = {$random, $random, $random, $random};
        nonce_d2_1 = {$random, $random, $random, $random};
        nonce_d2_2 = {$random, $random, $random, $random};
        nonce_d2_3 = V1_NONCE ^ nonce_d2_0 ^ nonce_d2_1 ^ nonce_d2_2;

        ad_d2_0    = {$random, $random};
        ad_d2_1    = {$random, $random};
        ad_d2_2    = {$random, $random};
        ad_d2_3    = V1_AD ^ ad_d2_0 ^ ad_d2_1 ^ ad_d2_2;

        din_d2_0   = {$random, $random};
        din_d2_1   = {$random, $random};
        din_d2_2   = {$random, $random};
        din_d2_3   = V1_PT ^ din_d2_0 ^ din_d2_1 ^ din_d2_2;

        @(posedge clk);
        start_d2   = 1;
        decrypt_d2 = 0;

        @(posedge clk);
        wait (ready_d2);
        @(posedge clk);

        $display("Ciphertext:   %h (Expected: %h)", dout_d2, V1_CT);
        $display("Tag:          %h (Expected: %h)", tag_out_d2, V1_TAG);

        if (dout_d2 === V1_CT && tag_out_d2 === V1_TAG) begin
            $display("[PASS] D=2 Encryption MATCHES Reference Test Vector!");
        end else begin
            $display("[FAIL] D=2 Encryption Output MISMATCH!");
            total_errors = total_errors + 1;
        end

        start_d2 = 0;
        @(posedge clk);
        #20;

        // --------------------------------------------------------------------
        // TEST 3: DECRYPTION (D = 1, 3 shares)
        // --------------------------------------------------------------------
        $display("\n--- [TEST 3] Ascon-128 Decryption (Order D = 1, 3 shares) ---");
        key_d1_0   = {$random, $random, $random, $random};
        key_d1_1   = {$random, $random, $random, $random};
        key_d1_2   = V1_KEY ^ key_d1_0 ^ key_d1_1;

        nonce_d1_0 = {$random, $random, $random, $random};
        nonce_d1_1 = {$random, $random, $random, $random};
        nonce_d1_2 = V1_NONCE ^ nonce_d1_0 ^ nonce_d1_1;

        ad_d1_0    = {$random, $random};
        ad_d1_1    = {$random, $random};
        ad_d1_2    = V1_AD ^ ad_d1_0 ^ ad_d1_1;

        din_d1_0   = {$random, $random};
        din_d1_1   = {$random, $random};
        din_d1_2   = V1_CT ^ din_d1_0 ^ din_d1_1; // Feed Ciphertext to decrypt
        tag_in_d1  = V1_TAG;

        @(posedge clk);
        start_d1   = 1;
        decrypt_d1 = 1;

        @(posedge clk);
        wait (ready_d1);
        @(posedge clk);

        $display("Decrypted PT: %h (Expected: %h)", dout_d1, V1_PT);
        $display("Dec Tag:      %h (Expected: %h)", tag_out_d1, V1_TAG);
        $display("Auth Valid:   %b (Expected: 1)", auth_valid_d1);

        if (dout_d1 === V1_PT && tag_out_d1 === V1_TAG && auth_valid_d1 === 1'b1) begin
            $display("[PASS] D=1 Decryption and Authentication PASSED!");
        end else begin
            $display("[FAIL] D=1 Decryption Output MISMATCH!");
            total_errors = total_errors + 1;
        end

        start_d1 = 0;
        @(posedge clk);
        #20;

        // --------------------------------------------------------------------
        // TEST 4: DECRYPTION (D = 2, 4 shares)
        // --------------------------------------------------------------------
        $display("\n--- [TEST 4] Ascon-128 Decryption (Order D = 2, 4 shares) ---");
        key_d2_0   = {$random, $random, $random, $random};
        key_d2_1   = {$random, $random, $random, $random};
        key_d2_2   = {$random, $random, $random, $random};
        key_d2_3   = V1_KEY ^ key_d2_0 ^ key_d2_1 ^ key_d2_2;

        nonce_d2_0 = {$random, $random, $random, $random};
        nonce_d2_1 = {$random, $random, $random, $random};
        nonce_d2_2 = {$random, $random, $random, $random};
        nonce_d2_3 = V1_NONCE ^ nonce_d2_0 ^ nonce_d2_1 ^ nonce_d2_2;

        ad_d2_0    = {$random, $random};
        ad_d2_1    = {$random, $random};
        ad_d2_2    = {$random, $random};
        ad_d2_3    = V1_AD ^ ad_d2_0 ^ ad_d2_1 ^ ad_d2_2;

        din_d2_0   = {$random, $random};
        din_d2_1   = {$random, $random};
        din_d2_2   = {$random, $random};
        din_d2_3   = V1_CT ^ din_d2_0 ^ din_d2_1 ^ din_d2_2;
        tag_in_d2  = V1_TAG;

        @(posedge clk);
        start_d2   = 1;
        decrypt_d2 = 1;

        @(posedge clk);
        wait (ready_d2);
        @(posedge clk);

        $display("Decrypted PT: %h (Expected: %h)", dout_d2, V1_PT);
        $display("Dec Tag:      %h (Expected: %h)", tag_out_d2, V1_TAG);
        $display("Auth Valid:   %b (Expected: 1)", auth_valid_d2);

        if (dout_d2 === V1_PT && tag_out_d2 === V1_TAG && auth_valid_d2 === 1'b1) begin
            $display("[PASS] D=2 Decryption and Authentication PASSED!");
        end else begin
            $display("[FAIL] D=2 Decryption Output MISMATCH!");
            total_errors = total_errors + 1;
        end

        start_d2 = 0;
        @(posedge clk);
        #20;

        $display("\n===============================================================");
        if (total_errors == 0) begin
            $display("   >>> ALL ASCON-128 AEAD TESTS PASSED SUCCESSFULLY! <<<");
        end else begin
            $display("   >>> TESTS FAILED with %0d errors <<<", total_errors);
        end
        $display("===============================================================\n");

        $finish;
    end

endmodule
