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


module Reveal_Top_v0
(
	input  wire [4:0]   okUH,
	output wire [2:0]   okHU,
	inout  wire [31:0]  okUHU,
	inout  wire         okAA,

	input  wire         sys_clk_p,
	input  wire         sys_clk_n,

	output wire [7:0]   led,

/********************** DDR3 RAM *****************************/
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

/************** TestHeader *****************/
  output wire [20:1] TestIO,
  output wire LaserIO_9,
	output wire LaserIO_11,

/********************** IMAGER *****************************/
	/************** MASKING ********************/
	output wire [16:1] mSTREAM,
	output wire MASK_EN,
	output wire CLKM,
	output wire DES,
	output wire SYNC,
	output wire RESET_N,

	/************** ROWDRIVER *****************/
	output wire PIX_GSUBC,
	output wire PIX_ROWMASK,         //MASKING
	output wire PIXREAD_EN,
	output wire PIXLEFTBUCK_SEL,    //READOUT
	output wire [9:0] ROWADD,                               //MASKING and READOUT
	output wire PIXDRAIN,
	output wire PIXGLOB_RES,
	output wire PIXVTG_GLOB,
	output wire PIXRES, //RESET

	/*************** READOUT *****************/
	output wire PGA_RES,
	output wire SAMP_R,
	output wire SAMP_S,//PGA SPECIFIC
	output wire CK_PH1,
	output wire READ_R,
	output wire READ_S, //PGA SPECIFIC
	output wire CP_COLMUX_IN,
	output wire MUX_START,            //ANALOG OUTPUT MUX CONTROL
	output wire RO_CLK_100,                             //CLK to interanally latch readout signals
	output wire COL_L_EN,
	output wire STDBY,
	output wire COL_PRECH,

	/*************** ToF *****************/
	output wire EXP,
	output wire FPGA_MOD0,
	output wire FPGA_MOD90,

	/*************** IMAGE SENSOR SPI *****************/
	output wire IS_SPI_DATA,
	output wire IS_SPI_CLK,
	output wire IS_SPI_UPLOAD,

/********************** PCB *****************************/
  /************** PCB SPI CONTROL***************/
  output wire PCB_SPI_DIN,
	output wire PCB_SPI_CLK,
  input wire PCB_SPI_DOUT,

  /************ PCB SPI CS & RST **************/
  output wire CS_POT1,
	output wire CS_POT2,
	output wire RS_POT,       //LDO POTS
  output wire CS_PLL,
	output wire CS_IBIAS,
  output wire CS_ADC1,
	output wire CS_ADC2,
	output wire CS_ADC_LDO,   //ADC

  /************ PCB ADC DATA & CTRL **************/
  output wire ADC_LDO_CLK,                                //LDO ADC CLK
  output wire ADC_CLK_OUT,                                //Input clocks for TI-ADCs ICs
  output wire ADC1_SHR,
	output wire ADC2_SHR,             //Sample and hold control for TI-ADC ICs

  input wire ADC1_DATA_CLK,
	input wire ADC2_DATA_CLK,     //Output clocks from TI-ADC ICs
  input wire [7:0] ADC1_DATA,
	input wire [7:0] ADC2_DATA, //Output data from TI-ADC ICs

  /*************** PCB PLL CTRL ****************/
  output wire PLL_ToF,
	output wire PLL_SYNC,

  /********* PCB LEVEL CONVERTER CTRL **********/
  output wire LC_EN
);

/************************************************/
//*********Opal Kelly inputs and outputs**********
/************************************************/
wire 		okClk;
wire [31:0] trig40; //triggers
wire [31:0] trig41; //triggers
wire [31:0] trig60;

wire [31:0] ep00wire;   //PCB_SPI_DATA
wire [31:0] ep01wire;
wire [31:0] ep02wire;
wire [31:0] ep03wire;
wire [31:0] ep04wire;
wire [31:0] ep20wire;
wire [31:0] ep21wire;
wire [31:0] ep22wire;

//pipe fifos

wire         pi0_ep_write;
wire         po0_ep_read;
wire [31:0]  pi0_ep_dataout;
wire [31:0]  po0_ep_datain;

wire         p0_rd_en;
wire         p0_full;
wire         p0_empty;
wire				 p0_prg_full;
wire [31:0]  p0_din_pipe;
wire [17:0]	 p0_rd_data_cnt;

wire         p1_rd_en;
wire         p1_full;
wire         p1_empty;
wire				 p1_prg_full;
wire [31:0]  p1_din_pipe;
wire [17:0]	 p1_rd_data_cnt;


wire         pipe_in_read;
wire [255:0] pipe_in_data;
wire [6:0]   pipe_in_rd_count;
wire [9:0]   pipe_in_wr_count;
wire         pipe_in_valid;
wire         pipe_in_full;
wire         pipe_in_empty;
reg          pipe_in_ready;

wire         pipe_out_write;
wire [255:0] pipe_out_data;
wire [9:0]   pipe_out_rd_count;
wire [6:0]   pipe_out_wr_count;
wire         pipe_out_full;
wire         pipe_out_empty;
reg          pipe_out_ready;



wire [255:0] pipe0_in_rd_data;
wire [  6:0] pipe0_in_rd_count;
wire [  8:0] pipe0_in_wr_count;
wire 				 pipe0_in_rd;
wire 				 pipe0_in_valid;
wire 				 pipe0_in_empty;
wire 				 pipe0_in_full;

wire [255:0] pipe0_out_wr_data;
wire [  6:0] pipe0_out_wr_count;
wire [  6:0] pipe0_out_rd_count;
wire 				 pipe0_out_wr;
wire 				 pipe0_out_full;


wire [255:0] pipe1_in_rd_data;
wire [  6:0] pipe1_in_rd_count;
wire [  8:0] pipe1_in_wr_count;
wire 				 pipe1_in_rd;
wire 				 pipe1_in_valid;
wire 				 pipe1_in_empty;


/* Readout wires */
wire [31:0] T1_e, T2_e, T3_e, T4_e, T5_e, T6_e, T7_e, T8_e, T9_e;
wire [31:0] T1_r, T2_r, T3_r, T4_r, T5_r, T6_r;
wire [31:0] Tgl_res;
wire [31:0] T_stdby;
wire [31:0] Texp_ctrl;
wire [31:0] NumPat;
wire [31:0] T_reset;
wire [31:0] NumRow;
wire [31:0] Tlat1;
wire [31:0] Tlat2;
wire 				adc1_dat_valid;
wire 				adc2_dat_valid;


wire [31:0] wirerst;
wire [31:0] wireNumPat;
wire [31:0] modesel;
wire [31:0] wireNumTri;
wire [31:0] camstart;


wire [31:0] testWireIn;
wire [31:0] testWireOut;
wire [15:0] FIFO_IN_DATA1;
wire [15:0] FIFO_IN_DATA2;

//MIG Infrastructure Reset
wire ui_clk;
reg sys_rst;
reg [31:0] rst_cnt;
initial sys_rst = 1;
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
	.ui_clk                         (ui_clk),
	.ui_clk_sync_rst                (),

	.app_wdf_mask                   (app_wdf_mask),

	// System Clock Ports
	.sys_clk_p                      (sys_clk_p),
	.sys_clk_n                      (sys_clk_n),

	.sys_rst                        (sys_rst)
	);

wire [2:0] img_cnt;
wire [31:0] NumRep;

//ddr3_test_v3 i_ddr3_ctl (
ddr3_ctl_v0 i_ddr3_ctl (
	.clk                (ui_clk),
	.reset              (ep01wire[2] | wirerst[0]),
	.reads_en           (ep01wire[0]),
	.writes_en          (ep01wire[1]),
	.test_en	          (modesel[0]),		// enable runnging mode
	.calib_done         (init_calib_complete),
  .img_cnt        	  (img_cnt),
  .NUM_PAT        	  (NumPat), //TODO rewire this to wireNumPatMem
  .NUM_REP        	  (NumRep),
  .IMG_ROW        	  (NumRow),

	// channel 0
	.ib0_re              (pipe_in_read),
	.ib0_data            (pipe_in_data),
	.ib0_count           (pipe_in_rd_count),
	.ib0_valid           (pipe_in_valid),
	.ib0_empty           (pipe_in_empty),

	.ob0_we              (pipe_out_write),
	.ob0_data            (pipe_out_data),
	.ob0_count           (pipe_in_wr_count), //TODO also interaction with cache_wr_count
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
    //.mask_addr_mem      (2560)
	);

/************************************************/
//**************** System clocks ****************
/************************************************/
//CLK Instantiation
wire clk_400,clk_200,clk_100,clk_50,clk_10,clk_022;
clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_400(clk_400),     // output clk_400
    .clk_200(clk_200),     // output clk_200
    .clk_100(clk_100),     // output clk_100
    .clk_050(clk_50),     // output clk_out4
    .clk_022(clk_022),
    .clk_015(),
    .clk_010(clk_10),
   // Clock in ports
    .clk_in1(ui_clk));

assign ADC_CLK_OUT = clk_10;

//assign mSTREAM[16:1] = {16{dout[2]}};
assign CLKM = clk_100;
assign ADC_LDO_CLK = ADC_CLK_OUT;
assign LC_EN = 0;
/************************************************/
//******************* PCB_SPI *******************
/************************************************/
wire [31:0] DOUT;
wire pcb_spi_trigger;
wire [7:0] pcb_spi_target;
assign pcb_spi_trigger = trig40[0];

SPI_top pcb_spi_inst(
    .clk(clk_100),                  //input:    reference clock
    .DIN(ep00wire),                 //input:    {DATA{15:0},6'b0,CPOL,CPHA,target[7:0]}
    .DOUT(DOUT[31:0]),              //output:   {DESERIALIZED DATA FROM SPI_DOUT}
    .trigger(pcb_spi_trigger),      //input:    {trigger to start the SPI}
    .SPI_CLK(PCB_SPI_CLK),          //output:   based on CPOL,CPHA information of DIN
    .SPI_DIN(PCB_SPI_DIN),          //output:   based on DATA information of DIN
    .TARGET(pcb_spi_target[7:0]),   //output:   based on target information of DIN
    .SPI_DOUT(PCB_SPI_DOUT)         //input:    input to the FPGA from SPI slaves
);

assign RS_POT   = 1;
assign CS_POT1  = pcb_spi_target[0];
assign CS_POT2  = pcb_spi_target[1];
assign CS_PLL   = pcb_spi_target[2];
assign CS_ADC1  = pcb_spi_target[3];
assign CS_ADC2  = pcb_spi_target[4];


/************************************************/
//******************* CIS T5 SPI *******************
/************************************************/
assign IS_SPI_UPLOAD = ~ep00wire[5];    //This is the special case of spi upload controlled through python code
                                        //IS_SPI_UPLOAD must go low before cis_spi_trigger
                                        //It should become high after 4 cis_spi_trigger(controlled through python code)
wire cis_spi_trigger;
assign cis_spi_trigger = trig40[2];

SPI_top cis_spi_inst(
    .clk(clk_100),                  //input:    reference clock
    .DIN(ep00wire),                 //input:    {DATA{15:0},6'b0,CPOL,CPHA,target[7:0]}
//    .DOUT(DOUT[31:0]),              //output:   {DESERIALIZED DATA FROM SPI_DOUT}
    .trigger(cis_spi_trigger),      //input:    {trigger to start the SPI}
    .SPI_CLK(IS_SPI_CLK),          //output:   based on CPOL,CPHA information of DIN
    .SPI_DIN(IS_SPI_DATA)          //output:   based on DATA information of DIN
//    .TARGET(pcb_spi_target[7:0])   //output:   based on target information of DIN
//    .SPI_DOUT(PCB_SPI_DOUT)         //input:    input to the FPGA from SPI slaves
);

/************************************************/
//******************* MASK UPLOAD *******************
/************************************************/
wire 		 mask_fifo_rd;
wire [255:0] cache_data;
wire [9:0]   cache_rd_count;
wire [6:0]   cache_wr_count;
wire [6:0]   wr_count;
wire         cache_rd_en;
wire         cache_full;
wire         ob_full;
wire         cache_empty;
wire         cache_valid;
reg          cache_ready;

//fifo_w256_128_r256_128_ib i_mask_cache (
//	.rst(ep01wire[2] | wirerst[0]),
//	.wr_clk(ui_clk),
//	.rd_clk(CLKM),
//	.din(pipe_out_data), // Bus [256 : 0]
//	.wr_en(pipe_out_write),
//	.rd_en(cache_rd_en),
//	.dout(cache_data), // Bus [31 : 0]
//	.full(cache_full),
//	.empty(cache_empty),
//	.valid(cache_valid),
//	.rd_data_count(cache_rd_count), // Bus [9 : 0]
//	.wr_data_count(cache_wr_count)); // Bus [6 : 0]
//
//
////testing
//patternToSensors_v0 u_patternToSensors(
//    .reset(ep01wire[2] | wirerst[0]),
//    .clk(CLKM),   // write in clk
//    //.Num_Pat(wireNumPat),			// number of patterns
//    .Num_Pat(NumPat),			// number of patterns
//    //.Num_Pat(1),			// number of patterns
//
//    .stream_en_i(mask_fifo_rd),    // test use , indicate data is writting to sensor fifo
//    .stream_en_o(EN_STREAM),    // test use , indicate data is writting to sensor fifo
//    //.stream_en_o(),    // test use , indicate data is writting to sensor fifo
//    .MSTREAMOUT(mSTREAM),    // final output from oddr
//    //.MSTREAMOUT(),    // final output from oddr
//
//    .stream_clk(CLKM),  // stream read out clk
//    .rd_en(cache_rd_en),						// rd_en for cache fifo
//    .empty(0),
//    .valid(1),
//    //.MSTREAM32(fake_data) //testing
//    .MSTREAM32() //testing
//);


	//actual
//patternToSensors_v0 u_patternToSensors(
//  .reset(ep01wire[2]),
//  .clk(clk_100),   // write in clk
//  .Num_Pat(wireNumPat),			// number of patterns
//  //.Num_Pat(1),			// number of patterns
//
//  .stream_en_i(mask_fifo_rd),    // test use , indicate data is writting to sensor fifo
//  .stream_en_o(EN_STREAM),    // test use , indicate data is writting to sensor fifo
//  //.stream_en_o(),    // test use , indicate data is writting to sensor fifo
//  .MSTREAMOUT(mSTREAM),    // final output from oddr
//  //.MSTREAMOUT(),    // final output from oddr
//
//  .stream_clk(CLKM),  // stream read out clk
//  .rd_en(cache_rd_en),						// rd_en for cache fifo
//	.empty(cache_empty),
//	.valid(cache_valid),
//  .MSTREAM32(cache_data)
//
//);

//wire [255:0] fake_data;
//wire [31:0] fake_data_wire_0;
//wire [31:0] fake_data_wire_1;
//wire [31:0] fake_data_wire_2;
//wire [31:0] fake_data_wire_3;
//wire [31:0] fake_data_wire_4;
//wire [31:0] fake_data_wire_5;
//wire [31:0] fake_data_wire_6;
//wire [31:0] fake_data_wire_7;
//
//assign fake_data[31:0] = fake_data_wire_0;
//assign fake_data[63:32] = fake_data_wire_1;
//assign fake_data[95:64] = fake_data_wire_2;
//assign fake_data[127:96] = fake_data_wire_3;
//assign fake_data[159:128] = fake_data_wire_4;
//assign fake_data[191:160] = fake_data_wire_5;
//assign fake_data[223:192] = fake_data_wire_6;
//assign fake_data[255:224] = fake_data_wire_7;






/************************************************/
//******************* EXP & RO *******************
/************************************************/

wire ex_trigger;
wire re_busy;

wire [9:0] ROWADD_EXP;
wire [9:0] ROWADD_RO;

assign ROWADD = (re_busy) ? ROWADD_RO : ROWADD_EXP;

reg re_triger;
always @(posedge CLKM) begin
	//re_triger <= re_busy|(~p0_empty);
	//re_triger <= re_busy|(img_cnt==2)|~camstart[0];
	re_triger <= re_busy|~p0_empty|~camstart[0];
end

assign STDBY = 0;
assign EXP = 0;
Exposure_v2 exposure_inst(
    //.STDBY(STDBY),
    //.NUM_SUB(wireNumPat), //TODO MAY WANT TO ADD THIS TO VARVALUESELECTOR
    .NUM_SUB(NumPat), //TODO MAY WANT TO ADD THIS TO VARVALUESELECTOR
    .rst(wirerst[0]),
    .CLKM(CLKM),
    .MASK_EN(MASK_EN),
		.EN_STREAM(mask_fifo_rd),
    .PIXDRAIN(PIXDRAIN),
    .PIXGLOB_RES(PIXGLOB_RES),
    .PIXVTG_GLOB(PIXVTG_GLOB),
    .PIXREAD_EN(PIXREAD_EN),
//    .EXP(EXP),
    .PIXGSUBC(PIX_GSUBC),
    .PIXROWMASK(PIX_ROWMASK),
    .DES(DES),
    .SYNC(SYNC),
    .ROWADD(ROWADD_EXP),
    .trigger_o(ex_trigger),
    .re_busy(re_triger),
    .T_stdby(T_stdby),
    .T_reset(T_reset),
    .Tgl_res(Tgl_res),
    .Texp_ctrl(Texp_ctrl),
    .T1(T1_e),
    .T2(T2_e),
    .T3(T3_e),
    .T4(T4_e),
    .T5(T5_e),
    .T6(T6_e),
    .T7(T7_e),
    .T8(T8_e),
    .T9(T9_e)
    );
assign PIXLEFTBUCK_SEL = COL_L_EN;

assign READ_S = ~COL_PRECH;

Readout_v3 readout_inst (
	.rst		(wirerst[0]),
	.CLK		(clk_100),
	.trigger	(ex_trigger),
	.re_busy	(re_busy),

	.ROWADD		(ROWADD_RO),

	.COL_L_EN	(COL_L_EN),
	.COL_PRECH	(COL_PRECH),
	.CP_MUX_IN	(CP_COLMUX_IN),
	.MUX_START	(MUX_START),
	.PIXRES		(PIXRES),
	.PH1		(CK_PH1),
	.PGA_RES	(PGA_RES),
	.SAMP_R		(SAMP_R),
	.SAMP_S		(SAMP_S),
	.READ_R		(READ_R),
	//.READ_S		(READ_S),
	//.READ_R		(),
	.READ_S		(),

	.T1		(T1_r),
	.T2		(T2_r),
	.T3		(T3_r),
	.T4		(T4_r),
	.T5		(T5_r),
	.T6		(T6_r),

	.adc_clk(ADC_CLK_OUT),
	.adc1_out_clk(ADC1_DATA_CLK),
	.adc2_out_clk(ADC2_DATA_CLK),
	.Tlat1(Tlat1),
	.Tlat2(Tlat2),
	.adc1_dat_valid(adc1_dat_valid),
	.adc2_dat_valid(adc2_dat_valid),
	.NUM_ROW	(NumRow)
);


wire rd0_valid;
wire [255:0] rd0_data;
wire rd1_almost_full;
wire [15:0] p0_out_rd_count;

// come in from on board memroy
// go to laptop
//fifo_w256_128_r256_128_ib i_readout0 (
//	.rst(wirerst[0]),
//	.wr_clk(ui_clk),
//	.rd_clk(okClk),
//	.din(pipe0_out_wr_data), // Bus [255 : 0]
//	.wr_en(pipe0_out_wr),
//	.rd_en(rd0_valid&(~rd1_almost_full)),
//	.dout(rd0_data), // Bus [255 : 0]
//	.full(),
//	.almost_full(),
//	.empty(),
//	.valid(rd0_valid),
//	.rd_data_count(pipe0_out_rd_count), // Bus [6 : 0]
//	.wr_data_count(pipe0_out_wr_count)); // Bus [6 : 0]
//
//
//
////fifo_w256_8192_r32_65536_cb i_readout1 (
//fifo_w256_2048_r32_16384_cb i_readout1 (
//	.rst(wirerst[0]),
//	.clk(okClk),
//	.din(rd0_data), // Bus [256 : 0]
//	.wr_en(rd0_valid&(~rd1_almost_full)),
//	//.rd_en(p0_rd_en),
//	//.dout(p0_din_pipe), // Bus [31 : 0]
//	//.full(p0_full),
//	.rd_en(),
//	.dout(), // Bus [31 : 0]
//	.full(),
//	.almost_full(rd1_almost_full),
//	//.empty(p0_empty),
//	.empty(),
//	//.rd_data_count(p0_out_rd_count), // Bus [16 : 0]
//	.rd_data_count(), // Bus [16 : 0]
//	.wr_data_count()); // Bus [13 : 0]

  assign trig60[0] = p0_full;
  assign trig60[1] = (p0_out_rd_count>60000)&(img_cnt==2);
  assign trig60[2] = p0_empty;
  assign trig60[3] = init_calib_complete;
  assign trig60[4] = img_cnt==2;

// assign PCB_SPI_DOUT =

//assign {ADC1_SHR, ADC2_SHR} = {trig40[1], trig40[1]};
assign {ADC1_SHR, ADC2_SHR} = {trig40[1], trig40[1]};

// ****************************
/*******      TEST FIFO ******/
//*****************************
wire [31:0] FIFO_Flag;
wire [31:0] OK_FIFO_DATA_OUT;
wire OK_FIFO_Start_Trig;
wire FIFO_Empty;
/************************************************/
//**************** ADC Readout *******************
/************************************************/

wire CP_MUX_IN_i;
wire adc_valid;
reg  MUX_START_i;
wire FIFO_IN_TRIG;
wire [8:0] ADC_DEBUG;
wire OK_FIFO_OUT_TRIG;
assign FIFO_Flag[2] = OK_FIFO_Start_Trig;

ADC2FIFO_v1 adc(
    .rst(wirerst[0]),
    .adc1_dat_valid(adc1_dat_valid),
    .adc2_dat_valid(adc2_dat_valid),
    .ADC1_DATA_RAW(ADC1_DATA),
    .ADC1_DATA_CLK(ADC1_DATA_CLK),
    .ADC2_DATA_RAW(ADC2_DATA),
    .ADC2_DATA_CLK(ADC2_DATA_CLK),
    .FIFO_IN_TRIG(FIFO_IN_TRIG),    // NOT USED

    // Real FIFO
    .rd_clk(ok_clk),
    .rd_en(p0_rd_en),
    .rd_data(p0_din_pipe),
    .full(p0_full),
    .empty(p0_empty),
    .valid(),
    .rd_data_count(p0_out_rd_count)
);


/************************************************/
//**************** CIS SPI ***********************
/************************************************/
/*wire cis_wr_en;
wire [31:0] cis_wr_data;

spi_master_v1 #(
	.NUM(6),
	.CLK_RATIO(800),
	.SS_SPACE(30)
) i_cis (
	.rst(rst),
	.clk(clk_100),
	.wr_clk(okClk),
	.wr_en(cis_wr_en),
	.wr_data(cis_wr_data),
	.MISO(0),

	// SPI OUTPUT
	.SPI_SS(IS_SPI_UPLOAD),
	.MOSI(IS_SPI_DATA),
	.SPI_CLK(IS_SPI_CLK)
);
*/

// assign TestIO[13:1] = {FIFO_IN_TRIG, ADC_DEBUG[6:0],
//                         CP_MUX_IN_i, MUX_START_i,
//                         ADC1_DATA_CLK,
//                         ADC_CLK_OUT, clk_100};
//	assign TestIO[1] = IS_SPI_UPLOAD;
//	assign TestIO[2] = IS_SPI_DATA;
//	assign TestIO[3] = IS_SPI_CLK;
//	assign TestIO[4] = cis_wr_en;
//	assign TestIO[5] = p0_empty;
//	assign TestIO[6] = rd0_valid;
//	assign TestIO[7] = img_cnt[0];
//	assign TestIO[8] = img_cnt[1];
//	assign TestIO[9] = pipe0_in_rd;
//	assign TestIO[10] = pipe0_in_empty;
  assign TestIO[9:1] = ROWADD[8:0];
	assign TestIO[10] = MUX_START;
	assign TestIO[11] = re_busy;
	assign TestIO[12] = ADC_CLK_OUT;
	assign TestIO[13] = ADC1_DATA_CLK;
	assign TestIO[14] = adc1_dat_valid;
	assign TestIO[15] = PIXLEFTBUCK_SEL;
	assign TestIO[16] = COL_PRECH;
	assign TestIO[17] = CP_COLMUX_IN;
	assign TestIO[18] = camstart[0];
	assign TestIO[19] = p0_full;
	assign TestIO[20] = p0_empty;




reg [7:0] counter;
wire cp_start;
reg stop_sig;
reg [3:0] stop_cnt;

initial counter = 0;
assign adc_valid = counter[0];
initial stop_sig = 1;
initial stop_cnt = 0;
initial MUX_START_i = 1;

assign cp_start = testWireIn[0];

always @(posedge ADC_CLK_OUT) begin
    counter <= counter + ((cp_start) ? 1 : 0);
    if (counter >= 8'h58) begin
        counter <= 0;
    end
end
always @(posedge clk_022) begin
    if (counter == 0) begin
        MUX_START_i <= 1;
    end else begin
        MUX_START_i <= 0;
    end
end


/************************************************/
//**************** LEDs & TestIO ****************
/************************************************/
function [7:0] xem7310_led;
input [7:0] a;
integer i;
begin
	for(i=0; i<8; i=i+1) begin: u
		xem7310_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

assign led[7:0]     = xem7310_led({1'b0,CS_POT2,6'b0});
// assign TestIO[8:1]  = dout[7:0];
// assign TestIO[9]    = CS_POT1;
// assign TestIO[10]   = CS_POT2;
// assign TestIO[11]   = PCB_SPI_DIN;
// assign TestIO[12]   = PCB_SPI_CLK;
// assign TestIO[20:13]  = dout[31:24];
//assign TestIO[13:1] = {CS_ADC1, ep00wire[27:24], pcb_spi_trigger, PCB_SPI_DOUT, PCB_SPI_DIN,
//                PCB_SPI_CLK, ADC1_DATA_CLK, ADC2_DATA_CLK, ADC_CLK_OUT, clk_100};

//exp ro testio

//assign TestIO[1] = CLKM;
//assign TestIO[2] = re_busy;
//assign TestIO[3] = ex_trigger;
//
//
//assign TestIO[4] = DES;
//assign TestIO[5] = EXP;
//assign TestIO[6] = MASK_EN;
//assign TestIO[7] = PIXGLOB_RES;
//assign TestIO[8] = PIXVTG_GLOB;
//assign TestIO[9] = PIX_GSUBC;
//assign TestIO[10] = COL_PRECH;
//
//assign TestIO[11] = COL_L_EN;
//assign TestIO[12] = CK_PH1;
//assign TestIO[13] = CP_COLMUX_IN;
//assign TestIO[14] = READ_R;
//assign TestIO[15] = READ_S;

/************************************************/
//**************** DDR3 RAM	****************
/************************************************/

// MIG User Interface instantiation
wire init_calib_complete;
wire [29 :0]  app_addr;
wire [2  :0]  app_cmd;
wire          app_en;
wire          app_rdy;
wire [255:0]  app_rd_data;
wire          app_rd_data_end;
wire          app_rd_data_valid;
wire [255:0]  app_wdf_data;
wire                       app_wdf_end;
wire [31 :0]  app_wdf_mask;
wire          app_wdf_rdy;
wire          app_wdf_wren;


	// fifo_w64_512_r256_128 pipeIn1_img_inst (
	// 	.rst(wirerst[0]),
	// 	.wr_clk(clk_100),
	// 	.rd_clk(clk_100),
	// 	.wr_en(FIFO_IN_TRIG),
	// 	.din  ({FIFO_IN_DATA2[31:0],16'h0000,FIFO_IN_DATA2[47:32]}),
	// 	.rd_en(pipe1_in_rd),
	// 	.dout (pipe1_in_rd_data),
	// 	.full (),
	// 	.almost_full(),
	// 	.empty(pipe1_in_empty),
	// 	.valid(pipe1_in_valid),
	// 	.rd_data_count(pipe1_in_rd_count),
	// 	.wr_data_count()
	// );



    //Adjust values of different parameters
	varValueSelector varValueSelector(
        .wr_en(ep02wire[0]),          // Address of the variable whose value needs to be changed
        .varAddress(ep04wire),          // Address of the variable whose value needs to be changed
        .varValueIn(ep03wire),         // Input Value of the variable
        .varValueOut(ep22wire),        // Output Value of the variable
				.T1_e(T1_e),
				.T2_e(T2_e),
				.T3_e(T3_e),
				.T4_e(T4_e),
				.T5_e(T5_e),
				.T6_e(T6_e),
				.T7_e(T7_e),
				.T8_e(T8_e),
				.T9_e(T9_e),
				.T1_r(T1_r),
				.T2_r(T2_r),
				.T3_r(T3_r),
				.T4_r(T4_r),
				.T5_r(T5_r),
				.T6_r(T6_r),
				.Tgl_res(Tgl_res),
				.T_stdby(T_stdby),
				.Texp_ctrl(Texp_ctrl),
				.NumPat(NumPat),
				.T_reset(T_reset),
				.NumRow(NumRow),
				.Tlat1(Tlat1),
				.Tlat2(Tlat2)
    );


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

//OKHost Instantiation
wire  [64:0] okEH;
wire [112:0] okHE;

okHost okHI (
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .okAA(okAA),
    .okClk(okClk),
    .okHE(okHE),
    .okEH(okEH)
);

localparam EHx_NUM = 9;

wire [65*EHx_NUM-1:0] okEHx;

okWireOR # (.N(EHx_NUM)) wireOR (okEH, okEHx);

okWireIn        wi00 (.okHE(okHE),  .ep_addr(8'h00),    .ep_dataout(ep00wire));     // PCB_SPI_DATA
okWireIn        wi01 (.okHE(okHE),  .ep_addr(8'h01), 		.ep_dataout(ep01wire));  // DDR3
okWireIn        wi02 (.okHE(okHE),  .ep_addr(8'h02),    .ep_dataout(ep02wire));  // read number
okWireIn        wi03 (.okHE(okHE),  .ep_addr(8'h03),    .ep_dataout(ep03wire));  // read address
okWireIn        wi04 (.okHE(okHE),  .ep_addr(8'h04),    .ep_dataout(ep04wire));  // read address
okWireIn        wi10 (.okHE(okHE),  .ep_addr(8'h10),    .ep_dataout(wirerst) );
okWireIn        wi12 (.okHE(okHE),  .ep_addr(8'h12),    .ep_dataout(wireNumPat));
okWireIn        wi13 (.okHE(okHE),  .ep_addr(8'h13),    .ep_dataout(modesel) );
okWireIn        wi14 (.okHE(okHE),  .ep_addr(8'h14),    .ep_dataout(wireNumTri) );
okWireIn        wi15 (.okHE(okHE),  .ep_addr(8'h15),    .ep_dataout(camstart) );
//testing

//okWireIn        wi05 (.okHE(okHE),   .ep_addr(8'h05),   .ep_dataout(fake_data_wire_0) );
//okWireIn        wi06 (.okHE(okHE),   .ep_addr(8'h06),   .ep_dataout(fake_data_wire_1) );
//okWireIn        wi07 (.okHE(okHE),   .ep_addr(8'h07),   .ep_dataout(fake_data_wire_2) );
//okWireIn        wi08 (.okHE(okHE),   .ep_addr(8'h08),   .ep_dataout(fake_data_wire_3) );
//okWireIn        wi09 (.okHE(okHE),   .ep_addr(8'h09),   .ep_dataout(fake_data_wire_4) );
//okWireIn        wi15 (.okHE(okHE),   .ep_addr(8'h15),   .ep_dataout(fake_data_wire_5) );
//okWireIn        wi17 (.okHE(okHE),   .ep_addr(8'h17),   .ep_dataout(fake_data_wire_6) );
//okWireIn        wi18 (.okHE(okHE),   .ep_addr(8'h18),   .ep_dataout(fake_data_wire_7) );


okWireIn        wi16 (.okHE(okHE),   .ep_addr(8'h16),   .ep_dataout(testWireIn));     // test

//okWireIn        wi17 (.okHE(okHE),   .ep_addr(8'h17),   .ep_dataout(mask_order));     // test


okTriggerIn	    ti40 (.okHE(okHE),      .ep_addr(8'h40),    .ep_clk(okClk), .ep_trigger(trig40));

okWireOut       wi20 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut       wi21 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(ep21wire));
okWireOut       wi22 (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h22), .ep_datain(ep22wire));
okWireOut       wi23 (.okHE(okHE), .okEH(okEHx[ 8*65 +: 65 ]), .ep_addr(8'h23), .ep_datain({16'b0,p0_out_rd_count}));

okBTPipeIn		pi80 (.okHE(okHE), .okEH(okEHx[ 4*65 +: 65 ]), .ep_addr(8'h80), .ep_write(pi0_ep_write), .ep_blockstrobe(), .ep_dataout(pi0_ep_dataout), .ep_ready(pipe_in_ready));
okBTPipeOut		poa0 (.okHE(okHE), .okEH(okEHx[ 5*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(po0_ep_read), .ep_blockstrobe(), .ep_datain(po0_ep_datain), .ep_ready(pipe_out_ready));

okPipeOut		pob0 (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'hb0), .ep_read(p0_rd_en), 				  .ep_datain(p0_din_pipe));

okTriggerOut    to6A (.okHE(okHE),     .okEH(okEHx[7*65 +: 65]),   .ep_addr(8'h6A),    .ep_clk(okClk),  .ep_trigger(trig60));


//channel 0 fifos
fifo_w32_1024_r256_128 okPipeIn_fifo (
	.rst(ep01wire[2]),
	.wr_clk(okClk),
	.rd_clk(ui_clk),
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
	.rst(ep01wire[2]),
	.wr_clk(ui_clk),
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


endmodule
