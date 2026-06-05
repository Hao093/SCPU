`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/25 11:23:10
// Design Name: 
// Module Name: ALL_TOP
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
// z
//////////////////////////////////////////////////////////////////////////////////

module ALL_TOP1(
    input clk,
      input rstn,
      input [15:0]sw_i,
      input [4:0]btn_i,

      
      output [15:0]led_o,
      output [7:0]disp_an_o,
      output [7:0]disp_seg_o,
      output AUD_PWM,       // ? 新增
      output AUD_SD         // ? 新增
    );
    
    //1.定义wire变量（以输出端口为准）
    //btn_i
    wire rst_i;
    wire audio_we;
    wire [31:0] audio_data;
    wire aud_pwm;  
      //U1
      wire CPU_MIO;
      wire [31:0]PC_out;
      wire mem_w;
      wire [31:0]Addr_out;
      wire [31:0]Data_out;
      wire [2:0]dm_ctrl;
      wire [31:0]cause;
      wire [31:0]Trap_inst;
      
      //U2
      wire [31:0]inst_in;
      //U3
      wire [31:0]Data_read;
      wire [31:0]Data_write_to_dm;
      wire [3:0]wea_mem;
      
      //RAM
      wire clka0_i;
      wire [31:0]ram_data_out;
      
      //U4
      wire GPIOf0000000_we;   
      wire [31:0]Peripheral_in;
      wire counter_we;
      wire [31:0]ram_data_in;
      wire [31:0]Cpu_data4bus;
      wire [11:0]ram_addr;
      wire [31:0]counter_out1;//是否和U9相连需要判断,中断设计输出计数器值故相连
      wire data_ram_we;
      wire GPIOe0000000_we;
      wire irq_mask_we;
      wire [31:0] irq_mask_data;
      wire [1:0] counter_ch;   // 来自 MIO_BUS
      
      //U5
      wire [7:0]point_out;
      wire [7:0]LE_out;
      wire [31:0]Disp_num;
      //U7
      wire [1:0]counter_set;
      wire [15:0]LED_out;
      wire [13:0]GPIOf0;
      //U8
      wire [31:0]clkdiv;
      wire Clk_CPU1;
    
      wire IO_clk_i;
      
      
      //U9
      wire counter0_OUT;
      wire counter1_OUT;
      wire counter2_OUT;
      wire counter_out;
      //U10
      wire [4:0]BTN_out;
      wire [15:0]SW_out;
      
      //BUFG
      wire Clk_CPU_raw;
      wire Clk_CPU;
      
    //2.定义reg变量
    reg [3:0] int_ext_cnt;
    always @(posedge clk or posedge rst_i) begin    // clk 是 100MHz
        if (rst_i)
            int_ext_cnt <= 0;
        else if (counter0_OUT)
            int_ext_cnt <= 4'hF;                    // 装载展宽值 15
        else if (int_ext_cnt)
            int_ext_cnt <= int_ext_cnt - 1;
    end
        wire int_stretched = counter0_OUT || (int_ext_cnt != 0);
    
    
    
    
    //3.特殊顶层变量赋值
    //assign btn_i[0] = BTNC ;
    //assign btn_i[1] = BTNU ;
    //assign btn_i[2] = BTNL ;
    //assign btn_i[3] = BTNR ;
    //assign btn_i[4] = BTND ;
    assign rst_i = ~rstn ;
    
    
    //4.非门赋值
    
    //U8 
    assign IO_clk_i = ~Clk_CPU;
    
    //RAM
    assign clka0_i = ~clk;
    
    
    
    SCPU    U1_SCPU       (
    .clk(Clk_CPU), 
    .reset(rst_i), 
    .MIO_ready(CPU_MIO), 
    .inst_in(inst_in), 
    .Data_in(Data_read), 
    .mem_w(mem_w), 
    .PC_out(PC_out), 
    .Addr_out(Addr_out), 
    .Data_out(Data_out), 
    .dm_ctrl(dm_ctrl), 
    .CPU_MIO(CPU_MIO), 
    .INT(int_stretched),
    .cause(cause),
    .Trap_inst(Trap_inst),
    .irq_mask_we(irq_mask_we),
    .irq_mask_data(irq_mask_data)
    );
    
    
    ROM_IM U2_ROMD(
    .a(PC_out[12:2]),
    .spo(inst_in));
    
    
   dm_controller  U3_dm_controller (
   .mem_w(mem_w), 
   .Addr_in(Addr_out),
   .Data_write(ram_data_in),
   .dm_ctrl(dm_ctrl), 
   .Data_read_from_dm(Cpu_data4bus),
   .Data_read(Data_read), 
   .Data_write_to_dm(Data_write_to_dm),
   .wea_mem(wea_mem));
    
       
   RAM_DM U3_RAM_B(
   .addra(ram_addr),
   .clka(clka0_i),
   .dina(Data_write_to_dm),
   .wea(wea_mem),
   .douta(ram_data_out)
   );    
       
       
  MIO_BUS  U4_MIO_BUS     (
  .clk(clk),
  .rst(rst_i),
  .BTN(BTN_out),
  .SW(SW_out[15:0]),
  .PC(PC_out),
  .mem_w(mem_w),
  .Cpu_data2bus(Data_out),
  .addr_bus(Addr_out), 
  .ram_data_out(ram_data_out), 
  .led_out(LED_out),
  .counter_out(counter_out),
  .counter0_out(counter0_OUT), 
  .counter1_out(counter1_OUT), 
  .counter2_out(counter2_OUT), 
  .Cpu_data4bus(Cpu_data4bus),
  .ram_data_in(ram_data_in),
  .ram_addr(ram_addr),
  .data_ram_we(data_ram_we),
  .GPIOf0000000_we(GPIOf0000000_we),
  .GPIOe0000000_we(GPIOe0000000_we),
  .counter_we(counter_we),
  .Peripheral_in(Peripheral_in),
  .cause(cause),
  .Trap_inst(Trap_inst),
  .irq_mask_we(irq_mask_we),
  .irq_mask_data(irq_mask_data),
  .counter_ch(counter_ch),
  .audio_we   (audio_we),
  .audio_data (audio_data)
  );
  
  Multi_8CH32  U5_Multi_8CH32   (
  .clk(clk), 
  .rst(rst_i), 
  .EN(GPIOe0000000_we), 
  .Switch(SW_out[7:5]),
  .point_in({clkdiv[31:0],clkdiv[31:0]}),
   .LES(~64'h0), 
  .data0(Peripheral_in), 
  .data1({1'b0,1'b0,PC_out[31:2]}), 
  .data2(inst_in), 
  .data3(counter_out), //修改过后连上了U9
  .data4(Addr_out), 
  .data5(Data_out), 
  .data6(Cpu_data4bus), 
  .data7(PC_out), 
  .point_out(point_out), .LE_out(LE_out), .Disp_num(Disp_num));
  
  SSeg7 U6_SSeg7   (
  .clk(clk), 
  .rst(rst_i), 
  .SW0(SW_out[0]), 
  .flash(clkdiv[10]), 
  .Hexs(Disp_num), 
  .point(point_out), 
  .LES(LE_out), 
  .seg_an(disp_an_o), 
  .seg_sout(disp_seg_o));
  
  SPIO  U7_SPIO  (
  .clk(IO_clk_i), 
  .rst(rst_i), 
  .EN(GPIOf0000000_we), 
  .P_Data(Peripheral_in[31:0]), 
  .counter_set(counter_set), 
  .LED_out(LED_out), 
  .led(led_o), 
  .GPIOf0(GPIOf0));  
    
  clk_div U8_clk_div ( .clk(clk),
					 .rst(rst_i),
					 .SW2(SW_out[2]),
					 .clkdiv(clkdiv[31:0]),
					 .Clk_CPU(Clk_CPU1)
					);  
    
    Counter_x U9_Counter_x      (.clk(IO_clk_i),
					.rst(rst_i),
					.clk0(clkdiv[6]),
					.clk1(clkdiv[9]),
					.clk2(clkdiv[11]),
					.counter_we(counter_we),
					.counter_val(Peripheral_in[31:0]),
					.counter_ch(counter_ch),				//Counter channel set

					.counter0_OUT(counter0_OUT),
					.counter1_OUT(counter1_OUT),
					.counter2_OUT(counter2_OUT),
					.counter_out(counter_out)
					
					);
					
					
    Enter U10_Enter    (.clk(clk),
                .BTN(btn_i[4:0]),	 
                .SW(sw_i), 
                .BTN_out(BTN_out),
                .SW_out(SW_out) 
            );
            
            
            reg sw2_sync1, sw2_sync2;
            always @(posedge clk) begin
                sw2_sync1 <= SW_out[2];
                sw2_sync2 <= sw2_sync1;
            end
            
            BUFGMUX #(
                .CLK_SEL_TYPE("ASYNC")
            ) bufgmux_cpu (
                .O(Clk_CPU),
                .I0(clkdiv[0]),      // SW2=0 时选择 I0（快速）
                .I1(clkdiv[24]),     // SW2=1 时选择 I1（慢速）
                .S(sw2_sync2)
            );

pwm_audio u_pwm_audio (
    .clk      (clk),
    .rst      (rst_i),       // 取反！pwm_audio 高电平复位，而 rst_i 平时为低
    .we       (audio_we),
    .data     (audio_data),
    .aud_pwm  (AUD_PWM)
);

assign AUD_SD = 1'b1;         // 功放使能，高电平工作    
endmodule
