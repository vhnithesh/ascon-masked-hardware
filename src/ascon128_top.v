// ============================================================================
// File: ascon128_top.v
// Description: Top-level Masked/Unmasked Ascon-128 AEAD Wrapper
//              Selects between:
//                ORDER = 0 : Unmasked (1 share)
//                ORDER = 1 : 1st-Order Masked (3 shares)
//                ORDER = 2 : 2nd-Order Masked (4 shares)
// Standard: NIST SP 800-232 / Ascon v1.2
// ============================================================================

`timescale 1ns / 1ps

module ascon128_top #(
    parameter ORDER = 1,          // Masking order: 0 (1 share), 1 (3 shares), or 2 (4 shares)
    parameter k     = 128,        // Key size
    parameter r     = 64,         // Rate
    parameter a     = 12,         // Initialization / Finalization rounds
    parameter b     = 6,          // Intermediate rounds
    parameter l     = 40,         // Length of Associated Data (bits)
    parameter y     = 40          // Length of Plaintext / Ciphertext (bits)
)(
    input  wire         clk,
    input  wire         rst,

    // Control
    input  wire         start,
    input  wire         decrypt,
    output wire         ready,
    output wire         auth_valid,

    // Key Shares (up to 4 shares)
    input  wire [k-1:0] key_0,
    input  wire [k-1:0] key_1,
    input  wire [k-1:0] key_2,
    input  wire [k-1:0] key_3,

    // Nonce Shares (up to 4 shares)
    input  wire [127:0] nonce_0,
    input  wire [127:0] nonce_1,
    input  wire [127:0] nonce_2,
    input  wire [127:0] nonce_3,

    // Associated Data Shares (up to 4 shares)
    input  wire [l-1:0] ad_0,
    input  wire [l-1:0] ad_1,
    input  wire [l-1:0] ad_2,
    input  wire [l-1:0] ad_3,

    // Data In Shares (Plaintext / Ciphertext)
    input  wire [y-1:0] data_in_0,
    input  wire [y-1:0] data_in_1,
    input  wire [y-1:0] data_in_2,
    input  wire [y-1:0] data_in_3,

    // Expected Tag for Decryption
    input  wire [127:0] tag_in,

    // Fresh Randomness Masks
    input  wire [63:0]  r0, r1, r2, r3, r4, r5, r6, r7,

    // Outputs
    output wire [y-1:0] data_out_0,
    output wire [y-1:0] data_out_1,
    output wire [y-1:0] data_out_2,
    output wire [y-1:0] data_out_3,
    output wire [y-1:0] data_out,

    output wire [127:0] tag_out_0,
    output wire [127:0] tag_out_1,
    output wire [127:0] tag_out_2,
    output wire [127:0] tag_out_3,
    output wire [127:0] tag_out
);

    generate
        if (ORDER == 0) begin : gen_order_0
            assign data_out_0 = data_out;
            assign data_out_1 = {y{1'b0}};
            assign data_out_2 = {y{1'b0}};
            assign data_out_3 = {y{1'b0}};

            assign tag_out_0  = tag_out;
            assign tag_out_1  = 128'd0;
            assign tag_out_2  = 128'd0;
            assign tag_out_3  = 128'd0;

            ascon128_d0 #(
                .k(k), .r(r), .a(a), .b(b), .l(l), .y(y)
            ) u_ascon_d0 (
                .clk(clk),
                .rst(rst),
                .start(start),
                .decrypt(decrypt),
                .ready(ready),
                .key(key_0),
                .nonce(nonce_0),
                .ad(ad_0),
                .data_in(data_in_0),
                .tag_in(tag_in),
                .data_out(data_out),
                .tag_out(tag_out),
                .auth_valid(auth_valid)
            );
        end else if (ORDER == 1) begin : gen_order_1
            assign data_out_3 = {y{1'b0}};
            assign tag_out_3  = 128'd0;

            ascon128_d1 #(
                .k(k), .r(r), .a(a), .b(b), .l(l), .y(y)
            ) u_ascon_d1 (
                .clk(clk),
                .rst(rst),
                .start(start),
                .decrypt(decrypt),
                .ready(ready),
                .key_0(key_0), .key_1(key_1), .key_2(key_2),
                .nonce_0(nonce_0), .nonce_1(nonce_1), .nonce_2(nonce_2),
                .ad_0(ad_0), .ad_1(ad_1), .ad_2(ad_2),
                .data_in_0(data_in_0), .data_in_1(data_in_1), .data_in_2(data_in_2),
                .tag_in(tag_in),
                .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6),
                .data_out_0(data_out_0), .data_out_1(data_out_1), .data_out_2(data_out_2),
                .data_out(data_out),
                .tag_out_0(tag_out_0), .tag_out_1(tag_out_1), .tag_out_2(tag_out_2),
                .tag_out(tag_out),
                .auth_valid(auth_valid)
            );
        end else begin : gen_order_2
            ascon128_d2 #(
                .k(k), .r(r), .a(a), .b(b), .l(l), .y(y)
            ) u_ascon_d2 (
                .clk(clk),
                .rst(rst),
                .start(start),
                .decrypt(decrypt),
                .ready(ready),
                .key_0(key_0), .key_1(key_1), .key_2(key_2), .key_3(key_3),
                .nonce_0(nonce_0), .nonce_1(nonce_1), .nonce_2(nonce_2), .nonce_3(nonce_3),
                .ad_0(ad_0), .ad_1(ad_1), .ad_2(ad_2), .ad_3(ad_3),
                .data_in_0(data_in_0), .data_in_1(data_in_1), .data_in_2(data_in_2), .data_in_3(data_in_3),
                .tag_in(tag_in),
                .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
                .data_out_0(data_out_0), .data_out_1(data_out_1), .data_out_2(data_out_2), .data_out_3(data_out_3),
                .data_out(data_out),
                .tag_out_0(tag_out_0), .tag_out_1(tag_out_1), .tag_out_2(tag_out_2), .tag_out_3(tag_out_3),
                .tag_out(tag_out),
                .auth_valid(auth_valid)
            );
        end
    endgenerate

endmodule
