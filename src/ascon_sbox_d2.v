// ============================================================================
// File: ascon_sbox_d2.v
// Description: Masked Ascon S-box for Order D = 2 (4 shares)
//              Implements 2nd-order Threshold Implementation (TI) satisfying
//              Non-completeness and Uniformity properties.
// Reference: https://github.com/aneeshkandi14/ascon-hw-public
// ============================================================================

`timescale 1ns / 1ps

module ascon_sbox_d2 (
    // Share 0 inputs
    input  wire [63:0] x0_0, x1_0, x2_0, x3_0, x4_0,
    // Share 1 inputs
    input  wire [63:0] x0_1, x1_1, x2_1, x3_1, x4_1,
    // Share 2 inputs
    input  wire [63:0] x0_2, x1_2, x2_2, x3_2, x4_2,
    // Share 3 inputs
    input  wire [63:0] x0_3, x1_3, x2_3, x3_3, x4_3,

    // Share 0 outputs
    output wire [63:0] y0_0, y1_0, y2_0, y3_0, y4_0,
    // Share 1 outputs
    output wire [63:0] y0_1, y1_1, y2_1, y3_1, y4_1,
    // Share 2 outputs
    output wire [63:0] y0_2, y1_2, y2_2, y3_2, y4_2,
    // Share 3 outputs
    output wire [63:0] y0_3, y1_3, y2_3, y3_3, y4_3
);

    // Coordinate functions for Share 0
    assign y0_0 = x3_1 ^ (x2_0 & x1_1) ^ (x2_0 & x1_2) ^ (x2_1 & x1_0) ^ (x2_1 & x1_1) ^ 
                  (x2_2 & x1_0) ^ x2_2 ^ (x1_0 & x0_2) ^ (x1_1 & x0_0) ^ (x1_1 & x0_2) ^ 
                  (x1_2 & x0_2) ^ x0_0 ^ x0_1 ^ x0_2;

    assign y1_0 = (x3_0 & x2_0) ^ (x3_0 & x1_2) ^ (x3_1 & x2_0) ^ (x3_1 & x2_1) ^ 
                  (x3_1 & x2_2) ^ (x3_1 & x1_2) ^ (x3_2 & x1_1) ^ (x2_0 & x1_0) ^ 
                  (x2_0 & x1_1) ^ (x2_0 & x1_2) ^ (x2_1 & x1_0) ^ (x2_1 & x1_2) ^ 
                  x2_1 ^ (x2_2 & x1_0) ^ (x2_2 & x1_1) ^ (x2_2 & x1_2) ^ x1_2 ^ x0_0;

    assign y2_0 = (x4_0 & x3_1) ^ (x4_3 & x3_1) ^ (x4_3 & x3_3) ^ x4_3 ^ x1_3;

    assign y3_0 = (x4_0 & x0_3) ^ x4_0 ^ (x4_1 & x0_0) ^ (x4_1 & x0_3) ^ x4_1 ^ 
                  (x4_3 & x0_0) ^ (x3_0 & x0_1) ^ (x3_0 & x0_3) ^ x3_0 ^ 
                  (x3_1 & x0_1) ^ (x3_3 & x0_0) ^ (x3_3 & x0_1) ^ (x3_3 & x0_3) ^ x1_1;

    assign y4_0 = (x4_0 & x1_1) ^ (x4_0 & x1_3) ^ (x4_1 & x1_3) ^ x4_1 ^ (x4_3 & x1_0) ^ 
                  x4_3 ^ x3_3 ^ (x1_0 & x0_0) ^ (x1_0 & x0_1) ^ (x1_1 & x0_3) ^ (x1_3 & x0_3);

    // Coordinate functions for Share 1
    assign y0_1 = (x4_0 & x1_0) ^ (x4_0 & x1_2) ^ (x4_2 & x1_0) ^ (x4_2 & x1_3) ^ 
                  x3_0 ^ x3_2 ^ x2_0 ^ (x2_2 & x1_2) ^ (x2_3 & x1_0) ^ (x2_3 & x1_2) ^ 
                  x2_3 ^ (x1_0 & x0_0) ^ (x1_2 & x0_0) ^ (x1_2 & x0_3) ^ (x1_3 & x0_0) ^ 
                  (x1_3 & x0_2);

    assign y1_1 = x4_3 ^ (x3_1 & x2_3) ^ (x3_1 & x1_1) ^ x3_1 ^ (x3_2 & x2_1) ^ 
                  (x3_2 & x2_3) ^ (x3_2 & x1_2) ^ (x3_2 & x1_3) ^ (x3_3 & x2_2) ^ 
                  (x3_3 & x1_1) ^ (x2_2 & x1_3) ^ (x2_3 & x1_2) ^ x1_3 ^ x0_3;

    assign y2_1 = (x4_1 & x3_2) ^ (x4_1 & x3_3) ^ x4_1 ^ (x4_2 & x3_1) ^ 
                  (x4_2 & x3_3) ^ (x4_3 & x3_2) ^ x2_1 ^ x2_2 ^ x2_3;

    assign y3_1 = (x4_0 & x0_0) ^ x4_2 ^ (x3_0 & x0_0) ^ (x3_0 & x0_2) ^ 
                  (x3_2 & x0_2) ^ (x3_3 & x0_2) ^ x3_3 ^ x2_2 ^ x1_3 ^ x0_0 ^ x0_2 ^ x0_3;

    assign y4_1 = (x4_0 & x1_0) ^ (x4_1 & x1_0) ^ (x4_1 & x1_2) ^ (x4_2 & x1_1) ^ 
                  x4_2 ^ x3_0 ^ (x1_0 & x0_2) ^ (x1_1 & x0_0) ^ (x1_1 & x0_1) ^ 
                  (x1_1 & x0_2) ^ x1_1 ^ (x1_2 & x0_2);

    // Coordinate functions for Share 2
    assign y0_2 = (x4_1 & x1_1) ^ (x4_1 & x1_2) ^ (x4_2 & x1_1) ^ (x4_2 & x1_2) ^ 
                  (x4_3 & x1_2) ^ (x4_3 & x1_3) ^ x3_3 ^ (x2_1 & x1_2) ^ 
                  (x2_2 & x1_1) ^ (x2_2 & x1_3) ^ (x2_3 & x1_1) ^ (x1_1 & x0_3) ^ 
                  (x1_2 & x0_1) ^ x1_2 ^ (x1_3 & x0_1);

    assign y1_2 = x4_0 ^ x4_2 ^ (x3_0 & x2_2) ^ (x3_0 & x1_0) ^ (x3_2 & x2_0) ^ 
                  (x3_2 & x2_2) ^ (x3_2 & x1_0) ^ x3_2 ^ (x3_3 & x2_0) ^ 
                  (x3_3 & x2_3) ^ (x3_3 & x1_0) ^ (x3_3 & x1_2) ^ (x3_3 & x1_3) ^ 
                  (x2_0 & x1_3) ^ x2_0 ^ x2_2 ^ (x2_3 & x1_0) ^ x1_0 ^ x0_2;

    assign y2_2 = (x4_0 & x3_3) ^ x4_0 ^ (x4_2 & x3_0) ^ (x4_2 & x3_2) ^ 
                  (x4_3 & x3_0) ^ x2_0 ^ x1_2 ^ 64'hffffffffffffffff;

    assign y3_2 = (x4_0 & x0_1) ^ (x4_0 & x0_2) ^ (x4_1 & x0_2) ^ (x4_2 & x0_0) ^ 
                  (x4_2 & x0_1) ^ (x4_2 & x0_2) ^ (x3_1 & x0_0) ^ (x3_2 & x0_0) ^ 
                  (x3_2 & x0_1) ^ x3_2 ^ x2_0 ^ x1_0 ^ x1_2;

    assign y4_2 = (x4_1 & x1_1) ^ (x4_2 & x1_2) ^ (x4_2 & x1_3) ^ (x4_3 & x1_1) ^ 
                  (x4_3 & x1_2) ^ x3_1 ^ x3_2 ^ (x1_2 & x0_1) ^ x1_2 ^ 
                  (x1_3 & x0_1) ^ (x1_3 & x0_2) ^ x1_3;

    // Coordinate functions for Share 3
    assign y0_3 = (x4_0 & x1_1) ^ (x4_0 & x1_3) ^ (x4_1 & x1_0) ^ (x4_1 & x1_3) ^ 
                  (x4_3 & x1_0) ^ (x4_3 & x1_1) ^ (x2_0 & x1_0) ^ (x2_0 & x1_3) ^ 
                  (x2_1 & x1_3) ^ x2_1 ^ (x2_3 & x1_3) ^ (x1_0 & x0_1) ^ 
                  (x1_0 & x0_3) ^ x1_0 ^ (x1_1 & x0_1) ^ x1_1 ^ (x1_3 & x0_3) ^ 
                  x1_3 ^ x0_3;

    assign y1_3 = x4_1 ^ (x3_0 & x2_1) ^ (x3_0 & x2_3) ^ (x3_0 & x1_1) ^ 
                  (x3_0 & x1_3) ^ x3_0 ^ (x3_1 & x1_0) ^ (x3_1 & x1_3) ^ 
                  (x3_3 & x2_1) ^ x3_3 ^ (x2_1 & x1_1) ^ (x2_1 & x1_3) ^ 
                  (x2_3 & x1_1) ^ (x2_3 & x1_3) ^ x2_3 ^ x1_1 ^ x0_1;

    assign y2_3 = (x4_0 & x3_0) ^ (x4_0 & x3_2) ^ (x4_1 & x3_0) ^ (x4_1 & x3_1) ^ 
                  x4_2 ^ x1_0 ^ x1_1;

    assign y3_3 = (x4_1 & x0_1) ^ (x4_2 & x0_3) ^ (x4_3 & x0_1) ^ (x4_3 & x0_2) ^ 
                  (x4_3 & x0_3) ^ x4_3 ^ (x3_1 & x0_2) ^ (x3_1 & x0_3) ^ 
                  x3_1 ^ (x3_2 & x0_3) ^ x2_1 ^ x2_3 ^ x0_1;

    assign y4_3 = (x4_0 & x1_2) ^ x4_0 ^ (x4_2 & x1_0) ^ (x4_3 & x1_3) ^ 
                  (x1_0 & x0_3) ^ x1_0 ^ (x1_2 & x0_0) ^ (x1_2 & x0_3) ^ (x1_3 & x0_0);

endmodule
