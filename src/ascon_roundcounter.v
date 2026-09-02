// ============================================================================
// File: ascon_roundcounter.v
// Description: Round counter module for controlling Ascon permutation rounds
// ============================================================================

`timescale 1ns / 1ps

module ascon_roundcounter (
    input  wire       clk,
    input  wire       rst,
    input  wire       permutation_start,
    input  wire       permutation_ready,
    output wire [4:0] counter
);
    reg [4:0] ctr;

    always @(posedge clk) begin
        if (rst) begin
            ctr <= 5'd0;
        end else begin
            if (permutation_ready || ~permutation_start)
                ctr <= 5'd0;
            else if (permutation_start)
                ctr <= ctr + 5'd1;
        end
    end

    assign counter = ctr;

endmodule
