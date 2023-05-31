`timescale 1ns / 1ps

/*--------------------------------------------------
	Project:	T5 ToF CEP Camera
	Module:		Readout
	Description:	Timing state machine for reading out pixels on ToF sensor
---------------------------------------------------*/

/*
TODO to note:
	ROWADD, external ROWADD or nah?
*/

module Readout_v1(
	input CLK,
	input rst,
	
	output reg [9:0] ROWADD,

	//handshaking signals
	input wire trigger_i,
	output reg re_busy,

	//output signals
	output reg COL_L_EN,
	output reg PIXRES_L,
	output reg PIXRES_R,
	output reg STDBY,
	output reg PRECH_COL,
	output reg PGA_RES,
	output reg CK_PH1,
	output reg SAMP_S,
	output reg SAMP_R,
	
	output reg READ_R,
	output reg READ_S,
	output reg MUX_START,
	output reg CP_COLMUX_IN,

	//timing delay parameters
	input wire [31:0] T1,
	input wire [31:0] T2,
	input wire [31:0] T3,
	input wire [31:0] T4,
	input wire [31:0] T5L,
	input wire [31:0] T5R,
	input wire [31:0] T6,
	input wire [31:0] T7,
	input wire [31:0] T8,
	input wire [31:0] T9,
	input wire [31:0] T10,
	
	input wire [31:0] T5_5,
	input wire [31:0] T5_6,

	input wire [31:0] T_ROW, //TODO don't think I need this but I'll leave this here
	input wire [31:0] T_PIX,
	input wire [31:0] NUM_SAMPL,
	input wire [31:0] NUM_SAMPR,

	input wire [31:0] NUM_ROW
	);

	parameter NUM_COL = 48;	//rows in output image

	//read timing
	integer READ_TIME_L; initial READ_TIME_L = 2*(T4 + NUM_SAMPR*T5R);
	integer READ_TIME_R; initial READ_TIME_R = 2*(T4 + NUM_SAMPL*T5L);

	//TODO internal registers required
	integer timer;		//count clock cycles for timing
	integer readTimer;
	integer delayTimer;
	integer fastTimer;
	integer	PH1_delayTimer;
	integer	PH1_fastTimer;

	integer	readR_fastTimer;

	//handshaking registers
	reg done_ro;		//trigger handshaking state change after done readout
	reg trig_start;		//trigger readout start from handshaking state machine

	integer HS_state;	//handshaking state
	integer RO_state;	//readout state
	
	//handshaking states
	localparam HS_idle 		= 3'b001;
	localparam HS_start		= 3'b010;
	
	//TODO control signal states
	localparam RO_idle 		= 9'b1;
	localparam RO_start		= 9'b10;
	localparam RO_signal_L_first	= 9'b100;
	localparam RO_reset_L_first	= 9'b1000;
	localparam RO_signal_L		= 9'b10000;
	localparam RO_reset_L		= 9'b100000;
	localparam RO_signal_R		= 9'b1000000;
	localparam RO_reset_R		= 9'b10000000;
	localparam RO_read_last		= 9'b100000000;

	//set all signals to initial state	
	initial begin
		ROWADD		= 0;

		re_busy		= 1'b0;	
	
		COL_L_EN	= 1'b0;
		PIXRES_L	= 1'b0;
		PIXRES_R	= 1'b0;
		STDBY		= 1'b1;
		PRECH_COL	= 1'b0;
		PGA_RES		= 1'b0;
		CK_PH1		= 1'b0;
		SAMP_S		= 1'b0;
		SAMP_R		= 1'b0;
		
		READ_R		= 1'b0;
		READ_S		= 1'b0;
		MUX_START	= 1'b0;
		CP_COLMUX_IN	= 1'b0;
	end


	//handshaking state machine----------------------------------------------
	always @(posedge CLK) begin
		if (rst) begin
 			HS_state <= HS_idle;
			re_busy <= 1'b0;
			trig_start <= 1'b0;
		end else begin
			case (HS_state)
				HS_idle: begin
					re_busy <= 1'b0;				

					if(trigger_i) begin
						HS_state <= HS_start;
						
						trig_start <= 1'b1; 
					end
				end

				HS_start: begin
					re_busy <= 1'b1;				
					trig_start <= 1'b0;
					
					if (done_ro) begin
						HS_state <= HS_idle;
					end

				end

				default: begin
					HS_state <= HS_idle;
				end
			endcase
		end
	end

	//state control machine----------------------------------------------

	//timer note - on CLK, >= delay-1 
	always @(posedge CLK) begin
		if (rst) begin
			RO_state <= RO_idle;
			timer <= 0; 
			readTimer <= 0; 
			delayTimer <= 0;
			fastTimer <= 0;
			PH1_delayTimer <= 0;
			PH1_fastTimer <= 0;
			readR_fastTimer <= 0;
		end else begin
			//timer = timer + 1;
			//readTimer = readTimer + 1;
			case (RO_state)
				RO_idle: begin
					done_ro <= 1'b0;	
					ROWADD <= 0;

					timer <= 0;
					readTimer <= 0;
					fastTimer <= 0;
					delayTimer<= 0;

					//readTimer <= readTimer + 1;
					
					if (trig_start) begin
						timer <= 0; 
						RO_state <= RO_start;
					end else begin
						timer <= timer + 1;
					end
				end
			
				RO_start: begin

					readTimer <= readTimer + 1;

					if (timer >= T2-1) begin 
						timer <= 0;
						readTimer <= 0;
						fastTimer <= 0;
						delayTimer<= 0;
						PH1_delayTimer <= 0;
						PH1_fastTimer <= 0;
						readR_fastTimer <= 0;
						
						RO_state <= RO_signal_L;
					end else begin
						timer <= timer + 1;
					end

				end

				RO_signal_L_first: begin

					readTimer <= readTimer + 1;

					if (timer >= (T4 + T5L*NUM_SAMPL)-1) begin
						timer <= 0;
						RO_state <= RO_reset_L_first;
					end else begin
						timer <= timer + 1;
					end

					if (PH1_delayTimer >= T4) begin
						if (PH1_fastTimer >= T5L-1) begin
							PH1_fastTimer <= 0;
						end else begin
							PH1_fastTimer <= PH1_fastTimer + 1;
						end
					end else begin
						PH1_delayTimer <= PH1_delayTimer + 1;
						PH1_fastTimer <= 0;
					end

				end

				RO_reset_L_first: begin

					if (timer >= (T4 + T5L*NUM_SAMPL)-1) begin
						timer <= 0;
						readTimer <= 0;
						PH1_delayTimer <= 0;
						PH1_fastTimer <= 0;
						readR_fastTimer <= 0;
						RO_state <= RO_signal_R;
					end else begin
						timer <= timer + 1;
						readTimer <= readTimer + 1;

						if (PH1_delayTimer >= T4) begin
							if (PH1_fastTimer >= T5L-1) begin
								PH1_fastTimer <= 0;
							end else begin
								PH1_fastTimer <= PH1_fastTimer + 1;
							end
						end else begin
							PH1_delayTimer <= PH1_delayTimer + 1;
							PH1_fastTimer <= 0;
						end
					end


				end

				RO_signal_L: begin

					readTimer <= readTimer + 1;

					if (timer >= (T4 + T5L*NUM_SAMPL)-1) begin
						timer <= 0;
						RO_state <= RO_reset_L;
					end else begin
						timer <= timer + 1;

					end

					if (delayTimer >= T5_5) begin
						if (fastTimer >= T5_6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

					if (PH1_delayTimer >= T4) begin
						if (PH1_fastTimer >= T5L-1) begin
							PH1_fastTimer <= 0;
						end else begin
							PH1_fastTimer <= PH1_fastTimer + 1;
						end
					end else begin
						PH1_delayTimer <= PH1_delayTimer + 1;
						PH1_fastTimer <= 0;
					end

					if (readR_fastTimer >= 2*T8+2*T7-1) begin
						readR_fastTimer <= 0;
					end else begin
						readR_fastTimer <= readR_fastTimer + 1;
					end
				end

				RO_reset_L: begin
					if (timer >= (T4 + T5L*NUM_SAMPL)-1) begin
						timer <= 0;
						readTimer <= 0;
						fastTimer <= 0;
						delayTimer<= 0;
						PH1_delayTimer <= 0;
						PH1_fastTimer <= 0;
						readR_fastTimer <= 0;
						
						RO_state <= RO_signal_R;
					end else begin
						timer <= timer + 1;
						readTimer <= readTimer + 1;

					end

					if (delayTimer >= T5_5) begin
						if (fastTimer >= T5_6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

					if (PH1_delayTimer >= T4) begin
						if (PH1_fastTimer >= T5L-1) begin
							PH1_fastTimer <= 0;
						end else begin
							PH1_fastTimer <= PH1_fastTimer + 1;
						end
					end else begin
						PH1_delayTimer <= PH1_delayTimer + 1;
						PH1_fastTimer <= 0;
					end

					if (readR_fastTimer >= 2*T8+2*T7-1) begin
						readR_fastTimer <= 0;
					end else begin
						readR_fastTimer <= readR_fastTimer + 1;
					end
				end
				RO_signal_R: begin

					readTimer <= readTimer + 1;

					if (timer >= (T4 + T5R*NUM_SAMPR)-1) begin
						timer <= 0;
						RO_state <= RO_reset_R;
					end else begin
						timer <= timer + 1;

					end

					if (delayTimer >= T5_5) begin
						if (fastTimer >= T5_6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

					if (PH1_delayTimer >= T4) begin
						if (PH1_fastTimer >= T5R-1) begin
							PH1_fastTimer <= 0;
						end else begin
							PH1_fastTimer <= PH1_fastTimer + 1;
						end
					end else begin
						PH1_delayTimer <= PH1_delayTimer + 1;
						PH1_fastTimer <= 0;
					end

					if (readR_fastTimer >= 2*T8+2*T7-1) begin
						readR_fastTimer <= 0;
					end else begin
						readR_fastTimer <= readR_fastTimer + 1;
					end
				end

				RO_reset_R: begin
					if (timer >= (T4 + T5R*NUM_SAMPR)-1) begin
						timer <= 0;
						readTimer <= 0;
						fastTimer <= 0;
						delayTimer<= 0;
						PH1_delayTimer <= 0;
						PH1_fastTimer <= 0;

						readR_fastTimer <= 0;

						ROWADD <= ROWADD + 1;

						if (ROWADD == NUM_ROW-1) RO_state <= RO_read_last;
						else	RO_state <= RO_signal_L;
					end else begin
						timer <= timer + 1;
						readTimer <= readTimer + 1;

					end

					if (delayTimer >= T5_5) begin
						if (fastTimer >= T5_6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

					if (PH1_delayTimer >= T4) begin
						if (PH1_fastTimer >= T5R-1) begin
							PH1_fastTimer <= 0;
						end else begin
							PH1_fastTimer <= PH1_fastTimer + 1;
						end
					end else begin
						PH1_delayTimer <= PH1_delayTimer + 1;
						PH1_fastTimer <= 0;
					end

					if (readR_fastTimer >= 2*T8+2*T7-1) begin
						readR_fastTimer <= 0;
					end else begin
						readR_fastTimer <= readR_fastTimer + 1;
					end
				end
				RO_read_last: begin
					if (readTimer >= 2*(T4 + T5R*NUM_SAMPR)-1) begin
						timer <= 0;
						readTimer <= 0;
						done_ro <= 1'b1;
						RO_state <= RO_idle;
					end else begin
						timer <= timer + 1;
						readTimer <= readTimer + 1;

					end

					if (delayTimer >= T5_5) begin
						if (fastTimer >= T5_6-1) begin
							fastTimer <= 0;
						end else begin
							fastTimer <= fastTimer + 1;
						end
					end else begin
						delayTimer <= delayTimer + 1;
						fastTimer <= 0;
					end

					if (readR_fastTimer >= 2*T8+2*T7-1) begin
						readR_fastTimer <= 0;
					end else begin
						readR_fastTimer <= readR_fastTimer + 1;
					end
				end
			endcase	
		end
	end

	/*
	//timer logic
	always @(posedge CLK) begin
		if (rst) begin
			RO_state_prev <= RO_state;
			timer <= 0; 
			readTimer <= 0; 
		end else begin
			if (RO_state != RO_state_prev) begin
				timer <= 0;
				RO_state_prev <= RO_state;
				if (RO_state == RO_signal_L || RO_state == RO_signal_R || RO_state == RO_read_last) begin
					readTimer <= 0;
				end
			end else begin
				timer <= timer + 1;
				readTimer <= readTimer + 1;
			end
		end
	end
	*/

	/*
	always @(RO_state) begin
		timer <= 0;
		if (RO_state == RO_signal_L || RO_state == RO_signal_R || RO_state == RO_read_last) begin
			readTimer <= 0;
		end
	end
	*/
	/*
	//sequential ROWADD
	always @(RO_state) begin
		if (RO_state == RO_idle) begin
			ROWADD <= 0;
		end else if(RO_state == RO_signal_L) begin
			ROWADD <= ROWADD + 1;
		end
	end
    */
	//signal generation----------------------------------------------
	//TODO issues with modulus
	always @(*) begin
		if (rst) begin
			COL_L_EN	<= 1'b0;
			PIXRES_L	<= 1'b0;
			PIXRES_R	<= 1'b0;
			STDBY		<= 1'b1;
			PRECH_COL	<= 1'b0;
			PGA_RES		<= 1'b0;
			CK_PH1		<= 1'b0;
			SAMP_S		<= 1'b0;
			SAMP_R		<= 1'b0;
			
			READ_R		<= 1'b0;
			READ_S		<= 1'b0;
			MUX_START	<= 1'b0;
			CP_COLMUX_IN	<= 1'b0;
		end else begin
			case (RO_state)
				RO_idle: begin
					COL_L_EN	<= 1'b0;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b1;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= 1'b0;
					CK_PH1		<= 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= 1'b0;
					
					READ_R		<= 1'b0;
					READ_S		<= 1'b0;
					MUX_START	<= 1'b0;
					CP_COLMUX_IN	<= 1'b0;
				end
				RO_start: begin
					COL_L_EN	<= 1'b0;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= 1'b0;
					CK_PH1		<= 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= 1'b0;
					
					READ_R		<= 1'b0;
					READ_S		<= 1'b0;
					MUX_START	<= 1'b0;
					CP_COLMUX_IN	<= 1'b0;
				end
				RO_signal_L_first: begin
					COL_L_EN	<= 1'b1;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= (timer < T3) ? 1'b1 : 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5L/2) ? 1'b1 : 1'b0;
					SAMP_S		<= (timer < T6) ? 1'b0 : 1'b1;
					SAMP_R		<= 1'b0;
					
					READ_R		<= 1'b0;
					READ_S		<= 1'b0;
					MUX_START	<= 1'b1;
					CP_COLMUX_IN	<= 1'b0;
				end
				RO_reset_L_first: begin
					COL_L_EN	<= 1'b1;
					PIXRES_L	<= (timer < T1) ? 1'b1 : 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5L/2) ? 1'b1 : 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= (timer < T6) ? 1'b0 : 1'b1;
					
					READ_R		<= 1'b0;
					READ_S		<= 1'b0;
					MUX_START	<= 1'b1;
					CP_COLMUX_IN	<= 1'b0;
				end
				RO_signal_L: begin
					COL_L_EN	<= 1'b1;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= (timer < T3) ? 1'b1 : 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5L/2) ? 1'b1 : 1'b0;
					SAMP_S		<= (timer < T6) ? 1'b0 : 1'b1;
					SAMP_R		<= 1'b0;
					
					READ_R		<= (readR_fastTimer < T8) ? 1'b1 : 1'b0;
					READ_S		<= (readR_fastTimer >= T8+T7) && (readR_fastTimer < 2*T8+T7) ? 1'b1 : 1'b0;
					//READ_S		<= (readTimer % (2*(T8+T7)) < T8+T7) || (readTimer % (2*(T8+T7))) >= 2*T8+T7 ? 1'b0 : 1'b1;
					MUX_START	<= (readTimer < T9) ? 1'b1 : 1'b0;
					CP_COLMUX_IN	<= (delayTimer >= T5_5) && (fastTimer < T5_6/2) ? 1'b1 : 1'b0;
				end
				RO_reset_L: begin
					COL_L_EN	<= 1'b1;
					PIXRES_L	<= (timer < T1) ? 1'b1 : 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5L/2) ? 1'b1 : 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= (timer < T6) ? 1'b0 : 1'b1;
					
					READ_R		<= (readR_fastTimer < T8) ? 1'b1 : 1'b0;
					READ_S		<= (readR_fastTimer >= T8+T7) && (readR_fastTimer < 2*T8+T7) ? 1'b1 : 1'b0;
					MUX_START	<= 1'b0;
					CP_COLMUX_IN	<= (delayTimer >= T5_5) && (fastTimer < T5_6/2) ? 1'b1 : 1'b0;
				end
				RO_signal_R: begin
					COL_L_EN	<= 1'b0;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5R/2) ? 1'b1 : 1'b0;
					SAMP_S		<= (timer < T6) ? 1'b0 : 1'b1;
					SAMP_R		<= 1'b0;
					
					READ_R		<= (readR_fastTimer < T8) ? 1'b1 : 1'b0;
					READ_S		<= (readR_fastTimer >= T8+T7) && (readR_fastTimer < 2*T8+T7) ? 1'b1 : 1'b0;
					MUX_START	<= (readTimer < T9) ? 1'b1 : 1'b0;
					CP_COLMUX_IN	<= (delayTimer >= T5_5) && (fastTimer < T5_6/2) ? 1'b1 : 1'b0;
				end
				RO_reset_R: begin
					COL_L_EN	<= 1'b0;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= (timer < T1) ? 1'b1 : 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= (timer < T4) ? 1'b1 : 1'b0;
					CK_PH1		<= (PH1_delayTimer >= T4) && (PH1_fastTimer < T5R/2) ? 1'b1 : 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= (timer < T6) ? 1'b0 : 1'b1;
					
					READ_R		<= (readR_fastTimer < T8) ? 1'b1 : 1'b0;
					READ_S		<= (readR_fastTimer >= T8+T7) && (readR_fastTimer < 2*T8+T7) ? 1'b1 : 1'b0;
					MUX_START	<= 1'b0;
					CP_COLMUX_IN	<= (delayTimer >= T5_5) && (fastTimer < T5_6/2) ? 1'b1 : 1'b0;
				end
				RO_read_last: begin
					COL_L_EN	<= 1'b1;
					PIXRES_L	<= 1'b0;
					PIXRES_R	<= 1'b0;
					STDBY		<= 1'b0;
					PRECH_COL	<= 1'b0;
					PGA_RES		<= 1'b0;
					CK_PH1		<= 1'b0;
					SAMP_S		<= 1'b0;
					SAMP_R		<= 1'b0;
					
					READ_R		<= (readR_fastTimer < T8) ? 1'b1 : 1'b0;
					READ_S		<= (readR_fastTimer >= T8+T7) && (readR_fastTimer < 2*T8+T7) ? 1'b1 : 1'b0;
					MUX_START	<= (readTimer < T9) ? 1'b1 : 1'b0;
					CP_COLMUX_IN	<= (delayTimer >= T5_5) && (fastTimer < T5_6/2) ? 1'b1 : 1'b0;
				end
				default: begin
                    COL_L_EN	<= 1'b1;
                    PIXRES_L	<= 1'b0;
                    PIXRES_R	<= 1'b0;
                    STDBY		<= 1'b1;
                    PRECH_COL	<= 1'b0;
                    PGA_RES		<= 1'b0;
                    CK_PH1		<= 1'b0;
                    SAMP_S		<= 1'b0;
                    SAMP_R		<= 1'b0;
                    
                    READ_R		<= 1'b0;
                    READ_S		<= 1'b0;
                    MUX_START	<= 1'b0;
                    CP_COLMUX_IN	<= 1'b0;
				end
			endcase
		end
	end
endmodule
