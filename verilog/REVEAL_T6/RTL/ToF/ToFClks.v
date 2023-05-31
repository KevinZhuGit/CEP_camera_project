`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rahul Gulve
// 
// Create Date: 10/10/2019 06:52:29 PM
// Design Name: 
// Module Name: ToFClks
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Provide 8 bit DELAY DUTY settings for 3 clocks separately.
//              Delay is calculated based on synchronised positive edge of VALID signal
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//<VALID>_______________________________________//____
//______|                                      //     |__________________
//      |         |<------PERIOD--->|
//      |         |______           |______
//      |<-DELAY->|-DUTY-|          |-DUTY-|    //
//CLKi____________|      |__________|      |___//_______________________

/* 
ToFClks DUT(
	.CLKIN(clk),
	.VALID(valid),
	.PERIOD(PERIOD),
	
	.CLKOUT1(out1),		// output clock-1 with duty1 and period1
	.DUTY1(DUTY1),		// DUTY1[7:0]
	.DELAY1(DELAY1),    // DELAY[7:0]
	
	.CLKOUT2(out2),
	.DUTY2(DUTY2),
	.DELAY2(DELAY2),

	.CLKOUT3(out3),
	.DUTY3(DUTY3),
	.DELAY3(DELAY3)
);
*/
module ToFClks(
    input  wire CLKIN,
	input  wire VALID, 
	input  wire [31:0] PERIOD,
	
	output wire CLKOUT1,
	input  wire [31:0] DUTY1,
	input  wire [31:0] DELAY1,

	output wire CLKOUT2,
	input  wire [31:0] DUTY2,
	input  wire [31:0] DELAY2,

	output wire CLKOUT3,
	input  wire [31:0] DUTY3,
	input  wire [31:0] DELAY3
    );
    
    ToFModGen clk1 (
    	.CLKIN(CLKIN),
    	.VALID(VALID),
    	.PERIOD(PERIOD),
    	.CLKOUT(CLKOUT1),
    	.DUTY(DUTY1),
    	.DELAY(DELAY1)
    );
    
    ToFModGen clk2 (
    	.CLKIN(CLKIN),
    	.VALID(VALID),
    	.PERIOD(PERIOD),
    	.CLKOUT(CLKOUT2),
    	.DUTY(DUTY2),
    	.DELAY(DELAY2)
    );

    ToFModGen clk3 (
    	.CLKIN(CLKIN),
    	.VALID(VALID),
    	.PERIOD(PERIOD),
    	.CLKOUT(CLKOUT3),
    	.DUTY(DUTY3),
    	.DELAY(DELAY3)
    );
    
endmodule
