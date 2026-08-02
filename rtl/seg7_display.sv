`timescale 1ns/1ps
// =============================================================
// seg7_display.sv  -  7-segment display driver  (Nexys A7-100T)
//
// Displays match position in DECIMAL on the 8-digit display.
//
// Layout (left → right):
//   an[7]        blank
//   an[6..4]     ypos (column, 0-639) in decimal  e.g. "040"
//   an[3]        blank separator
//   an[2..0]     xpos (row,    0-479) in decimal  e.g. "100"
//
// Before match_found = 1, all digits are blank.
//
// BCD conversion: double-dabble (shift-and-add-3), fully combinatorial.
// Refresh: 50 MHz / 50 000 = 1 kHz per digit → 125 Hz full scan.
//
// Segment mapping (seg[6:0], ACTIVE-LOW):
//   seg[0]=CA  seg[1]=CB  seg[2]=CC  seg[3]=CD
//   seg[4]=CE  seg[5]=CF  seg[6]=CG
// =============================================================
module seg7_display (
    input  wire        clk,         // 50 MHz system clock
    input  wire        rst,         // active-low synchronous reset
    input  wire [9:0]  xpos,        // match row    (0..479) from processor_array
    input  wire [9:0]  ypos,        // match column (0..639) from processor_array
    input  wire        match_found, // HIGH once a valid match has been latched
    output reg  [7:0]  an,          // digit anodes,    ACTIVE-LOW
    output reg  [6:0]  seg          // segment cathodes, ACTIVE-LOW
);

    // ------------------------------------------------------------------
    // Binary → BCD  (double-dabble, 10-bit input → 12-bit BCD)
    //   bcd[11:8] = hundreds   bcd[7:4] = tens   bcd[3:0] = units
    // Vivado unrolls the for-loop into ~10 levels of add-3+shift logic.
    // No DSP blocks used.
    // ------------------------------------------------------------------
    function automatic [11:0] bin_to_bcd;
        input [9:0] bin;
        integer i;
        reg [11:0] bcd;
        begin
            bcd = 12'd0;
            for (i = 9; i >= 0; i = i - 1) begin
                if (bcd[11:8] >= 4'd5) bcd[11:8] = bcd[11:8] + 4'd3;
                if (bcd[7:4]  >= 4'd5) bcd[7:4]  = bcd[7:4]  + 4'd3;
                if (bcd[3:0]  >= 4'd5) bcd[3:0]  = bcd[3:0]  + 4'd3;
                bcd = {bcd[10:0], bin[i]};
            end
            bin_to_bcd = bcd;
        end
    endfunction

    wire [11:0] xbcd = bin_to_bcd(xpos);   // [11:8]=H [7:4]=T [3:0]=U
    wire [11:0] ybcd = bin_to_bcd(ypos);

    // ------------------------------------------------------------------
    // Digit refresh counter
    // ------------------------------------------------------------------
    reg [15:0] div_cnt;
    reg [2:0]  sel;

    always @(posedge clk) begin
        if (!rst) begin
            div_cnt <= 16'd0;
            sel     <= 3'd0;
        end else if (div_cnt == 16'd49999) begin
            div_cnt <= 16'd0;
            sel     <= sel + 3'd1;
        end else begin
            div_cnt <= div_cnt + 16'd1;
        end
    end

    // ------------------------------------------------------------------
    // Digit data mux  (decimal BCD digits, 0-9)
    // ------------------------------------------------------------------
    reg [3:0] nibble;
    reg       show_blank;

    always @(*) begin
        nibble     = 4'd0;
        show_blank = 1'b0;
        case (sel)
            3'd7: show_blank = 1'b1;                                          // leftmost: blank
            3'd6: begin nibble = ybcd[11:8]; show_blank = !match_found; end   // ypos hundreds
            3'd5: begin nibble = ybcd[7:4];  show_blank = !match_found; end   // ypos tens
            3'd4: begin nibble = ybcd[3:0];  show_blank = !match_found; end   // ypos units
            3'd3: show_blank = 1'b1;                                          // separator: blank
            3'd2: begin nibble = xbcd[11:8]; show_blank = !match_found; end   // xpos hundreds
            3'd1: begin nibble = xbcd[7:4];  show_blank = !match_found; end   // xpos tens
            3'd0: begin nibble = xbcd[3:0];  show_blank = !match_found; end   // xpos units
            default: show_blank = 1'b1;
        endcase
    end

    // ------------------------------------------------------------------
    // Anode: one-cold (active-LOW)
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) an <= 8'hFF;
        else      an <= ~(8'b0000_0001 << sel);
    end

    // ------------------------------------------------------------------
    // Segment decoder  (digits 0-9 only, active-LOW)
    // seg[6:0] = { CG, CF, CE, CD, CC, CB, CA }
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst || show_blank) begin
            seg <= 7'b111_1111;
        end else begin
            case (nibble)
                4'd0: seg <= 7'b100_0000;
                4'd1: seg <= 7'b111_1001;
                4'd2: seg <= 7'b010_0100;
                4'd3: seg <= 7'b011_0000;
                4'd4: seg <= 7'b001_1001;
                4'd5: seg <= 7'b001_0010;
                4'd6: seg <= 7'b000_0010;
                4'd7: seg <= 7'b111_1000;
                4'd8: seg <= 7'b000_0000;
                4'd9: seg <= 7'b001_0000;
                default: seg <= 7'b111_1111;
            endcase
        end
    end

endmodule