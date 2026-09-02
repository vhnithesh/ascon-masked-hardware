// ============================================================================
// File: ascon_roundconstant.v
// Description: Round constant generation and masked injection for Ascon
//              Supports D = 1 (3 shares) and D = 2 (4 shares) with optional
//              fresh remasking randomness (r0, r1, r2).
// ============================================================================

`timescale 1ns / 1ps

// Function to compute Ascon 8-bit round constant
module ascon_rc_calc (
    input  wire [3:0] round_idx,   // 0 to 11
    input  wire [4:0] total_rounds,// 12, 8, or 6
    output reg  [7:0] rc
);
    always @(*) begin
        case (total_rounds)
            5'd12: rc = 8'hf0 - (round_idx * 8'h0f);
            5'd8:  rc = 8'hb4 - (round_idx * 8'h0f);
            5'd6:  rc = 8'h96 - (round_idx * 8'h0f);
            default: rc = 8'hf0 - (round_idx * 8'h0f);
        endcase
    end
endmodule

// Round constant injection for D = 1 (3 shares)
module ascon_roundconstant_d1 (
    input  wire [63:0] x2_0_in, x2_1_in, x2_2_in,
    input  wire [63:0] r0, r1,       // Fresh 64-bit random masks
    input  wire [3:0]  round_idx,
    input  wire [4:0]  total_rounds,
    output wire [63:0] x2_0_out, x2_1_out, x2_2_out
);

    wire [7:0] rc;
    ascon_rc_calc u_rc (.round_idx(round_idx), .total_rounds(total_rounds), .rc(rc));

    assign x2_0_out = x2_0_in ^ r0;
    assign x2_1_out = x2_1_in ^ r1;
    assign x2_2_out = x2_2_in ^ r0 ^ r1 ^ {56'd0, rc};

endmodule

// Round constant injection for D = 2 (4 shares)
module ascon_roundconstant_d2 (
    input  wire [63:0] x2_0_in, x2_1_in, x2_2_in, x2_3_in,
    input  wire [63:0] r0, r1, r2,   // Fresh 64-bit random masks
    input  wire [3:0]  round_idx,
    input  wire [4:0]  total_rounds,
    output wire [63:0] x2_0_out, x2_1_out, x2_2_out, x2_3_out
);

    wire [7:0] rc;
    ascon_rc_calc u_rc (.round_idx(round_idx), .total_rounds(total_rounds), .rc(rc));

    assign x2_0_out = x2_0_in ^ r0;
    assign x2_1_out = x2_1_in ^ r1;
    assign x2_2_out = x2_2_in ^ r2;
    assign x2_3_out = x2_3_in ^ r0 ^ r1 ^ r2 ^ {56'd0, rc};

endmodule
