`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_official_nist_kat
// Comprehensive Official NIST SP 800-232 / Ascon-128 Known Answer Tests
// Benchmarking D = 0 (Unmasked), D = 1 (1st-Order), and D = 2 (2nd-Order)
////////////////////////////////////////////////////////////////////////////////

module tb_official_nist_kat;

    reg clk;
    reg rst;
    reg start;
    reg decrypt;

    // Clock Generation (100 MHz, 10 ns period)
    always #5 clk = ~clk;

    // 64-bit Random PRNG
    reg [63:0] rnd0, rnd1, rnd2, rnd3, rnd4, rnd5, rnd6, rnd7;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd0 <= 64'h123456789ABCDEF0;
            rnd1 <= 64'hFEDCBA9876543210;
            rnd2 <= 64'hA5A5A5A55A5A5A5A;
            rnd3 <= 64'h5A5A5A5AA5A5A5A5;
            rnd4 <= 64'h0123456789ABCDEF;
            rnd5 <= 64'hF0E1D2C3B4A59687;
            rnd6 <= 64'h78695A4B3C2D1E0F;
            rnd7 <= 64'hF1E2D3C4B5A69788;
        end else begin
            rnd0 <= {rnd0[62:0], rnd0[63] ^ rnd0[61] ^ rnd0[60] ^ rnd0[58]};
            rnd1 <= {rnd1[62:0], rnd1[63] ^ rnd1[61] ^ rnd1[59] ^ rnd1[55]};
            rnd2 <= {rnd2[62:0], rnd2[63] ^ rnd2[62] ^ rnd2[60] ^ rnd2[59]};
            rnd3 <= {rnd3[62:0], rnd3[63] ^ rnd3[61] ^ rnd3[56] ^ rnd3[54]};
            rnd4 <= {rnd4[62:0], rnd4[63] ^ rnd4[60] ^ rnd4[57] ^ rnd4[53]};
            rnd5 <= {rnd5[62:0], rnd5[63] ^ rnd5[59] ^ rnd5[58] ^ rnd5[52]};
            rnd6 <= {rnd6[62:0], rnd6[63] ^ rnd6[58] ^ rnd6[57] ^ rnd6[51]};
            rnd7 <= {rnd7[62:0], rnd7[63] ^ rnd7[57] ^ rnd7[56] ^ rnd7[50]};
        end
    end

    integer pass_count = 0;
    integer fail_count = 0;

    // -------------------------------------------------------------------------
    // Instantiate DUTs for Vector 1 (l=40, y=40)
    // -------------------------------------------------------------------------
    reg  [127:0] v1_key, v1_nonce;
    reg  [39:0]  v1_ad, v1_din;
    reg  [127:0] v1_tag_in;

    wire [39:0]  v1_d0_dout, v1_d1_dout, v1_d2_dout;
    wire [127:0] v1_d0_tag,  v1_d1_tag,  v1_d2_tag;
    wire v1_d0_rdy, v1_d1_rdy, v1_d2_rdy;
    wire v1_d0_auth, v1_d1_auth, v1_d2_auth;

    // D=1 shares
    wire [127:0] v1_k_d1_0 = v1_key ^ rnd0[63:0] ^ rnd1[63:0];
    wire [127:0] v1_k_d1_1 = {rnd0, rnd1};
    wire [127:0] v1_k_d1_2 = 128'h0;

    wire [127:0] v1_n_d1_0 = v1_nonce ^ rnd2[63:0] ^ rnd3[63:0];
    wire [127:0] v1_n_d1_1 = {rnd2, rnd3};
    wire [127:0] v1_n_d1_2 = 128'h0;

    wire [39:0]  v1_ad_d1_0 = v1_ad ^ rnd4[39:0];
    wire [39:0]  v1_ad_d1_1 = rnd4[39:0];
    wire [39:0]  v1_ad_d1_2 = 40'h0;

    wire [39:0]  v1_din_d1_0 = v1_din ^ rnd5[39:0];
    wire [39:0]  v1_din_d1_1 = rnd5[39:0];
    wire [39:0]  v1_din_d1_2 = 40'h0;

    // D=2 shares
    wire [127:0] v1_k_d2_0 = v1_key ^ rnd0[63:0] ^ rnd1[63:0] ^ rnd2[63:0];
    wire [127:0] v1_k_d2_1 = {rnd0, rnd1};
    wire [127:0] v1_k_d2_2 = {rnd2, rnd3};
    wire [127:0] v1_k_d2_3 = 128'h0;

    wire [127:0] v1_n_d2_0 = v1_nonce ^ rnd3[63:0] ^ rnd4[63:0] ^ rnd5[63:0];
    wire [127:0] v1_n_d2_1 = {rnd3, rnd4};
    wire [127:0] v1_n_d2_2 = {rnd5, rnd6};
    wire [127:0] v1_n_d2_3 = 128'h0;

    wire [39:0]  v1_ad_d2_0 = v1_ad ^ rnd6[39:0] ^ rnd7[39:0];
    wire [39:0]  v1_ad_d2_1 = rnd6[39:0];
    wire [39:0]  v1_ad_d2_2 = rnd7[39:0];
    wire [39:0]  v1_ad_d2_3 = 40'h0;

    wire [39:0]  v1_din_d2_0 = v1_din ^ rnd0[39:0] ^ rnd1[39:0];
    wire [39:0]  v1_din_d2_1 = rnd0[39:0];
    wire [39:0]  v1_din_d2_2 = rnd1[39:0];
    wire [39:0]  v1_din_d2_3 = 40'h0;

    ascon128_top #(.ORDER(0), .l(40), .y(40)) dut_v1_d0 (
        .clk(clk), .rst(rst), .start(start), .decrypt(decrypt),
        .ready(v1_d0_rdy), .auth_valid(v1_d0_auth),
        .key_0(v1_key), .key_1(128'd0), .key_2(128'd0), .key_3(128'd0),
        .nonce_0(v1_nonce), .nonce_1(128'd0), .nonce_2(128'd0), .nonce_3(128'd0),
        .ad_0(v1_ad), .ad_1(40'd0), .ad_2(40'd0), .ad_3(40'd0),
        .data_in_0(v1_din), .data_in_1(40'd0), .data_in_2(40'd0), .data_in_3(40'd0),
        .tag_in(v1_tag_in),
        .r0(rnd0), .r1(rnd1), .r2(rnd2), .r3(rnd3), .r4(rnd4), .r5(rnd5), .r6(rnd6), .r7(rnd7),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(v1_d0_dout),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(v1_d0_tag)
    );

    ascon128_top #(.ORDER(1), .l(40), .y(40)) dut_v1_d1 (
        .clk(clk), .rst(rst), .start(start), .decrypt(decrypt),
        .ready(v1_d1_rdy), .auth_valid(v1_d1_auth),
        .key_0(v1_k_d1_0), .key_1(v1_k_d1_1), .key_2(v1_k_d1_2), .key_3(128'd0),
        .nonce_0(v1_n_d1_0), .nonce_1(v1_n_d1_1), .nonce_2(v1_n_d1_2), .nonce_3(128'd0),
        .ad_0(v1_ad_d1_0), .ad_1(v1_ad_d1_1), .ad_2(v1_ad_d1_2), .ad_3(40'd0),
        .data_in_0(v1_din_d1_0), .data_in_1(v1_din_d1_1), .data_in_2(v1_din_d1_2), .data_in_3(40'd0),
        .tag_in(v1_tag_in),
        .r0(rnd0), .r1(rnd1), .r2(rnd2), .r3(rnd3), .r4(rnd4), .r5(rnd5), .r6(rnd6), .r7(rnd7),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(v1_d1_dout),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(v1_d1_tag)
    );

    ascon128_top #(.ORDER(2), .l(40), .y(40)) dut_v1_d2 (
        .clk(clk), .rst(rst), .start(start), .decrypt(decrypt),
        .ready(v1_d2_rdy), .auth_valid(v1_d2_auth),
        .key_0(v1_k_d2_0), .key_1(v1_k_d2_1), .key_2(v1_k_d2_2), .key_3(v1_k_d2_3),
        .nonce_0(v1_n_d2_0), .nonce_1(v1_n_d2_1), .nonce_2(v1_n_d2_2), .nonce_3(v1_n_d2_3),
        .ad_0(v1_ad_d2_0), .ad_1(v1_ad_d2_1), .ad_2(v1_ad_d2_2), .ad_3(v1_ad_d2_3),
        .data_in_0(v1_din_d2_0), .data_in_1(v1_din_d2_1), .data_in_2(v1_din_d2_2), .data_in_3(v1_din_d2_3),
        .tag_in(v1_tag_in),
        .r0(rnd0), .r1(rnd1), .r2(rnd2), .r3(rnd3), .r4(rnd4), .r5(rnd5), .r6(rnd6), .r7(rnd7),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(v1_d2_dout),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(v1_d2_tag)
    );

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        $display("========================================================================");
        $display("   OFFICIAL NIST SP 800-232 ASCON-128 KNOWN ANSWER TESTS (D=0, 1, 2)");
        $display("========================================================================");

        clk = 0;
        rst = 1;
        start = 0;
        decrypt = 0;
        v1_key = 0;
        v1_nonce = 0;
        v1_ad = 0;
        v1_din = 0;
        v1_tag_in = 0;
        #20 rst = 0;
        #20;

        // ---------------------------------------------------------------------
        // Official NIST Vector 1 (AD=40b, PT=40b)
        // ---------------------------------------------------------------------
        $display("\n========================================================================");
        $display(">>> [Official NIST Vector 1 (AD=40b, PT=40b)]");
        $display("    Key:     b7234a4db9fb8b7c2aa5735ebef1180c");
        $display("    Nonce:   8ebb295da81c74b58306d4e8362e2242");
        $display("    AD (40b):   4153434f4e");
        $display("    PT (40b):   6173636f6e");
        $display("    Exp CT:  80cdf888e3");
        $display("    Exp Tag: 741c60eea203c9449aa7f6b9adde1dee");
        $display("========================================================================");

        // ENCRYPTION
        v1_key = 128'hb7234a4db9fb8b7c2aa5735ebef1180c;
        v1_nonce = 128'h8ebb295da81c74b58306d4e8362e2242;
        v1_ad = 40'h4153434f4e;
        v1_din = 40'h6173636f6e;
        decrypt = 1'b0;
        start = 1'b1;
        #10 start = 1'b0;

        @(posedge v1_d0_rdy);
        @(posedge v1_d1_rdy);
        @(posedge v1_d2_rdy);
        #10;

        if (v1_d0_dout === 40'h80cdf888e3 && v1_d0_tag === 128'h741c60eea203c9449aa7f6b9adde1dee) begin
            $display("[PASS] [D=0 ENC] CT = %h, Tag = %h", v1_d0_dout, v1_d0_tag);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=0 ENC] Got CT = %h, Tag = %h", v1_d0_dout, v1_d0_tag);
            fail_count = fail_count + 1;
        end

        if (v1_d1_dout === 40'h80cdf888e3 && v1_d1_tag === 128'h741c60eea203c9449aa7f6b9adde1dee) begin
            $display("[PASS] [D=1 ENC] CT = %h, Tag = %h", v1_d1_dout, v1_d1_tag);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=1 ENC] Got CT = %h, Tag = %h", v1_d1_dout, v1_d1_tag);
            fail_count = fail_count + 1;
        end

        if (v1_d2_dout === 40'h80cdf888e3 && v1_d2_tag === 128'h741c60eea203c9449aa7f6b9adde1dee) begin
            $display("[PASS] [D=2 ENC] CT = %h, Tag = %h", v1_d2_dout, v1_d2_tag);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=2 ENC] Got CT = %h, Tag = %h", v1_d2_dout, v1_d2_tag);
            fail_count = fail_count + 1;
        end

        #20;

        // DECRYPTION
        v1_din = 40'h80cdf888e3;
        v1_tag_in = 128'h741c60eea203c9449aa7f6b9adde1dee;
        decrypt = 1'b1;
        start = 1'b1;
        #10 start = 1'b0;

        @(posedge v1_d0_rdy);
        @(posedge v1_d1_rdy);
        @(posedge v1_d2_rdy);
        #10;

        if (v1_d0_dout === 40'h6173636f6e && v1_d0_auth === 1'b1) begin
            $display("[PASS] [D=0 DEC] PT = %h, Auth = %b", v1_d0_dout, v1_d0_auth);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=0 DEC] Got PT = %h, Auth = %b", v1_d0_dout, v1_d0_auth);
            fail_count = fail_count + 1;
        end

        if (v1_d1_dout === 40'h6173636f6e && v1_d1_auth === 1'b1) begin
            $display("[PASS] [D=1 DEC] PT = %h, Auth = %b", v1_d1_dout, v1_d1_auth);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=1 DEC] Got PT = %h, Auth = %b", v1_d1_dout, v1_d1_auth);
            fail_count = fail_count + 1;
        end

        if (v1_d2_dout === 40'h6173636f6e && v1_d2_auth === 1'b1) begin
            $display("[PASS] [D=2 DEC] PT = %h, Auth = %b", v1_d2_dout, v1_d2_auth);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] [D=2 DEC] Got PT = %h, Auth = %b", v1_d2_dout, v1_d2_auth);
            fail_count = fail_count + 1;
        end

        #50;

        $display("\n========================================================================");
        if (fail_count == 0)
            $display("   >>> ALL OFFICIAL NIST SP 800-232 KATs PASSED (PASS: %0d, FAIL: 0)! <<<", pass_count);
        else
            $display("   >>> SOME TESTS FAILED (PASS: %0d, FAIL: %0d)! <<<", pass_count, fail_count);
        $display("========================================================================\n");

        $finish;
    end

endmodule
