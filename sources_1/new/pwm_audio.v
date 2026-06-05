`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/15 18:24:31
// Design Name: 
// Module Name: pwm_audio
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


module pwm_audio #(
    parameter VOLUME_SHIFT = 10   // 右移位数：数值越大音量越小 (2→1/4, 3→1/8, 4→1/16)
) (
    input         clk,
    input         rst,
    input         we,
    input  [31:0] data,
    output        aud_pwm,
    output        aud_sd
);

    reg [31:0] tone_ctrl = 0;
    reg [31:0] counter   = 0;
    reg [31:0] high_time = 0;

    // 锁存音调控制字
    always @(posedge clk) begin
        if (rst)
            tone_ctrl <= 0;
        else if (we)
            tone_ctrl <= data;
    end

    // 生成可调占空比 PWM
    always @(posedge clk) begin
        if (rst) begin
            counter   <= 0;
            high_time <= 0;
        end else if (tone_ctrl == 0) begin
            counter   <= 0;
            high_time <= 0;
        end else begin
            high_time <= tone_ctrl >> VOLUME_SHIFT;   // 音量控制
            if (counter >= tone_ctrl)
                counter <= 0;
            else
                counter <= counter + 1;
        end
    end

    // 开漏输出
    assign aud_pwm = (counter < high_time) ? 1'bz : 1'b0;
    assign aud_sd  = 1'b1;

endmodule
