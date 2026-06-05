// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
// Date        : Mon Jun 26 15:11:09 2023
// Host        : LAPTOP-E4IJ843E running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub C:/Users/user/Desktop/projects/edf_file/MIO_BUS.v
// Design      : MIO_BUS
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.

 // ---- 原始译码使能（组合逻辑） ----
 module MIO_BUS(   input clk,
					input rst,
					input[4:0]BTN, // 按钮
					input[15:0]SW, // 开关
					input mem_w, // 写内存
					input[31:0]Cpu_data2bus,				//data from CPU
					input[31:0]addr_bus, // 地址总线
					input[31:0]ram_data_out, // ram输出数据
					input[15:0]led_out,
					input[31:0]counter_out,
					input counter0_out,
					input counter1_out,
					input counter2_out,
					input [31:0]PC,
					input [31:0]cause,
					input [31:0]Trap_inst,
					
					
					output reg [1:0] counter_ch,
					output reg[31:0]Cpu_data4bus,				//write to CPU
					output reg[31:0]ram_data_in,				//from CPU write to Memory
					output reg[11:0]ram_addr,						//Memory Address signals
					output reg data_ram_we,
					output reg GPIOf0000000_we,
					output reg GPIOe0000000_we,
					output reg counter_we,
					output reg[31:0]Peripheral_in,
					output reg irq_mask_we,      // 新增
                    output reg [31:0] irq_mask_data,  // 新增
                    output reg audio_we,
                    output reg [31:0] audio_data
					);
					

	   //下面是ai给出的优化外设数据脉冲的代码
       // ---- 原始译码使能（组合逻辑） ----
        wire gpio_we_raw = mem_w && (addr_bus[31:28] == 4'b1111);
        wire seg7_we_raw = mem_w && (addr_bus[31:28] == 4'b1110);
    
        // ---- 脉冲展宽（保持至少 16 个 clk 周期） ----
        reg [3:0] gpio_we_ext_cnt, seg7_we_ext_cnt;
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                gpio_we_ext_cnt <= 0;
                seg7_we_ext_cnt <= 0;
            end else begin
                // LED 写使能展宽
                if (gpio_we_raw)
                    gpio_we_ext_cnt <= 4'hF;          // 装载展宽值
                else if (gpio_we_ext_cnt)
                    gpio_we_ext_cnt <= gpio_we_ext_cnt - 1;
                // 数码管写使能展宽
                if (seg7_we_raw)
                    seg7_we_ext_cnt <= 4'hF;
                else if (seg7_we_ext_cnt)
                    seg7_we_ext_cnt <= seg7_we_ext_cnt - 1;
            end
        end
        wire gpio_we_stretched = gpio_we_raw || (gpio_we_ext_cnt != 0);
        wire seg7_we_stretched = seg7_we_raw || (seg7_we_ext_cnt != 0);
    
        // ---- 写数据锁存（在原始使能有效时锁存） ----
        reg [31:0] peri_data_r;
        always @(posedge clk or posedge rst) begin
            if (rst)
                peri_data_r <= 0;
            else if (gpio_we_raw || seg7_we_raw)
                peri_data_r <= Cpu_data2bus;
        end
       


   
    always @(*) begin
        // 默认值
        Cpu_data4bus = 0;
        ram_data_in  = 0;
        ram_addr     = 0;
        data_ram_we  = 0;
        GPIOf0000000_we = 0;
        GPIOe0000000_we = 0;
        counter_we   = 0;
        Peripheral_in = 0;
        irq_mask_we = 0;
        irq_mask_data = 0;
        counter_ch = 2'b0;
        audio_we   = 0;
        audio_data = 0;
        case (addr_bus[31:28])
                4'b1111: begin //F0000000-FFFFFFFF,读取LED灯数据及写LED
                    Cpu_data4bus = {14'b0, led_out, 2'b00};
                    GPIOf0000000_we = gpio_we_stretched;
                    Peripheral_in   = peri_data_r;
                    data_ram_we = 0;                     //没必要写ram
                end
                4'b1110: begin //E0000000-EFFFFFFF,读写数码管
                    GPIOe0000000_we = seg7_we_stretched;
                    Peripheral_in   = peri_data_r;
                    data_ram_we = 0;                     // 不写 RAM
                    Cpu_data4bus = {11'b0, BTN, SW};
                end
                
                //下面是自己扩展的部分
				4'b1000:begin  //软件读取cause 80000000-8FFFFFFF,该地址不能写
				    Cpu_data4bus = cause;
				    data_ram_we = 0;
				end
				4'b1001:begin //软件读取异常指令,90000000-9FFFFFFF,该地址不能写
				    Cpu_data4bus = Trap_inst;
				    data_ram_we = 0;				    
				end
				4'b1010:begin //软件读取计数器值,A0000000-AFFFFFFF,该地址不能写
				    Cpu_data4bus = 32'h12345678;
				    data_ram_we = 0;				    
				end
				4'b1100: begin              // 0xC0000000-0xCFFFFFFF,写中断屏蔽寄存器
                    irq_mask_we   = mem_w;
                    irq_mask_data = Cpu_data2bus;
                    Cpu_data4bus  = 32'h0;  // 读取无意义
                    data_ram_we   = 0;
                end
                4'b1011: begin  //B0000000-BFFFFFFF,写计数器
                    counter_we   = mem_w;                     // 写使能
                    counter_ch   = addr_bus[1:0];             // 通道选择
                    Peripheral_in = Cpu_data2bus;             // 配置数据
                    data_ram_we  = 0;                         // 禁止写 RAM
                    Cpu_data4bus = 32'h0;                     // 读回 0（没有意义）
                end
                4'b1101: begin                    // 0xD0000000 音频外设
                    audio_we   = mem_w;
                    audio_data = Cpu_data2bus;
                    data_ram_we = 0;
                    Cpu_data4bus = 32'h0;         // 读回 0
                end
				default: begin 
					Cpu_data4bus = ram_data_out;
					ram_data_in = Cpu_data2bus;
					ram_addr = addr_bus[13:2];
					data_ram_we = mem_w;
            end
        endcase
    end
endmodule