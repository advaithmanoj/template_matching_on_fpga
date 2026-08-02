`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.06.2026 11:20:59
// Design Name: 
// Module Name: processor
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

module processor(
    input  [99:0]  iarray,
    input  [99:0]  tarray,
    input          mark,
    input          clk,
    input          rst,
    input          ena,
    output reg [99:0] tout    = 100'd0,
    output reg        markout = 1'b0,
    output reg [11:0] sad     = 12'd0,
    output reg        sign    = 1'b0
);

    reg  [11:0] result = 12'd0;       // 12 bits: holds up to 4095

    wire [99:0] xcorr;
    wire [6:0]  adder;                // btadder max = 100, fits in 7 bits
    wire [11:0] final_result;

    assign xcorr        = iarray ^ tarray;
    assign final_result = result + {5'b0, adder};  // include THIS cycle

    treeadder treeadder_inst(
        .din  (xcorr),
        .dout (adder)
    );

    always @(posedge clk ) begin
        if (!rst) begin
            tout    <= 100'd0;
            markout <= 1'b0;
            sad     <= 12'd0;
            sign    <= 1'b0;
            result  <= 12'd0;
        end
        else if (ena) begin
            tout    <= tarray;
            markout <= mark;

            if (mark) begin
                sad    <= final_result;
                sign   <= (final_result < 12'd27);  // SAD < 500 → match
                result <= 12'd0;                     // reset for next window
            end
            else begin
                result <= final_result;  // accumulate
                sign   <= 1'b0;
            end
        end
    end
endmodule
