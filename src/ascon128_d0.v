// ============================================================================
// File: ascon128_d0.v
// Description: Unmasked Ascon-128 AEAD Core for Order D = 0 (1 share)
// ============================================================================

`timescale 1ns / 1ps

module ascon128_d0 #(
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

    // Inputs (Single Unmasked Share)
    input  wire [k-1:0] key,
    input  wire [127:0] nonce,
    input  wire [l-1:0] ad,
    input  wire [y-1:0] data_in,

    // Expected Tag for Decryption
    input  wire [127:0] tag_in,

    // Outputs
    output wire [y-1:0] data_out,
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

    // Ascon-128 IV
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
    reg  [319:0] S;
    wire [r-1:0] Sr = S[319 : 320-r];
    wire [c-1:0] Sc = S[c-1 : 0];

    // Permutation interface
    reg  [319:0] P_in;
    wire [319:0] P_out;
    wire         perm_done;
    reg          perm_start;
    wire [4:0]   perm_ctr;

    // Padded AD & Data In
    wire [L-1:0] A = (l > 0) ? {ad, 1'b1, {nz_ad{1'b0}}} : {L{1'b0}};
    wire [Y-1:0] D = (y > 0) ? {data_in, 1'b1, {nz_pt{1'b0}}} : {Y{1'b0}};

    // Output Registers
    reg [Y-1:0] out_buf;
    reg [127:0] tag_reg;

    assign data_out = out_buf[Y-1 -: y];
    assign tag_out  = tag_reg;

    // Permutation core
    ascon_permutation_d0 u_perm (
        .clk(clk),
        .reset(rst),
        .ctr(perm_ctr),
        .S(P_in),
        .rounds(rounds),
        .start(perm_start),
        .out(P_out),
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
            S           <= 320'd0;
            out_buf     <= {Y{1'b0}};
            tag_reg     <= 128'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready      <= 1'b0;
                    auth_valid <= 1'b0;
                    block_ctr  <= 8'd0;
                    if (start) begin
                        P_in       <= {IV, key, nonce};
                        rounds     <= a;
                        perm_start <= 1'b1;
                        state      <= S_INIT;
                    end
                end

                S_INIT: begin
                    if (perm_done) begin
                        perm_start <= 1'b0;
                        if (l > 0) begin
                            S         <= {P_out[319:128], P_out[127:0] ^ key};
                            block_ctr <= 8'd0;
                            state     <= S_AD;
                        end else begin
                            S         <= {P_out[319:128], P_out[127:0] ^ key} ^ {319'd0, 1'b1};
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
                        P_in       <= {Sr ^ A[L-1-(block_ctr*r) -: r], Sc};
                        rounds     <= b;
                        perm_start <= 1'b1;
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        if (block_ctr == s - 1) begin
                            S         <= P_out ^ {319'd0, 1'b1};
                            block_ctr <= 8'd0;
                            if (y > 0)
                                state <= S_PTCT;
                            else
                                state <= S_FINALIZE;
                        end else begin
                            S         <= P_out;
                            block_ctr <= block_ctr + 8'd1;
                        end
                    end
                end

                S_PTCT: begin
                    if (!perm_start && block_ctr < t) begin
                        if (!decrypt) begin
                            // ENCRYPTION
                            out_buf[Y-1-(block_ctr*r) -: r] <= Sr ^ D[Y-1-(block_ctr*r) -: r];

                            if (block_ctr == t - 1) begin
                                S     <= {(Sr ^ D[Y-1-(block_ctr*r) -: r]), Sc};
                                state <= S_FINALIZE;
                            end else begin
                                P_in       <= {(Sr ^ D[Y-1-(block_ctr*r) -: r]), Sc};
                                rounds     <= b;
                                perm_start <= 1'b1;
                            end
                        end else begin
                            // DECRYPTION
                            out_buf[Y-1-(block_ctr*r) -: r] <= Sr ^ D[Y-1-(block_ctr*r) -: r];

                            if (block_ctr == t - 1) begin
                                S     <= {Sr ^ {(Sr[r-1 -: last_len] ^ data_in[y-1-(block_ctr*r) -: last_len]), 1'b1, {(r-1-last_len){1'b0}}}, Sc};
                                state <= S_FINALIZE;
                            end else begin
                                P_in       <= {D[Y-1-(block_ctr*r) -: r], Sc};
                                rounds     <= b;
                                perm_start <= 1'b1;
                            end
                        end
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        S          <= P_out;
                        block_ctr  <= block_ctr + 8'd1;
                    end
                end

                S_FINALIZE: begin
                    if (!perm_start) begin
                        P_in       <= S ^ {64'd0, key, 128'd0};
                        rounds     <= a;
                        perm_start <= 1'b1;
                    end else if (perm_done) begin
                        perm_start <= 1'b0;
                        tag_reg    <= P_out[127:0] ^ key;
                        state      <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                    if (decrypt) begin
                        auth_valid <= (tag_reg == tag_in);
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
