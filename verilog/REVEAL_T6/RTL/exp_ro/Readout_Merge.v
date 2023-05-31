`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2022 10:02:48 PM
// Design Name: 
// Module Name: Readout_Merge
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


module Readout_Merge(
	input wire rst,
	input wire adc1_start_trigger,
	input wire adc2_start_trigger,
	output wire adc1_busy,
	output wire adc2_busy,

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
  
	input wire [31:0] ADC1_Tcolumn,
	input wire [31:0] ADC1_T1,
	input wire [31:0] ADC1_T2_1,
	input wire [31:0] ADC1_T2_0,
	input wire [31:0] ADC1_T3,
	input wire [31:0] ADC1_T4,
	input wire [31:0] ADC1_T5,
	input wire [31:0] ADC1_T6,
	input wire [31:0] ADC1_T7,
	input wire [31:0] ADC1_T8,
	input wire [31:0] ADC1_T9,
	input wire [31:0] ADC1_TADC,
	input wire [31:0] ADC1_NUM_ROW,
	input wire [31:0] ADC1_Wait,

	input wire [31:0] ADC2_Tcolumn,
	input wire [31:0] ADC2_T1,
	input wire [31:0] ADC2_T2_1,
	input wire [31:0] ADC2_T2_0,
	input wire [31:0] ADC2_T3,
	input wire [31:0] ADC2_T4,
	input wire [31:0] ADC2_T5,
	input wire [31:0] ADC2_T6,
	input wire [31:0] ADC2_T7,
	input wire [31:0] ADC2_T8,
	input wire [31:0] ADC2_T9,
	input wire [31:0] ADC2_TADC,	
	input wire [31:0] ADC2_NUM_ROW,
	input wire [31:0] ADC2_Wait
	);
	
	parameter 	NUM_ADC_BITS = 12,
				NUM_COL = 20;

	
	reg re_busy, re_busy_i, i_am_adc1, i_am_adc2;

	reg [9:0] ROWADD_i;
	reg [1:0] ROWADD_phase; // the two bits which decide leftbucksel and odd_col_en
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

	wire [31:0] Tcolumn, T1, T2_1, T2_0, T3, T4, T5, T6, T7, T8, T9, TADC, NUM_ROW, T_RO_Wait;
	assign Tcolumn     = adc1_busy ? ADC1_Tcolumn     : ADC2_Tcolumn     ;
	assign T1          = adc1_busy ? ADC1_T1          : ADC2_T1          ;
	assign T2_1        = adc1_busy ? ADC1_T2_1        : ADC2_T2_1        ;
	assign T2_0        = adc1_busy ? ADC1_T2_0        : ADC2_T2_0        ;
	assign T3          = adc1_busy ? ADC1_T3          : ADC2_T3          ;
	assign T4          = adc1_busy ? ADC1_T4          : ADC2_T4          ;
	assign T5          = adc1_busy ? ADC1_T5          : ADC2_T5          ;
	assign T6          = adc1_busy ? ADC1_T6          : ADC2_T6          ;
	assign T7          = adc1_busy ? ADC1_T7          : ADC2_T7          ;
	assign T8          = adc1_busy ? ADC1_T8          : ADC2_T8          ;
	assign T9          = adc1_busy ? ADC1_T9          : ADC2_T9          ;
	assign TADC        = adc1_busy ? ADC1_TADC        : ADC2_TADC        ;
	assign NUM_ROW     = adc1_busy ? ADC1_NUM_ROW     : ADC2_NUM_ROW     ;
	assign T_RO_Wait   = adc1_busy ? ADC1_Wait        : ADC2_Wait        ;
	

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
	assign adc1_busy = re_busy & i_am_adc1;
	assign adc2_busy = re_busy & i_am_adc2; 
	reg i_am_adc1_i = 0;
	always @ (posedge TX_CLK) begin
		if(re_busy) begin
			triggerSync <= 0;
			i_am_adc1 	<= i_am_adc1;
			i_am_adc2 	<= i_am_adc2;
		end else begin
			if(adc1_start_trigger) begin
				triggerSync <= 1;
				i_am_adc1   <= 1;
				i_am_adc2   <= 0;
			end else if(adc2_start_trigger) begin
				triggerSync <= 1;
				i_am_adc1   <= 0;
				i_am_adc2   <= 1;
			end else begin
				triggerSync <= 0;
				i_am_adc1   <= re_busy & i_am_adc1;
				i_am_adc2   <= re_busy & i_am_adc2;
			end		
		end
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
					timer1     		<= 2;
					timer1_adc_clk 	<= 1;
				end
				
				S_startRepeat: begin // update which part of the row you are digitizing using variable row_part
					state1 			<= S_repeat;
					timer1 			<= timer1;
					timer1_adc_clk 	<= 1;
				end
				
				S_repeat: begin
					if(timer1 == Tcolumn) begin
						if(i_am_adc1)
							state1     <= (ROWADD_phase==2'b11) ? S_setRow : S_startRepeat;
						else if(i_am_adc2) 
							state1     <= (ROWADD_phase[0]==1'b1) ? S_setRow : S_startRepeat; // only one bucket.
	//						state1     <= (ROWADD_phase==2'b11) ? S_setRow : S_startRepeat; // for both buckets
					end else begin
						state1 <=S_repeat; 
					end
					timer1 		   <= timer1==Tcolumn ?    1   : timer1 + 1;	 
					timer1_adc_clk <= timer1_adc_clk==TADC ? 1 : timer1_adc_clk + 1;
				end				
				
				S_wait: begin
					timer1_adc_clk <= 1;
					timer1 		   <= timer1>=T_RO_Wait ?    1   : timer1+1;
					state1         <= timer1>=T_RO_Wait ? S_idle : S_wait; 
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
					ROWADD_i			<= (i_am_adc1 && (ROWADD_phase == 2'b11)) || (i_am_adc2 && (ROWADD_phase[0] == 1'b1)) ? ROWADD_i + 1 : ROWADD_i;
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
	localparam S2_load_wait				= 32'b1 << 2;
	localparam S2_load_prime_it  		= 32'b1 << 3;
	localparam S2_load_start			= 32'b1 << 4;
	localparam S2_load_repeat			= 32'b1 << 5;	

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
					state2 <= RST_BAR_LTCHD_i ? S2_idle : S2_monitor_RST_BAR_LTCHD;
					timer2 <= 1;  
					cnt_load <= 1;
				end

				S2_monitor_RST_BAR_LTCHD: begin
					if(i_am_adc1) begin
						state2 <= RST_BAR_LTCHD_i ? (T5>2 ? S2_load_wait : S2_load_start) : S2_monitor_RST_BAR_LTCHD; 
						timer2 <= RST_BAR_LTCHD_i ? (T5>2 ? 3            : 1            ) : timer2 + 1;  				
					end else begin
						// state2 	<= RST_BAR_LTCHD_i ? S2_load_prime_it : S2_monitor_RST_BAR_LTCHD; 
						state2 	<= RST_BAR_LTCHD_i ? S2_load_wait : S2_monitor_RST_BAR_LTCHD; 
						timer2 	<= 1;  										
					end
					cnt_load <= 0;
				end
				

				S2_load_wait: begin //same as S2_load_prime_it in Readout_1bit_T7 
					if(i_am_adc1) begin
						state2 		<= (timer2 == T5) ? S2_load_start : S2_load_wait;
						timer2 		<= (timer2 == T5) ? 1             : timer2+1;
						cnt_load 	<= 0;
					end else begin
						state2 		<= (timer2 == 23) ? S2_load_repeat : S2_load_wait;
						timer2 		<= (timer2 == 23) ? 1             : timer2+1;
						cnt_load 	<= cnt_load+timer2[0]; 						
					end
				end
	
				// S2_load_prime_it: begin
				// 	state2 		<= timer2 == 23   ? S2_load_start : S2_load_prime_it;
				// 	timer2      <= timer2 == 23   ?       1       : timer2 + 1;
				// 	cnt_load 	<= cnt_load+timer2[0]; 
				// end				

				S2_load_start: begin //only for adc1
					state2 	 	<= S2_load_repeat;
					timer2   	<= 1;
					cnt_load 	<= cnt_load + 1;
				end

				S2_load_repeat: begin //same as S2_load_start in Readout_1bit_T7
					state2 		<= (timer2 == T7) ? ((cnt_load == NUM_ADC_BITS) ? S2_idle : S2_load_start) : S2_load_repeat;
					timer2      <= (timer2 == T7) ?                   1                                    : timer2 + 1;
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

				S2_load_wait: begin  //same as S2_load_prime_it in Readout_1bit_T7 
					LOAD_IN_i		 <= i_am_adc1 ? 0 : ~LOAD_IN_i;
					ADC_DATA_VALID_i <= 0;					
				end
	
				S2_load_start: begin
					LOAD_IN_i		 <= i_am_adc1 ? 1 : timer2<T6;
					ADC_DATA_VALID_i <= i_am_adc1 ? 0 : ((timer2>=T8) && (timer2<T9)) ? 1:0;
				end
				
				S2_load_repeat: begin //same as S2_load_start in Readout_1bit_T7
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
			PIXLEFTBUCK_SEL <= i_am_adc1 ? ROWADD_phase[1] : 1;
			COLL_EN			<= i_am_adc1 ? ROWADD_phase[1] : 1;

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
