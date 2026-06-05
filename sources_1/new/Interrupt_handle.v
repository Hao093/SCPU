`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/29 11:23:41
// Design Name: 
// Module Name: Interrupt_handle
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


module Interrupt_handle (
    input  clk,          // 用于同步的时钟（CPU 主时钟）
    input  reset,          // 同步复位
    input  INT1,         // 计数器溢出中断（电平信号）
    input  INT2,         // ecall 异常（单周期脉冲）
    input  INT3,         // 非法指令异常（单周期脉冲）
    input IF_reg,
    output getINT,       // 是否有待处理的中断/异常
    output [31:0] INT_PC,// 统一中断入口地址
    output clear,         // Trap 需要清除 EX/MEM 寄存器
    output trap_taken
);

   assign getINT = INT1 | INT2 | INT3;        // 简单组合逻辑
   assign clear = INT3;
   assign INT_PC = 32'h00001100;
   assign trap_taken = getINT && IF_reg;   // 统一的中断触发标志
    
    
endmodule