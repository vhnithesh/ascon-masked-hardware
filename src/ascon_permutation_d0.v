// ============================================================================
// File: ascon_permutation_d0.v
// Description: Unmasked Ascon-128 Permutation for Order D = 0 (1 share)
// ============================================================================

`timescale 1ns / 1ps

module ascon_permutation_d0 (
    input  wire         clk,
    input  wire         reset,
    input  wire [4:0]   ctr,
    input  wire [319:0] S,
    input  wire [4:0]   rounds,
    input  wire         start,
    output wire [319:0] out,
    output reg          done
);

    reg [319:0] S_reg;
    reg [4:0]   round_ctr;

    // Split state into 5 64-bit words
    wire [63:0] x0 = (round_ctr == 0) ? S[319:256] : S_reg[319:256];
    wire [63:0] x1 = (round_ctr == 0) ? S[255:192] : S_reg[255:192];
    wire [63:0] x2 = (round_ctr == 0) ? S[191:128] : S_reg[191:128];
    wire [63:0] x3 = (round_ctr == 0) ? S[127:64]  : S_reg[127:64];
    wire [63:0] x4 = (round_ctr == 0) ? S[63:0]    : S_reg[63:0];

    // 1. Constant Addition Layer (p_C)
    wire [7:0] rc;
    ascon_rc_calc u_rc_calc (
        .round_idx(ctr[3:0]),
        .total_rounds(rounds),
        .rc(rc)
    );

    wire [63:0] x2_rc = x2 ^ {56'd0, rc};

    // 2. Substitution Layer (p_S)
    wire [63:0] y0, y1, y2, y3, y4;
    ascon_sbox_d0 u_sbox (
        .x0(x0), .x1(x1), .x2(x2_rc), .x3(x3), .x4(x4),
        .y0(y0), .y1(y1), .y2(y2),    .y3(y3), .y4(y4)
    );

    // 3. Linear Diffusion Layer (p_L)
    wire [63:0] z0, z1, z2, z3, z4;
    ascon_linear_share u_linear (
        .in0(y0), .in1(y1), .in2(y2), .in3(y3), .in4(y4),
        .out0(z0), .out1(z1), .out2(z2), .out3(z3), .out4(z4)
    );

    wire [319:0] next_S = {z0, z1, z2, z3, z4};

    always @(posedge clk) begin
        if (reset) begin
            round_ctr <= 5'd0;
            done      <= 1'b0;
            S_reg     <= 320'd0;
        end else if (start) begin
            if (round_ctr < rounds) begin
                S_reg     <= next_S;
                round_ctr <= round_ctr + 5'd1;
                if (round_ctr == rounds - 1)
                    done  <= 1'b1;
                else
                    done  <= 1'b0;
            end else begin
                done      <= 1'b0;
                round_ctr <= 5'd0;
            end
        end else begin
            round_ctr <= 5'd0;
            done      <= 1'b0;
        end
    end

    assign out = S_reg;

endmodule
