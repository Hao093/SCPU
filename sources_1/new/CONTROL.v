`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/18 10:45:29
// Design Name: 
// Module Name: CONTROL
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
// ALU control signal
`define ALU_NOP   3'b000 
`define ALU_ADD   3'b001
`define ALU_SUB   3'b010 
`define ALU_AND   3'b011
`define ALU_OR    3'b100

//EXT CTRL itype, stype, btype, utype, jtype
`define EXT_CTRL_ITYPE_SHAMT 6'b100000
`define EXT_CTRL_ITYPE	6'b010000
`define EXT_CTRL_STYPE	6'b001000
`define EXT_CTRL_BTYPE	6'b000100
`define EXT_CTRL_UTYPE	6'b000010
`define EXT_CTRL_JTYPE	6'b000001

`define GPRSel_RD 2'b00
`define GPRSel_RT 2'b01
`define GPRSel_31 2'b10

`define WDSel_FromALU 2'b00
`define WDSel_FromMEM 2'b01
`define WDSel_FromPC 2'b10

`define ALUOp_nop 5'b00000
`define ALUOp_lui 5'b00001
`define ALUOp_auipc 5'b00010
`define ALUOp_add 5'b00011
`define ALUOp_sub 5'b00100
`define ALUOp_bne 5'b00101
`define ALUOp_blt 5'b00110
`define ALUOp_bge 5'b00111
`define ALUOp_bltu 5'b01000
`define ALUOp_bgeu 5'b01001
`define ALUOp_slt 5'b01010
`define ALUOp_sltu 5'b01011
`define ALUOp_xor 5'b01100
`define ALUOp_or 5'b01101
`define ALUOp_and 5'b01110
`define ALUOp_sll 5'b01111
`define ALUOp_srl 5'b10000
`define ALUOp_sra 5'b10001

`define dm_word 3'b000
`define dm_halfword 3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte 3'b011
`define dm_byte_unsigned 3'b100


module ctrl(Op, Funct7, Funct3,
            RegWrite, MemWrite,
            EXTOp, ALUOp, 
            ALUSrc, GPRSel, WDSel,DMType,
            SBtype,I_jal,I_jalr,I_load,Stype,I_ecall,Trap,I_sret,I_sretn
            );
            
            
        
   input  [6:0] Op;       // opcode
   input  [6:0] Funct7;    // funct7
   input  [2:0] Funct3;    // funct3
          // 分支条件判断
   output       RegWrite; // control signal for register write
   output       MemWrite; // control signal for memory write
   output [5:0] EXTOp;    // control signal to signed extension
   output [4:0] ALUOp;    // ALU opertion
   output       ALUSrc;   // ALU source for b
	output [2:0] DMType;
   output [1:0] GPRSel;   // general purpose register selection
   output [1:0] WDSel;    // (register) write data selection
   output SBtype;
   output I_jal;
   output I_jalr;
   output I_load;
   output Stype;
   output I_ecall;
   output Trap;
   output I_sret;
   output I_sretn;
  // r format
    wire rtype  = ~Op[6]&Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0110011
    wire i_add  = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // add 0000000 000
    wire i_sub  = rtype& ~Funct7[6]& Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // sub 0100000 000
    wire i_or   = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]& Funct3[2]& Funct3[1]&~Funct3[0]; // or 0000000 110
    wire i_and  = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]& Funct3[2]& Funct3[1]& Funct3[0]; // and 0000000 111
    wire i_xor=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&~Funct3[1]&~Funct3[0];//0000000 100
    wire i_sll = rtype & ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]
             & ~Funct3[2] & ~Funct3[1] & Funct3[0]; // sll: funct7=0000000, funct3=001

    wire i_srl = rtype & ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]
             & Funct3[2] & ~Funct3[1] & Funct3[0]; // srl: funct7=0000000, funct3=101

    wire i_sra = rtype & ~Funct7[6] & Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]
             & Funct3[2] & ~Funct3[1] & Funct3[0]; // sra: funct7=0100000, funct3=101
    wire i_slt =   rtype &  ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]  & ~Funct3[2] & Funct3[1] & ~Funct3[0];  
    wire i_sltu =   rtype &  ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]  & ~Funct3[2] & Funct3[1] & Funct3[0];     
    
    
 // i format
    wire itype_l  = ~Op[6]&~Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0000011
    wire i_lb=itype_l&~Funct3[2]& ~Funct3[1]& ~Funct3[0]; //lb 000
    wire i_lh=itype_l&~Funct3[2]& ~Funct3[1]& Funct3[0];  //lh 001
    wire i_lw=itype_l&~Funct3[2]& Funct3[1]& ~Funct3[0];  //lw 010
    wire i_lbu=itype_l&Funct3[2]&~Funct3[1]& ~Funct3[0];  //lbu 100
    wire i_lhu=itype_l&Funct3[2]&~Funct3[1]& Funct3[0];  //lhu 101
    
// i format
    wire itype_r  = ~Op[6]&~Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0010011
    wire i_addi  =  itype_r& ~Funct3[2]& ~Funct3[1]& ~Funct3[0]; // addi 000
    wire i_andi = itype_r & Funct3[2] & Funct3[1] & Funct3[0]; // andi: funct3=111
    wire i_ori  =  itype_r& Funct3[2]& Funct3[1]&~Funct3[0]; // ori 110
	wire i_xori = itype_r & Funct3[2] & ~Funct3[1] & ~Funct3[0]; // xori: funct3=100
  // 在I-type指令部分添加：
    wire i_slli = itype_r & ~Funct3[2] & ~Funct3[1] & Funct3[0] 
              & ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0]; 
              // slli: funct3=001, funct7=0000000

    wire i_srli = itype_r & Funct3[2] & ~Funct3[1] & Funct3[0]
              & ~Funct7[6] & ~Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0];
              // srli: funct3=101, funct7=0000000

    wire i_srai = itype_r & Funct3[2] & ~Funct3[1] & Funct3[0]
              & ~Funct7[6] & Funct7[5] & ~Funct7[4] & ~Funct7[3] & ~Funct7[2] & ~Funct7[1] & ~Funct7[0];
              // srai: funct3=101, funct7=0100000
   wire i_slti = itype_r&  ~Funct3[2] & Funct3[1] & ~Funct3[0];
   wire i_sltiu = itype_r&  ~Funct3[2] & Funct3[1] & Funct3[0];         
              
 //jalr
	wire i_jalr =Op[6]&Op[5]&~Op[4]&~Op[3]&Op[2]&Op[1]&Op[0]& ~Funct3[2] & ~Funct3[1] & ~Funct3[0]; // funct3=000 jalr 1100111

  // s format
   wire stype  = ~Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//0100011
   wire i_sw   =  stype& ~Funct3[2]& Funct3[1]&~Funct3[0]; // sw 010
   wire i_sb    = stype& ~Funct3[2]& ~Funct3[1]&~Funct3[0];
   wire i_sh    = stype& ~Funct3[2]&~Funct3[1]&Funct3[0];
   
  // sb format
   wire sbtype  = Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//1100011
   wire i_beq  = sbtype& ~Funct3[2]& ~Funct3[1]&~Funct3[0]; // beq
   wire i_blt=   sbtype& Funct3[2]& ~Funct3[1]&~Funct3[0];
   wire i_bge=   sbtype& Funct3[2]&~Funct3[1]&Funct3[0];
   wire i_bne= sbtype& ~Funct3[2]&~Funct3[1]&Funct3[0]; //001
   wire i_bltu= sbtype& Funct3[2]&Funct3[1]&~Funct3[0]; //110
   wire i_bgeu= sbtype& Funct3[2]&Funct3[1]&Funct3[0]; //111
   
   
   wire utype_lui  = ~Op[6] & Op[5] & Op[4] & ~Op[3] & Op[2] & Op[1] & Op[0];   // 0110111
   wire utype_auipc= ~Op[6] & ~Op[5] & Op[4] & ~Op[3] & Op[2] & Op[1] & Op[0];  // 0010111
   wire i_lui = utype_lui;
   wire i_auipc = utype_auipc;
  //u型指令的指令码不一样

 // j format
   wire i_jal  = Op[6]& Op[5]&~Op[4]& Op[3]& Op[2]& Op[1]& Op[0];  // jal 1101111

 //中断实现指令,定义op=1110011,funct3=000-010
   wire i_ecall = Op[6]& Op[5]&Op[4]& ~Op[3]& ~Op[2]& Op[1]& Op[0] & ~Funct3[2]& ~Funct3[1]&~Funct3[0];
   wire i_sret = Op[6]& Op[5]&Op[4]& ~Op[3]& ~Op[2]& Op[1]& Op[0] & ~Funct3[2]& ~Funct3[1]&Funct3[0];//返回原指令PC
   wire i_sretn =  Op[6]& Op[5]&Op[4]& ~Op[3]& ~Op[2]& Op[1]& Op[0] & ~Funct3[2]& Funct3[1]&~Funct3[0];//返回原指令PC+4
 //三条指令不需要修改寄存器或者是读写内存，更多是对PC有改动，所以这里先识别，在EX阶段处理


//操作指令生成控制信号（写、MUX选择）
  assign RegWrite   = rtype | itype_r | itype_l | i_lui | i_auipc|i_jal|i_jalr;   // register write
  assign MemWrite   = stype;              // memory write
  assign ALUSrc     = itype_r | stype | itype_l |i_lui | i_auipc|i_jalr; // ALU B is from instruction immediate
  
  //上面应该都和自己写的一样
  
  // signed extension
  // EXT_CTRL_ITYPE_SHAMT 6'b100000
  // EXT_CTRL_ITYPE	      6'b010000
  // EXT_CTRL_STYPE	      6'b001000
  // EXT_CTRL_BTYPE	      6'b000100
  // EXT_CTRL_UTYPE	      6'b000010
  // EXT_CTRL_JTYPE	      6'b000001
  assign EXTOp[5] =     i_srli |i_slli|i_srai;
  //assign EXTOp[4]    =  i_ori | i_andi | i_jalr;
  assign EXTOp[4] = itype_l | (itype_r & ~(i_slli|i_srli|i_srai)) | i_jalr;  //（包含了srli等)
  assign EXTOp[3]    = stype; 
  assign EXTOp[2]    = sbtype; 
  assign EXTOp[1]    = i_lui | i_auipc;   
  assign EXTOp[0]    = i_jal;         


  
  
  // WDSel_FromALU 2'b00
  // WDSel_FromMEM 2'b01
  // WDSel_FromPC  2'b10 
  assign WDSel[0] = itype_l;
  assign WDSel[1] = i_jal | i_jalr;

 

  
//ALU操作好像没有问题，改一下这里信号差不多了
/*
`define ALUOp_nop 5'b00000
`define ALUOp_lui 5'b00001
`define ALUOp_auipc 5'b00010
`define ALUOp_add 5'b00011
`define ALUOp_sub 5'b00100
`define ALUOp_bne 5'b00101
`define ALUOp_blt 5'b00110
`define ALUOp_bge 5'b00111
`define ALUOp_bltu 5'b01000
`define ALUOp_bgeu 5'b01001
`define ALUOp_slt 5'b01010
`define ALUOp_sltu 5'b01011
`define ALUOp_xor 5'b01100
`define ALUOp_or 5'b01101
`define ALUOp_and 5'b01110
`define ALUOp_sll 5'b01111
`define ALUOp_srl 5'b10000
`define ALUOp_sra 5'b10001
*/
reg [4:0] ALUOp_reg;
always @(*) begin
    casez (1'b1)
        // 算术运算
        i_add | i_addi:          ALUOp_reg = `ALUOp_add;
        i_sub:                   ALUOp_reg = `ALUOp_sub;
        // 逻辑运算
        i_or  | i_ori:           ALUOp_reg = `ALUOp_or;
        i_and | i_andi:          ALUOp_reg = `ALUOp_and;
        i_xor | i_xori:          ALUOp_reg = `ALUOp_xor;
        // 移位运算
        i_sll | i_slli:          ALUOp_reg = `ALUOp_sll;
        i_srl | i_srli:          ALUOp_reg = `ALUOp_srl;
        i_sra | i_srai:          ALUOp_reg = `ALUOp_sra;
        // 比较运算
        i_slt | i_slti:          ALUOp_reg = `ALUOp_slt;
        i_sltu| i_sltiu:         ALUOp_reg = `ALUOp_sltu;
        // 分支指令（ALU 输出比较结果）
        i_beq | i_bne:           ALUOp_reg = `ALUOp_bne;   // 输出 (A==B)
        i_blt:                   ALUOp_reg = `ALUOp_blt;   // 输出 (A>=B)
        i_bge:                   ALUOp_reg = `ALUOp_bge;   // 输出 (A<B)
        i_bltu:                  ALUOp_reg = `ALUOp_bltu;  // 输出 (A>=B)
        i_bgeu:                  ALUOp_reg = `ALUOp_bgeu;  // 输出 (A<B)
        // U 型指令
        i_lui:                   ALUOp_reg = `ALUOp_lui;
        i_auipc:                 ALUOp_reg = `ALUOp_auipc;
        // 加载/存储指令（地址计算）
        i_lw | i_sw | i_lb | i_sb | i_lh | i_sh | i_lbu | i_lhu:  
                                   ALUOp_reg = `ALUOp_add;
        // jalr（地址计算）
        i_jalr:                  ALUOp_reg = `ALUOp_add;
        // jal（无需 ALU 运算）
        i_jal:                   ALUOp_reg = `ALUOp_nop;
        default:                 ALUOp_reg = `ALUOp_nop;
    endcase
end

assign ALUOp = ALUOp_reg;
//运算不需要看是否有立即数，前面控制信号已经挑选出来了，只需要看操作即可，有立即数不影响实际操作
//没有subi
	
//根据具体S和i_L指令生成DataMem数据操作类型编码   
// dm_word 3'b000
//dm_halfword 3'b001
//dm_halfword_unsigned 3'b010
//dm_byte 3'b011
//dm_byte_unsigned 3'b100

assign DMType[2]=i_lbu;
assign DMType[1]=i_lb | i_sb | i_lhu;
assign DMType[0]=i_lh | i_sh | i_lb | i_sb;

assign SBtype = sbtype;
assign I_jal = i_jal;
assign I_jalr = i_jalr;
assign I_load = itype_l;
assign Stype = stype;

//中断
assign I_ecall = i_ecall;

//据ai回答nop指令被映射为addi x0,0,那么异常指令的条件就是不是做好的37条指令,也不是ecall和sret\sretn，但是如果不是映射，需要修改
assign Trap = ~(i_add | i_addi|i_sub| i_or  | i_ori|i_and | i_andi| i_xor | i_xori|i_sll | i_slli|i_srl | i_srli|i_sra | i_srai|i_slt | i_slti|i_sltu| i_sltiu|
 i_beq | i_bne| i_blt | i_bltu| i_bge | i_bgeu|i_lui|i_auipc| i_lw | i_sw | i_lb | i_sb | i_lh | i_sh | i_lbu | i_lhu|i_jalr|i_jal|i_ecall|i_sret|i_sretn);
 
assign I_sret = i_sret;
assign I_sretn = i_sretn;
endmodule