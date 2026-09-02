// ============================================================================
// File: ascon_sbox_d0.v
// Description: Unmasked Ascon S-box for Order D = 0 (1 share)
// Standard: NIST SP 800-232 / Ascon v1.2 Specification
// ============================================================================

`timescale 1ns / 1ps

module ascon_sbox_d0 (
    input  wire [63:0] x0,
    input  wire [63:0] x1,
    input  wire [63:0] x2,
    input  wire [63:0] x3,
    input  wire [63:0] x4,

    output wire [63:0] y0,
    output wire [63:0] y1,
    output wire [63:0] y2,
    output wire [63:0] y3,
    output wire [63:0] y4
);

    assign y0 = (x4 & x1) ^ x3 ^ (x2 & x1) ^ x2 ^ (x1 & x0) ^ x1 ^ x0;
    assign y1 = x4 ^ (x3 & x2) ^ (x3 & x1) ^ x3 ^ x2 ^ x1 ^ x0 ^ (x2 & x1);
    assign y2 = (x4 & x3) ^ x4 ^ x2 ^ x1 ^ 64'hffffffffffffffff;
    assign y3 = (x4 & x0) ^ (x3 & x0) ^ x4 ^ x3 ^ x2 ^ x1 ^ x0;
    assign y4 = (x4 & x1) ^ x4 ^ x3 ^ (x1 & x0) ^ x1;

endmodule
