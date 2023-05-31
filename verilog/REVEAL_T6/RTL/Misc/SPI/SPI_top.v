`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2019 08:31:17 PM
// Design Name: 
// Module Name: SPI_top
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

//****************INSTANTIATION TEMPLATE****************
/*
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
*/

module SPI_top(
    input wire clk,             //input:    reference clock                        
    input wire [31:0] DIN,      //input:    {DATA{15:0},6'b0,CPOL,CPHA,target[7:0]}
    output wire [31:0] DOUT,    //output:   {DESERIALIZED DATA FROM SPI_DOUT}      
    input wire trigger,         //input:    {trigger to start the SPI}             
    output wire SPI_CLK,        //output:   based on CPOL,CPHA information of DIN  
    output wire SPI_DIN,        //output:   based on DATA information of DIN       
    output wire [7:0] TARGET,   //output:   based on target information of DIN     
    input wire SPI_DOUT         //input:    input to the FPGA from SPI slaves      
    );

    wire CPOL, CPHA;
    wire [7:0] target_in;
    wire [15:0] spi_word;
    wire LOAD_n;
    wire ser_trigger, ser_reset;
    
    
    // This serializer control and serializer is not good. It does not work with CPOL and CPHA
    serializer_ctrl ctrl_inst(                //Generates control signals based on CPOL and CPHA values for spi_serializer
        .clk(clk),                  
        .trigger_in(trigger),
        .trigger_out(ser_trigger),
        .reset_out(ser_reset)
    );     
    
    assign spi_word[15:0] = DIN[31:16];
    assign target_in[7:0] = DIN[7:0]; 
     //board level SPI serializer
     serializer ser_inst(
        .CLK100MHZ(clk),
        .enable(ser_trigger),
        .Reset(ser_reset),
        .DATA(spi_word[15:0]),
        .SRI(SPI_DIN),
        .CLK(SPI_CLK),
        .LD_n(LOAD_n));    
        

    assign TARGET[7:0] = ~({8{~LOAD_n}} & target_in[7:0]);

endmodule
