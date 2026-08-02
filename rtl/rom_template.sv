`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 19:14:55
// Design Name: 
// Module Name: rom_template
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

module rom_template(
    input wire        clock,
    input wire        clken,  // inv ena when this high it should count
    input wire [5:0]  address,  // starts from 0 to counts upto 40 then mark goes high (obv when !ena)
    output reg [99:0] q   //o/p
);

reg [99:0] rom [0:39];  //rom of 40 entires each entry has 100 bit
                       //rom[0] = template column 0 , rom[1] = template column 1

initial begin
    $readmemb("template.mem", rom); //
end

always @(posedge clock) begin
    if (clken)
        q <= rom[address]; //
end

endmodule
