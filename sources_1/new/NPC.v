`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/18 10:53:25
// Design Name: 
// Module Name: NPC
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
// NPC control signal
`define NPC_PLUS4   7'b0000000
`define NPC_BRANCH  7'b0000001
`define NPC_JUMP    7'b0000010
`define NPC_JALR    7'b0000100
`define NPC_SAME    7'b0001000
`define NPC_INT     7'b0010000
`define NPC_SRET    7'b0100000
`define NPC_SRETN   7'b1000000
module NPC(
    input  [31:0] PC,
    input  [6:0]  NPCOp,
    input  [31:0] IMM,
    input  [31:0] aluout,
    input  [31:0] EXPC,
    input  [31:0] INT_PC,
    input [31:0]SEPC,
    output reg [31:0] NPC
);
    wire [31:0] PCPLUS4 = PC + 4;
    always @(*) begin
        if (NPCOp[4])            // 中断 （该位只有在 IF_reg=1 时才可能为1）
            NPC = INT_PC;
        else if (NPCOp[5])       // sret
            NPC = SEPC;          // ← SEPC 从哪里来？
        else if (NPCOp[6])       // sretn
            NPC = SEPC + 4;
        else if (NPCOp[3])       // stall
            NPC = PC;
        else if (NPCOp[0])
            NPC = EXPC + IMM;
        else if (NPCOp[1])
            NPC = EXPC + IMM;
        else if (NPCOp[2])
            NPC = aluout;
        else
            NPC = PCPLUS4;
    end
endmodule
   /*
   always @(*) begin
      case (NPCOp)
          `NPC_PLUS4:  NPC = PCPLUS4;
          `NPC_BRANCH: NPC = EXPC+IMM;
          `NPC_JUMP:   NPC = EXPC+IMM;
		  `NPC_JALR:   NPC = aluout;
		  `NPC_SAME:   NPC = PC ;
		  `NPC_INT:
		               begin
		                 NPC = (IF)?INT_PC:PCPLUS4;	
		                 if(IF==1)
		                  IF = 0; //不允许中断嵌套
		                  SEPC = EXPC; //修改sepc的值
		               end
		  `NPC_SRET:   
		               begin
		                 NPC = SEPC;
		                 if(IF==0)
		                 IF = 1;
		               end
		  `NPC_SRETN:  
		              begin
		                 NPC = SEPC+4;
		                 if(IF==0)
		                 IF = 1;
		              end
          default:     NPC = PCPLUS4;
      endcase
   end // end always
   */

