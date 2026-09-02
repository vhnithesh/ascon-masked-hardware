// ============================================================================
// File: ascon128_d2.v
// Description: Masked Ascon-128 AEAD Core for Order D = 2 (4 shares)
// ============================================================================

`timescale 1ns / 1ps

module ascon128_d2 #(
    parameter k = 128,
    parameter r = 64,
    parameter a = 12,
    parameter b = 6,
    parameter l = 40,
    parameter y = 40
)(
    input  wire         clk,
    input  wire         rst,

    // Control
    input  wire         start,
    input  wire         decrypt,
    output reg          ready,

    // 4 Shares of Key, Nonce, AD, Data In
    input  wire [k-1:0] key_0, key_1, key_2, key_3,
    input  wire [127:0] nonce_0, nonce_1, nonce_2, nonce_3,
    input  wire [l-1:0] ad_0, ad_1, ad_2, ad_3,
    input  wire [y-1:0] data_in_0, data_in_1, data_in_2, data_in_3,

    // Expected Tag for Decryption
    input  wire [127:0] tag_in,

    // Fresh random masks
    input  wire [63:0]  r0, r1, r2, r3, r4, r5, r6, r7,

    // Outputs
    output wire [y-1:0] data_out_0, data_out_1, data_out_2, data_out_3,
    output wire [y-1:0] data_out,
    output wire [127:0] tag_out_0, tag_out_1, tag_out_2, tag_out_3,
    output wire [127:0] tag_out,
    output reg          auth_valid
);

    localparam c     = 320 - r;
    localparam nz_ad = ((l+1)%r == 0) ? 0 : r - ((l+1)%r);
    localparam L     = (l == 0) ? r : (l + 1 + nz_ad);
    localparam s     = (l == 0) ? 0 : (L / r);

    localparam nz_pt = ((y+1)%r == 0) ? 0 : r - ((y+1)%r);
    localparam Y     = (y == 0) ? r : (y + 1 + nz_pt);
    localparam t     = (y == 0) ? 0 : (Y / r);
    localparam last_len = (y % r == 0) ? r : (y % r);

    // Ascon-128 IV: k=128 (0x80), r=64 (0x40), a=12 (0x0c), b=6 (0x06), 0s (0x00000000)
    localparam [63:0] IV = {8'h80, 8'h40, 8'h0c, 8'h06, 32'h00000000};

    // FSM States
    localparam S_IDLE       = 3'd0,
               S_INIT       = 3'd1,
               S_AD         = 3'd2,
               S_PTCT       = 3'd3,
               S_FINALIZE   = 3'd4,
               S_DONE       = 3'd5;

    reg [2:0] state;
    reg [7:0] block_ctr;
    reg [4:0] rounds;

    // 320-bit State registers
    reg  [319:0] S_0, S_1, S_2, S_3;
    wire [r-1:0] Sr_0 = S_0[319 : 320-r];
    wire [r-1:0] Sr_1 = S_1[319 : 320-r];
    wire [r-1:0] Sr_2 = S_2[319 : 320-r];
    wire [r-1:0] Sr_3 = S_3[319 : 320-r];
    wire [c-1:0] Sc_0 = S_0[c-1 : 0];
    wire [c-1:0] Sc_1 = S_1[c-1 : 0];
    wire [c-1:0] Sc_2 = S_2[c-1 : 0];
    wire [c-1:0] Sc_3 = S_3[c-1 : 0];

    // Permutation interface
    reg  [319:0] P_in_0, P_in_1, P_in_2, P_in_3;
    wire [319:0] P_out_0, P_out_1, P_out_2, P_out_3;
    wire         perm_done;
    reg          perm_start;
    wire [4:0]   perm_ctr;

    // Padded AD shares
    wire [L-1:0] A_0 = (l > 0) ? {ad_0, 1'b1, {nz_ad{1'b0}}} : {L{1'b0}};
    wire [L-1:0] A_1 = (l > 0) ? {ad_1, 1'b0, {nz_ad{1'b0}}} : {L{1'b0}};
    wire [L-1:0] A_2 = (l > 0) ? {ad_2, 1'b0, {nz_ad{1'b0}}} : {L{1'b0}};
    wire [L-1:0] A_3 = (l > 0) ? {ad_3, 1'b0, {nz_ad{1'b0}}} : {L{1'b0}};

    // Padded Data In shares
    wire [Y-1:0] D_0 = (y > 0) ? {data_in_0, 1'b1, {nz_pt{1'b0}}} : {Y{1'b0}};
    wire [Y-1:0] D_1 = (y > 0) ? {data_in_1, 1'b0, {nz_pt{1'b0}}} : {Y{1'b0}};
    wire [Y-1:0] D_2 = (y > 0) ? {data_in_2, 1'b0, {nz_pt{1'b0}}} : {Y{1'b0}};
    wire [Y-1:0] D_3 = (y > 0) ? {data_in_3, 1'b0, {nz_pt{1'b0}}} : {Y{1'b0}};

    // Output Registers
    reg [Y-1:0] out_buf_0, out_buf_1, out_buf_2, out_buf_3;
    reg [127:0] tag_reg_0, tag_reg_1, tag_reg_2, tag_reg_3;

    assign data_out_0 = out_buf_0[Y-1 -: y];
    assign data_out_1 = out_buf_1[Y-1 -: y];
    assign data_out_2 = out_buf_2[Y-1 -: y];
    assign data_out_3 = out_buf_3[Y-1 -: y];
    assign data_out   = data_out_0 ^ data_out_1 ^ data_out_2 ^ data_out_3;

    assign tag_out_0  = tag_reg_0;
    assign tag_out_1  = tag_reg_1;
    assign tag_out_2  = tag_reg_2;
    assign tag_out_3  = tag_reg_3;
    assign tag_out    = tag_reg_0 ^ tag_reg_1 ^ tag_reg_2 ^ tag_reg_3;

    // Permutation core
    ascon_permutation_d2 u_perm (
        .clk(clk),
        .reset(rst),
        .ctr(perm_ctr),
        .S_0(P_in_0), .S_1(P_in_1), .S_2(P_in_2), .S_3(P_in_3),
        .rounds(rounds),
        .start(perm_start),
        .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
        .out_0(P_out_0), .out_1(P_out_1), .out_2(P_out_2), .out_3(P_out_3),
        .done(perm_done)
    );

    // Round counter
    ascon_roundcounter u_rc (
        .clk(clk),
        .rst(rst),
        .permutation_start(perm_start),
        .permutation_ready(perm_done),
        .counter(perm_ctr)
    );

    // AEAD Controller FSM
    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            ready       <= 1'b0;
            auth_valid  <= 1'b0;
            block_ctr   <= 8'd0;
            rounds      <= a;
            perm_start  <= 1'b0;
            S_0         <= 320'd0;
            S_1         <= 320'd0;
            S_2         <= 320'd0;
            S_3         <= 320'd0;
            out_buf_0   <= {Y{1'b0}};
            out_buf_1   <= {Y{1'b0}};
            out_buf_2   <= {Y{1'b0}};
            out_buf_3   <= {Y{1'b0}};
            tag_reg_0   <= 128'd0;
            tag_reg_1   <= 128'd0;
            tag_reg_2   <= 128'd0;
            tag_reg_3   <= 128'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready      <= 1'b0;
                    auth_valid <= 1'b0;
                    block_ctr  <= 8'd0;
                    if (start) begin
                        // Initial shared state: S = {IV, K, N} (320 bits)
                        P_in_0     <= {IV, key_0, nonce_0};
                        P_in_1     <= {64'd0, key_1, nonce_1};
                        P_in_2     <= {64'd0, key_2, nonce_2};
                        P_in_3     <= {64'd0, key_3, nonce_3};
                        rounds     <= a;
                        perm_start <= 1'b1;
                        state      <= S_INIT;
                    end
                end

                S_INIT: begin
                    if (perm_done) begin
                        perm_start <= 1'b0;
                        if (l > 0) begin
                            S_0       <= {P_out_0[319:128], P_out_0[127:0] ^ key_0};
                            S_1       <= {P_out_1[319:128], P_out_1[127:0] ^ key_1};
                            S_2       <= {P_out_2[319:128], P_out_2[127:0] ^ key_2};
                            S_3       <= {P_out_3[319:128], P_out_3[127:0] ^ key_3};
                            block_ctr <= 8'd0;
                            state     <= S_AD;
                        end else begin
                            // Domain separation: S_0 = S_0 ^ 1
                            S_0       <= {P_out_0[319:128], P_out_0[127:0] ^ key_0} ^ {319'd0, 1'b1};
                            S_1       <= {P_out_1[319:128], P_out_1[127:0] ^ key_1};
                            S_2       <= {P_out_2[319:128], P_out_2[127:0] ^ key_2};
                            S_3       <= {P_out_3[319:128], P_out_3[127:0] ^ key_3};
                            if (y > 0) begin
                                block_ctr <= 8'd0;
                                state     <= S_PTCT;
                            end else begin
                                state     <= S_FINALIZE;
                            end
                        end
                    end
                end

                S_AD: begin
                    if (!perm_start && block_ctr < s) begin
                        P_in_0     <= {Sr_0 ^ A_0[L-1-(block_ctr*r) -: r], Sc_0};
                        P_in_1     <= {Sr_1 ^ A_1[L-1-(block_ctr*r) -: r], Sc_1};
                        P_in_2     <= {Sr_2 ^ A_2[L-1-(block_ctr*r) -: r], Sc_2};
                        P_in_3     <= {Sr_3 ^ A_3[L-1-(block_ctr*r) -: r], Sc_3};
                        rounds     <= b;
                        perm_start <= 1'b1;
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        if (block_ctr == s - 1) begin
                            // Domain separation after last AD block
                            S_0 <= P_out_0 ^ {319'd0, 1'b1};
                            S_1 <= P_out_1;
                            S_2 <= P_out_2;
                            S_3 <= P_out_3;
                            block_ctr <= 8'd0;
                            if (y > 0)
                                state <= S_PTCT;
                            else
                                state <= S_FINALIZE;
                        end else begin
                            S_0 <= P_out_0;
                            S_1 <= P_out_1;
                            S_2 <= P_out_2;
                            S_3 <= P_out_3;
                            block_ctr <= block_ctr + 8'd1;
                        end
                    end
                end

                S_PTCT: begin
                    if (!perm_start && block_ctr < t) begin
                        if (!decrypt) begin
                            // ENCRYPTION
                            out_buf_0[Y-1-(block_ctr*r) -: r] <= Sr_0 ^ D_0[Y-1-(block_ctr*r) -: r];
                            out_buf_1[Y-1-(block_ctr*r) -: r] <= Sr_1 ^ D_1[Y-1-(block_ctr*r) -: r];
                            out_buf_2[Y-1-(block_ctr*r) -: r] <= Sr_2 ^ D_2[Y-1-(block_ctr*r) -: r];
                            out_buf_3[Y-1-(block_ctr*r) -: r] <= Sr_3 ^ D_3[Y-1-(block_ctr*r) -: r];

                            if (block_ctr == t - 1) begin
                                S_0 <= {(Sr_0 ^ D_0[Y-1-(block_ctr*r) -: r]), Sc_0};
                                S_1 <= {(Sr_1 ^ D_1[Y-1-(block_ctr*r) -: r]), Sc_1};
                                S_2 <= {(Sr_2 ^ D_2[Y-1-(block_ctr*r) -: r]), Sc_2};
                                S_3 <= {(Sr_3 ^ D_3[Y-1-(block_ctr*r) -: r]), Sc_3};
                                state <= S_FINALIZE;
                            end else begin
                                P_in_0     <= {(Sr_0 ^ D_0[Y-1-(block_ctr*r) -: r]), Sc_0};
                                P_in_1     <= {(Sr_1 ^ D_1[Y-1-(block_ctr*r) -: r]), Sc_1};
                                P_in_2     <= {(Sr_2 ^ D_2[Y-1-(block_ctr*r) -: r]), Sc_2};
                                P_in_3     <= {(Sr_3 ^ D_3[Y-1-(block_ctr*r) -: r]), Sc_3};
                                rounds     <= b;
                                perm_start <= 1'b1;
                            end
                        end else begin
                            // DECRYPTION
                            out_buf_0[Y-1-(block_ctr*r) -: r] <= Sr_0 ^ D_0[Y-1-(block_ctr*r) -: r];
                            out_buf_1[Y-1-(block_ctr*r) -: r] <= Sr_1 ^ D_1[Y-1-(block_ctr*r) -: r];
                            out_buf_2[Y-1-(block_ctr*r) -: r] <= Sr_2 ^ D_2[Y-1-(block_ctr*r) -: r];
                            out_buf_3[Y-1-(block_ctr*r) -: r] <= Sr_3 ^ D_3[Y-1-(block_ctr*r) -: r];

                            if (block_ctr == t - 1) begin
                                // In decryption, update state rate word with (P_t || 10*)
                                S_0 <= {Sr_0 ^ {(Sr_0[r-1 -: last_len] ^ data_in_0[y-1-(block_ctr*r) -: last_len]), 1'b1, {(r-1-last_len){1'b0}}}, Sc_0};
                                S_1 <= {Sr_1 ^ {(Sr_1[r-1 -: last_len] ^ data_in_1[y-1-(block_ctr*r) -: last_len]), 1'b0, {(r-1-last_len){1'b0}}}, Sc_1};
                                S_2 <= {Sr_2 ^ {(Sr_2[r-1 -: last_len] ^ data_in_2[y-1-(block_ctr*r) -: last_len]), 1'b0, {(r-1-last_len){1'b0}}}, Sc_2};
                                S_3 <= {Sr_3 ^ {(Sr_3[r-1 -: last_len] ^ data_in_3[y-1-(block_ctr*r) -: last_len]), 1'b0, {(r-1-last_len){1'b0}}}, Sc_3};
                                state <= S_FINALIZE;
                            end else begin
                                P_in_0     <= {D_0[Y-1-(block_ctr*r) -: r], Sc_0};
                                P_in_1     <= {D_1[Y-1-(block_ctr*r) -: r], Sc_1};
                                P_in_2     <= {D_2[Y-1-(block_ctr*r) -: r], Sc_2};
                                P_in_3     <= {D_3[Y-1-(block_ctr*r) -: r], Sc_3};
                                rounds     <= b;
                                perm_start <= 1'b1;
                            end
                        end
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        S_0        <= P_out_0;
                        S_1        <= P_out_1;
                        S_2        <= P_out_2;
                        S_3        <= P_out_3;
                        block_ctr  <= block_ctr + 8'd1;
                    end
                end

                S_FINALIZE: begin
                    if (!perm_start) begin
                        // Key addition before finalization: S = S ^ (0^64 || K || 0^128)
                        P_in_0     <= S_0 ^ {64'd0, key_0, 128'd0};
                        P_in_1     <= S_1 ^ {64'd0, key_1, 128'd0};
                        P_in_2     <= S_2 ^ {64'd0, key_2, 128'd0};
                        P_in_3     <= S_3 ^ {64'd0, key_3, 128'd0};
                        rounds     <= a;
                        perm_start <= 1'b1;
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        // Tag = P_out[127:0] ^ K
                        tag_reg_0  <= P_out_0[127:0] ^ key_0;
                        tag_reg_1  <= P_out_1[127:0] ^ key_1;
                        tag_reg_2  <= P_out_2[127:0] ^ key_2;
                        tag_reg_3  <= P_out_3[127:0] ^ key_3;
                        state      <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                    if (decrypt) begin
                        auth_valid <= ((tag_reg_0 ^ tag_reg_1 ^ tag_reg_2 ^ tag_reg_3) == tag_in);
                    end else begin
                        auth_valid <= 1'b1;
                    end
                    if (!start)
                        state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
