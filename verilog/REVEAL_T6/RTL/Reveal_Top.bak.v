`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
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
/*
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
	output wire         ddr3_reset_n
*/


/************** TestHeader *****************/    
    output wire [20:1] TestIO,
    output wire LaserIO_9, output wire LaserIO_11,

/********************** IMAGER *****************************/
    /************** MASKING ********************/    
    output wire [16:1] mSTREAM,
    output wire MASK_EN,output wire CLKM, 
    output wire DES, output wire SYNC, output wire RESET_N, 

    /************** ROWDRIVER *****************/    
    output wire PIX_GSUBC, output wire PIX_ROWMASK,         //MASKING
    output wire PIXREAD_EN, output wire PIXLEFTBUCK_SEL,    //READOUT
    output wire [9:0] ROWADD,                               //MASKING and READOUT
    output wire PIXDRAIN, output wire PIXGLOB_RES, output wire PIXVTG_GLOB, output wire PIXRES, //RESET
    
    /*************** READOUT *****************/    
    output wire PGA_RES, output wire SAMP_R, output wire SAMP_S,//PGA SPECIFIC 
    output wire CK_PH1, output wire READ_R, output wire READ_S, //PGA SPECIFIC
    output wire CP_COLMUX_IN, output wire MUX_START,            //ANALOG OUTPUT MUX CONTROL
    output wire RO_CLK_100,                             //CLK to interanally latch readout signals
    output wire COL_L_EN, output wire STDBY,
    output wire COL_PRECH,

    /*************** ToF *****************/    
    output wire EXP, output wire FPGA_MOD0, wire FPGA_MOD90,

    /*************** IMAGE SENSOR SPI *****************/    
    output wire IS_SPI_DATA, output wire IS_SPI_CLK, output wire IS_SPI_UPLOAD,

/********************** PCB *****************************/
    /************** PCB SPI CONTROL***************/
    output wire PCB_SPI_DIN, output wire PCB_SPI_CLK,
    input wire PCB_SPI_DOUT,
    
    /************ PCB SPI CS & RST **************/
    output wire CS_POT1, output wire CS_POT2, output wire RS_POT,       //LDO POTS
    output wire CS_PLL, output wire CS_IBIAS,
    output wire CS_ADC1, output wire CS_ADC2, output wire CS_ADC_LDO,   //ADC
   
    /************ PCB ADC DATA & CTRL **************/
    output wire ADC_LDO_CLK,                                //LDO ADC CLK
    output wire ADC_CLK_OUT,                                //Input clocks for TI-ADCs ICs
    output wire ADC1_SHR, output wire ADC2_SHR,             //Sample and hold control for TI-ADC ICs           
    
    input wire ADC1_DATA_CLK, input wire ADC2_DATA_CLK,     //Output clocks from TI-ADC ICs
    input wire [7:0] ADC1_DATA, input wire [7:0] ADC2_DATA, //Output data from TI-ADC ICs

    /*************** PCB PLL CTRL ****************/
    output wire PLL_ToF, output wire PLL_SYNC,

    /********* PCB LEVEL CONVERTER CTRL **********/
    output wire LC_EN
   );

/************************************************/
//*********Opal Kelly inputs and outputs**********
/************************************************/
wire [31:0] trig40; //triggers
wire [31:0] trig41; //triggers
wire [31:0] ep00wire;   //PCB_SPI_DATA
wire [31:0] ep01wire;
wire [31:0] ep02wire;
wire [31:0] ep03wire;
wire [31:0] ep04wire;
wire [31:0] ep20wire;
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

wire [31:0] Texp_ctrl;
wire [31:0] Tgl_res;
wire [31:0] T_reset;
wire [31:0] T_stdby;
wire [31:0] NumPat;
wire [31:0] NumRow;



wire [31:0] wirerst;
wire [31:0] modesel;
wire [31:0] wireNumTri;

wire [31:0] testWireIn;
wire [31:0] testWireOut;
wire [31:0] testWireOut2;
wire [15:0] FIFO_IN_DATA1;
wire [15:0] FIFO_IN_DATA2;

/************************************************/
//**************** System clocks ****************
/************************************************/
//CLK Instantiation
wire clk_400,clk_200,clk_100,clk_50,clk_010,clk_022;
  clk_wiz_adc_test instance_name
   (
    // Clock out ports
    .clk_400(clk_400),     // output clk_400
    .clk_200(clk_200),     // output clk_200
    .clk_100(clk_100),     // output clk_100
    .clk_050(clk_50),     // output clk_out4
    .clk_022(clk_022),
    .clk_015(ADC_CLK_OUT),
    .clk_010(clk_010),
   // Clock in ports
    .clk_in1_p(sys_clk_p),    // input clk_in1_p
    .clk_in1_n(sys_clk_n));    // input clk_in1_n


wire [31:0] dout;    
counter #(.N(32)) dut(
    .clk(clk_400),
    .dout(dout[31:0]));
wire rst;
assign rst = trig41[0];

assign mSTREAM[16:1] = {16{dout[2]}};
assign CLKM          = dout[2];
// assign DES          = dout[6];
//assign ROWADD[9:0] = {{5{dout[9]}},dout[8:4]};
assign ADC_LDO_CLK = ADC_CLK_OUT;

//***********************
//OKHost Instantiation
//***********************
wire okClk;
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


/************************************************/
//******************* PCB_SPI *******************
/************************************************/
wire [31:0] DOUT;
wire pcb_spi_trigger;
wire [7:0] pcb_spi_target;
assign pcb_spi_trigger = trig40[0];
SPI_top pcb_spi_inst(
    .clk(clk_100),                  //input:    reference clock
    .DIN(ep00wire),           //input:    {DATA{15:0},6'b0,CPOL,CPHA,target[7:0]}
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
//******************* EXP & RO *******************
/************************************************/

parameter NUM_ROW	= 20;

wire ex_trigger;
wire re_busy;

wire [9:0] ROWADD_EXP;
wire [9:0] ROWADD_RO;

assign ROWADD = (re_busy) ? ROWADD_RO : ROWADD_EXP;


Exposure_v2 exposure_inst(
    .STDBY(STDBY),
    .NUM_SUB(1),
    .rst(wirerst[0]),
    .CLKM(CLKM),
    .MASK_EN(MASK_EN),
    .PIXDRAIN(PIXDRAIN),
    .PIXGLOB_RES(PIXGLOB_RES),
    .PIXVTG_GLOB(PIXVTG_GLOB),
    .EXP(EXP),
    .PIXGSUBC(PIX_GSUBC),
    .PIXROWMASK(PIX_ROWMASK),
    .DES(DES),
    .SYNC(SYNC),
    .ROWADD(ROWADD_EXP),
    .trigger_o(ex_trigger),
    .re_busy(re_busy),
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

Readout_v1 readout_inst (
	.rst		(wirerst[0]),
	.CLK		(CLKM),
	.trigger_i	(ex_trigger),
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
	.READ_S		(READ_S),

	.T1		(T1_r),
	.T2		(T2_r),
	.T3		(T3_r),
	.T4		(T4_r),
	.T5		(T5_r),
	.T6		(T6_r),

	.NUM_ROW	(NUM_ROW)
);


wire rd0_valid;
wire [255:0] rd0_data;
wire rd1_almost_full;
wire [16:0] p0_out_rd_count;

// come in from on board memroy
// go to laptop
fifo_w256_128_r256_128_ib i_readout0 (
	.rst(rst),
	.wr_clk(CLKM),
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
	.rst(rst),
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

// assign PCB_SPI_DOUT = 

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
reg MUX_START_i;
wire FIFO_IN_TRIG;
wire FIFO_IN_CLK;
wire [8:0] ADC_DEBUG;
wire OK_FIFO_OUT_TRIG;
assign FIFO_IN_CLK = clk_200;
ADC_RO adc(

    .rst(rst),
    .clk_100(clk_100),
    .CP_MUX_IN(CP_MUX_IN_i),
    .ADC_INCLK(ADC_CLK_OUT),
    .MUX_START(MUX_START_i),
    //.MUX_START(MUX_START),
    .ADC1_SHR(),
    .ADC1_DATA_RAW(ADC1_DATA),
    .ADC1_DATA_CLK(ADC1_DATA_CLK),
    .ADC2_SHR(),
    .ADC2_DATA_RAW(ADC2_DATA),
    .ADC2_DATA_CLK(ADC2_DATA_CLK),

    .FIFO_IN_CLK(FIFO_IN_CLK),
    .FIFO_IN_TRIG(FIFO_IN_TRIG),
    .FIFO_IN_DATA1(FIFO_IN_DATA1),
    .FIFO_IN_DATA2(FIFO_IN_DATA2),

    // DATA to OK
    .OK_FIFO_Start_Trig(OK_FIFO_Start_Trig),
    .OK_FIFO_DATA_OUT(OK_FIFO_DATA_OUT),
    .OK_FIFO_OUT_TRIG(OK_FIFO_OUT_TRIG),
    .OK_CLK(okClk),
    .OK_FIFO_EMPTY(),

    // RAM FIFO
    .RAM_FIFO_FULL(),
    .RAM_FIFO_EMPTY(),
    .RAM_FIFO_DOUT(),
    .RAM_FIFO_CLK(clk_100),
    .RAM_FIFO_RD_EN(0),
    .RAM_FIFO_VALID(),
    .RAM_FIFO_RD_COUNT(),
    .RAM_FIFO_WR_COUNT(),

    .DEBUG(ADC_DEBUG)
);
// assign TestIO[13:1] = {FIFO_IN_TRIG, ADC_DEBUG[6:0], 
//                         CP_MUX_IN_i, MUX_START_i, 
//                         ADC1_DATA_CLK,
//                         ADC_CLK_OUT, clk_100};
reg [7:0] counter;
wire cp_start;
reg stop_sig;
reg [3:0] stop_cnt;

initial counter = 0;
assign CP_MUX_IN_i = counter[0];
initial stop_sig = 1;
initial stop_cnt = 0;
initial MUX_START_i = 1;

assign cp_start = testWireIn[0];

always @(posedge clk_010) begin
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

assign led[7:0]     = xem7310_led({1'b0,CS_POT2,dout[31:26]});
// assign TestIO[8:1]  = dout[7:0];
// assign TestIO[9]    = CS_POT1;
// assign TestIO[10]   = CS_POT2;
// assign TestIO[11]   = PCB_SPI_DIN; 
// assign TestIO[12]   = PCB_SPI_CLK;
// assign TestIO[20:13]  = dout[31:24];
// assign TestIO[13:1] = {ADC1_SHR, ADC1_DATA[7:0], ADC1_DATA_CLK, ADC2_DATA_CLK, ADC_CLK_OUT, clk_100};



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
				.NumRow(NumRow)
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
assign testWireOut = {FIFO_IN_DATA1, FIFO_IN_DATA2};
assign testWireOut2[0] = ~OK_FIFO_Start_Trig;
assign testWireOut2[1] = FIFO_IN_TRIG;
assign testWireOut2[2] = FIFO_Empty;
assign testWireOut2[3] = OK_FIFO_OUT_TRIG;
assign testWireOut2[4] = FIFO_Flag[0];
assign testWireOut2[5] = FIFO_Flag[1];
assign testWireOut2[6] = FIFO_Flag[2];
assign testWireOut2[7] = rst;
assign testWireOut2[8] = ADC1_DATA_CLK;
assign testWireOut2[9] = ADC2_DATA_CLK;

assign FIFO_Flag[2] = OK_FIFO_Start_Trig;
assign FIFO_Flag[4] = FIFO_Empty;
assign FIFO_Flag[0] = 1;
assign FIFO_Flag[1] = 0;


localparam EHx_NUM = 7;
wire [65*EHx_NUM-1:0] okEHx;

okWireOR # (.N(EHx_NUM)) wireOR (okEH, okEHx);

okWireIn    wi00 (.okHE(okHE),      .ep_addr(8'h00),                    .ep_dataout(ep00wire));     // PCB_SPI_DATA
okWireIn    wi01 (.okHE(okHE),      .ep_addr(8'h01),                    .ep_dataout(testWireIn));     // test

okTriggerIn	ti40 (.okHE(okHE),      .ep_addr(8'h40),    .ep_clk(ADC_CLK_OUT), .ep_trigger(trig40));
okTriggerIn	ti41 (.okHE(okHE),      .ep_addr(8'h40),    .ep_clk(okClk), .ep_trigger(trig41));

okWireOut   wi21 (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'h21), .ep_datain(ep00wire)); 
okWireOut   wi22 (.okHE(okHE), .okEH(okEHx[ 1*65 +: 65 ]), .ep_addr(8'h22), .ep_datain(testWireOut));  // test
okWireOut   wi25 (.okHE(okHE), .okEH(okEHx[ 6*65 +: 65 ]), .ep_addr(8'h25), .ep_datain(testWireOut2));  // test
okWireOut   wi23 (.okHE(okHE), .okEH(okEHx[ 2*65 +: 65 ]), .ep_addr(8'h23), .ep_datain(FIFO_IN_DATA1[15:0]));  // test
okWireOut   wi24 (.okHE(okHE), .okEH(okEHx[ 3*65 +: 65 ]), .ep_addr(8'h24), .ep_datain(FIFO_IN_DATA2[15:0]));  // test

okTriggerOut to6A (.okHE(okHE),     .okEH(okEHx[4*65 +: 65]),   .ep_addr(8'h6A),    
                    .ep_clk(okClk),  .ep_trigger(FIFO_Flag));
okPipeOut poA3  (.okHE(okHE),       .okEH(okEHx[5*65 +: 65]),   .ep_addr(8'hA3),    
                    .ep_datain(OK_FIFO_DATA_OUT),  .ep_read(OK_FIFO_OUT_TRIG));

endmodule
