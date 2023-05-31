`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2019 06:01:34 PM
// Design Name: 
// Module Name: tb_ToFModGen
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


module tb_ToFModGen(

    );
    
    
    reg clk100 = 0;
    always #5 clk100 <= ~clk100;
	
	wire out1;
	reg valid;
    ToFModGen dut(
    .CLKIN(clk100),
    .PERIOD(10),
    .VALID(valid),
    .CLKOUT(out1),
    .DELAY(5),
    .DUTY(0));

	initial begin
		valid = 0;
	#10 valid = 1;
	#3000 valid = 0;	
	end        
        
endmodule
