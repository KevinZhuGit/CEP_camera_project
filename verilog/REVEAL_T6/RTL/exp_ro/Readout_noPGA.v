`timescale 1ns / 1ps

module Readout_noPGA(
	input CLK,
	input rst,
	
	input wire adc_clk,
	input wire adc1_out_clk,
	input wire adc2_out_clk,

	input wire [31:0] Tlat1,
	input wire [31:0] Tlat2,
	output reg adc1_dat_valid,
	output reg adc2_dat_valid,

	output reg [9:0] ROWADD,

	//handshaking signals
	input wire trigger,
	output reg re_busy,

	//output signals
	output reg COL_L_EN,
	output reg COL_PRECH,
	output reg CP_MUX_IN,
	output reg MUX_START,
	output reg PIXRES,
	output reg PH1,
	output reg PGA_RES,
	output reg SAMP_R,
	output reg SAMP_S,
	output reg READ_R,
	output reg READ_S,

	//timing delay parameters
	input wire [31:0] T1,
	input wire [31:0] T2,
	input wire [31:0] T3,
	input wire [31:0] T4,
	input wire [31:0] T5,
	input wire [31:0] T6,

	//input wire [31:0] T_stdby,

	input wire [31:0] NUM_ROW
	);

	//internal timers
	integer timer;		//count clock cycles for timing
	integer delayTimer;
	integer fastTimer;

	//handshaking registers
	reg done_ro;		//trigger handshaking state change after done readout
	reg trig_start;		//trigger readout start from handshaking state machine
	reg trigger_i;
	reg adc_rd;		//adc read signal
	reg [31:0] adc1_dly;
	reg [31:0] adc2_dly;

	integer HS_state;	//handshaking state
	integer RO_state;	//readout state

	//handshaking states
	localparam HS_idle 		= 3'b001;
	localparam HS_start		= 3'b010;

	//TODO control signal states
	localparam RO_idle 		= 9'b1;
	localparam RO_LB		= 9'b10;
	localparam RO_RB		= 9'b100;

	initial begin
		ROWADD		= 1'b0;

		re_busy 	= 1'b0;

		COL_L_EN	= 1'b0;
		COL_PRECH	= 1'b0;
		CP_MUX_IN	= 1'b0;
		MUX_START	= 1'b0;
		PIXRES		= 1'b0;
		PH1	    	= 1'b0;
		PGA_RES		= 1'b0;
		SAMP_R		= 1'b0;
		SAMP_S		= 1'b0;
		READ_R		= 1'b0;
		READ_S		= 1'b0;
		adc1_dly   = 0;
		adc2_dly   = 0;
	end

	// configurable delay
	reg adc_rd_i;
	always @(posedge adc1_out_clk) adc1_dly <= {adc1_dly[30:0],adc_rd};
	always @(posedge adc2_out_clk) adc2_dly <= {adc2_dly[30:0],adc_rd};

	//always @(posedge adc_clk) adc_rd_i <= adc_rd;

	always @(*) begin
		case(Tlat1) 
			32'd21: adc1_dat_valid = adc1_dly[20];
			32'd22: adc1_dat_valid = adc1_dly[21];
			32'd23: adc1_dat_valid = adc1_dly[22];
			32'd24: adc1_dat_valid = adc1_dly[23];
			32'd25: adc1_dat_valid = adc1_dly[24];
			32'd26: adc1_dat_valid = adc1_dly[25];
			32'd27: adc1_dat_valid = adc1_dly[26];
			32'd28: adc1_dat_valid = adc1_dly[27];
			32'd29: adc1_dat_valid = adc1_dly[28];
			32'd30: adc1_dat_valid = adc1_dly[29];
			32'd31: adc1_dat_valid = adc1_dly[30];
			32'd32: adc1_dat_valid = adc1_dly[31];
			default: adc1_dat_valid = adc1_dly[0];
		endcase
		case(Tlat2) 
			32'd21: adc2_dat_valid = adc2_dly[20];
			32'd22: adc2_dat_valid = adc2_dly[21];
			32'd23: adc2_dat_valid = adc2_dly[22];
			32'd24: adc2_dat_valid = adc2_dly[23];
			32'd25: adc2_dat_valid = adc2_dly[24];
			32'd26: adc2_dat_valid = adc2_dly[25];
			32'd27: adc1_dat_valid = adc2_dly[26];
			32'd28: adc1_dat_valid = adc2_dly[27];
			32'd29: adc1_dat_valid = adc2_dly[28];
			32'd30: adc1_dat_valid = adc2_dly[29];
			32'd31: adc1_dat_valid = adc2_dly[30];
			32'd32: adc1_dat_valid = adc2_dly[31];
			default: adc2_dat_valid = adc2_dly[0];
		endcase
	end

	// sync with adc in clock
	always @(posedge adc_clk) trigger_i <= trigger;


	reg [31:0] dly_cnt;
	//handshaking state machine----------------------------------------------
	always @(posedge CLK) begin
		if (rst) begin
 			HS_state <= HS_idle;
			re_busy <= 1'b0;
			trig_start <= 1'b0;
			dly_cnt <= 25;
		end else begin
			case (HS_state)
				HS_idle: begin
					re_busy <= 1'b0;

					if(trigger_i) begin
						if(dly_cnt==10) begin
							trig_start <= 1'b1;
							HS_state <= HS_start;
						end else begin
							dly_cnt <= dly_cnt - 1;
						end
					end
				end

				HS_start: begin
					dly_cnt <= 25;
					re_busy <= 1'b1;
					trig_start <= 1'b0;

					if (done_ro) begin
						HS_state <= HS_idle;
					end

				end

				default: begin
					HS_state <= HS_idle;
					dly_cnt <= 25;
					trig_start <= 1'b0;
				end
			endcase
		end
	end

	//state control machine----------------------------------------------
	always @(posedge CLK) begin
		if (rst) begin
			RO_state <= RO_idle;
			timer <= 0;
			delayTimer <= 0;
			fastTimer <= 0;
		end else begin
			case (RO_state)
				RO_idle: begin
					done_ro <= 1'b0;
					ROWADD <= 0;

					if (trig_start) begin
						timer <= 0;
						delayTimer <= 0;
						fastTimer <= 0;

						RO_state <= RO_LB;
					end else begin
						timer <= timer + 1;
					end
				end
				RO_LB: begin
					if (timer >= T2-1) begin
						timer <= 0;
						delayTimer <= 0;
						fastTimer <= 0;
						
						RO_state <= RO_RB;
					end else begin
						timer <= timer + 1;
					end

					if (delayTimer >= T5) begin
						if (fastTimer >= T6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

				end
				RO_RB: begin
					if (timer >= T2-1) begin
						timer <= 0;
						delayTimer <= 0;
						fastTimer <= 0;

						ROWADD <= ROWADD + 1;

						if (ROWADD == NUM_ROW - 1) begin
							RO_state <= RO_idle;
							done_ro <= 1'b1;
						end else RO_state <= RO_LB;

					end else begin
						timer <= timer + 1;
					end

					if (delayTimer >= T5) begin
						if (fastTimer >= T6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end
				end
				default: begin
					RO_state <= RO_idle;
					timer <= 0;
					fastTimer <= 0;
				end
			endcase
		end
	end

	//signal generation----------------------------------------------
	always @(*) begin
			case (RO_state)
				RO_idle: begin
					COL_L_EN	= 1'b0;
					COL_PRECH	= 1'b0;
					CP_MUX_IN	= 1'b0;
					MUX_START	= 1'b0;
					PIXRES		= 1'b0;
					PH1				= 1'b0;
					PGA_RES		= 1'b0;
					SAMP_R		= 1'b0;
					SAMP_S		= 1'b0;
					READ_R		= 1'b0;
					READ_S		= 1'b0;
					adc_rd		= 1'b0;
				end

				RO_LB: begin
					COL_PRECH	= (timer < T3) ? 1'b1 : 1'b0;
					CP_MUX_IN	= (delayTimer >= T5) && (fastTimer < T6/2) ? 1'b1 : 1'b0;
					MUX_START	= (timer < T4) ? 1'b1 : 1'b0;

					COL_L_EN	= 1'b1;
					PIXRES		= 1'b0;
					PH1				= 1'b0;
					PGA_RES		= 1'b0;
					SAMP_R		= 1'b0;
					SAMP_S		= 1'b0;
					READ_R		= 1'b0;
					READ_S		= 1'b0;
					//adc_rd		= (ROWADD==0)? ((delayTimer >= T4)? 1'b1 : 1'b0):1'b1;
					adc_rd		= (delayTimer >= T5-T6)? 1'b1 : 1'b0;
					//adc_rd		= (delayTimer >= T5)? 1'b1 : 1'b0;


				end

				RO_RB: begin
					COL_PRECH	= (timer < T3) ? 1'b1 : 1'b0;
					CP_MUX_IN	= (delayTimer >= T5) && (fastTimer < T6/2) ? 1'b1 : 1'b0;
					MUX_START	= (timer < T4) ? 1'b1 : 1'b0;

					COL_L_EN	= 1'b0;
					PIXRES		= 1'b0;
					PH1				= 1'b0;
					PGA_RES		= 1'b0;
					SAMP_R		= 1'b0;
					SAMP_S		= 1'b0;
					READ_R		= 1'b0;
					READ_S		= 1'b0;
					//adc_rd		= (delayTimer >= T4)? 1'b1 : 1'b0;
					adc_rd		= (delayTimer >= T5-T6)? 1'b1 : 1'b0;
					//adc_rd		= (delayTimer >= T5)? 1'b1 : 1'b0;
					//adc_rd		= 1'b1;
				end
				default: begin
					COL_L_EN	= 1'b0;
					COL_PRECH	= 1'b0;
					CP_MUX_IN	= 1'b0;
					MUX_START	= 1'b0;
					PIXRES		= 1'b0;
					PH1				= 1'b0;
					PGA_RES		= 1'b0;
					SAMP_R		= 1'b0;
					SAMP_S		= 1'b0;
					READ_R		= 1'b0;
					READ_S		= 1'b0;
					adc_rd		= 1'b0;
				end
			endcase
	end

endmodule
