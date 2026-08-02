`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.06.2026 11:25:04
// Design Name: 
// Module Name: linebuffer
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


module linebuffer (clk, rst, ena, tarray, iarray, valid, xpos, ypos, mark);
    
    // Control line input
    input clk;
    input rst;
    input ena;
    
    // Output from ROM
    wire [0:0] idata;
    output [99:0] tarray; //from template every clk pulse(with clken) u get 100bits of template for 40 times
    
    // Output from Shift register
    output [99:0] iarray;
    
    // Status line output
    output reg valid = 1'd0;
    output reg [9:0] xpos = 10'd0;
    output reg [9:0] ypos = 10'd0;
    output reg mark = 1'd1;
    
    // Addressing input to ROM
    reg [5:0] taddr = 6'd0;
    
    // Reverse clken
    wire clken; 
    
    assign clken = ena;  //

    wire [18:0] col_base = ({1'b0, xpos, 8'b0}
                          + {2'b0, xpos, 7'b0}
                          + {3'b0, xpos, 6'b0}
                          + {4'b0, xpos, 5'b0});
    wire [18:0] iaddr = col_base + {9'b0, ypos};
    
    rom_input rom_input_inst(
        .address (iaddr), // i addr 0-->d307199 (640*480)
        .clken (clken), //
        .clock (clk),
        .q (idata)  // single bit wire goes into shift reg
    );
    
    rom_template rom_template_inst(
        .address (taddr), // starts from 0 to counts upto 40 then mark goes high (obv when !ena)
        .clken (clken), // inv ena when this high it should count
        .clock (clk),  //
        .q (tarray)  //o/p
    );
    
    sreg_input sreg_input_inst(
        .clken (clken),
        .clock (clk),
        .shiftin (idata), //single bit data coming from rom_input counts from 0 to 640*480
        .taps (iarray)
    );
    
    always @ (posedge clk ) begin
        if (!rst) begin
            valid <= 1'd0;
            xpos <= 10'd0;
            ypos <= 10'd0;
            taddr <= 6'd0;
            mark <= 1'd1;
        end
        else
        if (ena) begin
            // Template address pointer
            if (taddr == 6'd39) begin
                taddr <= 6'd0;
                mark <= 1'd1;
            end
            else begin
                taddr <= taddr + 6'd1;
                mark <= 1'd0;
            end
            
            // X and Y position locator
// Scan order: xpos counts columns (0..639), ypos counts rows (0..479).
             if (xpos == 10'd639) begin
                  xpos <= 10'd0;
                  if (ypos == 10'd479)
                      ypos <= 10'd0;
                  else
                      ypos <= ypos + 10'd1;
                  end else
                      xpos <= xpos + 10'd1;

// Template is 40 columns wide and 100 rows tall.
         valid <= !((xpos < 10'd40) | (ypos < 10'd100));


//    old code        if (xpos == 10'd639) begin 
//                xpos <= 10'd0;
//                if (ypos == 10'd479)
//                    ypos <= 10'd0;
//                else
//                    ypos <= ypos + 10'd1;
//            end
//            else
//                xpos <= xpos + 10'd1;
            
//            valid <= !((xpos < 10'd40) | (ypos < 10'd100));  //valid only when inisde
        end
    end

endmodule
