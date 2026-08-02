`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2026 17:21:25
// Design Name: 
// Module Name: top_module
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


module top_module(
input clk,
input rst,
input ena,
output wire  [3:0]  vga_red,
output wire  [3:0]  vga_green,
output wire  [3:0]  vga_blue,
output wire         vga_hsync,
output wire         vga_vsync,
output wire [7:0]  an,         // 7-seg anodes,   active-LOW
output wire [6:0]  seg,
output wire led0,   // mmcm_locked  H17
output wire led1   // match_found K15
);         // 7-seg segments, active-LOW
    
//    module processor_array(clk, rst, ena, xpos, ypos);

//    input clk;
//    input rst;
//    input ena;
    
//    output reg [9:0] xpos;
//    output reg [9:0] ypos;

wire [9:0] xpos2vga;
wire [9:0] ypos2vga;
wire match_found;

// ADD THESE TWO LINES:
wire mmcm_locked;
wire rst_sync = rst & mmcm_locked;   // 0 until button released AND clock locked

wire clk50,clk25;
// In top_module port list:
//output wire led0,   // mmcm_locked
//output wire led1,   // match_found

// Assignments:
assign led0 = mmcm_locked;
assign led1 = match_found;

clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(clk50),     // output clk_out1
    .clk_out2(clk25),     // output clk_out2
    // Status and control signals
    .reset(~rst), // input reset
   // Clock in ports
     .locked(mmcm_locked),
    .clk_in1(clk)      // input clk_in1
);

processor_array instance1 (.clk(clk50),.rst(rst_sync),.ena(ena),.xpos(xpos2vga),.ypos(ypos2vga),  .match_found (match_found) ); 


vga_display vga_inst (
    .clk25   (clk25),          // 25 MHz pixel clock
    .sys_clk (clk50),            // your system clock
    .rst     (rst_sync),
    .xpos    (xpos2vga),           // from processor_array
    .ypos    (ypos2vga), // from processor_array
    .match_found (match_found),           
    .red     (vga_red),
    .green   (vga_green),
    .blue    (vga_blue),
    .hsync   (vga_hsync),
    .vsync   (vga_vsync)
);
 seg7_display seg7_inst (
    .clk         (clk50),
    .rst         (rst_sync),
    .xpos        (xpos2vga),
    .ypos        (ypos2vga),
    .match_found (match_found),
    .an          (an),
    .seg         (seg)
);  
    
endmodule
