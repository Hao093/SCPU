// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
// Date        : Tue Jun 20 18:23:52 2023
// Host        : LAPTOP-E4IJ843E running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub C:/Users/user/Desktop/projects/edf_file/SCPU.v
// Design      : SCPU
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
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

module SCPU(clk, reset, MIO_ready, inst_in, Data_in, mem_w, 
  PC_out, Addr_out, Data_out, dm_ctrl, CPU_MIO, INT, cause,Trap_inst,irq_mask_we,irq_mask_data);


  input clk;
  input reset;
  input MIO_ready;//1 not use
  input [31:0]inst_in;
  input [31:0]Data_in;
  output mem_w;
  output [31:0]PC_out;
  output [31:0]Addr_out;
  output [31:0]Data_out;
  output [2:0]dm_ctrl;//2 
  output CPU_MIO;//3 not use
  input INT;//计数器中断
  output [31:0]cause;
  output reg [31:0]Trap_inst;
  input irq_mask_we;          // 新增：掩码写使能
  input [31:0] irq_mask_data;  // 新增：掩码数据
  
    wire        RegWrite;    // control signal to register write
    wire [5:0]  EXTOp;       // control signal to signed extension
    wire [4:0]  ALUOp;       // ALU opertion
    wire [6:0]  NPCOp;       // next PC operation

    wire [1:0]  WDSel;       // (register) write data selection
    wire [1:0]  GPRSel;      // general purpose register selection
   
    wire        ALUSrc;      // ALU source for B
    wire        Zero;        // ALU ouput zero

    wire [31:0] NPC;         // next PC

    wire [4:0]  rs1;          // rs
    wire [4:0]  rs2;          // rt
    wire [4:0]  rd;          // rd
    wire [6:0]  Op;          // opcode
    wire [6:0]  Funct7;       // funct7
    wire [2:0]  Funct3;       // funct3
    wire [11:0] Imm12;       // 12-bit immediate
    wire [31:0] Imm32;       // 32-bit immediate
    wire [19:0] IMM;         // 20-bit immediate (address)
    wire [4:0]  A3;          // register address for write
    reg [31:0] WD;          // register write data
    wire [31:0] RD1,RD2;         // register data specified by rs
	
	wire [4:0] iimm_shamt;
	wire [11:0] iimm,simm,bimm;
	wire [19:0] uimm,jimm;
	wire [31:0] immout;
    wire[31:0] aluout;
    
    
    
    wire IO1;
   
    /*流水线加入信号*/
    //IF
    
    //ID
    wire [31:0]ID_instruction;
    wire SBtype;
    wire I_jal;
    wire I_jalr;
    wire I_load;
    wire Stype;
    wire ID_mem_w;
    wire [2:0]ID_dm_ctrl;
    wire [31:0]ID_PC;
    wire ID_EX_LOAD ;
    wire [4:0]ID_EX_RD ;
    wire stall;
    wire I_ecall;
    wire Trap;
    wire I_sret;
    wire I_sretn;
    wire valid;
    
    //EX
    wire [4:0]EX_MEM_RD;
    wire EX_MEM_Rewrite;
    wire EX_MEM_load;
    wire [4:0]MEM_WB_RD;
    wire MEM_WB_load ;
    wire MEM_WB_Rewrite;
    wire [4:0]EX_rs1;
    wire [4:0]EX_rs2;
    wire [31:0]ALU_A;
    wire [31:0]ALU_B;
    wire ex_mem_valid;
    wire mem_wb_valid;
    wire [4:0]EX_ALUOP;
    wire [31:0]EX_PC;
    wire all_jump;
    reg branch_taken;
    wire getINT;
    wire [31:0] INT_PC;
    wire clear;
    reg IF_reg;
    reg [31:0] SEPC_reg;
    wire trap_taken;
    reg INT1;
    reg last_INT;
    //MEM
    
    
    
    
    //WB
    wire WB_ReWrite;
    wire [31:0]WB_backnumber;
    wire [4:0]WB_rd;
    
    //流水线寄存器输入输出
    wire [199:0]IF_ID_in;
    wire [199:0]IF_ID_out;
    wire [199:0]ID_EX_IN;
    wire [199:0]ID_EX_OUT;
    wire [199:0]EX_MEM_IN;
    wire [199:0]EX_MEM_OUT;
    wire [199:0]MEM_WB_IN;
    wire [199:0]MEM_WB_OUT; 
    
    //流水线寄存器使能与清零信号
    wire IF_ID_write_enable;
    wire IF_ID_flush;
    wire ID_EX_flush;
    wire ID_EX_write_enable;
    wire EX_MEM_write_enable;
    wire EX_MEM_flush;
    wire MEM_WB_write_enable;
    wire MEM_WB_flush;
        
   
    
     //暂时未使用的信号
    assign IO1 = MIO_ready;
    assign CPU_MIO = MIO_ready;

    //前递单元、冒险检测单元和中断处理没有设置专用模块，也没有设置scause寄存器，只设置了IF寄存器


    //流水线寄存器,输入in和输出out选择直接在SCPU中赋值而不用中间变量
    //对流水线寄存器作如下规划，每个寄存器内容不一样，但是只需要约束好即可

    
    /* 
     IF  操作：取指令（在rom中完成）
     */
    
   //为了防止在EX的前半周期就计算完毕结果，然后改变NPC（NPC组合逻辑），然后在时钟上升沿之前取到正确指令，提前一个指令就跳转，PC和流水线CPU采用同一个时钟边沿
	PC U_PC(.clk(clk), .rst(reset), .NPC(NPC), .PC(PC_out) );

	//npc应该在EX阶段计算完全
	//需要设置新的NPCOp逻辑
	//新的NPC逻辑如下：只有在EX阶段判断是否跳转，此时利用EX阶段的立即数、ALU输出结果调整NPC，但是注意跳转用的PC是EXPC，PCout属于IF
	//如果有中断，利用INT_PC跳转至中断处理程序（统一入口）
	NPC U_NPC(.PC(PC_out), .NPCOp(NPCOp), .IMM(ID_EX_OUT[127:96]), .NPC(NPC), .aluout(aluout),.EXPC(EX_PC),.INT_PC(INT_PC),.SEPC(SEPC_reg));

    assign IF_ID_in[31:0] = inst_in;//指令
    assign IF_ID_in[63:32] = PC_out;//当前的PC
    assign IF_ID_in[64] = 1'b1;//代表指令有效
    assign IF_ID_in[199:65] = 135'b0;
    
    /*
        IF/ID:
        0-31位放指令码，由于没有译码没有啥要放的
        32-63位放当前取指令对应的PC       
    */
    GRE_array #(.WIDTH(200))IF_ID(.Clk(clk),.rst(reset),.write_enable(IF_ID_write_enable),.flush(IF_ID_flush),.in(IF_ID_in),.out(IF_ID_out));
    //控制逻辑在ID阶段的数据冒险处理
      
 
    /* 
     ID   操作：译码+读寄存器+立即数生成
    */
    assign valid = IF_ID_out[64];
    
    //译码在此处完成
    assign ID_instruction = IF_ID_out[31:0];       
    assign Op = ID_instruction[6:0];  // instruction
    assign Funct7 = ID_instruction[31:25]; // funct7
    assign Funct3 = ID_instruction[14:12]; // funct3
    assign rs1 = ID_instruction[19:15];  // rs1
    assign rs2 = ID_instruction[24:20];  // rs2
    assign rd = ID_instruction[11:7];  // rd
    assign Imm12 = ID_instruction[31:20];// 12-bit immediate
    assign IMM = ID_instruction[31:12];  // 20-bit immediate
        
    	ctrl U_ctrl(
		.Op(Op), .Funct7(Funct7), .Funct3(Funct3),
		.RegWrite(RegWrite), .MemWrite(ID_mem_w),
		.EXTOp(EXTOp), .ALUOp(ALUOp),
		.ALUSrc(ALUSrc), .GPRSel(GPRSel), .WDSel(WDSel),
		.DMType(ID_dm_ctrl),.SBtype(SBtype),.I_jal(I_jal),.I_jalr(I_jalr),.I_load(I_load),.Stype(Stype),.I_ecall(I_ecall),.Trap(Trap),.I_sret(I_sret),.I_sretn(I_sretn)
	);
	
	assign iimm_shamt=ID_instruction[24:20];
	assign iimm=ID_instruction[31:20];
	assign simm={ID_instruction[31:25],ID_instruction[11:7]};
	assign bimm={ID_instruction[31],ID_instruction[7],ID_instruction[30:25],ID_instruction[11:8]};
	assign uimm=ID_instruction[31:12];
	assign jimm={ID_instruction[31],ID_instruction[19:12],ID_instruction[20],ID_instruction[30:21]};
	
	
    	EXT U_EXT(
		.iimm_shamt(iimm_shamt), .iimm(iimm), .simm(simm), .bimm(bimm),
		.uimm(uimm), .jimm(jimm),
		.EXTOp(EXTOp), .immout(immout)
	);

        
        //进行冒险检测            
       assign ID_EX_RD = ID_EX_OUT[181:177];        
       assign ID_EX_LOAD = ID_EX_OUT[176];
        
       assign stall = (rs1 == ID_EX_RD && ID_EX_LOAD)? 1'b1:
       (rs2 == ID_EX_RD && ID_EX_LOAD && ~ALUSrc)?1'b1:
       (rs2 == ID_EX_RD && ID_EX_LOAD && ALUSrc && Stype)?1'b1:1'b0;//rs1重合即冒险，rs2分情况，指令中无立即数，如果含有立即数必须是s型指令
       
       assign IF_ID_write_enable = IF_ID_flush?1'b1:~stall;
       assign ID_EX_write_enable = 1'b1;
 
       /*
        ID/EX:
        0-31位放指令码
        32-63位放rs1的数据
        64-95位放rs2的数据
        96-127放立即数
        信号放置：
        128：RegWrite
        133-129：ALUOp
        134:ALUSrc
        136-135:WDSel
        137:mem_w
        140-138:ID_dm_ctrl;
        172-141:PC
        173:SBtype;
        174:I_jal;
        175:I_jalr;
        176:I_load;
        181-177=rd;
        186-182=rs1;
        191-187:rs2;
        192:Stype;
        193:I_ecall
        194:Trap
        195:sret
        196:sretn        
       */ 
            
       assign ID_EX_IN[31:0] = ID_instruction;
       assign ID_EX_IN[63:32] = RD1;
       assign ID_EX_IN[95:64] = RD2;
       assign ID_EX_IN[127:96] = immout;
       assign ID_EX_IN[128] = RegWrite;
       assign ID_EX_IN[133:129] = ALUOp;
       assign ID_EX_IN[134] = ALUSrc;
       assign ID_EX_IN[136:135] = WDSel;
       assign ID_EX_IN[137] = ID_mem_w; 
       assign ID_EX_IN[140:138] = ID_dm_ctrl;
       assign ID_EX_IN[172:141] = IF_ID_out[63:32];//PC
       assign ID_EX_IN[173] = SBtype;
       assign ID_EX_IN[174] = I_jal;
       assign ID_EX_IN[175] = I_jalr;
       assign ID_EX_IN[176] = I_load;
       assign ID_EX_IN[181:177] = rd;
       assign ID_EX_IN[186:182] = rs1;
       assign ID_EX_IN[191:187] = rs2;
       assign ID_EX_IN[192] = Stype;
       assign ID_EX_IN[193] = I_ecall;
       assign ID_EX_IN[194] = Trap&valid;//防止全清零指令错误置Trap为1
       assign ID_EX_IN[195] = I_sret;
       assign ID_EX_IN[196] = I_sretn;  
       assign ID_EX_IN[197] = 1'b1;  
       assign ID_EX_IN[199:198] =2'b0;
       
       GRE_array #(.WIDTH(200))ID_EX(.Clk(clk),.rst(reset),.write_enable(ID_EX_write_enable),.flush(ID_EX_flush),.in(ID_EX_IN),.out(ID_EX_OUT));  
          
    /*  
    EX  操作：进行计算+判断是否转移（待控制冒险时解决）
    */

    //这是一开始的时候对于通道0的00模式电平信号转脉冲信号的代码，对于01模式，因为输出的信号电平也较大，倒可以继续用，也可以继续优化
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            INT1     <= 1'b0;
            last_INT <= 1'b0;
        end else begin
            if (INT == 1) begin
                if (last_INT == 0) begin
                    INT1 <= 1;
                    last_INT <= 1;
                end else begin
                    INT1 <= 0;
                end
            end else begin
                INT1 <= 0;
                last_INT <= 0;
            end
        end
    end
    
    //IF和SEPC的设置
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_reg   <= 1'b1;
            SEPC_reg <= 32'b0;
        end 
        else begin
            if (trap_taken) 
            begin
                IF_reg   <= 1'b0;
                // 为方便SEPC统一存储返回指令的PC,实际上不需要sretn了
                if (NPCOp[0])                     // 分支跳转
                    SEPC_reg <= EX_PC + ID_EX_OUT[127:96]; 
                else if (NPCOp[1])                 // jal
                    SEPC_reg <= EX_PC + ID_EX_OUT[127:96]; 
                else if (NPCOp[2])                 // jalr
                    SEPC_reg <= aluout;           // 目标地址在 aluout
                else if(IF_ID_out[64])                             
                    SEPC_reg <= IF_ID_out[63:32]; //不能直接用当前PC+4,考虑到阻塞
            end 
            else if (NPCOp[5] || NPCOp[6]) 
            begin  // sret/sretn 返回
                IF_reg <= 1'b1;
            end
        end
    end

   //为了防止start函数未执行完就进入中断，导致栈指针未设置的情况，设置中断屏蔽寄存器
    reg [31:0] irq_mask;
    always @(posedge clk or posedge reset) begin
        if (reset)
            irq_mask <= 32'h0;          // 复位后所有中断屏蔽
        else if (irq_mask_we)
            irq_mask <= irq_mask_data;
    end

    // 只屏蔽 INT1（计数器中断），ecall 和 Trap 是同步触发的，不会打断start函数
    wire int1_masked = INT1 & irq_mask[0];   // bit0 控制计数器中断
    wire int2_masked = ID_EX_OUT[193];
    wire int3_masked = ID_EX_OUT[194];
    
    
    //进行中断检测，在硬件上直接生成对应的中断处理程序的地址
    //注意：这里的getINT只是代表有中断需要处理
    Interrupt_handle U_INTHAND(
        .INT1(int1_masked),//计数器中断
        .INT2(int2_masked),//ecall
        .INT3(int3_masked), //Trap
        .getINT(getINT),
        .INT_PC(INT_PC),
        .clear(clear),
        .clk(clk),
        .reset(reset),
        .trap_taken(trap_taken),
        .IF_reg(IF_reg)
    );   
    

    // 在 EX/MEM 写入 scause
    //需要考虑scause的读取映射到单独的内存地址
    //尝试映射到80000000-8FFFFFFF
    
    //在处理中断的时候才改变Scause,实际上可以用trap_taken信号
   SCAUSE U_scause(
        .clk(clk),
        .reset(reset),
        .getINT(getINT),
        .INT1(int1_masked),
        .INT2(int2_masked),
        .INT3(int3_masked),
        .cause(cause),
        .IF(IF_reg)
   );
    
        //异常指令输出
    always @(posedge clk) begin
        if (trap_taken && clear)   
            Trap_inst <= ID_EX_OUT[31:0];
    end
    
    
    //旁路处理，ID阶段已经处理阻塞，现在所需要的数据一定可以通过旁路获取（或ID阻塞后读取）
    
    assign EX_MEM_RD = EX_MEM_OUT[140:136];
    assign EX_MEM_Rewrite =EX_MEM_OUT[96];
    assign EX_MEM_load =EX_MEM_OUT[135];
    
    assign MEM_WB_RD = MEM_WB_OUT[136:132];
    assign MEM_WB_load = MEM_WB_OUT[131];
    assign MEM_WB_Rewrite = MEM_WB_OUT[96];
  
    assign EX_rs1 = ID_EX_OUT[186:182];
    assign EX_rs2 = ID_EX_OUT[191:187];
          
    assign ex_mem_valid = EX_MEM_Rewrite && (EX_MEM_RD != 5'd0);//写的寄存器不是0
    assign mem_wb_valid = MEM_WB_Rewrite && (MEM_WB_RD != 5'd0);
       
    //前递,在ID阶段已经阻塞过了，执行前递即可
     assign ALU_A = ((EX_rs1==EX_MEM_RD) && (~EX_MEM_load) && ex_mem_valid)? EX_MEM_OUT[63:32] : 
                    ((EX_rs1==MEM_WB_RD)  && mem_wb_valid && MEM_WB_load) ? MEM_WB_OUT[95:64]:
                    ((EX_rs1==MEM_WB_RD)  && mem_wb_valid && (~MEM_WB_load)) ? MEM_WB_OUT[63:32]:
                    ID_EX_OUT[63:32]; 
                                       
     assign ALU_B = ID_EX_OUT[134]? ID_EX_OUT[127:96]:((EX_rs2==EX_MEM_RD) && (~EX_MEM_load) && ex_mem_valid)? EX_MEM_OUT[63:32] : 
                    ((EX_rs2==MEM_WB_RD)  && mem_wb_valid && MEM_WB_load) ? MEM_WB_OUT[95:64]:
                    ((EX_rs2==MEM_WB_RD)  && mem_wb_valid && (~MEM_WB_load)) ? MEM_WB_OUT[63:32]:
                    ID_EX_OUT[95:64];//首先需要防止立即数末5位冲突，不是立即数，且rs2参与运算的情况下进行选择
       
    //获取当前PC，ALUOp用于计算,顺便送给NPC跳转
    assign EX_PC = ID_EX_OUT[172:141];
    assign EX_ALUOP = ID_EX_OUT[133:129];
        
    alu U_alu(.A(ALU_A), .B(ALU_B), .ALUOp(EX_ALUOP), .C(aluout), .Zero(Zero), .PC(EX_PC));
 
    //生成是否跳转信号，这个和alu的实现有关，选择把ctrl模块的内容迁移过来
    always @(*) begin
        case (ID_EX_OUT[14:12])//这个是sbtype的funct3
            3'b000: branch_taken = ~Zero; // beq
            3'b001: branch_taken =  Zero; // bne
            3'b100: branch_taken =  Zero; // blt
            3'b101: branch_taken = Zero; // bge
            3'b110: branch_taken =  Zero; // bltu
            3'b111: branch_taken = Zero; // bgeu
            default: branch_taken = 1'b0;
        endcase
    end
// NPC_PLUS4   7'b0000000
// NPC_BRANCH  7'b0000001
// NPC_JUMP    7'b0000010
// NPC_JALR    7'b0000100
// NPC_SAME    7'b0001000
// NPC_INT     7'b0010000
// NPC_SRET    7'b0100000
// NPC_SRETN   7'b1000000

//注意：有可能在其他位非0的时候产生getINT吗？
    assign NPCOp[0] = ID_EX_OUT[173] & branch_taken; //sb型+跳转
    assign NPCOp[1] = ID_EX_OUT[174];//jal
    assign NPCOp[2] = ID_EX_OUT[175];//jalr
    assign NPCOp[3] = stall;  //数据冒险阻塞不能改变PC
    assign NPCOp[4] = trap_taken;
    assign NPCOp[5] = ID_EX_OUT[195];//sret
    assign NPCOp[6] = ID_EX_OUT[196];//sretn
    
    
    //静态预测清零+中断检查清零，执行sret和sretn需要跳转，同样需要清零？
    assign all_jump = NPCOp[0] | NPCOp[1] | NPCOp[2]; 
    assign IF_ID_flush = (NPCOp[5])?1'b1:(NPCOp[6])?1'b1:(trap_taken)?1'b1:(all_jump)? 1'b1:1'b0;
    assign ID_EX_flush = (NPCOp[5])?1'b1:(NPCOp[6])?1'b1:(trap_taken)?1'b1:(all_jump)? 1'b1:(stall)?1'b1:1'b0;
         
           
       /*
       EX/MEM:      
       0-31位放指令码
       31-63位放计算结果（C）
       95-64位放rs2对应数据（针对s型指令）
       96：RegWrite; // control signal for register write
       98-97：WDSel;    // (register) write data selection
       99：MemWrite; // control signal for memory write
       102-100:DMtype
       134-103:PC      
       135:I_load
       140-136:rd
       */
    
     assign EX_MEM_write_enable = 1'b1; //后面两级流水线一直写，不需要保持原有数据
     assign EX_MEM_flush = (clear & trap_taken)?1'b1:1'b0;   //可以预想到异常指令是不可以执行的,至于ecall,sret,sretn是否需要清零，先观察一下
     
     assign EX_MEM_IN[31:0] = ID_EX_OUT[31:0];
     assign EX_MEM_IN[63:32]= aluout;
     assign EX_MEM_IN[95:64] = ((EX_rs2==EX_MEM_RD) && (~EX_MEM_load) && ex_mem_valid)? EX_MEM_OUT[63:32] : 
                    ((EX_rs2==MEM_WB_RD)  && mem_wb_valid && MEM_WB_load) ? MEM_WB_OUT[95:64]:
                    ((EX_rs2==MEM_WB_RD)  && mem_wb_valid && (~MEM_WB_load)) ? MEM_WB_OUT[63:32]:
                    ID_EX_OUT[95:64]; //针对s型指令，需要使用rs2的数据，但是不能直接使用ALU_B，否则会变为立即数
     assign EX_MEM_IN[96] = ID_EX_OUT[128]; //regwrite
     assign EX_MEM_IN[98:97] = ID_EX_OUT[136:135];//wdsel
     assign EX_MEM_IN[99] = ID_EX_OUT[137];//mem_w
     assign EX_MEM_IN[102:100] = ID_EX_OUT[140:138];//DMtype
     assign EX_MEM_IN[134:103] = ID_EX_OUT[172:141];//PC
     assign EX_MEM_IN[135] = ID_EX_OUT[176];//I_load
     assign EX_MEM_IN[140:136] = ID_EX_OUT[181:177] ;//rd
     assign EX_MEM_IN[199:141] = 59'b0;
     
     GRE_array #(.WIDTH(200))EX_MEM(.Clk(clk),.rst(reset),.write_enable(EX_MEM_write_enable),.flush(EX_MEM_flush),.in(EX_MEM_IN),.out(EX_MEM_OUT));


    /*  
    MEM  操作：访存
    */
    
    //注意：只需给出地址、信号、数据及接受数据即可，不需写控制逻辑等
    //给出：访存的地址、数据、读写信号
    assign Addr_out = EX_MEM_OUT[63:32];
	assign Data_out = EX_MEM_OUT[95:64];
    assign mem_w = EX_MEM_OUT[99];
    assign dm_ctrl = EX_MEM_OUT[102:100];
    
    /*MEM/WB
      操作：访存，存取数据
      0-31位放指令码
      32-63位计算结果(ALU输出)
      64-95位读取结果
      96：RegWrite; // control signal for register write
      98-97：WDSel;    // (register) write data selection
      130-99:pc_out
      131:I_load
      136-132:rd
    */
    
    assign MEM_WB_write_enable = 1;
    assign MEM_WB_flush = 0;
    
    assign MEM_WB_IN[31:0] = EX_MEM_OUT[31:0];
    assign MEM_WB_IN[63:32] = EX_MEM_OUT[63:32];
    assign MEM_WB_IN[95:64] = Data_in;
    assign MEM_WB_IN [96] = EX_MEM_OUT[96];//regwrite
    assign MEM_WB_IN[98:97] = EX_MEM_OUT[98:97];//wdsel
    assign MEM_WB_IN[130:99] = EX_MEM_OUT[134:103];//pc
    assign MEM_WB_IN[131] = EX_MEM_OUT[135];   //I_load
    assign MEM_WB_IN[136:132] = EX_MEM_OUT[140:136];//rd
    assign MEM_WB_IN[199:137] = 63'b0;
    
    GRE_array #(.WIDTH(200))MEM_WB(.Clk(clk),.rst(reset),.write_enable(MEM_WB_write_enable),.flush(MEM_WB_flush),.in(MEM_WB_IN),.out(MEM_WB_OUT));
      
          
    /*
      WB:利用MEM/WB流水线寄存器获取数据写回寄存器中
    */
    
        
    //写ALU输出，写内存读取数据，写返回地址（PC+4）
    //MEM_WB_OUT[98:97]是WDsel    
    assign WB_backnumber = (MEM_WB_OUT[98:97] == `WDSel_FromALU)? MEM_WB_OUT[63:32]:(MEM_WB_OUT[98:97] == `WDSel_FromMEM)?MEM_WB_OUT[95:64]:MEM_WB_OUT[130:99]+4;
    assign WB_ReWrite = MEM_WB_OUT[96];  
    assign WB_rd = MEM_WB_OUT[136:132];
    
        RF U_RF(
		.clk(~clk), .rst(reset),
		.RFWr(WB_ReWrite), 
		.A1(rs1), .A2(rs2), .A3(WB_rd), 
		.WD(WB_backnumber), 
		.RD1(RD1), .RD2(RD2)
	   );

endmodule
