// ============================================================================
// File: ascon_permutation_d1.v
// Description: Masked Ascon Permutation for Order D = 1 (3 shares)
//              Executes 'rounds' (12 or 6) iterations of (p_C -> p_S -> p_L)
//              over 3 shared 320-bit states.
// ============================================================================

`timescale 1ns / 1ps

module ascon_permutation_d1 (
    input  wire         clk,
    input  wire         reset,
    input  wire [4:0]   ctr,
    input  wire [319:0] S_0, S_1, S_2,
    input  wire [4:0]   rounds,
    input  wire         start,
    input  wire [63:0]  r0, r1, r2, r3, r4, r5, r6, // Fresh randomness

    output wire [319:0] out_0, out_1, out_2,
    output wire         done
);

    // State registers for 3 shares (5 x 64-bit words each)
    reg [63:0] x0_0_q, x1_0_q, x2_0_q, x3_0_q, x4_0_q;
    reg [63:0] x0_1_q, x1_1_q, x2_1_q, x3_1_q, x4_1_q;
    reg [63:0] x0_2_q, x1_2_q, x2_2_q, x3_2_q, x4_2_q;

    wire [63:0] x0_0_d, x1_0_d, x2_0_d, x3_0_d, x4_0_d;
    wire [63:0] x0_1_d, x1_1_d, x2_1_d, x3_1_d, x4_1_d;
    wire [63:0] x0_2_d, x1_2_d, x2_2_d, x3_2_d, x4_2_d;

    reg done_reg;

    always @(posedge clk) begin
        if (reset) begin
            {x0_0_q, x1_0_q, x2_0_q, x3_0_q, x4_0_q} <= 320'd0;
            {x0_1_q, x1_1_q, x2_1_q, x3_1_q, x4_1_q} <= 320'd0;
            {x0_2_q, x1_2_q, x2_2_q, x3_2_q, x4_2_q} <= 320'd0;
            done_reg <= 1'b0;
        end else begin
            if (start) begin
                if (ctr == 5'd0) begin
                    {x0_0_q, x1_0_q, x2_0_q, x3_0_q, x4_0_q} <= S_0;
                    {x0_1_q, x1_1_q, x2_1_q, x3_1_q, x4_1_q} <= S_1;
                    {x0_2_q, x1_2_q, x2_2_q, x3_2_q, x4_2_q} <= S_2;
                end else begin
                    {x0_0_q, x1_0_q, x2_0_q, x3_0_q, x4_0_q} <= {x0_0_d, x1_0_d, x2_0_d, x3_0_d, x4_0_d};
                    {x0_1_q, x1_1_q, x2_1_q, x3_1_q, x4_1_q} <= {x0_1_d, x1_1_d, x2_1_d, x3_1_d, x4_1_d};
                    {x0_2_q, x1_2_q, x2_2_q, x3_2_q, x4_2_q} <= {x0_2_d, x1_2_d, x2_2_d, x3_2_d, x4_2_d};
                end
            end

            if (ctr == rounds && start)
                done_reg <= 1'b1;
            else
                done_reg <= 1'b0;
        end
    end

    assign done = done_reg;

    assign out_0 = {x0_0_q, x1_0_q, x2_0_q, x3_0_q, x4_0_q};
    assign out_1 = {x0_1_q, x1_1_q, x2_1_q, x3_1_q, x4_1_q};
    assign out_2 = {x0_2_q, x1_2_q, x2_2_q, x3_2_q, x4_2_q};

    // 1. Constant Addition (p_C)
    wire [63:0] rc_out_0, rc_out_1, rc_out_2;
    wire [3:0]  current_round_idx = (ctr > 5'd0) ? (ctr[3:0] - 4'd1) : 4'd0;

    ascon_roundconstant_d1 u_rc_d1 (
        .x2_0_in(x2_0_q), .x2_1_in(x2_1_q), .x2_2_in(x2_2_q),
        .r0(r5), .r1(r6),
        .round_idx(current_round_idx),
        .total_rounds(rounds),
        .x2_0_out(rc_out_0), .x2_1_out(rc_out_1), .x2_2_out(rc_out_2)
    );

    // 2. Substitution Layer (p_S)
    wire [63:0] y0_0, y1_0, y2_0, y3_0, y4_0;
    wire [63:0] y0_1, y1_1, y2_1, y3_1, y4_1;
    wire [63:0] y0_2, y1_2, y2_2, y3_2, y4_2;

    ascon_sbox_d1 u_sbox_d1 (
        .x0_0(x0_0_q), .x1_0(x1_0_q), .x2_0(rc_out_0), .x3_0(x3_0_q), .x4_0(x4_0_q),
        .x0_1(x0_1_q), .x1_1(x1_1_q), .x2_1(rc_out_1), .x3_1(x3_1_q), .x4_1(x4_1_q),
        .x0_2(x0_2_q), .x1_2(x1_2_q), .x2_2(rc_out_2), .x3_2(x3_2_q), .x4_2(x4_2_q),

        .y0_0(y0_0), .y1_0(y1_0), .y2_0(y2_0), .y3_0(y3_0), .y4_0(y4_0),
        .y0_1(y0_1), .y1_1(y1_1), .y2_1(y2_1), .y3_1(y3_1), .y4_1(y4_1),
        .y0_2(y0_2), .y1_2(y1_2), .y2_2(y2_2), .y3_2(y3_2), .y4_2(y4_2)
    );

    // 3. Linear Diffusion Layer (p_L)
    ascon_linear_d1 u_lin_d1 (
        .in0_0(y0_0), .in1_0(y1_0), .in2_0(y2_0), .in3_0(y3_0), .in4_0(y4_0),
        .in0_1(y0_1), .in1_1(y1_1), .in2_1(y2_1), .in3_1(y3_1), .in4_1(y4_1),
        .in0_2(y0_2), .in1_2(y1_2), .in2_2(y2_2), .in3_2(y3_2), .in4_2(y4_2),

        .out0_0(x0_0_d), .out1_0(x1_0_d), .out2_0(x2_0_d), .out3_0(x3_0_d), .out4_0(x4_0_d),
        .out0_1(x0_1_d), .out1_1(x1_1_d), .out2_1(x2_1_d), .out3_1(x3_1_d), .out4_1(x4_1_d),
        .out0_2(x0_2_d), .out1_2(x1_2_d), .out2_2(x2_2_d), .out3_2(x3_2_d), .out4_2(x4_2_d)
    );

endmodule
