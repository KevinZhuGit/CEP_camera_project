`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:14:22 05/17/2018 
// Design Name: 
// Module Name:    Readout 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Readout_v1_T4(
	input rst,
	input wire trigger_i,
	output reg re_busy,
  output reg [8:0] ROWADD,
	output reg PIXREAD_SEL,
  output reg PIXLEFTBUCK_SEL,
  output reg PIXRES,
  output reg COLLOAD_EN,
  output reg PRECH_COL,
  output reg ADC_EN_N,
  output reg DATA_LOAD,
  output reg RST_ADC,
  output reg RST_OUTMUX,
  input wire ADC_CLK,
	output reg ADC_DATA_VALID,
  input wire TX_CLK,
  input wire TX_CLKx2,
	input wire TX_CLK_OUT,
	input wire [31:0] Tbuck,
	input wire [31:0] T1,
	input wire [31:0] T2,
	input wire [31:0] T3,
	input wire [31:0] T4,
	input wire [31:0] T5,
	input wire [31:0] T6,
	input wire [31:0] T7,
	input wire [31:0] T8,
	input wire [31:0] T_ADC,
	input wire [31:0] T_OSR,
	input wire [31:0] Treset
    );
	
	
	parameter 	NUM_ROW = 320,
				NUM_ADC_BITS = 14,
				NUM_COL = 108;

	reg ROWADD_i;
	reg ADC_DATA_VALID_i;
	reg PIXREAD_SEL_i;
	reg PIXLEFTBUCK_SEL_i;
	reg PIXRES_i;
	reg COLLOAD_EN_i;
	reg PRECH_COL_i;
	reg ADC_EN_N_i;
	reg DATA_LOAD_i;
	reg RST_ADC_i;
	reg RST_ADC_i2;
	reg RST_OUTMUX_i;
	reg RST_OUTMUX_i2;
	reg ADC_DATA_VALID_i2;
	reg re_busy_i;

	integer state;

	localparam	S_idle					= 0;
	localparam	S_starting			= 1;
	localparam	S_read_first		= 2;
	localparam	S_read_n_left		= 3;
	localparam	S_read_n_right	= 4;
	localparam	S_read_last			= 5;
	localparam	S_pix_reset			= 6;
	
	initial begin
		ROWADD_i 			= 9'd0;
		ADC_DATA_VALID_i= 1'b0;
		PIXREAD_SEL_i 	= 1'b0;
		PIXLEFTBUCK_SEL_i	= 1'b0;
		PIXRES_i			= 1'b0;
		COLLOAD_EN_i	= 1'b1;
		PRECH_COL_i		= 1'b0;
		ADC_EN_N_i		= 1'b1;
		DATA_LOAD_i		= 1'b0;
		RST_ADC_i			= 1'b0;
		RST_OUTMUX_i	= 1'b1;
		re_busy_i			= 1'b0;
	end
		
	reg triggerSync;
	initial triggerSync = 0;
	//always @ (negedge TX_CLK) begin
	//	triggerSync <= trigger_i;
	//end
	always @ (posedge ADC_CLK) begin
		triggerSync <= trigger_i;
	end

	integer timer;
	reg timerRst;
			
			
	always @ (posedge TX_CLK) begin
		if (rst) begin
 			state <= S_idle;
			timer <= 1;
		end
		else begin : state_table
			case (state)
				S_idle: begin
					state <= triggerSync ? S_starting : S_idle;
					timer <= 1;
				end
				
				S_starting: begin
					if(timer >= T2) begin
						state <= S_read_first;
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end
				end
				
				S_read_first: begin
					if(timer >= Tbuck) begin
						state <= S_read_n_right;
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end
				end
				
				S_read_n_right: begin
					if(timer >= Tbuck) begin
						if (ROWADD >= NUM_ROW - 1) begin
							state <= S_read_last;
						end else begin
							state <= S_read_n_left;
						end
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end

					if (ROWADD >= NUM_ROW - 1) begin
						state <= (timer == Tbuck) ? S_read_last : S_read_n_right;
					end
					else begin
						state <= (timer == Tbuck) ? S_read_n_left : S_read_n_right;
					end
				end
				
				S_read_n_left: begin
					if(timer >= Tbuck) begin
						state <= S_read_n_right;
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end
				end
				
				S_read_last: begin
					if(timer >= Tbuck) begin
						state <= S_pix_reset;
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end
				end
				
				S_pix_reset: begin
					if(timer >= Treset) begin
						state <= S_idle;
						timer <= 1;
					end else begin
						timer <= timer + 1;
					end
				end
				
				default: state <= S_idle;
			endcase
		end
	end
	

	always @ (posedge TX_CLK) begin
		if (rst) begin
			ROWADD <= 0;
		end
		else begin
			case (state)
				S_idle: begin
					ROWADD <= 9'd0;
				end
				
				S_starting: begin
					ROWADD <= 9'd0;
				end
				
				S_read_first: begin
					ROWADD <= 9'd0;
				end
				
				S_read_n_right: begin
					ROWADD <= (timer == Tbuck) ? (ROWADD + 9'd1) : ROWADD;
				end
				
				S_read_n_left: begin
					ROWADD <= ROWADD;
				end
				
				S_read_last: begin
					ROWADD <= NUM_ROW;
				end
				
				S_pix_reset: begin
					ROWADD <= 9'd0;
				end
			endcase
		end
	end
	
	always @ (*) begin
		if (rst) begin
			PIXREAD_SEL_i 	= 1'b0;
			PIXLEFTBUCK_SEL_i	= 1'b0;
			PIXRES_i			= 1'b0;
			COLLOAD_EN_i		= 1'b1;
			PRECH_COL_i		= 1'b0;
			ADC_EN_N_i		= 1'b1;
			DATA_LOAD_i		= 1'b0;
			RST_ADC_i			= 1'b0;
			RST_OUTMUX_i		= 1'b1;
			ADC_DATA_VALID_i= 1'b0;
			re_busy_i					= 1'b0;
		end
		else begin
			case (state) 
				S_idle: begin
					PIXREAD_SEL_i 	= 1'b0;
					PIXLEFTBUCK_SEL_i	= 1'b0;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= 1'b0;
					ADC_EN_N_i		= 1'b1;
					DATA_LOAD_i		= 1'b0;
					RST_ADC_i			= 1'b0;
					RST_OUTMUX_i		= 1'b1;
					ADC_DATA_VALID_i= 1'b0;
					re_busy_i					= 1'b0;
				end
				
				S_starting: begin
					PIXREAD_SEL_i 	= 1'b0;
					PIXLEFTBUCK_SEL_i	= 1'b0;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= 1'b0;
					ADC_EN_N_i		= 1'b0;
					DATA_LOAD_i		= 1'b0;
					RST_ADC_i			= 1'b0;
					RST_OUTMUX_i		= 1'b1;		
					ADC_DATA_VALID_i= 1'b0;
					re_busy_i					= 1'b1;
				end
				
				S_read_first: begin
					PIXREAD_SEL_i 	= 1'b1;
					PIXLEFTBUCK_SEL_i	= 1'b1;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= (timer <= T1);
					ADC_EN_N_i		= 1'b0;
					DATA_LOAD_i		= (timer <= T3);
					RST_ADC_i			= (timer <= T5 && timer > (T5 - T4));
					RST_OUTMUX_i		= 1'b1;
					ADC_DATA_VALID_i= 1'b0;
					re_busy_i					= 1'b1;

				end
				
				S_read_n_right: begin
					PIXREAD_SEL_i 	= 1'b1;
					PIXLEFTBUCK_SEL_i	= 1'b0;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= (timer <= T1);
					ADC_EN_N_i		= 1'b0;
					DATA_LOAD_i		= (timer <= T3);
					RST_ADC_i			= (timer <= T5 && timer > (T5 - T4));
					RST_OUTMUX_i		= (timer <= T6);
					ADC_DATA_VALID_i= (timer <= (NUM_ADC_BITS * NUM_COL + T6 + T7) && timer > (T6 + T7));
					re_busy_i					= 1'b1;
				end
				
				S_read_n_left: begin
					PIXREAD_SEL_i 	= 1'b1;
					PIXLEFTBUCK_SEL_i	= 1'b1;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= (timer <= T1);
					ADC_EN_N_i		= 1'b0;
					DATA_LOAD_i		= (timer <= T3);
					RST_ADC_i			= (timer <= T5 && timer > (T5 - T4));
					RST_OUTMUX_i		= (timer <= T6);
					ADC_DATA_VALID_i= (timer <= (NUM_ADC_BITS * NUM_COL + T6 + T7) && timer > (T6 + T7));
					re_busy_i					= 1'b1;
				end
	
				S_read_last: begin
					PIXREAD_SEL_i 	= 1'b0;
					PIXLEFTBUCK_SEL_i	= 1'b1;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= 1'b0;
					ADC_EN_N_i		= 1'b0;
					DATA_LOAD_i		= (timer <= T3);
					RST_ADC_i			= 1'b0;
					RST_OUTMUX_i		= (timer <= T6);
					ADC_DATA_VALID_i= (timer <= (NUM_ADC_BITS * NUM_COL + T6 + T7) && timer > (T6 + T7));
					re_busy_i					= 1'b1;
				end
				
				S_pix_reset: begin
					PIXREAD_SEL_i 	= 1'b0;
					PIXLEFTBUCK_SEL_i	= 1'b0;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= 1'b0;
					ADC_EN_N_i		= 1'b1;
					DATA_LOAD_i		= 1'b0;
					RST_ADC_i			= 1'b0;
					RST_OUTMUX_i		= 1'b0;
					ADC_DATA_VALID_i= 1'b0;
					re_busy_i					= 1'b1;
				end
				
				default: begin
					PIXREAD_SEL_i 	= 1'b0;
					PIXLEFTBUCK_SEL_i	= 1'b0;
					PIXRES_i			= 1'b0;
					COLLOAD_EN_i		= 1'b1;
					PRECH_COL_i		= 1'b0;
					ADC_EN_N_i		= 1'b1;
					DATA_LOAD_i		= 1'b0;
					RST_ADC_i			= 1'b0;
					RST_OUTMUX_i		= 1'b1;
					ADC_DATA_VALID_i= 1'b0;
					re_busy_i					= 1'b0;
				end
			endcase
		end
	end

  always @(posedge TX_CLK) begin
			PIXREAD_SEL     <=		PIXREAD_SEL_i;
			PIXLEFTBUCK_SEL <=		PIXLEFTBUCK_SEL_i;
			PIXRES          <=		PIXRES_i;
			COLLOAD_EN      <=		COLLOAD_EN_i;
			PRECH_COL       <=		PRECH_COL_i;
			ADC_EN_N        <=		ADC_EN_N_i;
			DATA_LOAD       <=		DATA_LOAD_i;
			//RST_ADC         <=		RST_ADC_i;
			RST_ADC_i2      <=		RST_ADC_i;
			re_busy         <=		re_busy_i;
			ADC_DATA_VALID  <= 		ADC_DATA_VALID_i;
      //RST_OUTMUX      <= 		RST_OUTMUX_i;
			//ADC_DATA_VALID_i2 <= ADC_DATA_VALID_i;
      RST_OUTMUX_i2     <= RST_OUTMUX_i;
	end
	
	/* ADC data valid signals are control by TX_CLK_OUT<i> */
	//always @ (posedge TX_CLK_OUT) begin
	//	//ADC_DATA_VALID <= ADC_DATA_VALID_i;
	//	ADC_DATA_VALID <= ADC_DATA_VALID_i2;
	//end

	//// test1
  //always @(posedge TX_CLK_OUT) begin
  //    RST_OUTMUX     <= RST_OUTMUX_i;
  //    //RST_OUTMUX_i2 <= RST_OUTMUX_i;
  //    //RST_OUTMUX     <= RST_OUTMUX_i2;
  //end

	// test2
  always @(negedge TX_CLKx2) begin
      RST_OUTMUX     <= RST_OUTMUX_i2;
  end

  always @(negedge TX_CLK) begin
			RST_ADC      <=		RST_ADC_i2;
  end

	
endmodule
