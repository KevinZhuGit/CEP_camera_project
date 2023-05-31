`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2019 11:32:18 PM
// Design Name: 
// Module Name: exp_ro_v4_tb
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


module exp_ro_v4_tb(

    );

	reg clk_5;  initial clk_5 = 1'b1; 	 always #100 clk_5 = ~clk_5; 
	reg clk_10;  initial clk_10 = 1'b1; 	 always #50 clk_10 = ~clk_10; 
	reg clk_30;  initial clk_30 = 1'b1; 	 always #16.667 clk_30 = ~clk_30; 
	reg clk_100; initial clk_100 = 1'b1; always #5 clk_100 = ~clk_100; 
	reg clk_200; initial clk_200 = 1'b1; always #2.5 clk_200 = ~clk_200; 

	reg reset;

	wire [7:0] ROWADD;
	wire [7:0] ROWADD_EXP;
	wire [7:0] ROWADD_RO;
    wire re_busy;
    
    assign ROWADD = (re_busy) ? ROWADD_RO : ROWADD_EXP;
    
   	wire ex_trigger;
	//RO----------------------------------------
	wire COL_L_EN;
	wire PIXRES_L;
	wire PIXRES_R;
	wire STDBY;
	wire COL_PRECH;
	wire PGA_RES;
	wire CK_PH1;
	wire SAMP_S;
	wire SAMP_R;

	wire READ_R;
	wire READ_S;
	wire MUX_START;
	wire CP_COLMUX_IN;
	wire PIXRES;

    //EXP---------------------------------------
    wire MASK_EN;
    wire PIXDRAIN;
    wire PIXGLOB_RES;
    wire PIXVTG_GLOB;
    wire PIXREAD_EN;
    wire EXP;
    wire PIX_GSUBC;
    wire PIX_ROWMASK;
    wire DES;
    wire SYNC; 
	
    /* Readout wires */
    wire [31:0] T1_e, T2_e, T3_e, T4_e, T5_e, T6_e, T7_e, T8_e, T9_e; 
    wire [31:0] T1_r, T2_r, T3_r, T4_r, T5_r, T6_r, T7_r, T8_r, T9_r, T10_r, T11_r, T12_r, T13_r, T14_r, NL_r, NR_r;
    wire [31:0] Tlat1, Tlat2;
    wire [31:0] Texp_ctrl;
    wire [31:0] Tgl_res;
    wire [31:0] T_reset;
    wire [31:0] T_stdby;
    wire [31:0] NumPat;
    wire [31:0] Tlat;
    wire [31:0] NumRow;
    
    
    reg re_trigger;
    always @(negedge clk_10) begin
        //re_trigger <= re_busy|(~p0_empty);
        re_trigger <= re_busy;
    end
	
    Exposure_v2 exposure_inst(
        .STDBY(STDBY),
        //.NUM_SUB(NumPat),
        .NUM_SUB(10),
        .rst(reset),
        .CLKM(clk_100),
        .MASK_EN(MASK_EN),
        .PIXDRAIN(PIXDRAIN),
        .PIXGLOB_RES(PIXGLOB_RES),
        .PIXVTG_GLOB(PIXVTG_GLOB),
        .PIXREAD_EN(PIXREAD_EN),
        .EXP(EXP),
        .PIXGSUBC(PIX_GSUBC),
        .PIXROWMASK(PIX_ROWMASK),
        .DES(DES),
        .SYNC(SYNC),
        .ROWADD(ROWADD_EXP),
        .trigger_o(ex_trigger),
        .re_busy(re_busy),
        .exp_start(re_busy | re_trigger),
        .T_stdby(T_stdby),
        .T_reset(1000),
        .Tgl_res(Tgl_res),
        .Texp_ctrl(Texp_ctrl),
        //.Texp_ctrl(2000),
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
    
assign READ_R = ~COL_PRECH & ~READ_S;
    
Readout_noPGA readout_inst (
	.rst		(reset),
//	.PGA_en(0),
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
//	.READ_R		(READ_R),
	.READ_S		(READ_S),

    .T1(940),
    .T2(470),
    .T3(2),
    .T4(5),
    .T5(40),
    .T6(10),
//    .T7(4),
//    .T8(6),
//    .T9(210),
//    .T10(2),
//    .T11(3),
//    .T12(10),
//    .T13(2),
//    .T14(207),
//    .NL(NL_r),
//    .NR(NR_r),

	.adc_clk(clk_10),
	.adc1_out_clk(),
	.adc2_out_clk(),
	.Tlat1(Tlat1),
	.Tlat2(Tlat2),
	.adc1_dat_valid(),
	.adc2_dat_valid(),

	//.NUM_ROW	(NumRow)
	.NUM_ROW	(10)
);

    //Adjust values of different parameters
	varValueSelector varValueSelector(
        .wr_en(0),          // Address of the variable whose value needs to be changed
        .varAddress(0),          // Address of the variable whose value needs to be changed
        .varValueIn(0),         // Input Value of the variable
        //.varValueOut(0),        // Output Value of the variable
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
				.T7_r(T7_r),
				.T8_r(T8_r),
				.T9_r(T9_r),
				.T10_r(T10_r),
				.T11_r(T11_r),
				.T12_r(T12_r),
				.T13_r(T13_r),
				.T14_r(T14_r),
				.NL(NL_r),
				.NR(NR_r),
				.Tgl_res(Tgl_res),
				.T_stdby(T_stdby),
				.Texp_ctrl(Texp_ctrl),
				.NumPat(NumPat),
				.T_reset(T_reset),
				.NumRow(NumRow),
				.Tlat1(Tlat1),
				.Tlat2(Tlat2)
    );



	
    
	initial begin
	  reset = 1'b1;
	end

	initial begin
	  #100 reset = 1'b0;
	end

    
endmodule
