// ============================================================================
// File: tb_ascon128_kat.v
// Description: Comprehensive Known Answer Test (KAT) Suite in Vivado
//              Tests all 3 masking orders (D = 0, D = 1, D = 2) for both
//              Authenticated Encryption and Decryption against NIST KAT vectors.
// ============================================================================

`timescale 1ns / 1ps

module tb_ascon128_kat;

    parameter PERIOD = 10;

    reg clk;
    reg rst;

    // Clock generator
    always #(PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------------
    // KAT Vectors Definition
    // ------------------------------------------------------------------------
    // KAT 1 (l=40, y=40): "ASCON" / "ascon"
    localparam [127:0] K1_KEY   = 128'hb7234a4db9fb8b7c2aa5735ebef1180c;
    localparam [127:0] K1_NONCE = 128'h8ebb295da81c74b58306d4e8362e2242;
    localparam [39:0]  K1_AD    = 40'h4153434f4e;
    localparam [39:0]  K1_PT    = 40'h6173636f6e;
    localparam [39:0]  K1_CT    = 40'h80cdf888e3;
    localparam [127:0] K1_TAG   = 128'h741c60eea203c9449aa7f6b9adde1dee;

    // KAT 2 (l=40, y=80): "ASCON" / "encryption"
    localparam [127:0] K2_KEY   = 128'h2db083053e848cefa30007336c47a5a1;
    localparam [127:0] K2_NONCE = 128'h3f3607dbce3503ba84f5843d623de056;
    localparam [39:0]  K2_AD    = 40'h4153434f4e;
    localparam [79:0]  K2_PT    = 80'h656e6372797074696f6e;
    localparam [79:0]  K2_CT    = 80'h87a59a2ea49b233259e3;
    localparam [127:0] K2_TAG   = 128'h402afdb55e031ce7ddef99b7f7709d1c;

    // KAT 3 (l=40, y=96): "ASCON" / "Hello World!"
    localparam [127:0] K3_KEY   = 128'h5362006eff0b33bc8bb9950abdb242fc;
    localparam [127:0] K3_NONCE = 128'h1ccfafbc6dc738283ca9fe21ce0fccaa;
    localparam [39:0]  K3_AD    = 40'h4153434f4e;
    localparam [95:0]  K3_PT    = 96'h48656c6c6f20576f726c6421;
    localparam [95:0]  K3_CT    = 96'h24cefa36227cb37b5149860a;
    localparam [127:0] K3_TAG   = 128'h579c9a31342638cddeadedc34d9ce2b3;

    // ------------------------------------------------------------------------
    // Signal definitions for KAT 1 (l=40, y=40)
    // ------------------------------------------------------------------------
    reg         start_k1_d0, decrypt_k1_d0;
    wire        ready_k1_d0, auth_valid_k1_d0;
    wire [39:0] dout_k1_d0;
    wire [127:0] tag_out_k1_d0;
    reg  [127:0] tag_in_k1_d0;
    reg  [39:0]  din_k1_d0;

    reg         start_k1_d1, decrypt_k1_d1;
    wire        ready_k1_d1, auth_valid_k1_d1;
    reg  [127:0] key_k1_d1_0, key_k1_d1_1, key_k1_d1_2;
    reg  [127:0] nonce_k1_d1_0, nonce_k1_d1_1, nonce_k1_d1_2;
    reg  [39:0]  ad_k1_d1_0, ad_k1_d1_1, ad_k1_d1_2;
    reg  [39:0]  din_k1_d1_0, din_k1_d1_1, din_k1_d1_2;
    wire [39:0]  dout_k1_d1;
    wire [127:0] tag_out_k1_d1;
    reg  [127:0] tag_in_k1_d1;

    reg         start_k1_d2, decrypt_k1_d2;
    wire        ready_k1_d2, auth_valid_k1_d2;
    reg  [127:0] key_k1_d2_0, key_k1_d2_1, key_k1_d2_2, key_k1_d2_3;
    reg  [127:0] nonce_k1_d2_0, nonce_k1_d2_1, nonce_k1_d2_2, nonce_k1_d2_3;
    reg  [39:0]  ad_k1_d2_0, ad_k1_d2_1, ad_k1_d2_2, ad_k1_d2_3;
    reg  [39:0]  din_k1_d2_0, din_k1_d2_1, din_k1_d2_2, din_k1_d2_3;
    wire [39:0]  dout_k1_d2;
    wire [127:0] tag_out_k1_d2;
    reg  [127:0] tag_in_k1_d2;

    // Instantiate KAT 1 D=0
    ascon128_top #(.ORDER(0), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_k1_d0 (
        .clk(clk), .rst(rst), .start(start_k1_d0), .decrypt(decrypt_k1_d0),
        .ready(ready_k1_d0), .auth_valid(auth_valid_k1_d0),
        .key_0(K1_KEY), .key_1(128'd0), .key_2(128'd0), .key_3(128'd0),
        .nonce_0(K1_NONCE), .nonce_1(128'd0), .nonce_2(128'd0), .nonce_3(128'd0),
        .ad_0(K1_AD), .ad_1(40'd0), .ad_2(40'd0), .ad_3(40'd0),
        .data_in_0(din_k1_d0), .data_in_1(40'd0), .data_in_2(40'd0), .data_in_3(40'd0),
        .tag_in(tag_in_k1_d0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k1_d0),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k1_d0)
    );

    // Instantiate KAT 1 D=1
    ascon128_top #(.ORDER(1), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_k1_d1 (
        .clk(clk), .rst(rst), .start(start_k1_d1), .decrypt(decrypt_k1_d1),
        .ready(ready_k1_d1), .auth_valid(auth_valid_k1_d1),
        .key_0(key_k1_d1_0), .key_1(key_k1_d1_1), .key_2(key_k1_d1_2), .key_3(128'd0),
        .nonce_0(nonce_k1_d1_0), .nonce_1(nonce_k1_d1_1), .nonce_2(nonce_k1_d1_2), .nonce_3(128'd0),
        .ad_0(ad_k1_d1_0), .ad_1(ad_k1_d1_1), .ad_2(ad_k1_d1_2), .ad_3(40'd0),
        .data_in_0(din_k1_d1_0), .data_in_1(din_k1_d1_1), .data_in_2(din_k1_d1_2), .data_in_3(40'd0),
        .tag_in(tag_in_k1_d1),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k1_d1),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k1_d1)
    );

    // Instantiate KAT 1 D=2
    ascon128_top #(.ORDER(2), .k(128), .r(64), .a(12), .b(6), .l(40), .y(40)) dut_k1_d2 (
        .clk(clk), .rst(rst), .start(start_k1_d2), .decrypt(decrypt_k1_d2),
        .ready(ready_k1_d2), .auth_valid(auth_valid_k1_d2),
        .key_0(key_k1_d2_0), .key_1(key_k1_d2_1), .key_2(key_k1_d2_2), .key_3(key_k1_d2_3),
        .nonce_0(nonce_k1_d2_0), .nonce_1(nonce_k1_d2_1), .nonce_2(nonce_k1_d2_2), .nonce_3(nonce_k1_d2_3),
        .ad_0(ad_k1_d2_0), .ad_1(ad_k1_d2_1), .ad_2(ad_k1_d2_2), .ad_3(ad_k1_d2_3),
        .data_in_0(din_k1_d2_0), .data_in_1(din_k1_d2_1), .data_in_2(din_k1_d2_2), .data_in_3(din_k1_d2_3),
        .tag_in(tag_in_k1_d2),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k1_d2),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k1_d2)
    );

    // ------------------------------------------------------------------------
    // Signal definitions for KAT 2 (l=40, y=80)
    // ------------------------------------------------------------------------
    reg         start_k2_d0, decrypt_k2_d0;
    wire        ready_k2_d0, auth_valid_k2_d0;
    wire [79:0] dout_k2_d0;
    wire [127:0] tag_out_k2_d0;
    reg  [127:0] tag_in_k2_d0;
    reg  [79:0]  din_k2_d0;

    reg         start_k2_d1, decrypt_k2_d1;
    wire        ready_k2_d1, auth_valid_k2_d1;
    reg  [127:0] key_k2_d1_0, key_k2_d1_1, key_k2_d1_2;
    reg  [127:0] nonce_k2_d1_0, nonce_k2_d1_1, nonce_k2_d1_2;
    reg  [39:0]  ad_k2_d1_0, ad_k2_d1_1, ad_k2_d1_2;
    reg  [79:0]  din_k2_d1_0, din_k2_d1_1, din_k2_d1_2;
    wire [79:0]  dout_k2_d1;
    wire [127:0] tag_out_k2_d1;
    reg  [127:0] tag_in_k2_d1;

    reg         start_k2_d2, decrypt_k2_d2;
    wire        ready_k2_d2, auth_valid_k2_d2;
    reg  [127:0] key_k2_d2_0, key_k2_d2_1, key_k2_d2_2, key_k2_d2_3;
    reg  [127:0] nonce_k2_d2_0, nonce_k2_d2_1, nonce_k2_d2_2, nonce_k2_d2_3;
    reg  [39:0]  ad_k2_d2_0, ad_k2_d2_1, ad_k2_d2_2, ad_k2_d2_3;
    reg  [79:0]  din_k2_d2_0, din_k2_d2_1, din_k2_d2_2, din_k2_d2_3;
    wire [79:0]  dout_k2_d2;
    wire [127:0] tag_out_k2_d2;
    reg  [127:0] tag_in_k2_d2;

    // Instantiate KAT 2 D=0
    ascon128_top #(.ORDER(0), .k(128), .r(64), .a(12), .b(6), .l(40), .y(80)) dut_k2_d0 (
        .clk(clk), .rst(rst), .start(start_k2_d0), .decrypt(decrypt_k2_d0),
        .ready(ready_k2_d0), .auth_valid(auth_valid_k2_d0),
        .key_0(K2_KEY), .key_1(128'd0), .key_2(128'd0), .key_3(128'd0),
        .nonce_0(K2_NONCE), .nonce_1(128'd0), .nonce_2(128'd0), .nonce_3(128'd0),
        .ad_0(K2_AD), .ad_1(40'd0), .ad_2(40'd0), .ad_3(40'd0),
        .data_in_0(din_k2_d0), .data_in_1(80'd0), .data_in_2(80'd0), .data_in_3(80'd0),
        .tag_in(tag_in_k2_d0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k2_d0),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k2_d0)
    );

    // Instantiate KAT 2 D=1
    ascon128_top #(.ORDER(1), .k(128), .r(64), .a(12), .b(6), .l(40), .y(80)) dut_k2_d1 (
        .clk(clk), .rst(rst), .start(start_k2_d1), .decrypt(decrypt_k2_d1),
        .ready(ready_k2_d1), .auth_valid(auth_valid_k2_d1),
        .key_0(key_k2_d1_0), .key_1(key_k2_d1_1), .key_2(key_k2_d1_2), .key_3(128'd0),
        .nonce_0(nonce_k2_d1_0), .nonce_1(nonce_k2_d1_1), .nonce_2(nonce_k2_d1_2), .nonce_3(128'd0),
        .ad_0(ad_k2_d1_0), .ad_1(ad_k2_d1_1), .ad_2(ad_k2_d1_2), .ad_3(40'd0),
        .data_in_0(din_k2_d1_0), .data_in_1(din_k2_d1_1), .data_in_2(din_k2_d1_2), .data_in_3(80'd0),
        .tag_in(tag_in_k2_d1),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k2_d1),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k2_d1)
    );

    // Instantiate KAT 2 D=2
    ascon128_top #(.ORDER(2), .k(128), .r(64), .a(12), .b(6), .l(40), .y(80)) dut_k2_d2 (
        .clk(clk), .rst(rst), .start(start_k2_d2), .decrypt(decrypt_k2_d2),
        .ready(ready_k2_d2), .auth_valid(auth_valid_k2_d2),
        .key_0(key_k2_d2_0), .key_1(key_k2_d2_1), .key_2(key_k2_d2_2), .key_3(key_k2_d2_3),
        .nonce_0(nonce_k2_d2_0), .nonce_1(nonce_k2_d2_1), .nonce_2(nonce_k2_d2_2), .nonce_3(nonce_k2_d2_3),
        .ad_0(ad_k2_d2_0), .ad_1(ad_k2_d2_1), .ad_2(ad_k2_d2_2), .ad_3(ad_k2_d2_3),
        .data_in_0(din_k2_d2_0), .data_in_1(din_k2_d2_1), .data_in_2(din_k2_d2_2), .data_in_3(din_k2_d2_3),
        .tag_in(tag_in_k2_d2),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k2_d2),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k2_d2)
    );

    // ------------------------------------------------------------------------
    // Signal definitions for KAT 3 (l=40, y=96)
    // ------------------------------------------------------------------------
    reg         start_k3_d0, decrypt_k3_d0;
    wire        ready_k3_d0, auth_valid_k3_d0;
    wire [95:0] dout_k3_d0;
    wire [127:0] tag_out_k3_d0;
    reg  [127:0] tag_in_k3_d0;
    reg  [95:0]  din_k3_d0;

    reg         start_k3_d1, decrypt_k3_d1;
    wire        ready_k3_d1, auth_valid_k3_d1;
    reg  [127:0] key_k3_d1_0, key_k3_d1_1, key_k3_d1_2;
    reg  [127:0] nonce_k3_d1_0, nonce_k3_d1_1, nonce_k3_d1_2;
    reg  [39:0]  ad_k3_d1_0, ad_k3_d1_1, ad_k3_d1_2;
    reg  [95:0]  din_k3_d1_0, din_k3_d1_1, din_k3_d1_2;
    wire [95:0]  dout_k3_d1;
    wire [127:0] tag_out_k3_d1;
    reg  [127:0] tag_in_k3_d1;

    reg         start_k3_d2, decrypt_k3_d2;
    wire        ready_k3_d2, auth_valid_k3_d2;
    reg  [127:0] key_k3_d2_0, key_k3_d2_1, key_k3_d2_2, key_k3_d2_3;
    reg  [127:0] nonce_k3_d2_0, nonce_k3_d2_1, nonce_k3_d2_2, nonce_k3_d2_3;
    reg  [39:0]  ad_k3_d2_0, ad_k3_d2_1, ad_k3_d2_2, ad_k3_d2_3;
    reg  [95:0]  din_k3_d2_0, din_k3_d2_1, din_k3_d2_2, din_k3_d2_3;
    wire [95:0]  dout_k3_d2;
    wire [127:0] tag_out_k3_d2;
    reg  [127:0] tag_in_k3_d2;

    // Instantiate KAT 3 D=0
    ascon128_top #(.ORDER(0), .k(128), .r(64), .a(12), .b(6), .l(40), .y(96)) dut_k3_d0 (
        .clk(clk), .rst(rst), .start(start_k3_d0), .decrypt(decrypt_k3_d0),
        .ready(ready_k3_d0), .auth_valid(auth_valid_k3_d0),
        .key_0(K3_KEY), .key_1(128'd0), .key_2(128'd0), .key_3(128'd0),
        .nonce_0(K3_NONCE), .nonce_1(128'd0), .nonce_2(128'd0), .nonce_3(128'd0),
        .ad_0(K3_AD), .ad_1(40'd0), .ad_2(40'd0), .ad_3(40'd0),
        .data_in_0(din_k3_d0), .data_in_1(96'd0), .data_in_2(96'd0), .data_in_3(96'd0),
        .tag_in(tag_in_k3_d0),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k3_d0),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k3_d0)
    );

    // Instantiate KAT 3 D=1
    ascon128_top #(.ORDER(1), .k(128), .r(64), .a(12), .b(6), .l(40), .y(96)) dut_k3_d1 (
        .clk(clk), .rst(rst), .start(start_k3_d1), .decrypt(decrypt_k3_d1),
        .ready(ready_k3_d1), .auth_valid(auth_valid_k3_d1),
        .key_0(key_k3_d1_0), .key_1(key_k3_d1_1), .key_2(key_k3_d1_2), .key_3(128'd0),
        .nonce_0(nonce_k3_d1_0), .nonce_1(nonce_k3_d1_1), .nonce_2(nonce_k3_d1_2), .nonce_3(128'd0),
        .ad_0(ad_k3_d1_0), .ad_1(ad_k3_d1_1), .ad_2(ad_k3_d1_2), .ad_3(40'd0),
        .data_in_0(din_k3_d1_0), .data_in_1(din_k3_d1_1), .data_in_2(din_k3_d1_2), .data_in_3(96'd0),
        .tag_in(tag_in_k3_d1),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k3_d1),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k3_d1)
    );

    // Instantiate KAT 3 D=2
    ascon128_top #(.ORDER(2), .k(128), .r(64), .a(12), .b(6), .l(40), .y(96)) dut_k3_d2 (
        .clk(clk), .rst(rst), .start(start_k3_d2), .decrypt(decrypt_k3_d2),
        .ready(ready_k3_d2), .auth_valid(auth_valid_k3_d2),
        .key_0(key_k3_d2_0), .key_1(key_k3_d2_1), .key_2(key_k3_d2_2), .key_3(key_k3_d2_3),
        .nonce_0(nonce_k3_d2_0), .nonce_1(nonce_k3_d2_1), .nonce_2(nonce_k3_d2_2), .nonce_3(nonce_k3_d2_3),
        .ad_0(ad_k3_d2_0), .ad_1(ad_k3_d2_1), .ad_2(ad_k3_d2_2), .ad_3(ad_k3_d2_3),
        .data_in_0(din_k3_d2_0), .data_in_1(din_k3_d2_1), .data_in_2(din_k3_d2_2), .data_in_3(din_k3_d2_3),
        .tag_in(tag_in_k3_d2),
        .r0(64'd0), .r1(64'd0), .r2(64'd0), .r3(64'd0), .r4(64'd0), .r5(64'd0), .r6(64'd0), .r7(64'd0),
        .data_out_0(), .data_out_1(), .data_out_2(), .data_out_3(), .data_out(dout_k3_d2),
        .tag_out_0(), .tag_out_1(), .tag_out_2(), .tag_out_3(), .tag_out(tag_out_k3_d2)
    );

    integer err_count = 0;

    initial begin
        clk = 0;
        rst = 1;

        start_k1_d0 = 0; decrypt_k1_d0 = 0; tag_in_k1_d0 = 0; din_k1_d0 = 0;
        start_k1_d1 = 0; decrypt_k1_d1 = 0; tag_in_k1_d1 = 0;
        start_k1_d2 = 0; decrypt_k1_d2 = 0; tag_in_k1_d2 = 0;

        start_k2_d0 = 0; decrypt_k2_d0 = 0; tag_in_k2_d0 = 0; din_k2_d0 = 0;
        start_k2_d1 = 0; decrypt_k2_d1 = 0; tag_in_k2_d1 = 0;
        start_k2_d2 = 0; decrypt_k2_d2 = 0; tag_in_k2_d2 = 0;

        start_k3_d0 = 0; decrypt_k3_d0 = 0; tag_in_k3_d0 = 0; din_k3_d0 = 0;
        start_k3_d1 = 0; decrypt_k3_d1 = 0; tag_in_k3_d1 = 0;
        start_k3_d2 = 0; decrypt_k3_d2 = 0; tag_in_k3_d2 = 0;

        #30;
        rst = 0;
        #10;

        $display("========================================================================");
        $display("   ASCON-128 KNOWN ANSWER TESTS (KAT): D = 0, D = 1, D = 2 IN VIVADO");
        $display("========================================================================");

        // ====================================================================
        // KAT VECTOR 1: PT = "ascon" (40 bits), AD = "ASCON" (40 bits)
        // ====================================================================
        $display("\n========================================================================");
        $display(">>> [KAT VECTOR 1] AD=\"ASCON\" (40-bit), PT=\"ascon\" (40-bit)");
        $display("    Key:   %h", K1_KEY);
        $display("    Nonce: %h", K1_NONCE);
        $display("    AD:    %h", K1_AD);
        $display("    PT:    %h", K1_PT);
        $display("    Exp CT: %h", K1_CT);
        $display("    Exp Tag:%h", K1_TAG);
        $display("========================================================================");

        // --- D = 0 Encryption ---
        din_k1_d0 = K1_PT;
        @(posedge clk);
        start_k1_d0 = 1; decrypt_k1_d0 = 0;
        @(posedge clk);
        wait(ready_k1_d0);
        @(posedge clk);
        if (dout_k1_d0 === K1_CT && tag_out_k1_d0 === K1_TAG)
            $display("[PASS] [D=0 ENC] CT = %h, Tag = %h", dout_k1_d0, tag_out_k1_d0);
        else begin
            $display("[FAIL] [D=0 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k1_d0, K1_CT, tag_out_k1_d0, K1_TAG);
            err_count = err_count + 1;
        end
        start_k1_d0 = 0;
        @(posedge clk);

        // --- D = 0 Decryption ---
        din_k1_d0 = K1_CT; tag_in_k1_d0 = K1_TAG;
        @(posedge clk);
        start_k1_d0 = 1; decrypt_k1_d0 = 1;
        @(posedge clk);
        wait(ready_k1_d0);
        @(posedge clk);
        if (dout_k1_d0 === K1_PT && tag_out_k1_d0 === K1_TAG && auth_valid_k1_d0 === 1'b1)
            $display("[PASS] [D=0 DEC] PT = %h, Tag = %h, Auth = %b", dout_k1_d0, tag_out_k1_d0, auth_valid_k1_d0);
        else begin
            $display("[FAIL] [D=0 DEC] PT = %h (exp %h), Auth = %b", dout_k1_d0, K1_PT, auth_valid_k1_d0);
            err_count = err_count + 1;
        end
        start_k1_d0 = 0;
        @(posedge clk);

        // --- D = 1 Encryption ---
        key_k1_d1_0 = {$random, $random, $random, $random};
        key_k1_d1_1 = {$random, $random, $random, $random};
        key_k1_d1_2 = K1_KEY ^ key_k1_d1_0 ^ key_k1_d1_1;
        nonce_k1_d1_0 = {$random, $random, $random, $random};
        nonce_k1_d1_1 = {$random, $random, $random, $random};
        nonce_k1_d1_2 = K1_NONCE ^ nonce_k1_d1_0 ^ nonce_k1_d1_1;
        ad_k1_d1_0 = {$random, $random}; ad_k1_d1_1 = {$random, $random};
        ad_k1_d1_2 = K1_AD ^ ad_k1_d1_0 ^ ad_k1_d1_1;
        din_k1_d1_0 = {$random, $random}; din_k1_d1_1 = {$random, $random};
        din_k1_d1_2 = K1_PT ^ din_k1_d1_0 ^ din_k1_d1_1;

        @(posedge clk);
        start_k1_d1 = 1; decrypt_k1_d1 = 0;
        @(posedge clk);
        wait(ready_k1_d1);
        @(posedge clk);
        if (dout_k1_d1 === K1_CT && tag_out_k1_d1 === K1_TAG)
            $display("[PASS] [D=1 ENC] CT = %h, Tag = %h", dout_k1_d1, tag_out_k1_d1);
        else begin
            $display("[FAIL] [D=1 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k1_d1, K1_CT, tag_out_k1_d1, K1_TAG);
            err_count = err_count + 1;
        end
        start_k1_d1 = 0;
        @(posedge clk);

        // --- D = 1 Decryption ---
        din_k1_d1_0 = {$random, $random}; din_k1_d1_1 = {$random, $random};
        din_k1_d1_2 = K1_CT ^ din_k1_d1_0 ^ din_k1_d1_1;
        tag_in_k1_d1 = K1_TAG;
        @(posedge clk);
        start_k1_d1 = 1; decrypt_k1_d1 = 1;
        @(posedge clk);
        wait(ready_k1_d1);
        @(posedge clk);
        if (dout_k1_d1 === K1_PT && tag_out_k1_d1 === K1_TAG && auth_valid_k1_d1 === 1'b1)
            $display("[PASS] [D=1 DEC] PT = %h, Tag = %h, Auth = %b", dout_k1_d1, tag_out_k1_d1, auth_valid_k1_d1);
        else begin
            $display("[FAIL] [D=1 DEC] PT = %h (exp %h), Auth = %b", dout_k1_d1, K1_PT, auth_valid_k1_d1);
            err_count = err_count + 1;
        end
        start_k1_d1 = 0;
        @(posedge clk);

        // --- D = 2 Encryption ---
        key_k1_d2_0 = {$random, $random, $random, $random};
        key_k1_d2_1 = {$random, $random, $random, $random};
        key_k1_d2_2 = {$random, $random, $random, $random};
        key_k1_d2_3 = K1_KEY ^ key_k1_d2_0 ^ key_k1_d2_1 ^ key_k1_d2_2;
        nonce_k1_d2_0 = {$random, $random, $random, $random};
        nonce_k1_d2_1 = {$random, $random, $random, $random};
        nonce_k1_d2_2 = {$random, $random, $random, $random};
        nonce_k1_d2_3 = K1_NONCE ^ nonce_k1_d2_0 ^ nonce_k1_d2_1 ^ nonce_k1_d2_2;
        ad_k1_d2_0 = {$random, $random}; ad_k1_d2_1 = {$random, $random};
        ad_k1_d2_2 = {$random, $random}; ad_k1_d2_3 = K1_AD ^ ad_k1_d2_0 ^ ad_k1_d2_1 ^ ad_k1_d2_2;
        din_k1_d2_0 = {$random, $random}; din_k1_d2_1 = {$random, $random};
        din_k1_d2_2 = {$random, $random}; din_k1_d2_3 = K1_PT ^ din_k1_d2_0 ^ din_k1_d2_1 ^ din_k1_d2_2;

        @(posedge clk);
        start_k1_d2 = 1; decrypt_k1_d2 = 0;
        @(posedge clk);
        wait(ready_k1_d2);
        @(posedge clk);
        if (dout_k1_d2 === K1_CT && tag_out_k1_d2 === K1_TAG)
            $display("[PASS] [D=2 ENC] CT = %h, Tag = %h", dout_k1_d2, tag_out_k1_d2);
        else begin
            $display("[FAIL] [D=2 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k1_d2, K1_CT, tag_out_k1_d2, K1_TAG);
            err_count = err_count + 1;
        end
        start_k1_d2 = 0;
        @(posedge clk);

        // --- D = 2 Decryption ---
        din_k1_d2_0 = {$random, $random}; din_k1_d2_1 = {$random, $random};
        din_k1_d2_2 = {$random, $random}; din_k1_d2_3 = K1_CT ^ din_k1_d2_0 ^ din_k1_d2_1 ^ din_k1_d2_2;
        tag_in_k1_d2 = K1_TAG;
        @(posedge clk);
        start_k1_d2 = 1; decrypt_k1_d2 = 1;
        @(posedge clk);
        wait(ready_k1_d2);
        @(posedge clk);
        if (dout_k1_d2 === K1_PT && tag_out_k1_d2 === K1_TAG && auth_valid_k1_d2 === 1'b1)
            $display("[PASS] [D=2 DEC] PT = %h, Tag = %h, Auth = %b", dout_k1_d2, tag_out_k1_d2, auth_valid_k1_d2);
        else begin
            $display("[FAIL] [D=2 DEC] PT = %h (exp %h), Auth = %b", dout_k1_d2, K1_PT, auth_valid_k1_d2);
            err_count = err_count + 1;
        end
        start_k1_d2 = 0;
        @(posedge clk);

        // ====================================================================
        // KAT VECTOR 2: PT = "encryption" (80 bits), AD = "ASCON" (40 bits)
        // ====================================================================
        $display("\n========================================================================");
        $display(">>> [KAT VECTOR 2] AD=\"ASCON\" (40-bit), PT=\"encryption\" (80-bit)");
        $display("    Key:   %h", K2_KEY);
        $display("    Nonce: %h", K2_NONCE);
        $display("    AD:    %h", K2_AD);
        $display("    PT:    %h", K2_PT);
        $display("    Exp CT: %h", K2_CT);
        $display("    Exp Tag:%h", K2_TAG);
        $display("========================================================================");

        // --- D = 0 Encryption ---
        din_k2_d0 = K2_PT;
        @(posedge clk);
        start_k2_d0 = 1; decrypt_k2_d0 = 0;
        @(posedge clk);
        wait(ready_k2_d0);
        @(posedge clk);
        if (dout_k2_d0 === K2_CT && tag_out_k2_d0 === K2_TAG)
            $display("[PASS] [D=0 ENC] CT = %h, Tag = %h", dout_k2_d0, tag_out_k2_d0);
        else begin
            $display("[FAIL] [D=0 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k2_d0, K2_CT, tag_out_k2_d0, K2_TAG);
            err_count = err_count + 1;
        end
        start_k2_d0 = 0;
        @(posedge clk);

        // --- D = 0 Decryption ---
        din_k2_d0 = K2_CT; tag_in_k2_d0 = K2_TAG;
        @(posedge clk);
        start_k2_d0 = 1; decrypt_k2_d0 = 1;
        @(posedge clk);
        wait(ready_k2_d0);
        @(posedge clk);
        if (dout_k2_d0 === K2_PT && tag_out_k2_d0 === K2_TAG && auth_valid_k2_d0 === 1'b1)
            $display("[PASS] [D=0 DEC] PT = %h, Tag = %h, Auth = %b", dout_k2_d0, tag_out_k2_d0, auth_valid_k2_d0);
        else begin
            $display("[FAIL] [D=0 DEC] PT = %h (exp %h), Auth = %b", dout_k2_d0, K2_PT, auth_valid_k2_d0);
            err_count = err_count + 1;
        end
        start_k2_d0 = 0;
        @(posedge clk);

        // --- D = 1 Encryption ---
        key_k2_d1_0 = {$random, $random, $random, $random};
        key_k2_d1_1 = {$random, $random, $random, $random};
        key_k2_d1_2 = K2_KEY ^ key_k2_d1_0 ^ key_k2_d1_1;
        nonce_k2_d1_0 = {$random, $random, $random, $random};
        nonce_k2_d1_1 = {$random, $random, $random, $random};
        nonce_k2_d1_2 = K2_NONCE ^ nonce_k2_d1_0 ^ nonce_k2_d1_1;
        ad_k2_d1_0 = {$random, $random}; ad_k2_d1_1 = {$random, $random};
        ad_k2_d1_2 = K2_AD ^ ad_k2_d1_0 ^ ad_k2_d1_1;
        din_k2_d1_0 = {$random, $random, $random}; din_k2_d1_1 = {$random, $random, $random};
        din_k2_d1_2 = K2_PT ^ din_k2_d1_0 ^ din_k2_d1_1;

        @(posedge clk);
        start_k2_d1 = 1; decrypt_k2_d1 = 0;
        @(posedge clk);
        wait(ready_k2_d1);
        @(posedge clk);
        if (dout_k2_d1 === K2_CT && tag_out_k2_d1 === K2_TAG)
            $display("[PASS] [D=1 ENC] CT = %h, Tag = %h", dout_k2_d1, tag_out_k2_d1);
        else begin
            $display("[FAIL] [D=1 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k2_d1, K2_CT, tag_out_k2_d1, K2_TAG);
            err_count = err_count + 1;
        end
        start_k2_d1 = 0;
        @(posedge clk);

        // --- D = 1 Decryption ---
        din_k2_d1_0 = {$random, $random, $random}; din_k2_d1_1 = {$random, $random, $random};
        din_k2_d1_2 = K2_CT ^ din_k2_d1_0 ^ din_k2_d1_1;
        tag_in_k2_d1 = K2_TAG;
        @(posedge clk);
        start_k2_d1 = 1; decrypt_k2_d1 = 1;
        @(posedge clk);
        wait(ready_k2_d1);
        @(posedge clk);
        if (dout_k2_d1 === K2_PT && tag_out_k2_d1 === K2_TAG && auth_valid_k2_d1 === 1'b1)
            $display("[PASS] [D=1 DEC] PT = %h, Tag = %h, Auth = %b", dout_k2_d1, tag_out_k2_d1, auth_valid_k2_d1);
        else begin
            $display("[FAIL] [D=1 DEC] PT = %h (exp %h), Auth = %b", dout_k2_d1, K2_PT, auth_valid_k2_d1);
            err_count = err_count + 1;
        end
        start_k2_d1 = 0;
        @(posedge clk);

        // --- D = 2 Encryption ---
        key_k2_d2_0 = {$random, $random, $random, $random};
        key_k2_d2_1 = {$random, $random, $random, $random};
        key_k2_d2_2 = {$random, $random, $random, $random};
        key_k2_d2_3 = K2_KEY ^ key_k2_d2_0 ^ key_k2_d2_1 ^ key_k2_d2_2;
        nonce_k2_d2_0 = {$random, $random, $random, $random};
        nonce_k2_d2_1 = {$random, $random, $random, $random};
        nonce_k2_d2_2 = {$random, $random, $random, $random};
        nonce_k2_d2_3 = K2_NONCE ^ nonce_k2_d2_0 ^ nonce_k2_d2_1 ^ nonce_k2_d2_2;
        ad_k2_d2_0 = {$random, $random}; ad_k2_d2_1 = {$random, $random};
        ad_k2_d2_2 = {$random, $random}; ad_k2_d2_3 = K2_AD ^ ad_k2_d2_0 ^ ad_k2_d2_1 ^ ad_k2_d2_2;
        din_k2_d2_0 = {$random, $random, $random}; din_k2_d2_1 = {$random, $random, $random};
        din_k2_d2_2 = {$random, $random, $random}; din_k2_d2_3 = K2_PT ^ din_k2_d2_0 ^ din_k2_d2_1 ^ din_k2_d2_2;

        @(posedge clk);
        start_k2_d2 = 1; decrypt_k2_d2 = 0;
        @(posedge clk);
        wait(ready_k2_d2);
        @(posedge clk);
        if (dout_k2_d2 === K2_CT && tag_out_k2_d2 === K2_TAG)
            $display("[PASS] [D=2 ENC] CT = %h, Tag = %h", dout_k2_d2, tag_out_k2_d2);
        else begin
            $display("[FAIL] [D=2 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k2_d2, K2_CT, tag_out_k2_d2, K2_TAG);
            err_count = err_count + 1;
        end
        start_k2_d2 = 0;
        @(posedge clk);

        // --- D = 2 Decryption ---
        din_k2_d2_0 = {$random, $random, $random}; din_k2_d2_1 = {$random, $random, $random};
        din_k2_d2_2 = {$random, $random, $random}; din_k2_d2_3 = K2_CT ^ din_k2_d2_0 ^ din_k2_d2_1 ^ din_k2_d2_2;
        tag_in_k2_d2 = K2_TAG;
        @(posedge clk);
        start_k2_d2 = 1; decrypt_k2_d2 = 1;
        @(posedge clk);
        wait(ready_k2_d2);
        @(posedge clk);
        if (dout_k2_d2 === K2_PT && tag_out_k2_d2 === K2_TAG && auth_valid_k2_d2 === 1'b1)
            $display("[PASS] [D=2 DEC] PT = %h, Tag = %h, Auth = %b", dout_k2_d2, tag_out_k2_d2, auth_valid_k2_d2);
        else begin
            $display("[FAIL] [D=2 DEC] PT = %h (exp %h), Auth = %b", dout_k2_d2, K2_PT, auth_valid_k2_d2);
            err_count = err_count + 1;
        end
        start_k2_d2 = 0;
        @(posedge clk);

        // ====================================================================
        // KAT VECTOR 3: PT = "Hello World!" (96 bits), AD = "ASCON" (40 bits)
        // ====================================================================
        $display("\n========================================================================");
        $display(">>> [KAT VECTOR 3] AD=\"ASCON\" (40-bit), PT=\"Hello World!\" (96-bit)");
        $display("    Key:   %h", K3_KEY);
        $display("    Nonce: %h", K3_NONCE);
        $display("    AD:    %h", K3_AD);
        $display("    PT:    %h", K3_PT);
        $display("    Exp CT: %h", K3_CT);
        $display("    Exp Tag:%h", K3_TAG);
        $display("========================================================================");

        // --- D = 0 Encryption ---
        din_k3_d0 = K3_PT;
        @(posedge clk);
        start_k3_d0 = 1; decrypt_k3_d0 = 0;
        @(posedge clk);
        wait(ready_k3_d0);
        @(posedge clk);
        if (dout_k3_d0 === K3_CT && tag_out_k3_d0 === K3_TAG)
            $display("[PASS] [D=0 ENC] CT = %h, Tag = %h", dout_k3_d0, tag_out_k3_d0);
        else begin
            $display("[FAIL] [D=0 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k3_d0, K3_CT, tag_out_k3_d0, K3_TAG);
            err_count = err_count + 1;
        end
        start_k3_d0 = 0;
        @(posedge clk);

        // --- D = 0 Decryption ---
        din_k3_d0 = K3_CT; tag_in_k3_d0 = K3_TAG;
        @(posedge clk);
        start_k3_d0 = 1; decrypt_k3_d0 = 1;
        @(posedge clk);
        wait(ready_k3_d0);
        @(posedge clk);
        if (dout_k3_d0 === K3_PT && tag_out_k3_d0 === K3_TAG && auth_valid_k3_d0 === 1'b1)
            $display("[PASS] [D=0 DEC] PT = %h, Tag = %h, Auth = %b", dout_k3_d0, tag_out_k3_d0, auth_valid_k3_d0);
        else begin
            $display("[FAIL] [D=0 DEC] PT = %h (exp %h), Auth = %b", dout_k3_d0, K3_PT, auth_valid_k3_d0);
            err_count = err_count + 1;
        end
        start_k3_d0 = 0;
        @(posedge clk);

        // --- D = 1 Encryption ---
        key_k3_d1_0 = {$random, $random, $random, $random};
        key_k3_d1_1 = {$random, $random, $random, $random};
        key_k3_d1_2 = K3_KEY ^ key_k3_d1_0 ^ key_k3_d1_1;
        nonce_k3_d1_0 = {$random, $random, $random, $random};
        nonce_k3_d1_1 = {$random, $random, $random, $random};
        nonce_k3_d1_2 = K3_NONCE ^ nonce_k3_d1_0 ^ nonce_k3_d1_1;
        ad_k3_d1_0 = {$random, $random}; ad_k3_d1_1 = {$random, $random};
        ad_k3_d1_2 = K3_AD ^ ad_k3_d1_0 ^ ad_k3_d1_1;
        din_k3_d1_0 = {$random, $random, $random}; din_k3_d1_1 = {$random, $random, $random};
        din_k3_d1_2 = K3_PT ^ din_k3_d1_0 ^ din_k3_d1_1;

        @(posedge clk);
        start_k3_d1 = 1; decrypt_k3_d1 = 0;
        @(posedge clk);
        wait(ready_k3_d1);
        @(posedge clk);
        if (dout_k3_d1 === K3_CT && tag_out_k3_d1 === K3_TAG)
            $display("[PASS] [D=1 ENC] CT = %h, Tag = %h", dout_k3_d1, tag_out_k3_d1);
        else begin
            $display("[FAIL] [D=1 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k3_d1, K3_CT, tag_out_k3_d1, K3_TAG);
            err_count = err_count + 1;
        end
        start_k3_d1 = 0;
        @(posedge clk);

        // --- D = 1 Decryption ---
        din_k3_d1_0 = {$random, $random, $random}; din_k3_d1_1 = {$random, $random, $random};
        din_k3_d1_2 = K3_CT ^ din_k3_d1_0 ^ din_k3_d1_1;
        tag_in_k3_d1 = K3_TAG;
        @(posedge clk);
        start_k3_d1 = 1; decrypt_k3_d1 = 1;
        @(posedge clk);
        wait(ready_k3_d1);
        @(posedge clk);
        if (dout_k3_d1 === K3_PT && tag_out_k3_d1 === K3_TAG && auth_valid_k3_d1 === 1'b1)
            $display("[PASS] [D=1 DEC] PT = %h, Tag = %h, Auth = %b", dout_k3_d1, tag_out_k3_d1, auth_valid_k3_d1);
        else begin
            $display("[FAIL] [D=1 DEC] PT = %h (exp %h), Auth = %b", dout_k3_d1, K3_PT, auth_valid_k3_d1);
            err_count = err_count + 1;
        end
        start_k3_d1 = 0;
        @(posedge clk);

        // --- D = 2 Encryption ---
        key_k3_d2_0 = {$random, $random, $random, $random};
        key_k3_d2_1 = {$random, $random, $random, $random};
        key_k3_d2_2 = {$random, $random, $random, $random};
        key_k3_d2_3 = K3_KEY ^ key_k3_d2_0 ^ key_k3_d2_1 ^ key_k3_d2_2;
        nonce_k3_d2_0 = {$random, $random, $random, $random};
        nonce_k3_d2_1 = {$random, $random, $random, $random};
        nonce_k3_d2_2 = {$random, $random, $random, $random};
        nonce_k3_d2_3 = K3_NONCE ^ nonce_k3_d2_0 ^ nonce_k3_d2_1 ^ nonce_k3_d2_2;
        ad_k3_d2_0 = {$random, $random}; ad_k3_d2_1 = {$random, $random};
        ad_k3_d2_2 = {$random, $random}; ad_k3_d2_3 = K3_AD ^ ad_k3_d2_0 ^ ad_k3_d2_1 ^ ad_k3_d2_2;
        din_k3_d2_0 = {$random, $random, $random}; din_k3_d2_1 = {$random, $random, $random};
        din_k3_d2_2 = {$random, $random, $random}; din_k3_d2_3 = K3_PT ^ din_k3_d2_0 ^ din_k3_d2_1 ^ din_k3_d2_2;

        @(posedge clk);
        start_k3_d2 = 1; decrypt_k3_d2 = 0;
        @(posedge clk);
        wait(ready_k3_d2);
        @(posedge clk);
        if (dout_k3_d2 === K3_CT && tag_out_k3_d2 === K3_TAG)
            $display("[PASS] [D=2 ENC] CT = %h, Tag = %h", dout_k3_d2, tag_out_k3_d2);
        else begin
            $display("[FAIL] [D=2 ENC] CT = %h (exp %h), Tag = %h (exp %h)", dout_k3_d2, K3_CT, tag_out_k3_d2, K3_TAG);
            err_count = err_count + 1;
        end
        start_k3_d2 = 0;
        @(posedge clk);

        // --- D = 2 Decryption ---
        din_k3_d2_0 = {$random, $random, $random}; din_k3_d2_1 = {$random, $random, $random};
        din_k3_d2_2 = {$random, $random, $random}; din_k3_d2_3 = K3_CT ^ din_k3_d2_0 ^ din_k3_d2_1 ^ din_k3_d2_2;
        tag_in_k3_d2 = K3_TAG;
        @(posedge clk);
        start_k3_d2 = 1; decrypt_k3_d2 = 1;
        @(posedge clk);
        wait(ready_k3_d2);
        @(posedge clk);
        if (dout_k3_d2 === K3_PT && tag_out_k3_d2 === K3_TAG && auth_valid_k3_d2 === 1'b1)
            $display("[PASS] [D=2 DEC] PT = %h, Tag = %h, Auth = %b", dout_k3_d2, tag_out_k3_d2, auth_valid_k3_d2);
        else begin
            $display("[FAIL] [D=2 DEC] PT = %h (exp %h), Auth = %b", dout_k3_d2, K3_PT, auth_valid_k3_d2);
            err_count = err_count + 1;
        end
        start_k3_d2 = 0;
        @(posedge clk);

        // ====================================================================
        // SUMMARY
        // ====================================================================
        $display("\n========================================================================");
        if (err_count == 0) begin
            $display("   >>> ALL KAT VECTOR TESTS PASSED FOR D = 0, D = 1, AND D = 2! <<<");
        end else begin
            $display("   >>> KAT TESTS FAILED with %0d errors! <<<", err_count);
        end
        $display("========================================================================\n");

        $finish;
    end

endmodule