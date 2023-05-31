`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 10:07:24 AM
// Design Name: 
// Module Name: wait_counter
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
//////////////////////////////////////////////////////////////////////////////////
module wait_counter(enable,clk,trigger);
	 input wire enable;
	 input wire clk;
	 output reg trigger;
	 reg [6:0]counter;
	 
	 initial counter = 7'b0;
	 initial trigger = 0;
	 always@(negedge clk)begin
		if(enable)begin
			if(counter < 7'd30)begin
				trigger <= 0;
				counter <= counter + 1'b1;
			end
			else begin
				counter <= 7'b0;
				trigger <= 1;
			end
		end
		else begin
			counter <= 7'b0;
			trigger <= 0;
		end
	 end


endmodule
