
`timescale 1ns/100ps

module Reveal_Top_tb;

    parameter num_row = 1;
    //parameter num_streams = 52;  // seems fixed
    parameter num_streams = 5120;  // seems fixed

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter COL_WIDTH             = 10; // # of memory Column Address bits.
   parameter CS_WIDTH              = 1; // # of unique CS outputs to memory.
   parameter DM_WIDTH              = 4; // # of DM (data mask)
   parameter DQ_WIDTH              = 32; // # of DQ (data)
   parameter DQS_WIDTH             = 4;
   parameter DQS_CNT_WIDTH         = 2; // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8; // # of DQ per DQS
   parameter ECC                   = "OFF";
   parameter RANKS                 = 1; // # of Ranks.
   parameter ODT_WIDTH             = 1; // # of ODT outputs to memory.
   parameter ROW_WIDTH             = 15; // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 29;
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_MODE            = "8";
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   parameter CA_MIRROR             = "OFF";
                                     // C/A mirror opt for DDR3 dual rank

   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5;
                                     // Input Clock Period
   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIM_BYPASS_INIT_CAL   = "FAST";
                                     // # = "SIM_INIT_CAL_FULL" -  Complete
                                     //              memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter TCQ                   = 100;
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter RST_ACT_LOW           = 0;
                                     // =1 for active low reset,
                                     // =0 for active high.

   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   parameter REFCLK_FREQ           = 200.0;
                                     // IODELAYCTRL reference clock frequency
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   //parameter tCK                   = 2500;
                                     // memory tCK paramter.
                     // # = Clock Period in pS.
   parameter nCK_PER_CLK           = 4;
                                     // # of memory CKs per fabric CLK



  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//

  localparam real TPROP_DQS          = 0.00;
                                       // Delay for DQS signal during Write Operation
  localparam real TPROP_DQS_RD       = 0.00;
                       // Delay for DQS signal during Read Operation
  localparam real TPROP_PCB_CTRL     = 0.00;
                       // Delay for Address and Ctrl signals
  localparam real TPROP_PCB_DATA     = 0.00;
                       // Delay for data signal during Write operation
  localparam real TPROP_PCB_DATA_RD  = 0.00;
                       // Delay for data signal during Read operation

  localparam MEMORY_WIDTH            = 16;
  localparam NUM_COMP                = DQ_WIDTH/MEMORY_WIDTH;
  localparam ECC_TEST         = "OFF" ;
  localparam ERR_INSERT = (ECC_TEST == "ON") ? "OFF" : ECC ;


  localparam real REFCLK_PERIOD = (1000.0/(2*REFCLK_FREQ));
  localparam RESET_PERIOD = 200; //in pSec
  //localparam real SYSCLK_PERIOD = tCK;
  localparam real SYSCLK_PERIOD = 2500;



  //**************************************************************************//
  // Wire Declarations
  //**************************************************************************//
  // added
  wire                                      empty;
  wire                                      fuck;
  wire [9:0]                                MSTREAMOUT;
  reg [31:0]                                wiremode;
  wire                                      clk_out;
  wire                                      stream_en;

  wire                                      pipe_in_empty;
  wire                                      pipe_in_full;
  wire                                      pipe_in_almost_full;
  reg [31:0]                                 pipe_in_wr_data;
  reg                                        pipe_in_wr;
  reg [11:0]                                 count;


  //////////////for rdout and exposure///////////
   	//inputs
	reg  RESET;

	wire TX_CLK,CLKM,CLKMPRE,ADC_CLK;

	wire [4:0]  	okUH;
	wire [2:0]  	okHU;
	wire [31:0] 	okUHU;
	wire 				 	okAA;

	wire [7:0]		led;

  wire CS_POT1;
  wire CS_POT2;
  wire ADC_SYNC1;
  wire ADC_SYNC2;
  wire SPI_DI;
  reg SPI_DO;
  wire SPICLK;
  wire RS_POT;
  wire IBIAS_POT;
	wire DIN_T4;
	wire SPICLK_T4;
	wire CS_T4;

  //output wire RST_N,
	wire RESET_N;

  /* Mask to sensor */
  wire [10:1] MSTREAM;

	/* Exposure Output */
	wire PIXGSUBC;
	wire PIXDRAIN;
	wire PIXGLOB_RES;
	wire PIXVTG_GLOB;
	wire EN_STREAM;
	wire DES_2ND;
	wire MASK_EN;

	/* Readout Output */
	wire PIXREAD_SEL;
	wire PIXLEFTBUCK_SEL;
	wire PIX_ROWMASK;
	wire PIXRES;
	wire COLLOAD_EN;
	wire PRECH_COL;
	wire ADC_EN;
	wire DATA_LOAD;
	wire RST_ADC;
	wire RST_OUTMUX;

	wire [8:0] ROWADD;


  /* i/o for ADC Read */
  wire ADCCLK_IN;
  wire TX_CLK_OUT;
  reg [2:0] DIGOUT;

	/* Test Headers */
	wire [20:1] TestIO;

  //////////////////////

  reg                                sys_rst_n;
  reg  						                   sys_clk_i;
  wire                               sys_clk_p;
  wire                               sys_clk_n;

  wire   sys_rst;

  wire                               ddr3_reset_n;
  wire [DQ_WIDTH-1:0]                ddr3_dq_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_fpga;
  wire [ROW_WIDTH-1:0]               ddr3_addr_fpga;
  wire [3-1:0]              ddr3_ba_fpga;
  wire                               ddr3_ras_n_fpga;
  wire                               ddr3_cas_n_fpga;
  wire                               ddr3_we_n_fpga;
  wire [1-1:0]               ddr3_cke_fpga;
  wire [1-1:0]                ddr3_ck_p_fpga;
  wire [1-1:0]                ddr3_ck_n_fpga;


  //wire                               i_top.i_top.init_calib_complete;
  wire                               tg_compare_error;

  wire [DM_WIDTH-1:0]                ddr3_dm_fpga;

  wire [ODT_WIDTH-1:0]               ddr3_odt_fpga;



  reg [DM_WIDTH-1:0]                 ddr3_dm_sdram_tmp;

  reg [ODT_WIDTH-1:0]                ddr3_odt_sdram_tmp;



  wire [DQ_WIDTH-1:0]                ddr3_dq_sdram;
  reg [ROW_WIDTH-1:0]                ddr3_addr_sdram [0:1];
  reg [3-1:0]               ddr3_ba_sdram [0:1];
  reg                                ddr3_ras_n_sdram;
  reg                                ddr3_cas_n_sdram;
  reg                                ddr3_we_n_sdram;
  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram;
  wire [ODT_WIDTH-1:0]               ddr3_odt_sdram;
  reg [1-1:0]                ddr3_cke_sdram;
  wire [DM_WIDTH-1:0]                ddr3_dm_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_sdram;
  reg [1-1:0]                 ddr3_ck_p_sdram;
  reg [1-1:0]                 ddr3_ck_n_sdram;

	reg 	mem_write_done;
  reg   reset;

	parameter NUM_PAT=1;
	parameter exp_time = 10;

  initial pipe_in_wr_data = 0;
  initial pipe_in_wr = 0;
  initial count = 0;
  initial wiremode = 0;
//**************************************************************************//

  //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
  initial begin
    sys_rst_n = 1'b0;
    #RESET_PERIOD
      sys_rst_n = 1'b1;
   end

   assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  //**************************************************************************//
  // Clock Generation
  //**************************************************************************//

  initial
    sys_clk_i = 1'b0;
  always
    sys_clk_i = #(CLKIN_PERIOD/2.0) ~sys_clk_i;

  assign sys_clk_p = sys_clk_i;
  assign sys_clk_n = ~sys_clk_i;



  always @( * ) begin
    ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
    ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
    ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_addr_fpga[ROW_WIDTH-1:9],
                                                  ddr3_addr_fpga[7], ddr3_addr_fpga[8],
                                                  ddr3_addr_fpga[5], ddr3_addr_fpga[6],
                                                  ddr3_addr_fpga[3], ddr3_addr_fpga[4],
                                                  ddr3_addr_fpga[2:0]} :
                                                 ddr3_addr_fpga;
    ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_ba_fpga[3-1:2],
                                                  ddr3_ba_fpga[0],
                                                  ddr3_ba_fpga[1]} :
                                                 ddr3_ba_fpga;
    ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
    ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
    ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
    ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
  end


  assign ddr3_cs_n_sdram =  {(CS_WIDTH*1){1'b0}};


  always @( * )
    ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
  assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;


  always @( * )
    ddr3_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;
  assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;


// Controlling the bi-directional BUS

  genvar dqwd;
  generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq
       (
        .A             (ddr3_dq_fpga[dqwd]),
        .B             (ddr3_dq_sdram[dqwd]),
        .reset         (sys_rst_n),
        .phy_init_done (i_top.init_calib_complete)
       );
    end
          WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq_0
       (
        .A             (ddr3_dq_fpga[0]),
        .B             (ddr3_dq_sdram[0]),
        .reset         (sys_rst_n),
        .phy_init_done (i_top.init_calib_complete)
       );
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_p
       (
        .A             (ddr3_dqs_p_fpga[dqswd]),
        .B             (ddr3_dqs_p_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (i_top.init_calib_complete)
       );

      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_n
       (
        .A             (ddr3_dqs_n_fpga[dqswd]),
        .B             (ddr3_dqs_n_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (i_top.init_calib_complete)
       );
    end
  endgenerate




  //===========================================================================
  //                        Reveal Top
  //===========================================================================

Reveal_Top i_top (
	.okUH(okUH),
	.okHU(okHU),
	.okUHU(okUHU),
	.okAA(okAA),

	.led(led),

  .sys_clk_p            (sys_clk_p),
  .sys_clk_n            (sys_clk_n),

  .ddr3_dq              (ddr3_dq_fpga),
  .ddr3_addr            (ddr3_addr_fpga),
  .ddr3_ba              (ddr3_ba_fpga),
  .ddr3_ck_p            (ddr3_ck_p_fpga),
  .ddr3_ck_n            (ddr3_ck_n_fpga),
  .ddr3_cke             (ddr3_cke_fpga),
  .ddr3_ras_n           (ddr3_ras_n_fpga),
  .ddr3_cas_n           (ddr3_cas_n_fpga),
  .ddr3_we_n            (ddr3_we_n_fpga),
  .ddr3_odt             (ddr3_odt_fpga),
  .ddr3_dm              (ddr3_dm_fpga),
  .ddr3_dqs_n           (ddr3_dqs_n_fpga),
  .ddr3_dqs_p           (ddr3_dqs_p_fpga),
  .ddr3_reset_n         (ddr3_reset_n),
  //.sys_rst             (sys_rst),

	/* SPI and motherboard signals */
  .CS_POT1(CS_POT1),
  .CS_POT2(CS_POT2),
  //.ADC_SYNC1(ADC_SYNC1),
  //.ADC_SYNC2(ADC_SYNC2),
  //.SPI_DI(SPI_DI),
  //.SPI_DO(SPI_DO),
  //.SPICLK(SPICLK),
  .RS_POT(RS_POT),
  //.IBIAS_POT(IBIAS_POT),
	//.DIN_T4(DIN_T4),
	//.SPICLK_T4(SPICLK_T4),
	//.CS_T4(CS_T4),

  //output wire RST_N,
	.RESET_N(RESET_N),

  /* Mask to sensor */
  .mSTREAM(MSTREAM),

	/* Exposure Output */
	//.PIXGSUBC(PIXGSUBC),
	.PIXDRAIN(PIXDRAIN),
	.PIXGLOB_RES(PIXGLOB_RES),
	.PIXVTG_GLOB(PIXVTG_GLOB),
	//.EN_STREAM(EN_STREAM),
	.DES(DES_2ND),
	.MASK_EN(MASK_EN),
	.CLKM(CLKM),

	/* Readout Output */
	//.PIXREAD_SEL(PIXREAD_SEL),
	.PIXLEFTBUCK_SEL(PIXLEFTBUCK_SEL),
	.PIX_ROWMASK(PIX_ROWMASK),
	.PIXRES(PIXRES),
	//.COLLOAD_EN(COLLOAD_EN),
	.COL_PRECH(PRECH_COL),
	//.ADC_EN(ADC_EN),
	//.DATA_LOAD(DATA_LOAD),
	//.RST_ADC(RST_ADC),
	//.RST_OUTMUX(RST_OUTMUX),
	//.TX_CLK(TX_CLK),
	.ROWADD(ROWADD),


  /* i/o for ADC Read */
  //.ADCCLK_IN(ADCCLK_IN),
  //.TX_CLK_OUT(TX_CLK),
  //.DIGOUT(DIGOUT),

	/* Test Headers */
	//.reset(reset),
	.TestIO(TestIO)

   );

  //**************************************************************************//
  // Memory Models instantiations
  //**************************************************************************//

  genvar r,i;
  generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      if(DQ_WIDTH/16) begin: mem
        for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
          ddr3_model u_comp_ddr3
            (
             .rst_n   (ddr3_reset_n),
             .ck      (ddr3_ck_p_sdram),
             .ck_n    (ddr3_ck_n_sdram),
             .cke     (ddr3_cke_sdram[r]),
             .cs_n    (ddr3_cs_n_sdram[r]),
             .ras_n   (ddr3_ras_n_sdram),
             .cas_n   (ddr3_cas_n_sdram),
             .we_n    (ddr3_we_n_sdram),
             .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
             .ba      (ddr3_ba_sdram[r]),
             .addr    (ddr3_addr_sdram[r]),
             .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
             .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
             .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
             .tdqs_n  (),
             .odt     (ddr3_odt_sdram[r])
             );
        end
      end
      if (DQ_WIDTH%16) begin: gen_mem_extrabits
        ddr3_model u_comp_ddr3
          (
           .rst_n   (ddr3_reset_n),
           .ck      (ddr3_ck_p_sdram),
           .ck_n    (ddr3_ck_n_sdram),
           .cke     (ddr3_cke_sdram[r]),
           .cs_n    (ddr3_cs_n_sdram[r]),
           .ras_n   (ddr3_ras_n_sdram),
           .cas_n   (ddr3_cas_n_sdram),
           .we_n    (ddr3_we_n_sdram),
           .dm_tdqs ({ddr3_dm_sdram[DM_WIDTH-1],ddr3_dm_sdram[DM_WIDTH-1]}),
           .ba      (ddr3_ba_sdram[r]),
           .addr    (ddr3_addr_sdram[r]),
           .dq      ({ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)],
                      ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
           .dqs     ({ddr3_dqs_p_sdram[DQS_WIDTH-1],
                      ddr3_dqs_p_sdram[DQS_WIDTH-1]}),
           .dqs_n   ({ddr3_dqs_n_sdram[DQS_WIDTH-1],
                      ddr3_dqs_n_sdram[DQS_WIDTH-1]}),
           .tdqs_n  (),
           .odt     (ddr3_odt_sdram[r])
           );
      end
    end
  endgenerate

	//------------------------------------------------------------------------
	// Begin okHostInterface simulation user configurable  global data
	//------------------------------------------------------------------------
	parameter BlockDelayStates = 5;   // REQUIRED: # of clocks between blocks of pipe data
	parameter ReadyCheckDelay = 5;    // REQUIRED: # of clocks before block transfer before
												 //           host interface checks for ready (0-255)
	parameter PostReadyDelay = 5;     // REQUIRED: # of clocks after ready is asserted and
												 //           check that the block transfer begins (0-255)

  parameter pipeInSize = 1024;
	//parameter pipeInSize = 320*17*NUM_PAT;      // REQUIRED: byte (must be even) length of default
												 //           PipeIn; Integer 0-2^32
	//parameter pipeOutSize = 1048576;     // REQUIRED: byte (must be even) length of default
	parameter pipeOutSize = 1024;     // REQUIRED: byte (must be even) length of default
												 //           PipeOut; Integer 0-2^32
	parameter registerSetSize = 16;  // Size of array for register set commands.

 	integer ii,j,k, m,n;
	reg  [7:0]  pipeIn [0:(pipeInSize-1)];
	reg  [7:0]  pipeOut [0:(pipeOutSize-1)];
	//Registers
	reg [31:0] u32Address  [0:(registerSetSize-1)];
	reg [31:0] u32Data     [0:(registerSetSize-1)];
	reg [31:0] u32Count;

	reg initial_done;

	initial begin
		DIGOUT = 3'b111;
		SPI_DO = 1;
	end

	initial begin
		for (ii=0; ii<pipeInSize; ii=ii+1) begin
				pipeIn[ii] = $urandom;
		end
		$display("1 %d", $time);
		reset=1;
		wait(i_top.re_busy)
    reset=0;
		initial_done = 0;
		FrontPanelReset();
		$display("2 %d", $time);				// Start routine with FrontPanelReset;
		SetWireInValue(8'h10, 32'd1, 32'hffffffff);     // rst
		SetWireInValue(8'h12, NUM_PAT, 32'hffffffff);     //wire num_pat
		SetWireInValue(8'h11, exp_time, 32'hffffffff);  	//wireexp
		SetWireInValue(8'h01, 32'h00000004, 32'hffffffff);     // rst
		UpdateWireIns();
		$display("6 %d", $time);
		SetWireInValue(8'h01, 32'h00000004, 32'hffffffff);     // ddr write mode
		UpdateWireIns();
		initial_done = 1;

		FrontPanelReset();
		SetWireInValue(8'h10, 32'd0, 32'hffffffff);     // de-rst

		wait(i_top.init_calib_complete);

		FrontPanelReset();
		SetWireInValue(8'h10, 32'd0, 32'hffffffff);     // de-rst
		UpdateWireIns();
		SetWireInValue(8'h01, 32'h00000002, 32'hffffffff);     // ddr write mode
		UpdateWireIns();
		WriteToBlockPipeIn(8'h80, 512, pipeInSize);

		SetWireInValue(8'h01, 32'h00000001, 32'hffffffff);     // ddr write mode
		UpdateWireIns();

		while(1) begin
			//wait(i_top.p0_prg_full)
			//wait(i_top.p0_rd_data_cnt==864)
			ReadFromPipeOut(8'ha0, pipeOutSize);
		end

		//for(j=0;j<100;j=j+1) begin
		//	wait(i_top.p0_prg_full)
		//	ReadFromPipeOut(8'hB0, pipeInSize);
		//end

		//# 1000000000000;

	end


`include "/home/thomas/Documents/summer/T5/REVEAL_T5/src/verilog/REVEAL_T5/Testbenches/Reveal_Top_tb/okHostCalls.v"
//`include "C:/Users/xia/Documents/Shared/T4/T4_ok/T4_ok.srcs/sim_1/new/okHostCalls.v"

endmodule
