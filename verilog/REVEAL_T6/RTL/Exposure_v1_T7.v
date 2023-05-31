`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2022 10:44:42 AM
// Design Name: 
// Module Name: 
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

module Exposure_v1_T7
    #(parameter MASK_DES = 16)
   (
    input wire rst,
	input wire CLKM, //200MHz clock
	output reg trigger_o,
	output reg exp_busy,
	input wire re_busy,
	output reg PIXGSUBC,
	output reg PIXDRAIN,
	output reg PIXGLOB_RES,
	output reg PIXVTG_GLOB,
	output reg EN_STREAM,
	output reg DES_2ND,
	output reg MASK_EN,
	output reg PROJ_TRG,
	output reg [8:0] ROWADD, 

	input wire [31:0] NUM_PAT,
	input wire [31:0] NUM_REP,
	input wire [31:0] NUM_ROW,
	input wire [31:0] NUM_GSUB,
	input wire [31:0] Tproj_dly,
	input wire [31:0] Tgl_res,
	input wire [31:0] Texp_ctrl,
	input wire [31:0] Tadd,
	input wire [31:0] Tdes2_d,
	input wire [31:0] Tdes2_w,
	input wire [31:0] Tmsken_d,
	input wire [31:0] Tmsken_w,
	input wire [31:0] Tdrain_w,
	input wire [31:0] Tgsub_w,
	input wire [31:0] Treset,
	input wire [31:0] TdrainR_d,
	input wire [31:0] TdrainF_d,
	input wire [31:0] T_MU_wait
    );

	reg [31:0] proj_r;
	reg [31:0] exp_r;
	reg [31:0] add_r;
	reg [31:0] des2d_r;
	reg [31:0] des2w_r;
	reg [31:0] mskend_r;
	reg [31:0] mskenw_r;
	reg [31:0] gsub_r;
	reg [31:0] gsub_r0;
	reg [31:0] rst_r;
    wire [31:0] contrast_led_r;
    
	reg expTimeTrigger_flag;

	always @ (posedge CLKM) proj_r <= Tproj_dly + 12;
	always @ (posedge CLKM) exp_r <= Texp_ctrl;
	always @ (posedge CLKM) add_r <= Tadd;
	always @ (posedge CLKM) des2d_r <= Tdes2_d;
	always @ (posedge CLKM) des2w_r <= Tdes2_w;
	always @ (posedge CLKM) mskend_r <= Tmsken_d;
	always @ (posedge CLKM) mskenw_r <= Tmsken_w;
	always @ (posedge CLKM) gsub_r <= Tgsub_w;
	always @ (posedge CLKM) gsub_r0 <= gsub_r;
	always @ (posedge CLKM) rst_r <= Treset;


	reg [31:0] Tproj;
	reg [31:0] repnum_r;
	reg [31:0] mu_r0;
	reg [31:0] mu_r2;
	reg [31:0] crepeat_r0;
	reg [31:0] cvtg_r;
    reg [31:0] mu_all;
    
	always @ (posedge CLKM)
		Tproj <= Texp_ctrl+ (Tgsub_w + (NUM_ROW+1) * MASK_DES + 3 )*(NUM_REP-1)-92-Tproj_dly;
    always @ (posedge CLKM) mu_all       <= (Tgsub_w + (NUM_ROW+1) * MASK_DES + 3 )*(NUM_REP-1);
	always @ (posedge CLKM) repnum_r <= NUM_REP ;
	always @ (posedge CLKM) mu_r0  		 <= Tgsub_w + NUM_ROW * MASK_DES ;
	always @ (posedge CLKM) mu_r2  		 <= mu_r0 - 2;
	always @ (posedge CLKM) crepeat_r0 <= mu_r0 + Tgsub_w;
	always @ (posedge CLKM) cvtg_r 		 <= gsub_r + Tgl_res;

	integer cntSub;
	integer cntGsubc;
	integer cntRep;
	integer state;
	integer timer;
	integer ProjTimer;
	integer cnt_trigger_wait;

	integer cnt_reset;
	integer cnt_repeat_dm;
	integer cnt_sub;
	integer cnt_repeat;
	integer cnt_repeat1;
	integer cnt_gsubc;
	integer cnt_drainDel1, cnt_drainDel2;
	integer cntLed;


	localparam 	S_idle	 					= 0;
	localparam 	S_reset	 					= 1;
	localparam	S_repeat_dm			        = 2;
	localparam	S_sub0				 		= 3;
	localparam	S_sub1				 		= 4;
	localparam	S_sub2				 		= 5;
	localparam	S_gsubc1			 		= 6;
	localparam	S_gsubc2			 		= 7;
	localparam	S_gsubc3			 		= 8;
	localparam	S_repeat0				    = 9;
	localparam	S_repeat1				    = 10;
	localparam	S_repeat2				    = 11;
	localparam	S_repeat3				    = 12;
	localparam	S_trigger				    = 13;


	always @ (posedge CLKM) begin
		if (rst) begin
			state <= S_idle;
			trigger_o <= 0;
			ProjTimer <= 1;
			cntRep <= 0;
			cntSub <= 0;
			//cnt_reset <= 0;
			cnt_reset <= rst_r;
			cnt_sub <= 0;
			cnt_repeat <= 0;
			cnt_repeat1 <= 0;
			cnt_gsubc <= 0;
			cnt_drainDel1 <= 0;
			cnt_drainDel2 <= 0;
			cnt_repeat_dm <= 0;
			cntLed        <= 0;
			cnt_trigger_wait <= 0;
			//ROWADD <= 0;
		end else begin
			case (state)
				S_idle: begin
                    cntLed <= 0;
					if(~re_busy) begin
						cntSub <= NUM_PAT;
						state <= S_reset;
						//cnt_reset <= rst_r;
					end
				end

				S_reset: begin
                    cntLed <= 0;
					if(cnt_reset == 0) begin
						state <= S_repeat_dm;
						cnt_repeat_dm <= crepeat_r0;
						cnt_reset <= rst_r;
					end else begin
						cnt_reset <= cnt_reset - 1;
					end
				end

				S_repeat_dm: begin
                    cntLed <= 0;
					if(cnt_repeat_dm == 0) begin
						state <= S_sub0;
					end else begin
						cnt_repeat_dm <= cnt_repeat_dm - 1;
					end
				end

				S_sub0: begin
                    cntLed <= 0;
					if(cntSub == 0) begin
						state <= S_trigger;
					end else begin
						cnt_sub <= exp_r;
						state <= S_sub1;
					end
				end

				S_sub1: begin
                    cntLed     <= cntLed+1;
					ProjTimer  <= ProjTimer+1;
                    cntLed     <= cntLed + 1;
					cnt_sub <= cnt_sub - 1;
					if(cnt_sub == 0) begin
						state <= S_sub2;
					end
				end

				S_sub2: begin
                    cntLed         <= cntLed+1;
					ProjTimer      <= ProjTimer+1;
                    cntLed         <= cntLed + 1;
					state          <= S_gsubc1;
					cntRep         <= repnum_r-1;
					cnt_gsubc      <= Tgsub_w;
					cnt_drainDel1  <= TdrainR_d;
				end

				S_gsubc1: begin
                    cntLed         <= cntLed+1;
					ProjTimer      <= ProjTimer+1;
					state          <= S_gsubc1;
					cnt_gsubc      <= cnt_gsubc - 1;
					cnt_drainDel1  <= cnt_drainDel1 - 1;
					if(cnt_drainDel1 == 1) begin
						state <= S_gsubc2;
					end
				end

                S_gsubc2: begin
                    cntLed          <= cntLed+1;
                    ProjTimer       <= ProjTimer+1;
                    state           <= S_gsubc2;
                    cnt_gsubc       <= cnt_gsubc - 1;
					if(cnt_gsubc == 1) begin
						state <= S_gsubc3;
						cnt_drainDel2 <= TdrainF_d;
					end
                end

                S_gsubc3: begin
                    cntLed          <= cntLed+1;
                    ProjTimer       <= ProjTimer+1;
                    state           <= S_gsubc3;
                    cnt_drainDel2   <= cnt_drainDel2 - 1;
                    if(cnt_drainDel2 == 1) begin
                        state <= S_repeat0;
                        cnt_repeat <= 15;
                    end
                end


				S_repeat0: begin
                    cntLed          <= cntLed+1;
					cnt_repeat      <= cnt_repeat - 1;
					ProjTimer       <= ProjTimer+1;
					if(cnt_repeat == 0) begin
						cnt_repeat1 <= 0;
						state <= S_repeat1;
					end
				end

				S_repeat1: begin
                    cntLed          <= cntLed+1;
					cnt_repeat      <= cnt_repeat + 1;
					ProjTimer       <= ProjTimer+1;
					if(cnt_repeat == MASK_DES) begin
						cnt_repeat <= 1;
						cnt_repeat1 <= cnt_repeat1+1;
						if(cnt_repeat1==(NUM_ROW-2)) begin
							state <= S_repeat2;
						end else begin
							state <= S_repeat1;
						end
					end
				end

				S_repeat2: begin
                    cntLed          <= cntLed+1;
					cnt_repeat      <= cnt_repeat + 1;
					ProjTimer       <= ProjTimer+1;
					if(cnt_repeat == MASK_DES) begin
						cnt_repeat <= 1;
						state <= S_repeat3;
					end
				end

				S_repeat3: begin
                    cntLed          <= cntLed+1;
					ProjTimer       <= ProjTimer+1;
					if(cntRep == 0) begin
						state <= S_sub0;
						cntSub <= cntSub - 1;
						ProjTimer <= 1;
					end else begin
						cnt_gsubc     <= Tgsub_w;
						cnt_drainDel1 <= TdrainR_d;
						state         <= S_gsubc1;
						cntRep        <= cntRep-1;
					end
				end

				S_trigger: begin
                    cntLed          <= 0;
					if(re_busy) begin
						trigger_o 			<= 0;
						state 				<= S_idle;
						cnt_trigger_wait 	<= 1; 
                    end else begin
                    	trigger_o 			<= cnt_trigger_wait==T_MU_wait  ?      1    : 0;
						cnt_trigger_wait 	<= cnt_trigger_wait==T_MU_wait  ?  T_MU_wait : cnt_trigger_wait+1; 
	                end                    	
				end

				default: begin
					if(re_busy) begin
						state <= S_idle;
					end else begin
						state <= S_trigger;
					end
				end
			endcase
		end
	end



	always @ (posedge CLKM) begin
		case (state)
			S_idle: begin
				PIXGSUBC 					<= 1'b0;
				PIXDRAIN 					<= 1'b1;
				PIXGLOB_RES 			<= 1'b0;
				PIXVTG_GLOB 			<= 1'b0;
				EN_STREAM 				<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 0;
			end

			S_reset: begin
				PIXGSUBC 					<= 1'b0;
				PIXDRAIN 					<= 1'b1;
				PIXGLOB_RES 			<= 1'b1;
				PIXVTG_GLOB 			<= 1'b1;
				EN_STREAM 				<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 0;
			end

			S_repeat_dm: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= (cnt_repeat_dm > mu_r2) ? 1'b1 : 1'b0;
				PIXGLOB_RES 			<= (cnt_repeat_dm > gsub_r0) ? 1'b1 : 1'b0;
				PIXVTG_GLOB 			<= (cnt_repeat_dm > cvtg_r)? 1'b1:1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_sub0: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				<= 1'b0;
				PIXVTG_GLOB				<= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_sub1: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
			end

			S_sub2: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_gsubc1: begin
				PIXGSUBC					<= 1'b1;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_gsubc2: begin
				PIXGSUBC					<= 1'b1;
				PIXDRAIN					<= 1'b1;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_gsubc3: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b1;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_trigger: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b1;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_repeat0: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b1;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			S_repeat1: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= (ROWADD==(NUM_ROW-2) && cnt_repeat>16-Tdes2_d)? 1'b0:1'b1;
				DES_2ND						<= ((cnt_repeat >= Tdes2_d)&&(cnt_repeat <Tdes2_d+Tdes2_w)) ? 1'b1 : 1'b0;
				MASK_EN						<= ((cnt_repeat >= Tmsken_d)&&(cnt_repeat <Tmsken_d+Tmsken_w)) ? 1'b1 : 1'b0;
				ROWADD 						<= (cnt_repeat == add_r)? ((cnt_repeat1==0)? 0:ROWADD+1):ROWADD;
				exp_busy				    <= 1;
			end

			S_repeat2: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= ((cnt_repeat >= Tdes2_d)&&(cnt_repeat <Tdes2_d+Tdes2_w)) ? 1'b1 : 1'b0;
				MASK_EN						<= ((cnt_repeat >= Tmsken_d)&&(cnt_repeat <Tmsken_d+Tmsken_w)) ? 1'b1 : 1'b0;
				ROWADD 						<= (cnt_repeat == add_r)? ROWADD+1:ROWADD;
				exp_busy				    <= 1;
			end

			S_repeat3: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b0;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 1;
			end

			default: begin
				PIXGSUBC					<= 1'b0;
				PIXDRAIN					<= 1'b1;
				PIXGLOB_RES				    <= 1'b0;
				PIXVTG_GLOB				    <= 1'b0;
				EN_STREAM					<= 1'b0;
				DES_2ND						<= 1'b0;
				MASK_EN						<= 1'b0;
				ROWADD 						<= 0;
				exp_busy				    <= 0;
			end
		endcase
	end
    
   
endmodule
