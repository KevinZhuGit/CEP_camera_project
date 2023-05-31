`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2019 05:32:05 PM
// Design Name: 
// Module Name: ToFModGen
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
//<VALID>_______________________________________//____
//______|                                      //     |__________________
//      |         |<------PERIOD--->|
//      |         |______           |______
//      |<-DELAY->|-DUTY-|          |-DUTY-|    //
//CLKi____________|      |__________|      |___//_______________________

////
//ToFModGen dut(
//	.CLKIN(CLKIN),			// ip clock
//	.VALID(VALID),			// ip valid signal for clockout clkout = clkout*VALID
//	.PERIOD(PERIOD[31:0]),	// ip 32-bit period for clkout based on clkin
//	.CLKOUT(CLKOUT),		// OUTPUT CLOCK
//	.DUTY(DUTY[31:0]),		// ip 32-bit duty period for clkout
//	.DELAY(DELAY[31:0])		// ip 32-bit delay time for clkout
//);

module ToFModGen(
    input  wire CLKIN,
    input  wire VALID, 
    input  wire [31:0] PERIOD,
    
    output reg CLKOUT,
    input  wire [31:0] DUTY,
    input  wire [31:0] DELAY
    );
    
reg [31:0] counter1;  
reg [31:0] counter2;  
reg [31:0] counter3;  
    
    localparam s_idle = 4'b1;
    localparam s_delay = 4'b10;
    localparam s_high = 4'b100;
    localparam s_low = 4'b1000;
    
  
    
    reg [3:0] state;
    
    always@(posedge CLKIN) begin
    case(state)
   		s_idle: begin
   			state <= VALID ? (PERIOD==0 ? s_idle : (DELAY==0 ? (DUTY==0 ? s_low : s_high) : s_delay) ): s_idle;
   			counter1 <= 0;
   		end
   		s_delay: begin   		
   			state <= VALID ? (counter1 == DELAY-1 ? (DUTY == 0 ? s_low : s_high) : s_delay) 	: s_idle;
   			if(counter1 == DELAY-1)
   				counter1 <=0 ;
   			else
   				counter1 <= counter1 + 1;
   		end
   		s_high: begin
   			state <= VALID ? (counter1 == DUTY-1  ? s_low  : s_high)		: s_idle;
   			if(DUTY >= PERIOD)
   				counter1 <= 0;
   			else
   				counter1 <= counter1 + 1;
   		end
   		s_low: begin
   			state <= VALID ? (counter1 == PERIOD-1 ? s_high : s_low)		: s_idle;
   			if(DUTY == 0)
   				counter1 <= 0 ;
   			else if(counter1 == PERIOD-1)
   				counter1 <=0 ;
   			else
	   			counter1 <= counter1 + 1;
   		end
    	default: begin
    		state<= s_idle;
    	end
    endcase
    
    
    end
    
    always @(*) begin
    case(state)
    	s_idle: begin
    		CLKOUT <= 0;
    	end
    	s_delay: begin
    		CLKOUT <= 0;
    	end
    	s_high: begin
    		CLKOUT <= DUTY==0 ? 0 : 1;
    	end
    	s_low: begin
    		CLKOUT <= DUTY>=PERIOD-1 ? 1 : 0;
    	end
    	default : begin
    		CLKOUT <= 0;
    	end
    endcase
    end
    
    
endmodule
