`timescale 1ns/1ps

module seg7_display (
    input  wire        clk,         // 50 MHz system clock
    input  wire        rst,         // active-low synchronous reset
    input  wire [9:0]  xpos,        // match row    (0..479) from processor_array
    input  wire [9:0]  ypos,        // match column (0..639) from processor_array
    input  wire        match_found, // HIGH once a valid match has been latched
    output reg  [7:0]  an,          // digit anodes,    ACTIVE-LOW
    output reg  [6:0]  seg          // segment cathodes, ACTIVE-LOW
);

 
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


    always @(posedge clk) begin
        if (!rst) an <= 8'hFF;
        else      an <= ~(8'b0000_0001 << sel);
    end


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
