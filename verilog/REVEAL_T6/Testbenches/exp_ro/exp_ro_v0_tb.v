`timescale 1ns / 100ps

module exp_ro_v0_tb(
	output wire [9:0] ROWADD,
	output reg clk_200,
	output reg clk_100,
	output reg clk_10,
	output reg clk_5,
	output wire [9:0] ROWADD_EXP,
	output wire [9:0] ROWADD_RO,
	output wire [16:1] mSTREAM,
	output wire COL_L_EN,
	output wire PIXRES_L,
	output wire PIXRES_R,
	output wire STDBY,
	output wire COL_PRECH,
	output wire PGA_RES,
	output wire CK_PH1,
	output wire SAMP_S,
	output wire SAMP_R,
	output wire READ_R,
	output wire READ_S,
	output wire MUX_START,
	output wire CP_COLMUX_IN,
	output wire PIXRES,

    output wire MASK_EN,
    output wire PIXDRAIN,
    output wire PIXGLOB_RES,
    output wire PIXVTG_GLOB,
    output wire PIXREAD_EN,
    output wire EXP,
    output wire PIX_GSUBC,
    output wire PIX_ROWMASK,
    output wire DES,
    output wire SYNC,
	
	output wire re_busy,
	
	output reg reset
);

	reg clk_5;  initial clk_5 = 1'b1; 	 always #100 clk_5 = ~clk_5; 
	reg clk_10;  initial clk_10 = 1'b1; 	 always #50 clk_10 = ~clk_10; 
	reg clk_100; initial clk_100 = 1'b1; always #5 clk_100 = ~clk_100; 
	reg clk_200; initial clk_200 = 1'b1; always #2.5 clk_200 = ~clk_200; 

	reg reset;

	wire [9:0] ROWADD;
	wire [9:0] ROWADD_EXPT;
	wire [9:0] ROWADD_EXPB;
	wire [9:0] ROWADD_RO;
	wire ex_trigger;	
	wire re_busy;
//	assign ROWADD = (re_busy) ? ROWADD_RO : 323 - ROWADD_EXPT;

	wire btmArray;
	assign btmArray = 1;
//	assign ROWADD = (re_busy) ? {ROWADD_RO[9:1],(wireMask[24]?1'b0:ROWADD_RO[0])} : ((wireMask[24])?{ROWADD_EXPB[9:2],1'b1,1'b0} :323 - ROWADD_EXP);
	assign ROWADD[9:0] = (re_busy) ? {ROWADD_RO[9:1],btmArray 	 ? 1'b0 : ROWADD_RO[0]}: btmArray  ? {ROWADD_EXPB[9:3],3'b010}: 323 - ROWADD_EXPT;


	//RO----------------------------------------
	wire COL_L_EN;
	wire PIXRES_L;
	wire PIXRES_R;
	wire STDBY;
	wire PRECH_COL;
	wire PGA_RES;
	wire CK_PH1;
	wire SAMP_S;
	wire SAMP_R;

	wire READ_R;
	wire READ_S;
	wire MUX_START;
	wire CP_COLMUX_IN;

/* Readout wires */
wire [31:0] T1_e, T2_e, T3_e, T4_e, T5_e, T6_e, T7_e, T8_e, T9_e; 
wire [31:0] T1_r, T2_r, T3_r, T4_r, T5_r, T6_r;

wire [31:0] Texp_ctrl;
wire [31:0] Tgl_res;
wire [31:0] T_reset;
wire [31:0] T_stdby;
wire [31:0] NumPat;
wire [31:0] Tlat;
wire [31:0] NumRow,RO_RowStart;

wire MASK_EN;
wire EN_STREAM;


wire [255:0] cache_data;
wire [9:0]   cache_rd_count;
wire [6:0]   cache_wr_count;
wire         cache_rd_en;
wire         cache_empty;
wire         cache_valid;

//wire PIXDRAIN,PIXGLOB_RES,PIXVTG_GLOB,PIXREAD_EN,EXP,PIX_GSUBC,PIX_ROWMASK,DES,SYNC;
reg [16:1] mask_gated = 16'h5555;
reg [16:1] mask_ungated = 16'hAAAA;
reg [9:0] row_start = 10'd400;
reg [9:0] row_stop = 10'd440;
assign mSTREAM[16:1] = {16{PIXGLOB_RES}} | ( re_busy ? 16'b0 : ((ROWADD[9:0] > row_start) && (ROWADD[9:0] < row_stop) ? mask_gated : mask_ungated));
	
Exposure_v3 exposure_inst(
    .STDBY(STDBY),
    //.NUM_SUB(NumPat),
    .NUM_SUB(3),
    .rst(reset),
    .CLKM(clk_100),
    .MASK_EN(MASK_EN),
		.EN_STREAM(EN_STREAM),
    .PIXDRAIN(PIXDRAIN),
    .PIXGLOB_RES(PIXGLOB_RES),
    .PIXVTG_GLOB(PIXVTG_GLOB),
    .PIXREAD_EN(PIXREAD_EN),
    .EXP(EXP),
    .PIXGSUBC(PIX_GSUBC),
    .PIXROWMASK(PIX_ROWMASK),
    .DES(DES),
    .SYNC(SYNC),
    .ROWADDT(ROWADD_EXPT),
    .ROWADDB(ROWADD_EXPB),
    .trigger_o(ex_trigger),
    .re_busy(re_busy),
    .T_stdby(T_stdby),
    .T_reset(T_reset),
    .Tgl_res(1000),
    //.Texp_ctrl(Texp_ctrl),
    .Texp_ctrl(2000),
    .T1(T1_e),
    .T2(T2_e),
    .T3(T3_e),
    .T4(T4_e),
    .T5(T5_e),
    .T6(T6_e),
    .T7(T7_e),
    .T8(T8_e),
    .T9(50)
    );

wire [31:0] PERIOD, DUTY1, DELAY1, DUTY2, DELAY2, DUTY3, DELAY3;
    wire LASER_MOD, FPGA_MOD0,FPGA_MOD90;
    ToFClks u_ToFClks(
        	.CLKIN(clk_100),
        	.VALID(~PIXREAD_EN),
        	.PERIOD(100),
        	
        	.CLKOUT1(FPGA_MOD0),	// output clock-1 with duty1, delay1 and period
        	.DUTY1(50),		// DUTY1[7:0]
        	.DELAY1(0),    // DELAY[7:0]
        	
        	.CLKOUT2(FPGA_MOD90),
        	.DUTY2(50),
        	.DELAY2(25),
        
        	.CLKOUT3(LASER_MOD),
        	.DUTY3(50),
        	.DELAY3(50)
        );

Readout_v3 readout_inst (
	.rst		(reset),
	.CLK		(clk_100),
	.trigger(ex_trigger),
	.re_busy	(re_busy),

	.ROWADD		(ROWADD_RO),

	.COL_L_EN	(COL_L_EN),
	.COL_PRECH(COL_PRECH),
	.CP_MUX_IN(CP_COLMUX_IN),
	.MUX_START(MUX_START),
	.PIXRES		(PIXRES),
	.PH1			(CK_PH1),
	.PGA_RES	(PGA_RES),
	.SAMP_R		(SAMP_R),
	.SAMP_S		(SAMP_S),
	.READ_R		(READ_R),
	.READ_S		(READ_S),

	.T1		(T1_r),
	.T2		(T2_r),
	//.T2		(862),
	.T3		(T3_r),
	.T4		(T4_r),
	.T5		(T5_r),
	//.T5		(10),
	.T6		(T6_r),

	.adc_clk(clk_10),
	.adc1_out_clk(),
	.adc2_out_clk(),
	.Tlat1(),
	.Tlat2(),
	.adc1_dat_valid(),
	.adc2_dat_valid(),

	//.NUM_ROW	(NumRow)
	.NUM_ROW	(10),
	.RO_RowStart(322)
);



wire full;

fifo_w256_128_r256_128_ib i_mask_cache (
	.rst(reset),
	.wr_clk(clk_100),
	.rd_clk(clk_100),
	.din(256'hf00f0ff00ff0f00ff00f0ff00ff0f00ff00f0ff00ff0f00ff00f0ff00ff0f00ff00f0ff00ff0f00f), // Bus [256 : 0]
	.wr_en(~full),
	.rd_en(cache_rd_en),
	.dout(cache_data), // Bus [31 : 0]
	.full(full),
	.empty(cache_empty),
	.valid(cache_valid),
	.rd_data_count(cache_rd_count), // Bus [9 : 0]
	.wr_data_count(cache_wr_count)); // Bus [6 : 0]


patternToSensors_v2 u_patternToSensors(        
  .reset(reset),               
  .clk(clk_100),   // write in clk
  .Num_Pat(2),			// number of patterns

  .stream_clk(clk_100),  // stream read out clk
  .stream_en_i(EN_STREAM),    // test use , indicate data is writting to sensor fifo     
  .stream_en_o(),    // test use , indicate data is writting to sensor fifo     
  .MSTREAMOUT(),    // final output from oddr                            
  //.MSTREAMOUT(),    // final output from oddr                            

  .rd_en(cache_rd_en),						// rd_en for cache fifo 
	.empty(cache_empty),
	.valid(cache_valid),
  .MSTREAM32(cache_data)        
); 

	//Adjust values of different parameters
	varValueSelector varValueSelector(
        .wr_en(0),          // Address of the variable whose value needs to be changed
        .varAddress(0),          // Address of the variable whose value needs to be changed
        .varValueIn(0),         // Input Value of the variable
        .varValueOut(),        // Output Value of the variable
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
				.Tlat2(Tlat2),
				.DUTY1(DUTY1),
				.DUTY2(DUTY2),
				.DUTY3(DUTY3),
				.DELAY1(DELAY1),
				.DELAY2(DELAY2),
				.DELAY3(DELAY3),
				.PERIOD(PERIOD),
				.RO_RowStart(RO_RowStart)
    );


	
    
	initial begin
	  reset = 1'b1;
	end

	initial begin
	  #100 reset = 1'b0;
	end


endmodule
