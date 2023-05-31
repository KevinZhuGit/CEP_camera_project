`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2019 06:23:27 PM
// Design Name: 
// Module Name: tb_syntax
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


module tb_syntax(

    );

wire [16:1] mSTREAM;
wire [9:0] ROWADD;
reg clk_400;
wire [31:0] dout;    
    counter #(.N(32))dut_counter(
    .clk(clk_400),
    .dout(dout));

assign mSTREAM[16:1] = {16{dout[0]}};
assign ROWADD[9:0] = {{5{dout[5]}},dout[4:0]};

initial begin
    clk_400 <= 0;
end

always
    #0.5 clk_400 <= ~clk_400;

endmodule
