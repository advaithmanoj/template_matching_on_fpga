`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.06.2026 19:15:41
// Design Name: 
// Module Name: processor_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module processor_array(clk, rst, ena, xpos, ypos,match_found);

    input clk;
    input rst;
    input ena;
    
    output reg [9:0]  xpos;
    output reg [9:0]  ypos;
    output reg        match_found;   // HIGH after at least one SAD result is available

    wire [99:0] iarray;
    wire [4099:0] tarray;
    wire [40:0] mark;
    wire valid;
    wire [39:0] sign;
    wire [479:0] sad;
    wire [9:0] xcpos;
    wire [9:0] ycpos;
    
    reg [11:0] min_sad;
    integer j;
    
    linebuffer linebuffer_inst (
        .clk (clk),
        .rst (rst),
        .ena (ena),
        .tarray (tarray[0 +: 100]),
        .iarray (iarray),
        .valid (valid),
        .xpos (xcpos),
        .ypos (ycpos),
        .mark (mark[0])
    ); 
    
    genvar i;
    generate
        for (i = 0; i < 40; i = i + 1) begin: processor_array_inst
            processor inst (
                .iarray (iarray),
                .tarray (tarray[i*100 +: 100]),
                .mark (mark[i]),
                .clk (clk),
                .rst (rst),
                .ena (ena),
                .tout (tarray[(i+1)*100 +: 100]),
                .markout (mark[i+1]),
                .sad (sad[i*12 +: 12]),
                .sign (sign[i])
            );
        end
    endgenerate
    
    // Track the best (minimum) SAD seen so far.
    always @ (posedge clk) begin
        if (!rst) begin
            xpos        <= 10'd0;
            ypos        <= 10'd0;
            min_sad     <= 12'hFFF;
            match_found <= 1'b0;
        end
        else if (ena) begin
            for (j = 0; j < 40; j = j + 1) begin
                if (valid & mark[j+1] & (sad[j*12 +: 12] < min_sad)) begin
                    min_sad     <= sad[j*12 +: 12];
                    xpos        <= ycpos - 10'd100;
                    ypos        <= xcpos - 10'd40 - j[9:0];
                    match_found <= 1'b1;
                end
            end
        end
    end

endmodule
