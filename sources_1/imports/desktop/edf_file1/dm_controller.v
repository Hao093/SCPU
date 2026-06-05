// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
// Date        : Tue Jun 20 11:12:44 2023
// Host        : LAPTOP-E4IJ843E running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub C:/Users/user/Desktop/projects/edf_file/dm_controller.v
// Design      : dm_controller
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
// dm_controller.v (优化版)
`timescale 1ns / 1ps

`define dm_word              3'b000
`define dm_halfword          3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte              3'b011
`define dm_byte_unsigned     3'b100

`timescale 1ns / 1ps

`define dm_word              3'b000
`define dm_halfword          3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte              3'b011
`define dm_byte_unsigned     3'b100

module dm_controller (
    input         mem_w,
    input  [31:0] Addr_in,
    input  [31:0] Data_write,
    input  [2:0]  dm_ctrl,
    input  [31:0] Data_read_from_dm,
    output [31:0] Data_read,
    output [31:0] Data_write_to_dm,
    output [3:0]  wea_mem
);

    wire [1:0] addr_low = Addr_in[1:0];

    // 是否为外设地址（高4位为 4'b1110 或 4'b1111）
    //注：扩展总线时有意识的使得ram写信号为0，实际上不需要该信号考察
    wire is_peripheral = (Addr_in[31:28] == 4'b1110) || (Addr_in[31:28] == 4'b1111);

    // ---------- 写字节使能（外设地址时禁止写RAM） ----------
    reg [3:0] wea_byte;
    always @(*) begin
        if (!mem_w || is_peripheral)   // 加入地址判断
            wea_byte = 4'b0;
        else case (dm_ctrl)
            `dm_word:                   wea_byte = 4'b1111;
            `dm_halfword, `dm_halfword_unsigned:
                wea_byte = addr_low[1] ? 4'b1100 : 4'b0011;
            `dm_byte, `dm_byte_unsigned:
                case (addr_low) 
                    2'b00: wea_byte = 4'b0001;
                    2'b01: wea_byte = 4'b0010;
                    2'b10: wea_byte = 4'b0100;
                    2'b11: wea_byte = 4'b1000;
                endcase
            default: wea_byte = 4'b0;
        endcase
    end
    assign wea_mem = wea_byte;

    // ---------- 写数据对齐（外设地址时强制写0） ----------
    reg [31:0] data_to_dm;
    always @(*) begin
        if (!mem_w || is_peripheral)   // 外设地址时不输出有效写数据
            data_to_dm = 32'b0;
        else case (dm_ctrl)
            `dm_word:   data_to_dm = Data_write;
            `dm_halfword, `dm_halfword_unsigned:
                data_to_dm = addr_low[1] ? {Data_write[15:0], 16'b0} : {16'b0, Data_write[15:0]};
            `dm_byte, `dm_byte_unsigned:
                case (addr_low)
                    2'b00: data_to_dm = {24'b0, Data_write[7:0]};
                    2'b01: data_to_dm = {16'b0, Data_write[7:0], 8'b0};
                    2'b10: data_to_dm = {8'b0, Data_write[7:0], 16'b0};
                    2'b11: data_to_dm = {Data_write[7:0], 24'b0};
                endcase
            default: data_to_dm = 32'b0;
        endcase
    end
    assign Data_write_to_dm = data_to_dm;

    // ---------- 读数据扩展（外设地址时直接透传） ----------
    reg [31:0] read_data;
    always @(*) begin
        if (is_peripheral) begin
            // 外设数据已经是完整的32位，不需要扩展
            read_data = Data_read_from_dm;
        end else begin
            case (dm_ctrl)
                `dm_word:   read_data = Data_read_from_dm;
                `dm_halfword: begin
                    if (addr_low[1])
                        read_data = {{16{Data_read_from_dm[31]}}, Data_read_from_dm[31:16]};
                    else
                        read_data = {{16{Data_read_from_dm[15]}}, Data_read_from_dm[15:0]};
                end
                `dm_halfword_unsigned: begin
                    if (addr_low[1])
                        read_data = {16'b0, Data_read_from_dm[31:16]};
                    else
                        read_data = {16'b0, Data_read_from_dm[15:0]};
                end
                `dm_byte: begin
                    case (addr_low)
                        2'b00: read_data = {{24{Data_read_from_dm[7]}},  Data_read_from_dm[7:0]};
                        2'b01: read_data = {{24{Data_read_from_dm[15]}}, Data_read_from_dm[15:8]};
                        2'b10: read_data = {{24{Data_read_from_dm[23]}}, Data_read_from_dm[23:16]};
                        2'b11: read_data = {{24{Data_read_from_dm[31]}}, Data_read_from_dm[31:24]};
                    endcase
                end
                `dm_byte_unsigned: begin
                    case (addr_low)
                        2'b00: read_data = {24'b0, Data_read_from_dm[7:0]};
                        2'b01: read_data = {24'b0, Data_read_from_dm[15:8]};
                        2'b10: read_data = {24'b0, Data_read_from_dm[23:16]};
                        2'b11: read_data = {24'b0, Data_read_from_dm[31:24]};
                    endcase
                end
                default: read_data = 32'b0;
            endcase
        end
    end
    assign Data_read = read_data;

endmodule