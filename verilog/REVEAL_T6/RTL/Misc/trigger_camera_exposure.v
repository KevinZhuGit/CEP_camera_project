`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2022 09:56:50 PM
// Design Name: 
// Module Name: top_handshake
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
/* Instantiation template
trigger_camera_exposure exposure_handshake(
		.rst(rst),							//ip
		.clk(clk),							//ip
		.re_busy(re_busy),					//ip			
		.dram_flag(dram_flag),				//ip
		.external_trigger(external_trigger),//ip
		.slave_mode(slave_mode),			//ip

		.exp_trigger(exp_trigger)			//op
    );
*/

module trigger_camera_exposure(
		input  wire rst,
		input  wire clk,
		input  wire re_busy,
		input  wire dram_flag,
		input  wire external_trigger,
		input  wire slave_mode,

		output reg  exp_trigger
    );

	integer state_t, delay_cnt;
	localparam S_0=0;
	localparam S_1=1;
	localparam S_2=2;
	localparam S_3=3;
	localparam S_4=4;
	
	always @(posedge clk) begin
		if(rst) begin
			state_t <= S_0;
			exp_trigger <= 1;
			delay_cnt <= 1;
		end else begin
	
			case(state_t)
				S_0: begin // ready for exposure
					if(~dram_flag) begin // wait to finish the readout and image transfer from DRAM to PC
						delay_cnt <= delay_cnt - 1;
						if(delay_cnt==0) begin
							if(slave_mode)
								state_t <= S_1;
							else
								state_t <= S_2;
						end
					end
				end
				S_1: begin // trigger exposure 
					// in salve mode wait for external camera trigger
					state_t <= external_trigger ? S_2 : S_1;
				end 
				S_2: begin    // in master mode jump to this and just wait for readout to start
					exp_trigger <= 0;
					if(re_busy) begin
						exp_trigger <= 1;
						state_t <= S_0;
						delay_cnt <= 1;
					end
				end 
				default: begin
					state_t <= S_0;
				end
			endcase
		end
	end
	
endmodule
