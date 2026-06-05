`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/01 10:52:59
// Design Name: 
// Module Name: pregister
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


module GRE_array #(parameter WIDTH=200)(
    input Clk, rst, write_enable, flush,
    input [0:WIDTH-1] in,
    output reg [0:WIDTH-1] out
);
    always @(posedge Clk or posedge rst) begin
        if (rst)
            out <= 0;
        else if (write_enable) begin
            if (flush)
                out <= 0;
            else
                out <= in;
        end
    end
endmodule
