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
// =============================================================
// rom_input - Single-port synchronous ROM
//   Stores the binary input image: 640 × 480 = 307 200 pixels
//   Each pixel is 1 bit (binary thresholded image).
//
//   Interface matches the Quartus altsyncram ROM_1PORT style:
//     address - read address
//     clken   - clock enable (active-high; driven by !ena in top)
//     clock   - rising-edge clock
//     q       - registered 1-bit output (1-cycle latency)
//
//   Synthesis note:
//     307 200 is not a power-of-two.  Quartus can infer block RAM
//     for arbitrary depths, but if you get a warning you can either:
//       (a) pad the array to 2^19 = 524 288 (wastes ~27 % BRAM), or
//       (b) replace this file with a Quartus IP (altsyncram) core
//           configured for depth=307200, width=1, ROM mode.
//
//   Initialisation:
//     Place a 1-bit-per-line binary text file named "input_image.mif"
//     (or .bin / .hex - change $readmemb to $readmemh as needed) in
//     the project directory before simulation / synthesis.
// =============================================================

module rom_input (
    input  wire [18:0] address,   // log2(307200) ≈ 18.23 → 19 bits
    input  wire        clken,     // active-high clock enable
    input  wire        clock,
    output reg  [0:0]  q  //goes to shift reg
);

    // ---- Memory array ----
    // 307 200 entries × 1 bit  (≈ 37.5 kB)
    localparam DEPTH = 307200;
    reg [0:0] mem [0:DEPTH-1]; //mem[0],mem[1],......mem[307199]

    // ---- Initialise from file (simulation + synthesis) ----
    // $readmemb expects one binary digit per line (0 or 1).
    // Comment this out and use Quartus .mif flow for synthesis if preferred.
    initial begin
        $readmemb("input_image.bin", mem); //input_image.bin should be a row of binary nos from 0 to 307199
    end

    // ---- Synchronous read with clock enable ----
    always @(posedge clock) begin
        if (clken)
            q <= mem[address];
    end

endmodule
