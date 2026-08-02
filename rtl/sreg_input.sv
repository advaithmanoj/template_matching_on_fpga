`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 19:52:55
// Design Name: 
// Module Name: sreg_input
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
// sreg_input - 100-tap, 640-sample-spaced synchronous shift register
//   Matches the Quartus ALTSHIFT_TAPS megafunction interface.
//
//   Each enabled clock edge shifts in one image pixel.
//
//   'taps' exposes pixels spaced one 640-pixel row apart, matching the
//   original ALTSHIFT_TAPS tap_distance=640 line buffer.
//
//   Interface:
//     clken   - active-high clock enable (from !ena in top)
//     clock   - rising-edge clock
//     shiftin - 1-bit serial data in (idata from rom_input)
//     taps    - 100-bit parallel output (one vertical image column)
//
//   Synthesis:
//     Quartus infers this as SRL (shift-register logic) packed into
//     ALMs / LEs, or as block RAM when depth > device threshold.
//     Vivado can map this long shift chain to SRL resources.
// =============================================================

module sreg_input (
    input  wire        clken,
    input  wire        clock,
    input  wire [0:0]  shiftin,
    output wire [99:0] taps
);

   // reg [99:0] shreg = 100'd0; //a 100 bit reg
    
    
    // SHREG_EXTRACT off → force FFs instead of SRL16/SRL32
   // (* SHREG_EXTRACT = "no" *)
    localparam integer NTAPS        = 100;
    localparam integer TAP_DISTANCE = 640;

    reg [NTAPS*TAP_DISTANCE-1:0] shreg = {NTAPS*TAP_DISTANCE{1'b0}};

    // MAX_FANOUT tells Vivado to replicate this register to keep
    // fanout per driver ≤ 8 (tune this value to taste)
    //(* SHREG_EXTRACT = "no", MAX_FANOUT = 8 *)

    always @(posedge clock) begin
        if (clken)
            shreg <= { shreg[NTAPS*TAP_DISTANCE-2:0], shiftin[0] };
    end

    genvar i;
    generate
        for (i = 0; i < NTAPS; i = i + 1) begin : tap_gen
            assign taps[i] = shreg[((i + 1) * TAP_DISTANCE) - 1];
        end
    endgenerate

endmodule
