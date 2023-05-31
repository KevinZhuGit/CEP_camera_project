`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2021 06:17:06 PM
// Design Name: 
// Module Name: divideSignal
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


module divideSignal(
    input wire [31:0] in,
    input wire [31:0] divider,
    output reg [31:0] out,
    input clk
    );

wire [31:0] divide_by_2_power_01; assign divide_by_2_power_01[31:0] = {32{divider[0]}} & {1'b0, in[31:1]};
wire [31:0] divide_by_2_power_02; assign divide_by_2_power_02[31:0] = {32{divider[1]}} & {2'b0, in[31:2]};
wire [31:0] divide_by_2_power_03; assign divide_by_2_power_03[31:0] = {32{divider[2]}} & {3'b0, in[31:3]};
wire [31:0] divide_by_2_power_04; assign divide_by_2_power_04[31:0] = {32{divider[3]}} & {4'b0, in[31:4]};
wire [31:0] divide_by_2_power_05; assign divide_by_2_power_05[31:0] = {32{divider[4]}} & {5'b0, in[31:5]};
wire [31:0] divide_by_2_power_06; assign divide_by_2_power_06[31:0] = {32{divider[5]}} & {6'b0, in[31:6]};
wire [31:0] divide_by_2_power_07; assign divide_by_2_power_07[31:0] = {32{divider[6]}} & {7'b0, in[31:7]};
wire [31:0] divide_by_2_power_08; assign divide_by_2_power_08[31:0] = {32{divider[7]}} & {8'b0, in[31:8]};
wire [31:0] divide_by_2_power_09; assign divide_by_2_power_09[31:0] = {32{divider[8]}} & {9'b0, in[31:9]};
wire [31:0] divide_by_2_power_10; assign divide_by_2_power_10[31:0] = {32{divider[9]}} & {10'b0, in[31:10]};

always @(posedge clk) begin
    out[31:0] <= divide_by_2_power_01[31:0]+divide_by_2_power_02[31:0]+divide_by_2_power_03[31:0]+divide_by_2_power_04[31:0]+divide_by_2_power_05[31:0]+divide_by_2_power_06[31:0]+divide_by_2_power_07[31:0]+divide_by_2_power_08[31:0]+divide_by_2_power_09[31:0]+divide_by_2_power_10; 
end    
    
endmodule
