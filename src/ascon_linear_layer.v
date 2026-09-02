// ============================================================================
// File: ascon_linear_layer.v
// Description: Linear diffusion layer for Ascon permutation
//              Includes 1-share, D=1 (3 shares), and D=2 (4 shares) modules.
//              Each share undergoes the linear transformation independently:
//                Sigma0(x0) = x0 ^ (x0 >>> 19) ^ (x0 >>> 28)
//                Sigma1(x1) = x1 ^ (x1 >>> 61) ^ (x1 >>> 39)
//                Sigma2(x2) = x2 ^ (x2 >>> 1)  ^ (x2 >>> 6)
//                Sigma3(x3) = x3 ^ (x3 >>> 10) ^ (x3 >>> 17)
//                Sigma4(x4) = x4 ^ (x4 >>> 7)  ^ (x4 >>> 41)
// ============================================================================

`timescale 1ns / 1ps

// Single-share linear diffusion
module ascon_linear_share (
    input  wire [63:0] in0, in1, in2, in3, in4,
    output wire [63:0] out0, out1, out2, out3, out4
);
    // Circular right shift (ror) functions
    assign out0 = in0 ^ {in0[18:0], in0[63:19]} ^ {in0[27:0], in0[63:28]};
    assign out1 = in1 ^ {in1[60:0], in1[63:61]} ^ {in1[38:0], in1[63:39]};
    assign out2 = in2 ^ {in2[0],    in2[63:1]}  ^ {in2[5:0],  in2[63:6]};
    assign out3 = in3 ^ {in3[9:0],  in3[63:10]} ^ {in3[16:0], in3[63:17]};
    assign out4 = in4 ^ {in4[6:0],  in4[63:7]}  ^ {in4[40:0], in4[63:41]};
endmodule

// D = 1 (3 shares) linear diffusion layer
module ascon_linear_d1 (
    // Inputs (3 shares)
    input  wire [63:0] in0_0, in1_0, in2_0, in3_0, in4_0,
    input  wire [63:0] in0_1, in1_1, in2_1, in3_1, in4_1,
    input  wire [63:0] in0_2, in1_2, in2_2, in3_2, in4_2,

    // Outputs (3 shares)
    output wire [63:0] out0_0, out1_0, out2_0, out3_0, out4_0,
    output wire [63:0] out0_1, out1_1, out2_1, out3_1, out4_1,
    output wire [63:0] out0_2, out1_2, out2_2, out3_2, out4_2
);

    ascon_linear_share lin_share0 (
        .in0(in0_0), .in1(in1_0), .in2(in2_0), .in3(in3_0), .in4(in4_0),
        .out0(out0_0), .out1(out1_0), .out2(out2_0), .out3(out3_0), .out4(out4_0)
    );

    ascon_linear_share lin_share1 (
        .in0(in0_1), .in1(in1_1), .in2(in2_1), .in3(in3_1), .in4(in4_1),
        .out0(out0_1), .out1(out1_1), .out2(out2_1), .out3(out3_1), .out4(out4_1)
    );

    ascon_linear_share lin_share2 (
        .in0(in0_2), .in1(in1_2), .in2(in2_2), .in3(in3_2), .in4(in4_2),
        .out0(out0_2), .out1(out1_2), .out2(out2_2), .out3(out3_2), .out4(out4_2)
    );

endmodule

// D = 2 (4 shares) linear diffusion layer
module ascon_linear_d2 (
    // Inputs (4 shares)
    input  wire [63:0] in0_0, in1_0, in2_0, in3_0, in4_0,
    input  wire [63:0] in0_1, in1_1, in2_1, in3_1, in4_1,
    input  wire [63:0] in0_2, in1_2, in2_2, in3_2, in4_2,
    input  wire [63:0] in0_3, in1_3, in2_3, in3_3, in4_3,

    // Outputs (4 shares)
    output wire [63:0] out0_0, out1_0, out2_0, out3_0, out4_0,
    output wire [63:0] out0_1, out1_1, out2_1, out3_1, out4_1,
    output wire [63:0] out0_2, out1_2, out2_2, out3_2, out4_2,
    output wire [63:0] out0_3, out1_3, out2_3, out3_3, out4_3
);

    ascon_linear_share lin_share0 (
        .in0(in0_0), .in1(in1_0), .in2(in2_0), .in3(in3_0), .in4(in4_0),
        .out0(out0_0), .out1(out1_0), .out2(out2_0), .out3(out3_0), .out4(out4_0)
    );

    ascon_linear_share lin_share1 (
        .in0(in0_1), .in1(in1_1), .in2(in2_1), .in3(in3_1), .in4(in4_1),
        .out0(out0_1), .out1(out1_1), .out2(out2_1), .out3(out3_1), .out4(out4_1)
    );

    ascon_linear_share lin_share2 (
        .in0(in0_2), .in1(in1_2), .in2(in2_2), .in3(in3_2), .in4(in4_2),
        .out0(out0_2), .out1(out1_2), .out2(out2_2), .out3(out3_2), .out4(out4_2)
    );

    ascon_linear_share lin_share3 (
        .in0(in0_3), .in1(in1_3), .in2(in2_3), .in3(in3_3), .in4(in4_3),
        .out0(out0_3), .out1(out1_3), .out2(out2_3), .out3(out3_3), .out4(out4_3)
    );

endmodule
