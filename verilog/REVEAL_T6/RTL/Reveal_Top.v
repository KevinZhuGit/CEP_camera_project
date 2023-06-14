`timescale 1ns / 100ps
// Company:
// Engineer:
//
// Create Date:    11:03:00 09/20/2017
// Design Name:
// Module Name:    Reveal_Top
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


module Reveal_Top
(
	input  wire [4:0]   okUH,
	output wire [2:0]   okHU,
	inout  wire [31:0]  okUHU,
	inout  wire         okAA,

	input  wire         sys_clk_p,
	input  wire         sys_clk_n,

	output wire [7:0]   led,
    

/****************** DDR3 memory *****************/
	inout  wire [31:0]  ddr3_dq,
	output wire [14:0]  ddr3_addr,
	output wire [2 :0]  ddr3_ba,
	output wire [0 :0]  ddr3_ck_p,
	output wire [0 :0]  ddr3_ck_n,
	output wire [0 :0]  ddr3_cke,
	output wire         ddr3_cas_n,
	output wire         ddr3_ras_n,
	output wire         ddr3_we_n,
	output wire [0 :0]  ddr3_odt,
	output wire [3 :0]  ddr3_dm,
	inout  wire [3 :0]  ddr3_dqs_p,
	inout  wire [3 :0]  ddr3_dqs_n,
	output wire         ddr3_reset_n, 


   // SDI
	output wire        	SCLK,
	inout wire         	SDI,
	input wire         	SDO,
	input wire         	SDO_REFGEN_ADC,

	output wire         VREF_EN,
	
	output wire         SPI_DIN,
	output wire         SPI_CLK,
	output wire         SPI_SS_MASK_UPLOAD, //active low
	output wire         SPI_SS_READOUT, //active low
	
	output wire			CS_POT1,
	output wire			CS_POT2, 
	output wire			CS_POT3, 

	output wire         LC_EN,


   // Reset
	output wire         PIX_GLOB_RES_R,
	output wire         PIX_GLOB_RES_L,
	output wire         PIXRES,

   // Masking
	output wire [20:1]	MSTREAM,
	output wire         DES2ND,
	output wire         EN_STREAM,
	output wire         CLKM,

	output wire         PIX_ROWMASK,
	output wire         MASK_EN,
	output wire         PIX_GSUBC,
	output wire         PIX_DRAIN,
	output wire         PIXVTG_GLOB,

	output wire         DEC_EN,
	output wire         DEC_SEL,
	output wire [8 :0]  ROWADD,

   // Readout conversion
	output wire         PIXREAD_EN,
	output wire         PIX_LEFTBUCK_SEL,
	output wire         PIX_RIGHTBUCK_SEL,
	output wire         STDBY12,
	output wire         COL_PRECH_12,
	output wire         COL_EN,
	output wire         COLL_EN,
	output wire         ODDCOL_EN,
	output wire         LOAD_IN,
	output wire         ADC_CLK,
	output wire         ADC_RST,

   // Readout data transfer
	input wire [17:1 ] 	DIGOUT,
	input wire [4 :1 ] 	DCLK,
	output wire         TX_CLK_IN,
	output wire         RST_BAR_LTCHD,
	output wire         ANA_MUX_RST,

   // Not using these signals at the moment
	input wire         	DIGMUX_OUT2,
	input wire         	DIGMUX_OUT1,
	input wire         	RP_VALID_ACC,
	input wire         	MUX2_15A,
	input wire         	MUX2_13A,
	input wire         	MUX2_11A,
	input wire         	MUX2_9A,
	input wire         	MUX2_16A,
	input wire         	MUX2_14A,
	input wire         	MUX2_12A,
	input wire         	MUX2_10A,
	input wire [4 :1 ] 	ADCCLK_OUT,
	
	output wire [9:1 ] TEST_IO,
	input  wire CAM_TG
);

wire  PROJ_TRG;

wire rst;
reg   sys_rst;
// Clock
wire sys_clk;
wire clk;
wire CLKM_i;

// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

// Endpoint connections:
wire [31:0]  ep00wire;
wire [31:0]  ep01wire;
wire [31:0]  ep02wire;
wire [31:0]  ep03wire;
wire [31:0]  ep04wire;
wire [31:0]  ep20wire, ep22wire;
wire [31:0]  trig40;
wire [31:0]  trig60;


wire [31:0] spi_din;
wire [31:0] spi_target;
wire [31:0] wirerst;
wire [31:0] wireExp;
wire [31:0] wireNumPat;
wire [31:0] modesel;
wire [31:0] wireNumPatMem;
wire [31:0] wireMinFrameTime;
wire [31:0] wireProjDelay;
wire [31:0] wirePhaseSel;

// Counter 1:
reg  [23:0] div1;
reg         clk1div;
reg  [7:0]  count1;
reg         count1eq00;
reg         count1eq80;
wire        reset1;
wire        disable1;

// Counter 2:
reg  [23:0] div2;
reg         clk2div;
reg  [7:0]  count2;
reg         count2eqFF;
wire        reset2;
wire        up2;
wire        down2;
wire        autocount2;

//Masking cache
wire [9:0]   cache_rd_count;
wire [6:0]   cache_wr_count;
wire         cache_empty;
wire         cache_valid;
wire         cache_full;
wire [255:0] cache_data;
wire         cache_rd_en;


//ddr3_test_v3
wire 			init_calib_complete;
wire [2:0] 		img_cnt;
wire [31:0] 	NumRep;

wire 			pipe_in_read;
wire [255:0] 	pipe_in_data;
wire [6:0] 		pipe_in_rd_count;
wire 			pipe_in_valid;
wire 			pipe_in_empty;
wire         	pipe_in_full;
reg          	pipe_in_ready;

wire         	pipe_out_write;
wire [255:0] 	pipe_out_data;
wire [9:0]   	pipe_out_rd_count;
wire [6:0]   	pipe_out_wr_count;
wire         	pipe_out_empty;
wire [6:0]		wr_count;
wire 			pipe_out_full;
reg          	pipe_out_ready;

wire 			pipe0_in_rd;
wire [255:0] 	pipe0_in_rd_data;
wire [6:0] 		pipe0_in_rd_count;
wire [9:0]   	pipe_in_wr_count;
wire 			pipe0_in_valid;
wire 			pipe0_in_empty;

wire 			pipe0_out_wr;
wire [255:0] 	pipe0_out_wr_data;
wire [6:0]		pipe0_out_wr_count;
wire [6:0] 		pipe0_out_rd_count;
wire 			pipe0_out_full;

wire 			pipe2_in_rd;
wire [255:0] 	pipe2_in_rd_data;
wire [6:0] 		pipe2_in_rd_count;
wire [9:0]   	pipe2_in_wr_count;
wire 			pipe2_in_valid;
wire 			pipe2_in_empty;

wire 			pipe2_out_wr;
wire [255:0] 	pipe2_out_wr_data;
wire [6:0]		pipe2_out_wr_count;
wire [6:0] 		pipe2_out_rd_count;
wire 			pipe2_out_full;


wire			app_rdy;
wire 			app_en;
wire [2:0]    	app_cmd;
wire [29:0]   	app_addr;

wire [255:0]  	app_rd_data;
wire          	app_rd_data_end;
wire          	app_rd_data_valid;

wire 			app_wdf_rdy;
wire 			app_wdf_wren;
wire [255:0]  	app_wdf_data;
wire 		    app_wdf_end;
wire [31:0]   	app_wdf_mask;


//PIPE FIFOs
wire p0_rd_en;
wire [31:0]  p0_din_pipe;
wire         p0_full;
wire 		 p0_empty;
wire         po0_ep_read;
wire [31:0]  pi0_ep_dataout;
wire         pi0_ep_write;
wire [31:0]  po0_ep_datain;

//varValueSelector
wire [31:0] NumGsub;
wire [31:0] Tproj_dly;
wire [31:0] NumExp;
wire [31:0] IMG_SIZE, MASK_SIZE, SUB_IMG_SIZE, UNIT_SUB_IMG_SIZE, sub_img_cnt, N_SUBREADOUTS;


// Counter 1:
assign reset1     = ep00wire[0];
assign disable1   = ep00wire[1];
assign autocount2 = ep00wire[2];

// Counter 2:
assign reset2     = trig40[0];
assign up2        = trig40[1];
assign down2      = trig40[2];


assign PIXREAD_EN  = 1'b1;

assign LC_EN        = 0;


wire rd_enable;
wire re_busy;
wire ex_trigger;

wire PIXLEFTBUCK_SEL_i;

wire clk_400;
wire clk_200;
wire clk_100;
wire clk_150;
wire clk_50;
wire clk_25;
wire clk_14;
wire clk_7;

wire TX_CLKi;
wire TX_CLKi2;
wire CLKMi;
wire ADC_CLK;

assign TX_CLKi2 = clk_200;
assign TX_CLKi = clk_100;
assign ADC_CLKi = clk_7;
//	assign CLKMi = clk_100;
//	assign CLKMi = clk_50;
//	assign CLKMi = clk_25;
//  CLKMi assignment in the TEST_IO section

clk_wiz_0 clk_inst (
	.clk_in1(clk), //100MHz
	.clk_200(clk_200), //200MHz
	.clk_100(clk_100), //100MHz
	.clk_150(clk_150), //150MHZ
	.clk_14(clk_14), 
	.clk_7(clk_7),
	.clk_50(clk_50),
	.clk_25(clk_25)
);

clk_wiz_1 clk1_inst (
	.clk_in1(clk), //100MHz
	.clk_400(clk_400) //400MHz
);


reg [31:0] rst_cnt;
initial rst_cnt = 32'b0;
always @(posedge okClk) begin
	//if(rst_cnt < 32'h0800_0000) begin
	if(rst_cnt < 32'h0000_0100) begin
		rst_cnt <= rst_cnt + 1;
		sys_rst <= 1'b1;
	end
	else begin
		sys_rst <= 1'b0;
	end
end


// MIG User Interface instantiation
ddr3_256_32 u_ddr3_256_32 (
	// Memory interface ports
	.ddr3_addr                      (ddr3_addr),
	.ddr3_ba                        (ddr3_ba),
	.ddr3_cas_n                     (ddr3_cas_n),
	.ddr3_ck_n                      (ddr3_ck_n),
	.ddr3_ck_p                      (ddr3_ck_p),
	.ddr3_cke                       (ddr3_cke),
	.ddr3_ras_n                     (ddr3_ras_n),
	.ddr3_reset_n                   (ddr3_reset_n),
	.ddr3_we_n                      (ddr3_we_n),
	.ddr3_dq                        (ddr3_dq),
	.ddr3_dqs_n                     (ddr3_dqs_n),
	.ddr3_dqs_p                     (ddr3_dqs_p),
	.init_calib_complete            (init_calib_complete),
	
	.ddr3_dm                        (ddr3_dm),
	.ddr3_odt                       (ddr3_odt),
	// Application interface ports
	.app_addr                       (app_addr),
	.app_cmd                        (app_cmd),
	.app_en                         (app_en),
	.app_wdf_data                   (app_wdf_data),
	.app_wdf_end                    (app_wdf_end),
	.app_wdf_wren                   (app_wdf_wren),
	.app_rd_data                    (app_rd_data),
	.app_rd_data_end                (app_rd_data_end),
	.app_rd_data_valid              (app_rd_data_valid),
	.app_rdy                        (app_rdy),
	.app_wdf_rdy                    (app_wdf_rdy),
	.app_sr_req                     (1'b0),
	.app_sr_active                  (),
	.app_ref_req                    (1'b0),
	.app_ref_ack                    (),
	.app_zq_req                     (1'b0),
	.app_zq_ack                     (),
	.ui_clk                         (clk),
	.ui_clk_sync_rst                (rst),
	
	.app_wdf_mask                   (app_wdf_mask),
	
	// System Clock Ports
	.sys_clk_p                      (sys_clk_p),
	.sys_clk_n                      (sys_clk_n),
	
	.sys_rst                        (sys_rst)
	);



ddr3_test_v3 i_ddr3_ctl (
	.clk                (clk),
	.reset              (ep00wire[2] | rst),
	.reads_en           (ep00wire[0]),
	.writes_en          (ep00wire[1]),
	.test_en	          (modesel[0]),		// enable runnging mode
	.calib_done         (init_calib_complete),
  	.img_cnt        	  (img_cnt),
  	.sub_img_cnt        (sub_img_cnt), 
  //.NUM_PAT        	  (wireNumPat), 
  .NUM_PAT        	  (wireNumPatMem), 
  .NUM_REP        	  (NumRep), 

	// channel 0
	.ib0_re              (pipe_in_read),
	.ib0_data            (pipe_in_data),
	.ib0_count           (pipe_in_rd_count),
	.ib0_valid           (pipe_in_valid),
	.ib0_empty           (pipe_in_empty),
	
	.ob0_we              (pipe_out_write),
	.ob0_data            (pipe_out_data),
	.ob0_count           (wr_count),
	.ob0_full            (pipe_out_full),
	
	// channel 1
	.ib1_re              (pipe0_in_rd),   // output to fifo, rd_en for pipe_in
	.ib1_data            (pipe0_in_rd_data),   // data input from fifo, [255:0]
	.ib1_count           (pipe0_in_rd_count),  // input fromm fifo  how many input(256) left
	.ib1_valid           (pipe0_in_valid),  // input from fifo, if the input data is valid
	.ib1_empty           (pipe0_in_empty),  // input from fifo, if the pipe_in fifo is empty
	
	.ob1_we              (pipe0_out_wr),  // output to fifo of pipe_out, like wr_en
	.ob1_data            (pipe0_out_wr_data),  // output to fifo of pipe_out, [255:0]
	.ob1_count           (pipe0_out_wr_count), //  input from pipe_out, how many 255 data have been written to fifo
	.ob1_full            (pipe0_out_full), // input from fifo, if the fifo is full now

	// channel 2
	.ib2_re              (pipe2_in_rd),   // output to fifo, rd_en for pipe_in
	.ib2_data            (pipe2_in_rd_data),   // data input from fifo, [255:0]
	.ib2_count           (pipe2_in_rd_count),  // input fromm fifo  how many input(256) left
	.ib2_valid           (pipe2_in_valid),  // input from fifo, if the input data is valid
	.ib2_empty           (pipe2_in_empty),  // input from fifo, if the pipe_in fifo is empty
	
	.ob2_we              (pipe2_out_wr),  // output to fifo of pipe_out, like wr_en
	.ob2_data            (pipe2_out_wr_data),  // output to fifo of pipe_out, [255:0]
	.ob2_count           (pipe2_out_wr_count), //  input from pipe_out, how many 255 data have been written to fifo
	.ob2_full            (pipe2_out_full), // input from fifo, if the fifo is full now
	
	
	.app_rdy            (app_rdy),
	.app_en             (app_en),
	.app_cmd            (app_cmd),
	.app_addr           (app_addr),
	
	.app_rd_data        (app_rd_data),
	.app_rd_data_end    (app_rd_data_end),
	.app_rd_data_valid  (app_rd_data_valid),
	
	.app_wdf_rdy        (app_wdf_rdy),
	.app_wdf_wren       (app_wdf_wren),
	.app_wdf_data       (app_wdf_data),
	.app_wdf_end        (app_wdf_end),
	.app_wdf_mask       (app_wdf_mask),
	
	.IMG_SIZE 			(IMG_SIZE),
	.MASK_SIZE          (MASK_SIZE),
	.SUB_IMG_SIZE       (SUB_IMG_SIZE),
	.UNIT_SUB_IMG_SIZE  (UNIT_SUB_IMG_SIZE)
	);

	wire [255:0] adc_fifo_dout;
	wire [6:0] adc_fifo_rd_count;
	wire adc_fifo_valid, adc_fifo_empty, adc_fifo_rd_en, adc_fifo_full;
	wire adc1_busy,re_busy, adc1_en;
	wire adc2_busy,adc2_leftoverdata, adc2_en;
	
	assign wr_count = (modesel[0])? cache_wr_count:pipe_out_wr_count;


	assign adc_fifo_rd_en 	 = adc2_busy ?  pipe2_in_rd    : pipe0_in_rd;

	assign pipe2_in_rd_data  = adc_fifo_dout;
	assign pipe2_in_valid    = adc_fifo_valid;
	assign pipe2_in_rd_count = adc2_busy ?  adc_fifo_rd_count : 0;
	assign pipe2_in_empty    = adc_fifo_empty; 

	assign pipe0_in_rd_data  = adc_fifo_dout;
	assign pipe0_in_valid    = adc_fifo_valid;
	assign pipe0_in_rd_count = adc1_busy ?  adc_fifo_rd_count : 0; 
	assign pipe0_in_empty    = adc_fifo_empty; 


fifo_w256_128_r256_128_ib i_mask_cache (
	.rst(ep00wire[2]),
	.wr_clk(clk),
	.rd_clk(clk),
	.din(pipe_out_data), // Bus [256 : 0]
	.wr_en(pipe_out_write),
	.rd_en(cache_rd_en),
	.dout(cache_data), // Bus [31 : 0]
	.full(cache_full),
	.empty(cache_empty),
	.valid(cache_valid),
	.rd_data_count(cache_rd_count), // Bus [9 : 0]
	.wr_data_count(cache_wr_count)); // Bus [6 : 0]

patternToSensors_v0 u_patternToSensors(			
		
		.clk(clk), 	//clk for reading mstream
		.stream_clk(CLKMi),  //clk for writing pattern
		.reset(ep00wire[2]),		
				
		.Num_Pat(wireNumPat),
		.MSTREAMOUT(MSTREAM[20:1]),	//Might need to be connected to corresponding oK wires
		.stream_en_i(rd_enable),
		.stream_en_o(EN_STREAM),
					
		//flags for the fifo containing input MSTREAM32 data
		.MSTREAM32(cache_data),
		.empty(cache_empty),
		.valid(cache_valid),
		.rd_en(cache_rd_en)	
    );

	wire [31:0] MSTREAM_Select;


	reg [63:0] pulse_r; // filer noise
	reg flag;
	reg flag_st;
	integer delay_cnt;
	integer delay_cnt1;
	wire [31:0] Select;

	// when sensor readout happens (re_busy=1)
	// image data is readout and put into memory
	// img_cnt = img_cnt + 1 when start reading
	//
	// when img_cnt==2 exposure stops until PC readout finished
	// what happens if pc still reading but flag goes low??
	
	reg CAM_TG_int;
	always @(posedge CLKMi) begin
	  if(wirerst[0]) begin
			pulse_r <= 0;
			flag <= 0;
		end else begin
			flag <= (adc1_en&(re_busy|(img_cnt==2))) | (adc2_en & adc2_leftoverdata);
			pulse_r <= {pulse_r[62:0],CAM_TG_int};
		end
	end

    reg CAM_TG_OLD;
	integer cnt_cycles=0;
	wire [31:0] CAM_TG_HoldTime, CAM_TG_pulseWidth,CAM_TG_delay;
/*
    This module is implemented to trigger on the edge
    Instead of triggering at level of CAM_TG
    ________________
   |                |____    CAM_TG
    Triggered at posedge
   |
                          |<--T_PW-->|
   |<--THold-->|<--Tdly-->|__________|
    ______________________|          |   CAM_TG_int
*/	
    localparam S_TG_idle        = 0;	
    localparam S_posedgeMonitor = 1;	
    localparam S_assertTG       = 2;	
    localparam S_delayTG        = 3;	
	integer state_TG;
	wire   CAM_TG_inv;
//	assign CAM_TG_inv = ~CAM_TG;
	assign CAM_TG_inv = CAM_TG;
	
    always @(posedge CLKMi) begin
		if(wirerst[0]) begin
			state_TG <= S_TG_idle;
			CAM_TG_int <= 0;
			cnt_cycles <= 0;
			state_TG   <= S_TG_idle;
	    end else begin
		      case(state_TG) 
		          S_TG_idle:begin
		              CAM_TG_OLD <= CAM_TG_inv;
		              if((CAM_TG_inv==1)&(CAM_TG_OLD==0)) begin
		                  state_TG <= S_posedgeMonitor;
		              end
		              cnt_cycles <= 0;
		              CAM_TG_int <= 0;
		          end
		          
		          S_posedgeMonitor: begin
		                cnt_cycles <= CAM_TG_inv ? (cnt_cycles==CAM_TG_HoldTime ? 0 : cnt_cycles+1) : 0;
		                state_TG   <= CAM_TG_inv ? (cnt_cycles==CAM_TG_HoldTime?S_delayTG:S_posedgeMonitor) : S_TG_idle;
		                CAM_TG_int <= 0; 
		          end
		          
		          S_delayTG: begin
		              cnt_cycles   <= (cnt_cycles==CAM_TG_delay) ? 0 : cnt_cycles+1;
		              state_TG    <= (cnt_cycles==CAM_TG_delay) ? S_assertTG: S_delayTG;
		              CAM_TG_int  <= 0;
		          end
		          
		          S_assertTG: begin
		               CAM_TG_int <= 1;
		               cnt_cycles <= cnt_cycles + 1;
		               state_TG   <= cnt_cycles==CAM_TG_pulseWidth ? S_TG_idle : S_assertTG;   
		          end
		          
		      endcase
		end
    end


	trigger_camera_exposure exposure_handshake(
    		.rst(wirerst[0]),				//ip
    		.clk(CLKMi),					//ip
    		.re_busy(re_busy),				//ip			
    		.dram_flag(flag),				//ip
    		.external_trigger(CAM_TG_int),	//ip
    		.slave_mode(Select[31]),		//ip
    
    		.exp_trigger(re_triger)			//op
	);


/* Exposure wires*/
	wire [31:0] Tgl_res, Tdes2_d,Tdes2_w,Tmsken_w,Tmsken_d, Tgsub_w, TdrainR_d,TdrainF_d,MU_NUM_ROW, T_MU_wait;
	wire [9:0] ROWADD_EXP,ROWADD_EXP_i;

/*Readout wires */
	wire [31:0] T1,T2,T3,T4,T5,T6,T7,T8,Tbuck,TOSR,TADC,Tadd;
	wire [31:0] TExpRST, TReadRst;
	wire [31:0] LedNum, LedDly, LedExp, LedCtl, LedSeq;
	wire [9:0] ROWADD_RO, ROWADD_RO0, ROWADD_RO1;
	wire ADC_DATA_VALID, exp_busy;

	Exposure_v1_T7 exposure_inst (
		.rst(ep00wire[2]),
        .CLKM(CLKMi),
		.trigger_o(ex_trigger),
		.exp_busy(exp_busy),
		.re_busy(re_triger),
		.PIXGSUBC(PIX_GSUBC),
		.PIXDRAIN(PIX_DRAIN),
		.PIXGLOB_RES(PIXGLOB_RES_i),
		//.PIXGLOB_RES(PIXGLOB_RES),
		.PIXVTG_GLOB(PIXVTG_GLOB_i),
		.MASK_EN(MASK_EN),
		.EN_STREAM(rd_enable),
		.DES_2ND(DES2ND),
		.PROJ_TRG(PROJ_TRG),
		.ROWADD(ROWADD_EXP_i),
//		.contrastLED(contrastLED),

		.NUM_PAT(wireNumPat),
		.NUM_REP(NumRep),
		.NUM_ROW(MU_NUM_ROW),
		.NUM_GSUB(NumGsub),
		.Tproj_dly(Tproj_dly),
		.Tgl_res(Tgl_res),
		.Tadd(Tadd),
		.Texp_ctrl(wireExp),
		.Tdes2_d(Tdes2_d),
		.Tdes2_w(Tdes2_w),
		.Tmsken_d(Tmsken_d),
		.Tmsken_w(Tmsken_w),
		.Tgsub_w(Tgsub_w),
		.Treset(TExpRST),
		.TdrainR_d(TdrainR_d),
		.TdrainF_d(TdrainF_d),
		.T_MU_wait(T_MU_wait)
	);
	
	wire [31:0] TrigNo, TrigOffTime, TrigOnTime, TrigWaitTime;
	iamTriggered triggerMe(
	    .clk(TX_CLKi),                      // input clk                     
	    .trig_in(~PIXGLOB_RES_i),              // proj_trg generated by exposure
	    .trig_out(adc2_start_trigger),            // output trigger        
	    .TrigNo(TrigNo),                // Number of triggers     
	    .TrigOffTime(TrigOffTime),      // Off time for trigger            
	    .TrigOnTime(TrigOnTime),        // On time for trigger
	    .TrigWaitTime(TrigWaitTime)     // wait time for first trigger                
	);
	
	wire [31:0] TLEDNo, TLEDOff, TLEDOn, TLEDWait;
	wire contrastLED;
	iamTriggered contrastLEDTrigger(
	    .clk(clk_200),                      // input clk                     
	    .trig_in(~PIXGLOB_RES_i & ~PIX_GSUBC),              // proj_trg generated by exposure
	    .trig_out(contrastLED),            // output trigger        
	    .TrigNo(TLEDNo),                // Number of triggers     
	    .TrigOffTime(TLEDOff),      // Off time for trigger            
	    .TrigOnTime(TLEDOn),        // On time for trigger
	    .TrigWaitTime(TLEDWait)     // wait time for first trigger                
	);

	assign ADC_EN_PRE = 1'b1;
	 
	assign ROWADD = ROWADD_DEC;

	wire [31:0] ADC1_Tcolumn, ADC1_T1, ADC1_T2_1, ADC1_T2_0, ADC1_T3, ADC1_T4, ADC1_T5, ADC1_T6, ADC1_T7, ADC1_T8, ADC1_T9, ADC1_TADC, ADC1_NUM_ROW, ADC1_Wait;
	wire [31:0] ADC2_Tcolumn, ADC2_T1, ADC2_T2_1, ADC2_T2_0, ADC2_T3, ADC2_T4, ADC2_T5, ADC2_T6, ADC2_T7, ADC2_T8, ADC2_T9, ADC2_TADC, ADC2_NUM_ROW, ADC2_Wait;
	wire [9:0] ROWADD_RO_t7;
	Readout_Merge	u_Readout(
//	Readout_Full_T7	u_Readout(
		.rst				(wirerst[0]),
		
		.adc1_start_trigger (adc1_start_trigger),
		.adc1_busy 			(adc1_busy),

		.adc2_start_trigger (adc2_start_trigger & adc2_en),
		.adc2_busy 			(adc2_busy),
		
		.TX_CLK				(TX_CLKi),
		.TX_CLKx2			(TX_CLKi2),

		.ROWADD				(ROWADD_RO_t7),
		.SET_ROW			(SET_ROW_RO),
		.SET_ROW_DONE 		(SET_ROW_DONE_RO),

		.PIXLEFTBUCK_SEL	(PIX_LEFTBUCK_SEL_t7),
		.ODDCOL_EN			(ODDCOL_EN_t7),
		.PRECH_COL			(COL_PRECH_12_t7),
		.ADC_RST			(ADC_RST_t7),
		.ADC_CLK			(ADC_CLK_t7),

		.RST_BAR_LTCHD		(RST_BAR_LTCHD_t7),
		.LOAD_IN			(LOAD_IN_t7),
		.ADC_DATA_VALID		(ADC_DATA_VALID_t7),

		.PIXREAD_SEL		(PIXREAD_SEL_t7),
		.ADC_BIAS_EN		(ADC_BIAS_EN_t7),
		.COLL_EN			(COLL_EN_t7),
		.PIXRES				(PIXRES_t7),
		
		.ADC1_Tcolumn   (ADC1_Tcolumn),
		.ADC1_T1        (ADC1_T1),
		.ADC1_T2_1      (ADC1_T2_1),
		.ADC1_T2_0      (ADC1_T2_0),
		.ADC1_T3        (ADC1_T3),
		.ADC1_T4        (ADC1_T4),
		.ADC1_T5        (ADC1_T5),
		.ADC1_T6        (ADC1_T6),   
		.ADC1_T7        (ADC1_T7),
		.ADC1_T8        (ADC1_T8),
		.ADC1_T9        (ADC1_T9),
		.ADC1_TADC      (ADC1_TADC),
		.ADC1_NUM_ROW   (ADC1_NUM_ROW),
		.ADC1_Wait      (ADC1_Wait),

		.ADC2_Tcolumn   (ADC2_Tcolumn),
		.ADC2_T1        (ADC2_T1),
		.ADC2_T2_1      (ADC2_T2_1),
		.ADC2_T2_0      (ADC2_T2_0),
		.ADC2_T3        (ADC2_T3),
		.ADC2_T4        (ADC2_T4),
		.ADC2_T5        (ADC2_T5),
		.ADC2_T6        (ADC2_T6),
		.ADC2_T7        (ADC2_T7),
		.ADC2_T8        (ADC2_T8),
		.ADC2_T9        (ADC2_T9),
		.ADC2_TADC      (ADC2_TADC),
		.ADC2_NUM_ROW   (ADC2_NUM_ROW),
		.ADC2_Wait      (ADC2_Wait)			
	);	

	wire [8:0] mem_write_addr, mem_write_data, ROWADD_ADC2_MAPPED;
	wire [31:0] rowmapwire;
	wire mem_write_en;
	row_map_table map_rows_adc2(
		.clk(clk_200),
		.rowadd_in(ROWADD_RO_t7[8:0]),
		.rowadd_out(ROWADD_ADC2_MAPPED[8:0]),
		
		.mem_write_addr(mem_write_addr[8:0]), // address to write
		.mem_write_data(mem_write_data[8:0]), // what to write
		.we(mem_write_en)					  // when to write
	);
	wire [31:0] ROWADD_INCRMNT;
//	assign ROWADD_RO[8:0] 		= ROWADD_ADC2_MAPPED[8:0] + ROWADD_INCRMNT[8:0]	; 
	assign ROWADD_RO[8:0] 		= ROWADD_RO_t7[8:0] + ROWADD_INCRMNT[8:0]	; 
	assign ROWADD_EXP[8:0]      = ROWADD_EXP_i  + ROWADD_INCRMNT[8:0]			;
	assign mem_write_data[8:0] 	= rowmapwire[ 8:0]								;
	assign mem_write_addr[8:0] 	= rowmapwire[24:16]								;
	assign mem_write_en        	= rowmapwire[31]								;



	wire [31:0] T_DEC_SEL_0, T_DEC_SEL_1, T_DEC_EN_0, T_DEC_EN_1, T_DONE_1;
	wire [9:0]  ROWADD_DEC;
    set_row_decoder exp_ro_row_decoder(
		.clk(TX_CLKi),
		.rst(wirerst[0]),

		.ROWADD_MU(ROWADD_EXP),
		.ROWADD_RO(ROWADD_RO),
		.SET_ROW_MU(DES2ND),
		.SET_ROW_RO(SET_ROW_RO),
	
		.SET_ROW_DONE_MU(SET_ROW_DONE_MU),
		.SET_ROW_DONE_RO(SET_ROW_DONE_RO),
		.DEC_SEL(DEC_SEL),     
		.DEC_EN(DEC_EN),      
		.ROWADD_op(ROWADD_DEC),    


		.T_DEC_SEL_0(T_DEC_SEL_0[31:0]),
		.T_DEC_SEL_1(T_DEC_SEL_1[31:0]),
		.T_DEC_EN_0(T_DEC_EN_0[31:0]), 
		.T_DEC_EN_1(T_DEC_EN_1[31:0]), 
		.T_DONE_1(T_DONE_1[31:0])
    );	

	wire [17:1] DIGOUT_TEST, DIGOUT_IN;

    DIGOUT_test u_DIGOUT_test(
    	.clk			(TX_CLKi),
    	.rst			(adc2_start_trigger || adc1_start_trigger),
    	.RST_BAR_LTCHD	(RST_BAR_LTCHD_t7),
    	.ADC_DATA_VALID	(ADC_DATA_VALID),
    	.DIGOUT			(DIGOUT_TEST[17:1])
    );


	
    wire [4:1] ADC2FIFO_CLK;
	// wire adc_fifo_rst;
	// come in from chip ADC
	// go to ddr3 on board memroy 
	ADCtoFIFO i_adc_fifo(
        .rst(wirerst[0] || ex_trigger || PIXGLOB_RES_i),
        .rst_adc_parser(ex_trigger || PIXGLOB_RES_i),  // reset whenever exposure or readout starts
//        .adc_clk0_i(TXCLK_OUT),
//        .adc_clk0_i(ADC2FIFO_CLK),
        .adc_clk0_i(TX_CLKi),
        .adc_gr0_valid(ADC_DATA_VALID),
        .ch_data_i(DIGOUT_IN[17:1]),

        .p0_rd_clk(clk),
        .p0_rd_en(adc_fifo_rd_en),
        .p0_rd_data_cnt(adc_fifo_rd_count),
        .p0_full(adc_fifo_full),
        .p0_empty(adc_fifo_empty),
        .p0_valid(adc_fifo_valid),
        .p0_data_o(adc_fifo_dout)
    );



	wire rd0_valid;		
	wire [255:0] rd0_data;
	wire rd1_almost_full;
	wire [16:0] p0_out_rd_count;

	// come in from on board memroy	
	// go to laptop 
	//fifo_w256_512_r256_512_ib i_readout0 (
	fifo_w256_128_r256_128_ib i_readout0 (
		.rst(wirerst[0]),
		.wr_clk(clk),
		.rd_clk(okClk),
		.din(pipe0_out_wr_data), // Bus [255 : 0]
		.wr_en(pipe0_out_wr),
		.rd_en(rd0_valid&(~rd1_almost_full)),
		.dout(rd0_data), // Bus [255 : 0]
		.full(),
		.almost_full(),
		.empty(),
		.valid(rd0_valid),
		.rd_data_count(pipe0_out_rd_count), // Bus [6 : 0]
		.wr_data_count(pipe0_out_wr_count)); // Bus [6 : 0]

	fifo_w256_8192_r32_65536_cb i_readout1 (
		.rst(wirerst[0]),
		.clk(okClk),
		.din(rd0_data), // Bus [256 : 0]
		.wr_en(rd0_valid&(~rd1_almost_full)),
		.rd_en(p0_rd_en),
		.dout(p0_din_pipe), // Bus [31 : 0]
		.full(p0_full),
		.almost_full(rd1_almost_full),
		.empty(p0_empty),
		.rd_data_count(p0_out_rd_count), // Bus [16 : 0]
		.wr_data_count()); // Bus [13 : 0]


	wire [31:0] po_a3_din,   pi_83_dout;
	wire        po_a3_rd_en, pi_83_wr_en;
	fifo_w256_128_r32_1024 sub_img_out_fifo (
		.rst(wirerst[0]),

		.wr_clk(clk),
		.wr_en(pipe2_out_wr),
		.din(pipe2_out_wr_data), // Bus [256 : 0]
		.wr_data_count(pipe2_out_wr_count), // Bus [6 : 0]
		.full(pipe2_out_full),

		.rd_clk(okClk),
		.rd_en(po_a3_rd_en),
		.dout(po_a3_din), // Bus [31 : 0]
		.rd_data_count(), // Bus [9 : 0]
		.valid(),
		.empty(sub_img_out_fifo_empty)
	);

//	fifo_w32_1024_r256_128 sub_img_in_fifo (
//		.rst(wirerst[0]),

//		.wr_clk(okClk),
//		.wr_en(pi_83_wr_en),
//		.din(pi_83_dout), // Bus [31 : 0]
//		.wr_data_count(), // Bus [9 : 0]
//		.full(),

//		.rd_clk(clk),
//		.rd_en(pipe2_in_rd),
//		.dout(pipe2_in_rd_data), // Bus [256 : 0]
//		.rd_data_count(pipe2_in_rd_count), // Bus [6 : 0]
//		.empty(pipe2_in_empty),
//		.valid(pipe2_in_valid)
//	); 



  wire [31:0] imgCountTrig, SPI_CONTROL, I2C_DATA, I2C_CONTROL;
      
  assign trig60[0] = p0_full;
  assign trig60[1] = (p0_out_rd_count>imgCountTrig[16:0])&&(img_cnt==2);
  assign trig60[2] = p0_empty;
  assign trig60[3] = init_calib_complete;
  assign trig60[4] = sub_img_cnt==TrigNo;




  	//Adjust values of different parameters
	varValueSelector_T7 varValueSelector(
        .wr_en(ep02wire[0]),          // Address of the variable whose value needs to be changed
        .varAddress(ep04wire),          // Address of the variable whose value needs to be changed
        .varValueIn(ep03wire),         // Input Value of the variable
        .varValueOut(ep22wire),        // Output Value of the variable
		.clk(okClk),

		.numPattern(),
		.Texp_ctrl(),
		.Tdes2_d(Tdes2_d),
		.Tdes2_w(Tdes2_w),
		.Tmsken_d(Tmsken_d),
		.Tmsken_w(Tmsken_w),
		.Tgsub_w(Tgsub_w),
		.Tgl_Res(Tgl_Res),
		.Tproj_dly(Tproj_dly),
		.Tadd(Tadd),
		.NumRep(NumRep),
		.NumGsub(NumGsub),
		.TExpRST(TExpRST),
		.Tdrain_w(Tdrain_w),
		.imgCountTrig(imgCountTrig),
		.TdrainR_d(TdrainR_d),
		.TdrainF_d(TdrainF_d),
//		.TLedOn(TLedOn),
		.Select(Select),
		.CAM_TG_pulseWid(CAM_TG_pulseWid),
		.CAM_TG_HoldTime(CAM_TG_HoldTime),
		.CAM_TG_delay(CAM_TG_delay),
		.MASK_SIZE(MASK_SIZE),
		.IMG_SIZE(IMG_SIZE),
		.T_DEC_SEL_0(T_DEC_SEL_0),
		.T_DEC_SEL_1(T_DEC_SEL_1),
		.T_DEC_EN_0(T_DEC_EN_0),
		.T_DEC_EN_1(T_DEC_EN_1),
		.T_DONE_1(T_DONE_1),
		.MSTREAM_Select(MSTREAM_Select),
		.MU_NUM_ROW(MU_NUM_ROW),
		.SUB_IMG_SIZE(SUB_IMG_SIZE),
		.ADC1_Tcolumn(ADC1_Tcolumn),
		.ADC1_T1(ADC1_T1),
		.ADC1_T2_1(ADC1_T2_1),
		.ADC1_T2_0(ADC1_T2_0),
		.ADC1_T3(ADC1_T3),
		.ADC1_T4(ADC1_T4),
		.ADC1_T5(ADC1_T5),
		.ADC1_T6(ADC1_T6),
		.ADC1_T7(ADC1_T7),
		.ADC1_T8(ADC1_T8),
		.ADC1_T9(ADC1_T9),
		.ADC1_TADC(ADC1_TADC),
		.ADC1_NUM_ROW(ADC1_NUM_ROW),
		.ADC1_Wait(ADC1_Wait),
		.T_MU_wait(T_MU_wait),
		.ADC2_Tcolumn(ADC2_Tcolumn),
		.ADC2_T1(ADC2_T1),
		.ADC2_T2_1(ADC2_T2_1),
		.ADC2_T2_0(ADC2_T2_0),
		.ADC2_T3(ADC2_T3),
		.ADC2_T4(ADC2_T4),
		.ADC2_T5(ADC2_T5),
		.ADC2_T6(ADC2_T6),
		.ADC2_T7(ADC2_T7),
		.ADC2_T8(ADC2_T8),
		.ADC2_T9(ADC2_T9),
		.ADC2_TADC(ADC2_TADC),
		.ADC2_NUM_ROW(ADC2_NUM_ROW),
		.ADC2_Wait(ADC2_Wait),
//		.T_MU_wait(T_MU_wait),
		.TrigNo(TrigNo),
		.TrigOffTime(TrigOffTime),
		.TrigOnTime(TrigOnTime),
		.UNIT_SUB_IMG_SIZE(UNIT_SUB_IMG_SIZE),
		.N_SUBREADOUTS(N_SUBREADOUTS),
		.SPI_CONTROL(SPI_CONTROL),
		.I2C_DATA(I2C_DATA),	//I2C no longer used for new T7 board
		.I2C_CONTROL(I2C_CONTROL),
		.ROWADD_INCRMNT(ROWADD_INCRMNT),
		.TrigWaitTime(TrigWaitTime),
		.TLEDNo(TLEDNo),
		.TLEDOff(TLEDOff),
		.TLEDOn(TLEDOn),
		.TLEDWait(TLEDWait)
    );


    //* spi module instantiation
	wire [7:0] SPI_SS, CIS_SPI_SS;
	wire CPOL, CPHA, CPOL_sensor, CPHA_sensor;
	
	//assign CS_POT2 = SPI_SS[0];
	//assign CS_POT1= SPI_SS[1];
	assign CS_POT1 = 0;
	assign CS_POT2 = 0;
	assign CS_POT3 = 0;

    assign CS_VREFP = SPI_SS[2];
    assign CS_VREFN = SPI_SS[3];

	assign IBIAS_POT = SPI_SS[4];
	assign RS_POT = 1;
	assign CS_ADC1 = SPI_SS[5];
	assign CS_ADC2 = SPI_SS[6];

	assign SPI_SS_READOUT 		= CIS_SPI_SS[0];
	assign SPI_SS_MASK_UPLOAD 	= CIS_SPI_SS[1];

  	//////// spi laptop control
	wire ldo_wr_en;
	wire [31:0] ldo_wr_data;
	wire cis_wr_en;
	wire [31:0] cis_wr_data;

	//assign POT_WP 	= SPI_CONTROL[0];
	assign VREF_EN 	= SPI_CONTROL[1];


	spi_master_v1 #(
		.NUM(1),
		.CLK_RATIO(800),
		.SS_SPACE(30)
	) i_ldo (
				.rst(wirerst[0]),
        .clk(clk), 
        .wr_clk(okClk), 
        .wr_en(ldo_wr_en), 
        .wr_data(ldo_wr_data), 
        .MISO(0), 
        .SPI_SS(SPI_SS), 
        .MOSI(SDI), 
        .SPI_CLK(SCLK)
    );
    assign RESET_N = 1;
	spi_master_v1 #(
		.NUM(6),
		.CLK_RATIO(8000),
		.SS_SPACE(30)
	) i_cis (
		.rst(wirerst[0]),
        .clk(clk), 
        .wr_clk(okClk), 
        .wr_en(cis_wr_en), 
        .wr_data(cis_wr_data), 
        .MISO(0), 
        .SPI_SS(CIS_SPI_SS),  
        .MOSI(SPI_DIN), 
        .SPI_CLK(SPI_CLK) 
    );

	//**********TEST POINTS START
	
function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7310_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

assign led = xem7310_led({p0_empty,p0_full,ex_trigger,re_triger,re_busy,1'b0,ep00wire[0],ep00wire[1]});

wire [9:0] testBus1, testBus2, testBus3, testBus4,testBus5,testBus6,testBus7;
assign testBus1[9:1] = {DEC_EN,DEC_SEL,ROWADD[7:1]};
assign testBus2[9:1] = {po_a3_rd_en, pipe2_out_wr, pipe2_out_full, pipe2_out_wr_count[6:1]};
assign testBus3[9:1] = {pipe2_in_rd, pi_83_wr_en,  pipe2_in_empty, pipe2_in_rd_count[6:1]};
assign testBus4[9:1] = app_addr[11:3];
assign testBus5[9:1] = sub_img_cnt[8:0];
assign testBus6[9:1] = {mem_write_en, mem_write_addr[8:1]};
assign testBus7[9:1] = {mem_write_en, mem_write_data[8:1]};

//assign TEST_IO[1] = Select[11] ? (Select[1] ? testBus6[1]: testBus7[1]): (Select[1] ? adc_fifo_empty: ODDCOL_EN);
assign TEST_IO[1] = contrastLED;
assign TEST_IO[2] = Select[12] ? (Select[1] ? testBus1[2]: testBus7[2]): (Select[2] ? COL_PRECH_12     : PIX_LEFTBUCK_SEL);
assign TEST_IO[3] = Select[13] ? (Select[1] ? testBus1[3]: testBus7[3]): (Select[3] ? adc_fifo_rd_en   : ADC_DATA_VALID);
assign TEST_IO[4] = Select[14] ? (Select[1] ? testBus1[4]: testBus7[4]): (Select[4] ? ADC_RST          : LOAD_IN);
assign TEST_IO[5] = Select[15] ? (Select[1] ? testBus1[5]: testBus7[5]): (Select[5] ? COL_PRECH_12     : RST_BAR_LTCHD);
assign TEST_IO[6] = Select[16] ? (Select[1] ? testBus1[6]: testBus7[6]): (Select[6] ? DIGOUT[9]        : adc2_start_trigger);
assign TEST_IO[7] = Select[17] ? (Select[1] ? testBus1[7]: testBus7[7]): (Select[7] ? DIGOUT[10]       : re_busy);
assign TEST_IO[8] = Select[18] ? (Select[1] ? testBus1[8]: testBus7[8]): (Select[8] ? TX_CLKi          : re1bit_busy);
assign TEST_IO[9] = Select[19] ? (Select[1] ? testBus1[9]: testBus7[9]): (Select[9] ? PIX_LEFTBUCK_SEL : MASK_EN);

assign DIGOUT_IN[17:1] = Select[29] ? DIGOUT_TEST  : DIGOUT   ;
assign ADC2FIFO_CLK = 	{4{TX_CLKi}}; //Select[30] ? {4{TX_CLKi}} : DCLK[4:1] ;

assign STDBY12            = 0;
assign COL_EN             = 1;
assign PIXRES 			  = 0;

assign PIX_LEFTBUCK_SEL   = Select[21] ? 1 :  PIX_LEFTBUCK_SEL_t7; 
assign PIX_RIGHTBUCK_SEL  = Select[21] ? 0 :  ~PIX_LEFTBUCK_SEL_t7;

assign CLKMi 			  = Select[22] ? clk_50: clk100;

// Select[23] and Select[24] free

assign adc1_en            = Select[25];
assign adc2_en            = Select[26];
assign adc2_leftoverdata  = adc2_en && (sub_img_cnt != 0);

assign PIXVTG_GLOB        = Select[27] ? 1 : PIXVTG_GLOB_i;
assign PIX_ROWMASK 		  = Select[27] ? 0 : 1'b1;
assign ODDCOL_EN          = Select[28] ? ~ODDCOL_EN_t7 : ODDCOL_EN_t7;

assign COL_PRECH_12       = COL_PRECH_12_t7     ;
assign ADC_RST            = ADC_RST_t7          ;
assign ADC_CLK            = ADC_CLK_t7			;

assign RST_BAR_LTCHD      = RST_BAR_LTCHD_t7    ;
assign LOAD_IN            = LOAD_IN_t7          ;
assign ADC_DATA_VALID     = ADC_DATA_VALID_t7   ;

assign COLL_EN            = COLL_EN_t7          ;
//assign PIXREAD_EN         = PIXREAD_SEL_t7      ;


assign PIX_GLOB_RES_R     = PIXGLOB_RES_i;
assign PIX_GLOB_RES_L     = PIXGLOB_RES_i;

assign re1bit_busy        = adc2_busy;
assign adc1_start_trigger = adc1_en & ex_trigger;
assign re_busy            = adc1_en ? adc1_busy : ex_trigger;                    

//Block Throttle
always @(posedge okClk) begin
	// Check for enough space in input FIFO to pipe in another block
	if(pipe_in_wr_count <= (1024-128) ) begin
		pipe_in_ready <= 1'b1;
	end
	else begin
		pipe_in_ready <= 1'b0;
	end

	// Check for enough space in output FIFO to pipe out another block
	if(pipe_out_rd_count >= 128) begin
		pipe_out_ready <= 1'b1;
	end
	else begin
		pipe_out_ready <= 1'b0;
	end
end


// Instantiate the okHost and connect endpoints.
    wire [65*11-1:0] okEHx;
okHost okHI(
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),
	.okClk(okClk),
	.okHE(okHE), 
	.okEH(okEH)
);

okWireOR # (.N(11)) wireOR (okEH, okEHx);

okWireIn    wi00 (.okHE(okHE),   .ep_addr(8'h00), .ep_dataout(ep00wire));  // DDR3
okWireIn    wi01 (.okHE(okHE),   .ep_addr(8'h01), .ep_dataout(ep01wire));  // test wire
okWireIn    wi02 (.okHE(okHE),   .ep_addr(8'h02), .ep_dataout(ep02wire));  // read number 
okWireIn    wi03 (.okHE(okHE),   .ep_addr(8'h03), .ep_dataout(ep03wire));  // read address 
okWireIn    wi04 (.okHE(okHE),   .ep_addr(8'h04), .ep_dataout(ep04wire));  // read address 
okWireIn    wi08 (.okHE(okHE),   .ep_addr(8'h08), .ep_dataout(spi_din) );
okWireIn    wi09 (.okHE(okHE),   .ep_addr(8'h09), .ep_dataout(spi_target) );
okWireIn    wi0A (.okHE(okHE),   .ep_addr(8'h0A), .ep_dataout(rowmapwire) );
okWireIn    wi10 (.okHE(okHE),   .ep_addr(8'h10), .ep_dataout(wirerst) );
okWireIn    wi11 (.okHE(okHE),   .ep_addr(8'h11), .ep_dataout(wireExp) );
okWireIn    wi12 (.okHE(okHE),   .ep_addr(8'h12), .ep_dataout(wireNumPat));
okWireIn    wi13 (.okHE(okHE),   .ep_addr(8'h13), .ep_dataout(modesel) );
okWireIn    wi14 (.okHE(okHE),   .ep_addr(8'h14), .ep_dataout(wireNumPatMem) );
okWireIn 	wi16 (.okHE(okHE),   .ep_addr(8'h16), .ep_dataout(wirePhaseSel)   ); //testmodimp
okWireIn 	wi18 (.okHE(okHE),   .ep_addr(8'h18), .ep_dataout(wireMinFrameTime) );
okWireIn 	wi19 (.okHE(okHE),   .ep_addr(8'h19), .ep_dataout(wireProjDelay) );
        
okWireOut     wi20 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut     wi21 (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h21), .ep_datain({16'd0,p0_out_rd_count}));
okWireOut     wi22 (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h22), .ep_datain(ep22wire));

	
okTriggerIn 	ti40 (.okHE(okHE),							   						 .ep_addr(8'h40), .ep_clk(okClk), .ep_trigger(trig40));
okTriggerOut	to60 (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'h6a), .ep_clk(okClk), .ep_trigger(trig60));

okPipeOut		pob0 (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'hb0), .ep_read(p0_rd_en), 				  .ep_datain(p0_din_pipe));	
okBTPipeIn		pi80 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h80), .ep_write(pi0_ep_write), .ep_blockstrobe(), .ep_dataout(pi0_ep_dataout), .ep_ready(pipe_in_ready));
okBTPipeOut		poa0 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(po0_ep_read), .ep_blockstrobe(), .ep_datain(po0_ep_datain), .ep_ready(pipe_out_ready));

okPipeIn 		pi81 (.okHE(okHE), .okEH(okEHx[ 7*65 +: 65 ]), .ep_addr(8'h81), .ep_write(ldo_wr_en), .ep_dataout(ldo_wr_data));//ldo
okPipeIn 		pi82 (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h82), .ep_write(cis_wr_en), .ep_dataout(cis_wr_data));//cis

okPipeOut       poa3 (.okHE(okHE), .okEH(okEHx[ 9*65 +: 65 ]), .ep_addr(8'ha3), .ep_read(po_a3_rd_en), .ep_datain(po_a3_din));  //subframe out
okPipeIn        pi83 (.okHE(okHE), .okEH(okEHx[10*65 +: 65 ]), .ep_addr(8'h83), .ep_write(pi_83_wr_en),.ep_dataout(pi_83_dout));//subframe in test

fifo_w32_1024_r256_128 okPipeIn_fifo (
	.rst(ep00wire[2]),
	.wr_clk(okClk),
	.rd_clk(clk),
	.din(pi0_ep_dataout), // Bus [31 : 0]
	.wr_en(pi0_ep_write),
	.rd_en(pipe_in_read),
	.dout(pipe_in_data), // Bus [256 : 0]
	.full(pipe_in_full),
	.empty(pipe_in_empty),
	.valid(pipe_in_valid),
	.rd_data_count(pipe_in_rd_count), // Bus [6 : 0]
	.wr_data_count(pipe_in_wr_count)); // Bus [9 : 0]

fifo_w256_128_r32_1024 okPipeOut_fifo (
	.rst(ep00wire[2]),
	.wr_clk(clk),
	.rd_clk(okClk),
	.din(pipe_out_data), // Bus [256 : 0]
	.wr_en(pipe_out_write),
	.rd_en(po0_ep_read),
	.dout(po0_ep_datain), // Bus [31 : 0]
	.full(pipe_out_full),
	.empty(pipe_out_empty),
	.valid(),
	.rd_data_count(pipe_out_rd_count), // Bus [9 : 0]
	.wr_data_count(pipe_out_wr_count)); // Bus [6 : 0]



// Xilinx HDL Libraries Guide, version 13.3
ODDR #(
	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
	.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) ODDR_CLKM (
	.Q(CLKM), // 1-bit DDR output
	.C(CLKMi), // 1-bit clock input
	.CE(1'b1), // 1-bit clock enable input
	.D1(1'b0), // 1-bit data input (positive edge)
	.D2(1'b1), // 1-bit data input (negative edge)
	.R(1'b0), // 1-bit reset
	.S(1'b0) // 1-bit set
	);
// End of ODDR_inst instantiation

// Xilinx HDL Libraries Guide, version 13.3
ODDR #(
	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
	.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
	.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
	) ODDR_TX_CLK (
	.Q(TX_CLK_IN ), // 1-bit DDR output
	.C(TX_CLKi), // 1-bit clock input
	.CE(1'b1), // 1-bit clock enable input
	.D1(1'b1), // 1-bit data input (positive edge)
	.D2(1'b0), // 1-bit data input (negative edge)
	.R(1'b0), // 1-bit reset
	.S(1'b0) // 1-bit set
	);
// End of ODDR_inst instantiation


endmodule
