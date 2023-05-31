`timescale 1ns / 1ps

/*--------------------------------------------------
	Project:	T5 ToF CEP Camera
	Module:		Readout
	Description:	Timing state machine for reading out pixels on ToF sensor.
			v5 has switching of pga signals internally
---------------------------------------------------*/

module Readout_v5(
	input CLK,
	input rst,

	input PGA_en,
	
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
	input wire [31:0] T7,
	input wire [31:0] T8,
	input wire [31:0] T9,
	input wire [31:0] T10,
	input wire [31:0] T11,
	input wire [31:0] T12,
	input wire [31:0] T13,
	input wire [31:0] T14,

	input wire [31:0] NL,
	input wire [31:0] NR,

	input wire [31:0] NUM_ROW
	);

	//internal timers
	integer timer;		//count clock cycles for timing
	integer fastTimer;
	integer ph1_fastTimer;

	integer N_count;

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
	always @(posedge adc1_out_clk) adc1_dly <= {adc1_dly[30:0],adc_rd};
	always @(posedge adc2_out_clk) adc2_dly <= {adc2_dly[30:0],adc_rd};
	always @(*) begin
		case(Tlat1) 
			32'd21: adc1_dat_valid = adc1_dly[20];
			32'd22: adc1_dat_valid = adc1_dly[21];
			32'd23: adc1_dat_valid = adc1_dly[22];
			32'd24: adc1_dat_valid = adc1_dly[23];
			32'd25: adc1_dat_valid = adc1_dly[24];
			32'd26: adc1_dat_valid = adc1_dly[25];
			default: adc1_dat_valid = adc1_dly[0];
		endcase
		case(Tlat2) 
			32'd21: adc2_dat_valid = adc2_dly[20];
			32'd22: adc2_dat_valid = adc2_dly[21];
			32'd23: adc2_dat_valid = adc2_dly[22];
			32'd24: adc2_dat_valid = adc2_dly[23];
			32'd25: adc2_dat_valid = adc2_dly[24];
			32'd26: adc2_dat_valid = adc2_dly[25];
			default: adc2_dat_valid = adc2_dly[0];
		endcase
	end

	always @(posedge adc_clk) trigger_i <= trigger;


	reg [31:0] dly_cnt;
	//handshaking state machine----------------------------------------------
	always @(posedge CLK) begin
		if (rst) begin
 			HS_state <= HS_idle;
			re_busy <= 1'b0;
			trig_start <= 1'b0;
			dly_cnt <= T5>>1;
		end else begin
			case (HS_state)
				HS_idle: begin
					re_busy <= 1'b0;

					if(trigger_i) begin
						if(dly_cnt==0) begin
							trig_start <= 1'b1;
							HS_state <= HS_start;
						end else begin
							dly_cnt <= dly_cnt - 1;
						end
					end
				end

				HS_start: begin
					dly_cnt <= T5>>1;
					re_busy <= 1'b1;
					trig_start <= 1'b0;

					if (done_ro) begin
						HS_state <= HS_idle;
					end

				end

				default: begin
					HS_state <= HS_idle;
					dly_cnt <= T5>>1;
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
			fastTimer <= 0;
			ph1_fastTimer <= 0;
			N_count <= 0;
		end else begin
			case (RO_state)
				RO_idle: begin
					done_ro <= 1'b0;
					ROWADD <= 0;

					if (trig_start) begin
						timer <= 0;
						fastTimer <= 0;
						ph1_fastTimer <= 0;
						N_count <= 0;

						RO_state <= RO_LB;
					end else begin
						timer <= timer + 1;
					end
				end
				RO_LB: begin
					if (timer >= T2-1) begin
						timer <= 0;
						fastTimer <= 0;
						ph1_fastTimer <= 0;
						N_count <= 0;

						RO_state <= RO_RB;
					end else begin
						timer <= timer + 1;

						//cp_mux_in
						if (timer >= T5) begin
							if (fastTimer >= T6-1) fastTimer <= 0;
							else fastTimer <= fastTimer + 1;
						end else begin
							fastTimer <= 0;
						end

						//ph1
						if (timer >= T11) begin
							if (ph1_fastTimer >= T12-1) begin
								ph1_fastTimer <= 0;
								N_count <= N_count + 1;
							end
							else ph1_fastTimer <= ph1_fastTimer + 1;
						end else begin
							ph1_fastTimer <= 0;
						end
					end
				end
				RO_RB: begin
					if (timer >= T2-1) begin
						timer <= 0;
						fastTimer <= 0;
						ph1_fastTimer <= 0;
						N_count <= 0;

						ROWADD <= ROWADD + 1;

						if (ROWADD == NUM_ROW - 1) begin
							RO_state <= RO_idle;
							done_ro <= 1'b1;
						end else begin
							RO_state <= RO_LB;
						end

					end else begin
						timer <= timer + 1;

						//cp_mux_in
						if (timer >= T5) begin
							if (fastTimer >= T6-1) fastTimer <= 0;
							else fastTimer <= fastTimer + 1;
						end else begin
							fastTimer <= 0;
						end

						//ph1
						if (timer >= T11) begin
							if (ph1_fastTimer >= T12-1) begin
								ph1_fastTimer <= 0;
								N_count <= N_count + 1;
							end
							else ph1_fastTimer <= ph1_fastTimer + 1;
						end else begin
							ph1_fastTimer <= 0;
						end
					end


				end
				default: begin
					RO_state <= RO_idle;
					timer <= 0;
					fastTimer <= 0;
					ph1_fastTimer <= 0;
					N_count <= 0;
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
				CP_MUX_IN	= (timer >= T5) && (fastTimer < T6/2) ? 1'b1 : 1'b0;
				MUX_START	= (timer < T4) ? 1'b1 : 1'b0;

				COL_L_EN	= 1'b1;

				PIXRES		= (PGA_en) && (timer >= T9) && (timer < T9+T10) ? 1'b1: 1'b0;
				PH1		= (PGA_en) && (timer >= T11) && (ph1_fastTimer < T12/2) && (N_count < NL) ? 1'b1 : 1'b0;
				PGA_RES		= (PGA_en) && ((timer < T11) || ((timer >= T9) && (timer < T9+T11))) ? 1'b1: 1'b0;
				SAMP_S		= (PGA_en) && (timer >= T13) && (timer < T13+T14) ? 1'b1 : 1'b0;
				SAMP_R		= (PGA_en) && (timer >= T9+T13) && (timer < T9+T13+T14) ? 1'b1: 1'b0;
				READ_R		= (PGA_en) && (timer >= T5) && (fastTimer < T7) ? 1'b1: 1'b0;
				READ_S		= (PGA_en) && (timer >= T5) && (fastTimer >= T8) ? 1'b1: 1'b0;
				adc_rd		= (timer >= T5)? 1'b1 : 1'b0;


			end

			RO_RB: begin
				COL_PRECH	= (timer < T3) ? 1'b1 : 1'b0;
				CP_MUX_IN	= (timer >= T5) && (fastTimer < T6/2) ? 1'b1 : 1'b0;
				MUX_START	= (timer < T4) ? 1'b1 : 1'b0;

				COL_L_EN	= 1'b0;

				PIXRES		= (PGA_en) && (timer >= T9) && (timer < T9+T10) ? 1'b1: 1'b0;
				PH1		= (PGA_en) && (timer >= T11) && (ph1_fastTimer < T12/2) && (N_count < NR) ? 1'b1 : 1'b0;
				PGA_RES		= (PGA_en) && ((timer < T11) || ((timer >= T9) && (timer < T9+T11))) ? 1'b1: 1'b0;
				SAMP_S		= (PGA_en) && (timer >= T13) && (timer < T13+T14) ? 1'b1 : 1'b0;
				SAMP_R		= (PGA_en) && (timer >= T9+T13) && (timer < T9+T13+T14) ? 1'b1: 1'b0;
				READ_R		= (PGA_en) && (timer >= T5) && (fastTimer < T7) ? 1'b1: 1'b0;
				READ_S		= (PGA_en) && (timer >= T5) && (fastTimer >= T8) ? 1'b1: 1'b0;
				adc_rd		= (timer >= T5)? 1'b1 : 1'b0;
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

