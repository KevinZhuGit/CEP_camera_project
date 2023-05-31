`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2022 11:54:17 AM
// Design Name: 
// Module Name: Readout_v1_T7
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


module Readout_1bit_T7(

	input wire rst,
	input wire trigger_i,
	output reg re_busy,
  	input wire TX_CLK, 
	input wire TX_CLKx2, 

  	output reg [8:0] ROWADD,
  	output reg SET_ROW,   
	input wire SET_ROW_DONE,
	
  	output reg PIXLEFTBUCK_SEL,
  	output reg ODDCOL_EN,
  	output reg PRECH_COL,
  	output reg ADC_RST,
  	output reg ADC_CLK,

  	output reg RST_BAR_LTCHD,
  	output reg LOAD_IN,
	output reg ADC_DATA_VALID,

	output reg PIXREAD_SEL,
  	output reg ADC_BIAS_EN,
	output reg COLL_EN,
	output reg PIXRES,
  
	input wire [31:0] Tcolumn,
	input wire [31:0] T1,
	input wire [31:0] T2_1,
	input wire [31:0] T2_0,
	input wire [31:0] T3,
	input wire [31:0] T4,
	input wire [31:0] T5,
	input wire [31:0] T6,
	input wire [31:0] T7,
	input wire [31:0] T8,
	input wire [31:0] T9,
	input wire [31:0] TADC,	
	input wire [31:0] NUM_ROW,
	input wire [31:0] T_RO_Wait
	);
	
	parameter 	NUM_COL = 20;

	
	reg re_busy_i;

	reg [9:0] ROWADD_i;
	reg [1:0] ROWADD_phase; // the two bits which decide leftbucksel and odd_col_en
//	reg [0] ROWADD_phase; 	// one bit for which decide leftbucksel and odd_col_en
	reg SETROW_i;


	reg PIXREAD_SEL_i;
	reg ADC_BIAS_EN_i;
	reg COLL_EN_i;
	reg PIXRES_i;

	reg PRECH_COL_i;
	reg ADC_RST_i, ADC_RST_i2;
	reg ADC_CLK_i;

	reg RST_BAR_LTCHD_i, RST_BAR_LTCHD_i2;
	reg LOAD_IN_i;
	reg ADC_DATA_VALID_i;


	integer state1, timer1, timer1_adc_clk;
	localparam	S_idle					= 32'b1<<0;
	localparam  S_setRow                = 32'b1<<1;
	localparam	S_startRepeat			= 32'b1<<2;
	localparam	S_repeat				= 32'b1<<3;
	localparam  S_wait                  = 32'b1<<4;


    initial begin
    	state1				= S_idle;
    	timer1 				= 1;
    	timer1_adc_clk      = 1;
	end

	initial begin
		re_busy_i			= 1'b0;
		ROWADD_phase		= 2'b11;
		PRECH_COL_i			= 1'b0;
		ADC_RST_i			= 1'b0;
		
		RST_BAR_LTCHD_i		= 1'b1;
		LOAD_IN_i			= 1'b0;
		ADC_DATA_VALID_i	= 1'b0;
		
		// constant values throughout
		PIXREAD_SEL_i 		= 1'b1;
		ADC_BIAS_EN_i 		= 1'b1;
		COLL_EN_i 			= 1'b1;
		PIXRES_i			= 1'b0;
	end
		
	reg triggerSync;
	initial triggerSync = 0;

	
	always @ (posedge TX_CLK) begin
		triggerSync <= trigger_i;
	end

	// FSM1: states: ADC conversion	
	always @ (posedge TX_CLK) begin
		if (rst) begin
 			state1 <= S_idle;
			timer1 <= 1;
		end
		else begin : state_table
			case (state1)
				S_idle: begin
					state1 			<= triggerSync ? S_setRow : S_idle;
					timer1 			<= 1;
					timer1_adc_clk 	<= 1;
				end
				
				S_setRow: begin // set DEC_EN and DEC_SEL to load ROW_ADDRESS
					if(ROWADD_i[9:0] == (NUM_ROW[9:0]-1))
						state1 <= S_wait;
					else
						state1 		<= SET_ROW_DONE ? S_startRepeat : S_setRow;
					timer1     		<= 1;
					timer1_adc_clk 	<= 1;
				end
				
				S_startRepeat: begin // update which part of the row you are digitizing using variable row_part
					state1 			<= S_repeat;
					timer1 			<= 1;
					timer1_adc_clk 	<= 1;
				end
				
				S_repeat: begin
					if(timer1 == Tcolumn) begin
//						state1     <= (ROWADD_phase==2'b11) ? S_setRow : S_startRepeat; // for both buckets
						state1     <= (ROWADD_phase[0]==1'b1) ? S_setRow : S_startRepeat; // only one bucket.
					end else begin
						state1 <=S_repeat; 
					end
					timer1 		   <= timer1==Tcolumn ? 1        : timer1 + 1;	 
					timer1_adc_clk <= timer1_adc_clk==TADC ? 1 : timer1_adc_clk + 1;
				end				
				
				S_wait: begin
					timer1_adc_clk <= 1;
					timer1 		   <= timer1==T_RO_Wait ?    1   : timer1+1;
					state1         <= timer1==T_RO_Wait ? S_idle : S_wait; 
				end
				
				default: begin
					state1 			<= S_idle;
					timer1 			<= 1;
					timer1_adc_clk 	<= 1;
				end
			endcase
		end
	end	

	
	// FSM1: signals: ADC conversion	
	always @ (posedge TX_CLK) begin 
		if (rst) begin
			re_busy_i			<= 1'b0;
			ROWADD_i			<= 0;
			SETROW_i 			<= 0;
			ROWADD_phase 		<= 2'b11;
			ADC_RST_i			<= 1'b0;
			PRECH_COL_i			<= 1'b0;
			ADC_CLK_i 			<= 1'b0;
			RST_BAR_LTCHD_i		<= 1'b1;
		end
		else begin
			case (state1) 
				S_idle: begin
					re_busy_i			<= 1'b0;
					ROWADD_i			<= 0;
					SETROW_i 			<= 0;
					ROWADD_phase		<= 2'b11;
					ADC_RST_i			<= 1'b0;
					PRECH_COL_i			<= 1'b0;
					ADC_CLK_i 			<= 1'b0;
					RST_BAR_LTCHD_i		<= 1'b1;
				end
				
				S_setRow: begin
					re_busy_i			<= 1'b1;
					ROWADD_i			<= ROWADD_i;
					SETROW_i 			<= 1;
					ROWADD_phase		<= ROWADD_phase;
					ADC_RST_i			<= 0;
					PRECH_COL_i			<= 0;
					ADC_CLK_i 			<= 0;
					RST_BAR_LTCHD_i		<= 1; 
				end
				
				S_startRepeat: begin
					re_busy_i			<= 1'b1;
//					ROWADD_i			<= ROWADD_phase == 2'b11 ? ROWADD_i + 1 : ROWADD_i; //for two buckets
					ROWADD_i			<= ROWADD_phase[0] == 1'b1 ? ROWADD_i + 1 : ROWADD_i; //for single bucket
					SETROW_i 			<= 0;
					ROWADD_phase		<= ROWADD_phase + 2'b01;
					ADC_RST_i			<= timer1<T1 ? 1 : 0;
					PRECH_COL_i			<= timer1<T2_0 && timer1>=T2_1 	? 1 : 0;
					ADC_CLK_i 			<= 1'b1;
					RST_BAR_LTCHD_i		<= timer1<T3 ? 1 : 0; 
				end
				
				S_repeat: begin
					re_busy_i			<= 1'b1;
					ROWADD_i			<= ROWADD_i;
					SETROW_i 			<= 0;
					ROWADD_phase		<= ROWADD_phase;
					ADC_RST_i			<= timer1<T1 				    ? 1 : 0;
					PRECH_COL_i			<= timer1<T2_0 && timer1>=T2_1 	? 1 : 0;
					ADC_CLK_i 			<= timer1_adc_clk < TADC>>1 	? 1 : 0;
					RST_BAR_LTCHD_i		<= (timer1>=T3 && timer1<T4) 	? 0 : 1; 
				end
				
				S_wait: begin //chillout here
					re_busy_i			<= 1'b1;
					ROWADD_i			<= 0;
					SETROW_i 			<= 0;
					ROWADD_phase		<= 2'b11;
					ADC_RST_i			<= 1'b0;
					PRECH_COL_i			<= 1'b0;
					ADC_CLK_i 			<= 1'b0;
					RST_BAR_LTCHD_i		<= 1'b1;					
				end

				default: begin
					re_busy_i			<= 1'b0;
					ROWADD_i			<= 0;
					SETROW_i 			<= 0;
					ROWADD_phase 		<= 2'b11;
					ADC_RST_i			<= 0;
					PRECH_COL_i			<= 0;
					ADC_CLK_i 			<= 1'b0;
					RST_BAR_LTCHD_i		<= 1;
				end
			endcase
		end
	end	

	
	// FSM2: serializer	
	integer state2, timer2, cnt_load; // UwU
	localparam S2_idle					= 32'b1 << 0;
	localparam S2_monitor_RST_BAR_LTCHD	= 32'b1 << 1;
	localparam S2_load_prime_it  		= 32'b1 << 2;
	localparam S2_load_start			= 32'b1 << 3;
	localparam S2_load_repeat			= 32'b1 << 4;	

	initial begin
    	state2 				= S2_idle;
    	timer2              = 1;
    	cnt_load            = 1;
	end
	

	// FSM2: states: serializer	
	always @(posedge TX_CLK) begin
		if(rst) begin
			state2 <= S2_idle;
			timer2 <= 1;
			cnt_load <= 1;
		end else begin
			case (state2)
				S2_idle: begin
					state2 		<= RST_BAR_LTCHD_i ? S2_idle : S2_monitor_RST_BAR_LTCHD;
					timer2 		<= 1;  
					cnt_load 	<= 0;
				end
				S2_monitor_RST_BAR_LTCHD: begin
					state2 		<= RST_BAR_LTCHD_i ? S2_load_prime_it : S2_monitor_RST_BAR_LTCHD; 
					timer2 		<= 1;  				
					cnt_load 	<= 0;
				end				
				S2_load_prime_it: begin
					state2 		<= timer2 == 23   ? S2_load_start : S2_load_prime_it;
					timer2      <= timer2 == 23   ?       1       : timer2 + 1;
					cnt_load 	<= cnt_load+timer2[0]; 
				end				
				S2_load_start: begin
					state2 		<= (timer2 == T7) ? S2_idle : S2_load_start;
					timer2      <= (timer2 == T7) ?   1     : timer2 + 1;
					cnt_load 	<= cnt_load;
				end
				
				default: begin
					state2 <= S2_idle;
					timer2 <= 1;
					cnt_load <= 1;
				end
			endcase
		end
	end

	// FSM2: signals: serializer		
	always @(posedge TX_CLK) begin
		if(rst) begin
			LOAD_IN_i		 <= 0;
			ADC_DATA_VALID_i <= 0;	
		end else begin
			case (state2)
				S2_idle: begin
					LOAD_IN_i		 <= 0;
					ADC_DATA_VALID_i <= 0;					
				end
				
				S2_monitor_RST_BAR_LTCHD: begin
					LOAD_IN_i		 <= 0;
					ADC_DATA_VALID_i <= 0;					
				end
				
				S2_load_prime_it: begin
					LOAD_IN_i		 <= ~LOAD_IN_i;
					ADC_DATA_VALID_i <= 0;					
				end
	
				S2_load_start: begin
					LOAD_IN_i		 <= timer2<T6;
					ADC_DATA_VALID_i <= ((timer2>=T8) && (timer2<T9)) ? 1:0;		
				end

				default: begin
					LOAD_IN_i		 <= 0;
					ADC_DATA_VALID_i <= 0;					
				end
			endcase
		end
	end

	// signal synchronization	
	always @(posedge TX_CLK) begin
			re_busy         <= re_busy_i;
			
			// ADC control
			ROWADD 			<= ROWADD_i;
			SET_ROW			<= SETROW_i;
			
			// for two buckets
//			PIXLEFTBUCK_SEL <= ROWADD_phase[1];
//			COLL_EN			<= ROWADD_phase[1];
			
			// for single bucket			
			PIXLEFTBUCK_SEL <= 1;
			COLL_EN			<= 1;

            ODDCOL_EN 		<= ROWADD_phase[0];
			ADC_CLK			<= ADC_CLK_i;
			ADC_RST      	<= ADC_RST_i;
			PRECH_COL       <= PRECH_COL_i;

			
			// serializer
      		RST_BAR_LTCHD   <= RST_BAR_LTCHD_i;               
			LOAD_IN       	<= LOAD_IN_i;
			ADC_DATA_VALID  <= ADC_DATA_VALID_i;

			// constant
			PIXREAD_SEL		<= PIXREAD_SEL_i;
			ADC_BIAS_EN		<= ADC_BIAS_EN_i;
			PIXRES			<= PIXRES_i;
	end

    	
endmodule
