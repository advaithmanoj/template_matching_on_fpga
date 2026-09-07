`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 19:37:33
// Design Name: 
// Module Name: rom_input
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


`timescale 1ns / 1ps
// rom_input - Single-port synchronous ROM
//   Stores the binary input image: 640 × 480 = 307 200 pixels
//   Each pixel is 1 bit (binary thresholded image).
//
//   Initialisation:
//     Place a 1-bit-per-line binary text file named "input_image.mif"
//     (or .bin / .hex - change $readmemb to $readmemh as needed) in
//     the project directory before simulation / synthesis.

module rom_input (
    input  wire [18:0] address,   // log2(307200) ≈ 18.23 → 19 bits
    input  wire        clken,     // active-high clock enable
    input  wire        clock,
    output reg  [0:0]  q  //goes to shift reg
);

   
    localparam DEPTH = 307200;
    reg [0:0] mem [0:DEPTH-1];


    initial begin
        $readmemb("input_image.bin", mem); //input_image.bin should be a row of binary nos from 0 to 307199
    end

  
    always @(posedge clock) begin
        if (clken)
            q <= mem[address];
    end

endmodule
