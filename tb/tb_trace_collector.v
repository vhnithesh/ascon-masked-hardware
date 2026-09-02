// ============================================================================
// File: tb_trace_collector.v
// Description: Vivado Trace Collector for Ascon-128 (D = 0, D = 1, D = 2)
//              Generates synchronized simulated power traces (Hamming Distance
//              and Hamming Weight leakage model) across clock cycles for CNN training.
// Reference: https://github.com/Deadly-pro/ascon-dlsca
// ============================================================================

`timescale 1ns / 1ps

module tb_trace_collector;

    parameter PERIOD = 10;
    parameter NUM_TRACES = 1000;      // 1,000 traces for DL-SCA profiling
    parameter SAMPLES_PER_TRACE = 50; // Clock cycles per encryption operation

    reg clk;
    reg rst;

    always #(PERIOD/2) clk = ~clk;

    // Popcount functions
    function [6:0] popcount64;
        input [63:0] v;
        integer b;
        begin
            popcount64 = 0;
            for (b = 0; b < 64; b = b + 1)
                popcount64 = popcount64 + v[b];
        end
    endfunction

    // ------------------------------------------------------------------------
    // DUT Signals: D = 0, D = 1, D = 2
    // ------------------------------------------------------------------------
    reg         start_d0, decrypt_d0;
    wire        ready_d0, auth_valid_d0;
    reg  [127:0] key_d0, nonce_d0;
    reg  [39:0]  ad_d0, din_d0;
    wire [39:0]  dout_d0;
    wire [127:0] tag_out_d0;

    ascon128_top #(.ORDER(0), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_d0 (
        .clk(clk), .rst(rst),
        .start(start_d0), .decrypt(decrypt_d0),
        .ready(ready_d0), .auth_valid(auth_valid_d0),
        .key_0(key_d0), .key_1(128'd0), .key_2(128'd0), .key_3(128'd0),
        .nonce_0(nonce_d0), .nonce_1(128'd0), .nonce_2(128'd0), .nonce_3(128'd0),
        .ad_0(ad_d0), .ad_1(40'd0), .ad_2(40'd0), .ad_3(40'd0),
        .data_in_0(din_d0), .data_in_1(40'd0), .data_in_2(40'd0), .data_in_3(40'd0),
        .tag_in(128'd0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_d0),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_d0)
    );

    reg         start_d1, decrypt_d1;
    wire        ready_d1, auth_valid_d1;
    reg  [127:0] key_d1_0, key_d1_1, key_d1_2;
    reg  [127:0] nonce_d1_0, nonce_d1_1, nonce_d1_2;
    reg  [39:0]  ad_d1_0, ad_d1_1, ad_d1_2;
    reg  [39:0]  din_d1_0, din_d1_1, din_d1_2;
    wire [39:0]  dout_d1_0, dout_d1_1, dout_d1_2, dout_d1;
    wire [127:0] tag_out_d1_0, tag_out_d1_1, tag_out_d1_2, tag_out_d1;

    ascon128_top #(.ORDER(1), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_d1 (
        .clk(clk), .rst(rst),
        .start(start_d1), .decrypt(decrypt_d1),
        .ready(ready_d1), .auth_valid(auth_valid_d1),
        .key_0(key_d1_0), .key_1(key_d1_1), .key_2(key_d1_2), .key_3(128'd0),
        .nonce_0(nonce_d1_0), .nonce_1(nonce_d1_1), .nonce_2(nonce_d1_2), .nonce_3(128'd0),
        .ad_0(ad_d1_0), .ad_1(ad_d1_1), .ad_2(ad_d1_2), .ad_3(40'd0),
        .data_in_0(din_d1_0), .data_in_1(din_d1_1), .data_in_2(din_d1_2), .data_in_3(40'd0),
        .tag_in(128'd0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(dout_d1_0), .data_out_1(dout_d1_1), .data_out_2(dout_d1_2), .data_out_3(),
        .data_out(dout_d1),
        .tag_out_0(tag_out_d1_0), .tag_out_1(tag_out_d1_1), .tag_out_2(tag_out_d1_2), .tag_out_3(),
        .tag_out(tag_out_d1)
    );

    reg         start_d2, decrypt_d2;
    wire        ready_d2, auth_valid_d2;
    reg  [127:0] key_d2_0, key_d2_1, key_d2_2, key_d2_3;
    reg  [127:0] nonce_d2_0, nonce_d2_1, nonce_d2_2, nonce_d2_3;
    reg  [39:0]  ad_d2_0, ad_d2_1, ad_d2_2, ad_d2_3;
    reg  [39:0]  din_d2_0, din_d2_1, din_d2_2, din_d2_3;
    wire [39:0]  dout_d2_0, dout_d2_1, dout_d2_2, dout_d2_3, dout_d2;
    wire [127:0] tag_out_d2_0, tag_out_d2_1, tag_out_d2_2, tag_out_d2_3, tag_out_d2;

    ascon128_top #(.ORDER(2), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_d2 (
        .clk(clk), .rst(rst),
        .start(start_d2), .decrypt(decrypt_d2),
        .ready(ready_d2), .auth_valid(auth_valid_d2),
        .key_0(key_d2_0), .key_1(key_d2_1), .key_2(key_d2_2), .key_3(key_d2_3),
        .nonce_0(nonce_d2_0), .nonce_1(nonce_d2_1), .nonce_2(nonce_d2_2), .nonce_3(nonce_d2_3),
        .ad_0(ad_d2_0), .ad_1(ad_d2_1), .ad_2(ad_d2_2), .ad_3(ad_d2_3),
        .data_in_0(din_d2_0), .data_in_1(din_d2_1), .data_in_2(din_d2_2), .data_in_3(din_d2_3),
        .tag_in(128'd0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(dout_d2_0), .data_out_1(dout_d2_1), .data_out_2(dout_d2_2), .data_out_3(dout_d2_3),
        .data_out(dout_d2),
        .tag_out_0(tag_out_d2_0), .tag_out_1(tag_out_d2_1), .tag_out_2(tag_out_d2_2), .tag_out_3(tag_out_d2_3),
        .tag_out(tag_out_d2)
    );

    // Internal state monitoring for power trace modeling
    // D=0 internal state
    wire [319:0] S_int_d0 = dut_d0.gen_order_0.u_ascon_d0.u_perm.S_reg;
    reg  [319:0] S_prev_d0;

    // D=1 internal state (3 shares)
    wire [319:0] S0_int_d1 = {dut_d1.gen_order_1.u_ascon_d1.u_perm.x0_0_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x1_0_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x2_0_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x3_0_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x4_0_q};
    wire [319:0] S1_int_d1 = {dut_d1.gen_order_1.u_ascon_d1.u_perm.x0_1_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x1_1_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x2_1_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x3_1_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x4_1_q};
    wire [319:0] S2_int_d1 = {dut_d1.gen_order_1.u_ascon_d1.u_perm.x0_2_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x1_2_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x2_2_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x3_2_q, dut_d1.gen_order_1.u_ascon_d1.u_perm.x4_2_q};
    reg  [319:0] S0_prev_d1, S1_prev_d1, S2_prev_d1;

    // D=2 internal state (4 shares)
    wire [319:0] S0_int_d2 = {dut_d2.gen_order_2.u_ascon_d2.u_perm.x0_0_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x1_0_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x2_0_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x3_0_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x4_0_q};
    wire [319:0] S1_int_d2 = {dut_d2.gen_order_2.u_ascon_d2.u_perm.x0_1_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x1_1_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x2_1_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x3_1_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x4_1_q};
    wire [319:0] S2_int_d2 = {dut_d2.gen_order_2.u_ascon_d2.u_perm.x0_2_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x1_2_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x2_2_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x3_2_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x4_2_q};
    wire [319:0] S3_int_d2 = {dut_d2.gen_order_2.u_ascon_d2.u_perm.x0_3_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x1_3_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x2_3_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x3_3_q, dut_d2.gen_order_2.u_ascon_d2.u_perm.x4_3_q};
    reg  [319:0] S0_prev_d2, S1_prev_d2, S2_prev_d2, S3_prev_d2;

    // File descriptors
    integer fd_d0, fd_d1, fd_d2, fd_meta;
    integer tr_idx, cycle_idx;
    reg [127:0] cur_key, cur_nonce;
    reg [39:0]  cur_ad, cur_pt;

    integer hd_d0, hd_d1, hd_d2;

    initial begin
        clk = 0;
        rst = 1;
        start_d0 = 0; decrypt_d0 = 0; din_d0 = 0;
        start_d1 = 0; decrypt_d1 = 0; din_d1_0 = 0; din_d1_1 = 0; din_d1_2 = 0;
        start_d2 = 0; decrypt_d2 = 0; din_d2_0 = 0; din_d2_1 = 0; din_d2_2 = 0; din_d2_3 = 0;

        S_prev_d0 = 0;
        S0_prev_d1 = 0; S1_prev_d1 = 0; S2_prev_d1 = 0;
        S0_prev_d2 = 0; S1_prev_d2 = 0; S2_prev_d2 = 0; S3_prev_d2 = 0;

        // Open files for writing traces
        fd_d0   = $fopen("C:/Users/vhnit/ascon_masked_vivado/traces_d0.csv", "w");
        fd_d1   = $fopen("C:/Users/vhnit/ascon_masked_vivado/traces_d1.csv", "w");
        fd_d2   = $fopen("C:/Users/vhnit/ascon_masked_vivado/traces_d2.csv", "w");
        fd_meta = $fopen("C:/Users/vhnit/ascon_masked_vivado/traces_meta.csv", "w");

        #30;
        rst = 0;
        #10;

        $display("================================================================================");
        $display("   COLLECTING %0d SIMULATED POWER TRACES IN VIVADO (D=0, D=1, D=2)", NUM_TRACES);
        $display("================================================================================");

        for (tr_idx = 0; tr_idx < NUM_TRACES; tr_idx = tr_idx + 1) begin
            cur_key   = {$random, $random, $random, $random};
            cur_nonce = {$random, $random, $random, $random};
            cur_ad    = 40'h4153434f4e; // "ASCON"
            cur_pt    = {$random, $random};

            // Setup D=0
            key_d0   = cur_key;
            nonce_d0 = cur_nonce;
            ad_d0    = cur_ad;
            din_d0   = cur_pt;

            // Setup D=1 (3 random shares)
            key_d1_0   = {$random, $random, $random, $random};
            key_d1_1   = {$random, $random, $random, $random};
            key_d1_2   = cur_key ^ key_d1_0 ^ key_d1_1;
            nonce_d1_0 = {$random, $random, $random, $random};
            nonce_d1_1 = {$random, $random, $random, $random};
            nonce_d1_2 = cur_nonce ^ nonce_d1_0 ^ nonce_d1_1;
            ad_d1_0    = {$random, $random};
            ad_d1_1    = {$random, $random};
            ad_d1_2    = cur_ad ^ ad_d1_0 ^ ad_d1_1;
            din_d1_0   = {$random, $random};
            din_d1_1   = {$random, $random};
            din_d1_2   = cur_pt ^ din_d1_0 ^ din_d1_1;

            // Setup D=2 (4 random shares)
            key_d2_0   = {$random, $random, $random, $random};
            key_d2_1   = {$random, $random, $random, $random};
            key_d2_2   = {$random, $random, $random, $random};
            key_d2_3   = cur_key ^ key_d2_0 ^ key_d2_1 ^ key_d2_2;
            nonce_d2_0 = {$random, $random, $random, $random};
            nonce_d2_1 = {$random, $random, $random, $random};
            nonce_d2_2 = {$random, $random, $random, $random};
            nonce_d2_3 = cur_nonce ^ nonce_d2_0 ^ nonce_d2_1 ^ nonce_d2_2;
            ad_d2_0    = {$random, $random};
            ad_d2_1    = {$random, $random};
            ad_d2_2    = {$random, $random};
            ad_d2_3    = cur_ad ^ ad_d2_0 ^ ad_d2_1 ^ ad_d2_2;
            din_d2_0   = {$random, $random};
            din_d2_1   = {$random, $random};
            din_d2_2   = {$random, $random};
            din_d2_3   = cur_pt ^ din_d2_0 ^ din_d2_1 ^ din_d2_2;

            // Write metadata (key, nonce, ad, pt)
            $fwrite(fd_meta, "%h,%h,%h,%h\n", cur_key, cur_nonce, cur_ad, cur_pt);

            // Assert start
            @(posedge clk);
            start_d0 = 1; decrypt_d0 = 0;
            start_d1 = 1; decrypt_d1 = 0;
            start_d2 = 1; decrypt_d2 = 0;

            // Sample power consumption (Hamming Distance) cycle-by-cycle
            for (cycle_idx = 0; cycle_idx < SAMPLES_PER_TRACE; cycle_idx = cycle_idx + 1) begin
                @(posedge clk);

                // Compute D=0 Hamming Distance
                hd_d0 = popcount64(S_int_d0[319:256] ^ S_prev_d0[319:256]) +
                        popcount64(S_int_d0[255:192] ^ S_prev_d0[255:192]) +
                        popcount64(S_int_d0[191:128] ^ S_prev_d0[191:128]) +
                        popcount64(S_int_d0[127:64]  ^ S_prev_d0[127:64])  +
                        popcount64(S_int_d0[63:0]    ^ S_prev_d0[63:0]);

                // Compute D=1 Hamming Distance (sum of all 3 shares)
                hd_d1 = popcount64(S0_int_d1[319:256] ^ S0_prev_d1[319:256]) +
                        popcount64(S0_int_d1[255:192] ^ S0_prev_d1[255:192]) +
                        popcount64(S0_int_d1[191:128] ^ S0_prev_d1[191:128]) +
                        popcount64(S0_int_d1[127:64]  ^ S0_prev_d1[127:64])  +
                        popcount64(S0_int_d1[63:0]    ^ S0_prev_d1[63:0])    +
                        popcount64(S1_int_d1[319:256] ^ S1_prev_d1[319:256]) +
                        popcount64(S1_int_d1[255:192] ^ S1_prev_d1[255:192]) +
                        popcount64(S1_int_d1[191:128] ^ S1_prev_d1[191:128]) +
                        popcount64(S1_int_d1[127:64]  ^ S1_prev_d1[127:64])  +
                        popcount64(S1_int_d1[63:0]    ^ S1_prev_d1[63:0])    +
                        popcount64(S2_int_d1[319:256] ^ S2_prev_d1[319:256]) +
                        popcount64(S2_int_d1[255:192] ^ S2_prev_d1[255:192]) +
                        popcount64(S2_int_d1[191:128] ^ S2_prev_d1[191:128]) +
                        popcount64(S2_int_d1[127:64]  ^ S2_prev_d1[127:64])  +
                        popcount64(S2_int_d1[63:0]    ^ S2_prev_d1[63:0]);

                // Compute D=2 Hamming Distance (sum of all 4 shares)
                hd_d2 = popcount64(S0_int_d2[319:256] ^ S0_prev_d2[319:256]) +
                        popcount64(S0_int_d2[255:192] ^ S0_prev_d2[255:192]) +
                        popcount64(S0_int_d2[191:128] ^ S0_prev_d2[191:128]) +
                        popcount64(S0_int_d2[127:64]  ^ S0_prev_d2[127:64])  +
                        popcount64(S0_int_d2[63:0]    ^ S0_prev_d2[63:0])    +
                        popcount64(S1_int_d2[319:256] ^ S1_prev_d2[319:256]) +
                        popcount64(S1_int_d2[255:192] ^ S1_prev_d2[255:192]) +
                        popcount64(S1_int_d2[191:128] ^ S1_prev_d2[191:128]) +
                        popcount64(S1_int_d2[127:64]  ^ S1_prev_d2[127:64])  +
                        popcount64(S1_int_d2[63:0]    ^ S1_prev_d2[63:0])    +
                        popcount64(S2_int_d2[319:256] ^ S2_prev_d2[319:256]) +
                        popcount64(S2_int_d2[255:192] ^ S2_prev_d2[255:192]) +
                        popcount64(S2_int_d2[191:128] ^ S2_prev_d2[191:128]) +
                        popcount64(S2_int_d2[127:64]  ^ S2_prev_d2[127:64])  +
                        popcount64(S2_int_d2[63:0]    ^ S2_prev_d2[63:0])    +
                        popcount64(S3_int_d2[319:256] ^ S3_prev_d2[319:256]) +
                        popcount64(S3_int_d2[255:192] ^ S3_prev_d2[255:192]) +
                        popcount64(S3_int_d2[191:128] ^ S3_prev_d2[191:128]) +
                        popcount64(S3_int_d2[127:64]  ^ S3_prev_d2[127:64])  +
                        popcount64(S3_int_d2[63:0]    ^ S3_prev_d2[63:0]);

                // Write sample to trace CSV
                if (cycle_idx == SAMPLES_PER_TRACE - 1) begin
                    $fwrite(fd_d0, "%d\n", hd_d0);
                    $fwrite(fd_d1, "%d\n", hd_d1);
                    $fwrite(fd_d2, "%d\n", hd_d2);
                end else begin
                    $fwrite(fd_d0, "%d,", hd_d0);
                    $fwrite(fd_d1, "%d,", hd_d1);
                    $fwrite(fd_d2, "%d,", hd_d2);
                end

                S_prev_d0  <= S_int_d0;
                S0_prev_d1 <= S0_int_d1; S1_prev_d1 <= S1_int_d1; S2_prev_d1 <= S2_int_d1;
                S0_prev_d2 <= S0_int_d2; S1_prev_d2 <= S1_int_d2; S2_prev_d2 <= S2_int_d2; S3_prev_d2 <= S3_int_d2;
            end

            // Wait until ready and deassert start
            while (!(ready_d0 && ready_d1 && ready_d2)) @(posedge clk);
            start_d0 = 0; start_d1 = 0; start_d2 = 0;
            @(posedge clk);

            if ((tr_idx + 1) % 200 == 0 || tr_idx == 0)
                $display("[TRACE] Captured %4d / %0d traces for D=0, D=1, D=2", tr_idx + 1, NUM_TRACES);
        end

        $fclose(fd_d0);
        $fclose(fd_d1);
        $fclose(fd_d2);
        $fclose(fd_meta);

        $display("================================================================================");
        $display("   TRACE COLLECTION COMPLETE: Saved 1,000 traces for D=0, D=1, D=2");
        $display("================================================================================");
        $finish;
    end

endmodule