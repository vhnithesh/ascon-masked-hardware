`timescale 1ns / 1ps

module tb_verify_sboxes;

    reg [63:0] x0, x1, x2, x3, x4;
    wire [63:0] sl0_ref, sl1_ref, sl2_ref, sl3_ref, sl4_ref;

    // Unmasked reference S-box
    // sl0 = (x4 & x1) ^ x3 ^ (x2 & x1) ^ x2 ^ (x1 & x0) ^ x1 ^ x0;      
    // sl1 = x4 ^ (x3 & x2) ^ (x3 & x1) ^ x3 ^ x2 ^ x1 ^ x0 ^ (x2 & x1);
    // sl2 = (x4 & x3) ^ x4 ^ x2 ^ x1 ^ 64'hffffffffffffffff;               
    // sl3 = (x4 & x0) ^ (x3 & x0) ^ x4 ^ x3 ^ x2 ^ x1 ^ x0;                 
    // sl4 = (x4 & x1) ^ x4 ^ x3 ^ (x1 & x0) ^ x1;
    assign sl0_ref = (x4 & x1) ^ x3 ^ (x2 & x1) ^ x2 ^ (x1 & x0) ^ x1 ^ x0;      
    assign sl1_ref = x4 ^ (x3 & x2) ^ (x3 & x1) ^ x3 ^ x2 ^ x1 ^ x0 ^ (x2 & x1);
    assign sl2_ref = (x4 & x3) ^ x4 ^ x2 ^ x1 ^ 64'hffffffffffffffff;               
    assign sl3_ref = (x4 & x0) ^ (x3 & x0) ^ x4 ^ x3 ^ x2 ^ x1 ^ x0;                 
    assign sl4_ref = (x4 & x1) ^ x4 ^ x3 ^ (x1 & x0) ^ x1;

    // D=1 (3 shares)
    reg [63:0] x0_d1_0, x1_d1_0, x2_d1_0, x3_d1_0, x4_d1_0;
    reg [63:0] x0_d1_1, x1_d1_1, x2_d1_1, x3_d1_1, x4_d1_1;
    reg [63:0] x0_d1_2, x1_d1_2, x2_d1_2, x3_d1_2, x4_d1_2;

    wire [63:0] y0_d1_0, y1_d1_0, y2_d1_0, y3_d1_0, y4_d1_0;
    wire [63:0] y0_d1_1, y1_d1_1, y2_d1_1, y3_d1_1, y4_d1_1;
    wire [63:0] y0_d1_2, y1_d1_2, y2_d1_2, y3_d1_2, y4_d1_2;

    ascon_sbox_d1 u_sbox_d1 (
        .x0_0(x0_d1_0), .x1_0(x1_d1_0), .x2_0(x2_d1_0), .x3_0(x3_d1_0), .x4_0(x4_d1_0),
        .x0_1(x0_d1_1), .x1_1(x1_d1_1), .x2_1(x2_d1_1), .x3_1(x3_d1_1), .x4_1(x4_d1_1),
        .x0_2(x0_d1_2), .x1_2(x1_d1_2), .x2_2(x2_d1_2), .x3_2(x3_d1_2), .x4_2(x4_d1_2),
        .y0_0(y0_d1_0), .y1_0(y1_d1_0), .y2_0(y2_d1_0), .y3_0(y3_d1_0), .y4_0(y4_d1_0),
        .y0_1(y0_d1_1), .y1_1(y1_d1_1), .y2_1(y2_d1_1), .y3_1(y3_d1_1), .y4_1(y4_d1_1),
        .y0_2(y0_d1_2), .y1_2(y1_d1_2), .y2_2(y2_d1_2), .y3_2(y3_d1_2), .y4_2(y4_d1_2)
    );

    wire [63:0] y0_d1 = y0_d1_0 ^ y0_d1_1 ^ y0_d1_2;
    wire [63:0] y1_d1 = y1_d1_0 ^ y1_d1_1 ^ y1_d1_2;
    wire [63:0] y2_d1 = y2_d1_0 ^ y2_d1_1 ^ y2_d1_2;
    wire [63:0] y3_d1 = y3_d1_0 ^ y3_d1_1 ^ y3_d1_2;
    wire [63:0] y4_d1 = y4_d1_0 ^ y4_d1_1 ^ y4_d1_2;

    // D=2 (4 shares)
    reg [63:0] x0_d2_0, x1_d2_0, x2_d2_0, x3_d2_0, x4_d2_0;
    reg [63:0] x0_d2_1, x1_d2_1, x2_d2_1, x3_d2_1, x4_d2_1;
    reg [63:0] x0_d2_2, x1_d2_2, x2_d2_2, x3_d2_2, x4_d2_2;
    reg [63:0] x0_d2_3, x1_d2_3, x2_d2_3, x3_d2_3, x4_d2_3;

    wire [63:0] y0_d2_0, y1_d2_0, y2_d2_0, y3_d2_0, y4_d2_0;
    wire [63:0] y0_d2_1, y1_d2_1, y2_d2_1, y3_d2_1, y4_d2_1;
    wire [63:0] y0_d2_2, y1_d2_2, y2_d2_2, y3_d2_2, y4_d2_2;
    wire [63:0] y0_d2_3, y1_d2_3, y2_d2_3, y3_d2_3, y4_d2_3;

    ascon_sbox_d2 u_sbox_d2 (
        .x0_0(x0_d2_0), .x1_0(x1_d2_0), .x2_0(x2_d2_0), .x3_0(x3_d2_0), .x4_0(x4_d2_0),
        .x0_1(x0_d2_1), .x1_1(x1_d2_1), .x2_1(x2_d2_1), .x3_1(x3_d2_1), .x4_1(x4_d2_1),
        .x0_2(x0_d2_2), .x1_2(x1_d2_2), .x2_2(x2_d2_2), .x3_2(x3_d2_2), .x4_2(x4_d2_2),
        .x0_3(x0_d2_3), .x1_3(x1_d2_3), .x2_3(x2_d2_3), .x3_3(x3_d2_3), .x4_3(x4_d2_3),
        .y0_0(y0_d2_0), .y1_0(y1_d2_0), .y2_0(y2_d2_0), .y3_0(y3_d2_0), .y4_0(y4_d2_0),
        .y0_1(y0_d2_1), .y1_1(y1_d2_1), .y2_1(y2_d2_1), .y3_1(y3_d2_1), .y4_1(y4_d2_1),
        .y0_2(y0_d2_2), .y1_2(y1_d2_2), .y2_2(y2_d2_2), .y3_2(y3_d2_2), .y4_2(y4_d2_2),
        .y0_3(y0_d2_3), .y1_3(y1_d2_3), .y2_3(y2_d2_3), .y3_3(y3_d2_3), .y4_3(y4_d2_3)
    );

    wire [63:0] y0_d2 = y0_d2_0 ^ y0_d2_1 ^ y0_d2_2 ^ y0_d2_3;
    wire [63:0] y1_d2 = y1_d2_0 ^ y1_d2_1 ^ y1_d2_2 ^ y1_d2_3;
    wire [63:0] y2_d2 = y2_d2_0 ^ y2_d2_1 ^ y2_d2_2 ^ y2_d2_3;
    wire [63:0] y3_d2 = y3_d2_0 ^ y3_d2_1 ^ y3_d2_2 ^ y3_d2_3;
    wire [63:0] y4_d2 = y4_d2_0 ^ y4_d2_1 ^ y4_d2_2 ^ y4_d2_3;

    integer test_idx;
    integer errors_d1 = 0;
    integer errors_d2 = 0;

    initial begin
        #1;
        for (test_idx = 0; test_idx < 100; test_idx = test_idx + 1) begin
            x0 = {$random, $random};
            x1 = {$random, $random};
            x2 = {$random, $random};
            x3 = {$random, $random};
            x4 = {$random, $random};

            // D=1 shares
            x0_d1_0 = {$random, $random}; x0_d1_1 = {$random, $random}; x0_d1_2 = x0 ^ x0_d1_0 ^ x0_d1_1;
            x1_d1_0 = {$random, $random}; x1_d1_1 = {$random, $random}; x1_d1_2 = x1 ^ x1_d1_0 ^ x1_d1_1;
            x2_d1_0 = {$random, $random}; x2_d1_1 = {$random, $random}; x2_d1_2 = x2 ^ x2_d1_0 ^ x2_d1_1;
            x3_d1_0 = {$random, $random}; x3_d1_1 = {$random, $random}; x3_d1_2 = x3 ^ x3_d1_0 ^ x3_d1_1;
            x4_d1_0 = {$random, $random}; x4_d1_1 = {$random, $random}; x4_d1_2 = x4 ^ x4_d1_0 ^ x4_d1_1;

            // D=2 shares
            x0_d2_0 = {$random, $random}; x0_d2_1 = {$random, $random}; x0_d2_2 = {$random, $random}; x0_d2_3 = x0 ^ x0_d2_0 ^ x0_d2_1 ^ x0_d2_2;
            x1_d2_0 = {$random, $random}; x1_d2_1 = {$random, $random}; x1_d2_2 = {$random, $random}; x1_d2_3 = x1 ^ x1_d2_0 ^ x1_d2_1 ^ x1_d2_2;
            x2_d2_0 = {$random, $random}; x2_d2_1 = {$random, $random}; x2_d2_2 = {$random, $random}; x2_d2_3 = x2 ^ x2_d2_0 ^ x2_d2_1 ^ x2_d2_2;
            x3_d2_0 = {$random, $random}; x3_d2_1 = {$random, $random}; x3_d2_2 = {$random, $random}; x3_d2_3 = x3 ^ x3_d2_0 ^ x3_d2_1 ^ x3_d2_2;
            x4_d2_0 = {$random, $random}; x4_d2_1 = {$random, $random}; x4_d2_2 = {$random, $random}; x4_d2_3 = x4 ^ x4_d2_0 ^ x4_d2_1 ^ x4_d2_2;

            #1;
            if (y0_d1 !== sl0_ref || y1_d1 !== sl1_ref || y2_d1 !== sl2_ref || y3_d1 !== sl3_ref || y4_d1 !== sl4_ref) begin
                $display("ERROR D=1 at test %0d:", test_idx);
                if (y0_d1 !== sl0_ref) $display("  y0 mismatch: got %h, expected %h", y0_d1, sl0_ref);
                if (y1_d1 !== sl1_ref) $display("  y1 mismatch: got %h, expected %h", y1_d1, sl1_ref);
                if (y2_d1 !== sl2_ref) $display("  y2 mismatch: got %h, expected %h", y2_d1, sl2_ref);
                if (y3_d1 !== sl3_ref) $display("  y3 mismatch: got %h, expected %h", y3_d1, sl3_ref);
                if (y4_d1 !== sl4_ref) $display("  y4 mismatch: got %h, expected %h", y4_d1, sl4_ref);
                errors_d1 = errors_d1 + 1;
            end

            if (y0_d2 !== sl0_ref || y1_d2 !== sl1_ref || y2_d2 !== sl2_ref || y3_d2 !== sl3_ref || y4_d2 !== sl4_ref) begin
                $display("ERROR D=2 at test %0d:", test_idx);
                if (y0_d2 !== sl0_ref) $display("  y0 mismatch: got %h, expected %h", y0_d2, sl0_ref);
                if (y1_d2 !== sl1_ref) $display("  y1 mismatch: got %h, expected %h", y1_d2, sl1_ref);
                if (y2_d2 !== sl2_ref) $display("  y2 mismatch: got %h, expected %h", y2_d2, sl2_ref);
                if (y3_d2 !== sl3_ref) $display("  y3 mismatch: got %h, expected %h", y3_d2, sl3_ref);
                if (y4_d2 !== sl4_ref) $display("  y4 mismatch: got %h, expected %h", y4_d2, sl4_ref);
                errors_d2 = errors_d2 + 1;
            end
        end

        $display("Verification Done! D=1 errors: %0d, D=2 errors: %0d", errors_d1, errors_d2);
        $finish;
    end

endmodule
