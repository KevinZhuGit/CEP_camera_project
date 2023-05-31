`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2022 03:09:56 AM
// Design Name: 
// Module Name: DIGOTU_test
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


module DIGOUT_test(
		input wire clk,
		input wire rst,
		input wire RST_BAR_LTCHD,
		input wire ADC_DATA_VALID,
		output wire [17:1] DIGOUT 
    );
    
/* Instantitaion template
	DIGOUT_test u_DIGOUT_test(
		.clk			(clk),
		.rst			(rst),
		.RST_BAR_LTCHD	(RST_BAR_LTCHD),
		.ADC_DATA_VALID (ADC_DATA_VALID),
		.DIGOUT			(DIGOUT[17:1])
	);

*/
	reg[31:0] STREAM_VAR=0, ROWADD = 0;


	integer state;
	localparam S_idle 	= 32'b1 << 0;
	localparam S_start 	= 32'b1 << 1;
	localparam S_update = 32'b1 << 2;
	localparam S_end    = 32'b1 << 3;
	
	integer count_update = 0;
	
	always @(posedge clk) begin
		if(rst) begin
			state <= S_idle;
			STREAM_VAR <= 0;
			count_update <= 0;
			ROWADD       <= 0;
		end else begin
			case (state)
				S_idle: begin
					state 			<= RST_BAR_LTCHD ? S_idle 		: S_start;				
					ROWADD          <= RST_BAR_LTCHD ? ROWADD       : ROWADD + 1 ;
					STREAM_VAR 		<= ROWADD;
					count_update    <= 0;  
				end
				
				S_start: begin
					state 			<= ADC_DATA_VALID ? S_update : S_start;
					STREAM_VAR 		<= STREAM_VAR;					
					count_update    <= count_update ;  
				end

				S_update: begin
					state <= S_end;
					STREAM_VAR <= STREAM_VAR;
					count_update    <= count_update + 1;  
				end
				
				S_end: begin
					state 			<= ADC_DATA_VALID ?  S_end 	: (count_update==12 ? S_idle :S_start);
					STREAM_VAR[12:0]<= ADC_DATA_VALID ? STREAM_VAR : {1'b0, STREAM_VAR[12:1]};  
				end
				
				default: begin
				
				end
			endcase
		end
	end
	
	assign DIGOUT[17:1] = {17{STREAM_VAR[0]}};
    
endmodule
