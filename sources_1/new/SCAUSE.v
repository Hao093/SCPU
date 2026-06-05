`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/05 20:40:27
// Design Name: 
// Module Name: SCAUSE
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


module SCAUSE(
      input clk,
      input reset,
      input INT1,
      input INT2,
      input INT3,
      input getINT,
      input IF,
      output reg [31:0] cause
    );
    
        always @(posedge reset,posedge getINT) begin
         if (reset) begin
            cause <= 0;
         end else if (IF && getINT) begin   //响应中断
        if (INT1)       cause <= 32'h00000001;  //计时器
        else if (INT2)  cause <= 32'h00000002;  // 系统调用
        else if (INT3)  cause <= 32'h00000003;  // 异常指令
    end
end
     
  
endmodule
