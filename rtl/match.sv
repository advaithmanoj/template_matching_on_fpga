`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 23:49:42
// Design Name: 
// Module Name: match
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


module match(
input clk,
input rst,
input logic [39:0] sign,
input logic valid,
input logic [9:0]y_pos_i,
input logic [9:0]x_pos_i,
input x_increment,
input y_increment,
output logic [9:0]y_cor_o,
output logic [9:0]x_cor_o
 );
 
 wire comp_out;                // sign ==1 match
 assign comp_out = (sign == 40'd0); 
 
  wire update_en;
 assign update_en = valid & (~comp_out); 
 
  // Calculates the new potential coordinates
    wire [9:0] next_x;
    wire [9:0] next_y;
    assign next_x = x_pos_i + x_increment;
    assign next_y = y_pos_i + y_increment;
 
 always@(posedge clk)begin
 if (rst)begin
  x_cor_o <= 10'd0;
  y_cor_o <= 10'd0;
 end
 else begin
   if (update_en) begin
       x_cor_o <= x_cor_o;
       y_cor_o <= y_cor_o; end
       else
       begin
       x_cor_o <= next_x;
       y_cor_o <= next_y; end
 end
 
 end
 
endmodule
