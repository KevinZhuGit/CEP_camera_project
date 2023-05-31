`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2019 06:53:41 PM
// Design Name: 
// Module Name: tb_SPI_TOP
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


module tb_SPI_TOP(

    );

reg clk, trigger, SPI_DOUT;
reg [31:0] DIN;
wire [31:0] DOUT;
wire SPI_CLK, SPI_DIN;
wire [7:0] TARGET;

initial begin
    clk = 0;
    trigger = 0;
    DIN = 32'hA50FF0F8;
    #20 trigger = 1;
    #1700  trigger = 0;
end


SPI_top dut(
    .clk(clk),              //input:    reference clock
    .DIN(DIN[31:0]),        //input:    {DATA{15:0},6'b0,CPOL,CPHA,target[7:0]}
    .DOUT(DOUT[31:0]),      //output:   {DESERIALIZED DATA FROM SPI_DOUT}
    .trigger(trigger),      //input:    {trigger to start the SPI}
    .SPI_CLK(SPI_CLK),      //output:   based on CPOL,CPHA information of DIN
    .SPI_DIN(SPI_DIN),      //output:   based on DATA information of DIN
    .TARGET(TARGET[7:0]),   //output:   based on target information of DIN
    .SPI_DOUT(SPI_DOUT)     //input:    input to the FPGA from SPI slaves
);

always
    #0.5 clk <= ~clk;

endmodule
