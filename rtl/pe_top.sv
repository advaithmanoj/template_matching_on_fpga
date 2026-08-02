`timescale 1ns / 1ps
module pe_top #(parameter WIDTH = 100) (
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] src,
    input  logic [WIDTH-1:0] tpl_i,
    output  logic [WIDTH-1:0] tpl_o,
    input  logic             mark_i, //input mark
    output logic             mark_out, //ouput mark
    output logic [8:0]       sad_out, //sad calculation
    output logic             sign //sign out
);
    logic [WIDTH-1:0] xor_out;
    logic [7:0]       sum;
    logic [8:0]       accumulator;

    assign xor_out = src ^ tpl_i;

    btadder inst1 (.din(xor_out), .dout(sum));
   
    always@(posedge clk) begin
    mark_out <= mark_i;
    tpl_o <= tpl_i;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator <= 9'b0;
            sad_out     <= 9'b0;
            sign        <= 1'b0;
            mark_out    <= 1'b0;
        end else begin
            accumulator <= mark_i ? 9'b0 : (accumulator + {1'b0, sum}); //if mark acc is filled with zero else sum from adder is added
            sad_out     <= mark_i ? accumulator : sad_out;  //if mark
            sign        <= mark_i ? accumulator[8] : sign;
            mark_out    <= mark_i;
        end
    end
endmodule