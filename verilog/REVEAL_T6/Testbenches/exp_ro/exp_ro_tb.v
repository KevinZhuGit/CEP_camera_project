`timescale 1ns / 1ps

module exp_ro_tb();

	reg clk_100; initial clk_100 = 1'b0; always #5   clk_100 = ~clk_100; 
	reg clk_200; initial clk_200 = 1'b0; always #2.5 clk_200 = ~clk_200; 
    reg clk_7  ; initial clk_7   = 1'b0; always #35  clk_7   = ~clk_7; 
    wire CLKMi, TX_CLKi, TX_CLKi2;
    assign CLKMi = clk_100;
    assign TX_CLKi  = clk_100;
    assign TX_CLKi2 = clk_200;
    assign ADC_CLK  = clk_7;
	reg rst;

	wire [7:0] ROWADD;
	wire [7:0] ROWADD_EXP;
	wire [7:0] ROWADD_RO;
    
	wire ex_trigger;	
	wire re_busy;
	reg [31:0] wirerst, Select;


	// Readout
	parameter 
		NUMROW_RO = 10,
	//T6 RO----------------------------------------
		NUM_SAMP	= 2,
		NUM_ROW		= 10,
		T_PIX		= 100,
		T1         = 5,
		T2         = 100,
		T3         = 20,
		T4         = 10,
		T5         = 14,
		T6         = 6,
		T7         = 17,
		T8         = 14,
	    TADC       = 13,
	    TOSR       = 115,
	    TReadRst   = 100,
	    Tbuck      = 1652,
	    T6_NUM_ADC_BITS = 14;
	// T7 RO----------------------------------------
     parameter  
        RO_Tcolumn_t7			= 700,
		RO_T1_t7                = 10,
		RO_T2_1_t7              = 400,
		RO_T2_0_t7              = 420,
		RO_T3_t7                = 20*12,
		RO_T4_t7                = RO_T3_t7+2,
		RO_T5_t7                = 4,
		RO_T6_t7                = 1,
		RO_T7_t7                = 22,
		RO_T8_t7                = 2,
		RO_T9_t7				= RO_T8_t7+20,
		RO_TADC_t7              = 22,
		RO_NUM_ROW_t7           = NUMROW_RO,
		T7_NUM_ADC_BITS 		= 12,
		T_RO_Wait               = 1024;	
	
    parameter
        wireNumPat  = 4,
        NumRep      = 2,
        NumGsub     = 0,
        Tproj_dly   = 110,
        Tgl_res     = 200,
        Tadd        = 3,
        wireExp     = 159,
        TLedOn      = 30000,
        Tdes2_d     = 2,
        Tdes2_w     = 4,
        Tmsken_d    = 4,
        Tmsken_w    = 11,
        Tgsub_w     = 100,
        TExpRst     = 100,
        TdrainR_d   = 10,
        TdrainF_d   = 20;

    
    parameter 
    	T_DEC_SEL_0 = 4,
        T_DEC_SEL_1 = 1,
        T_DEC_EN_0  = 4,
        T_DEC_EN_1  = 2,
        T_DONE_1    = 4;
    
    

   
	//EXP-------------------------------------- 
	Exposure_v1_T7 exposure_inst (
		.rst(wirerst[0]),
        .CLKM(CLKMi),
		.trigger_o(ex_trigger),
		.re_busy(re_busy),
		.PIXGSUBC(PIX_GSUBC),
		.PIXDRAIN(PIX_DRAIN),
		.PIXGLOB_RES(PIXGLOB_RES_i),
		//.PIXGLOB_RES(PIXGLOB_RES),
		.PIXVTG_GLOB(PIXVTG_GLOB),
		.MASK_EN(MASK_EN),
		.EN_STREAM(rd_enable),
		.DES_2ND(DES2ND),
		.PROJ_TRG(PROJ_TRG),
		.ROWADD(ROWADD_EXP),
		.contrastLED(contrastLED),

		.NUM_PAT(wireNumPat),
		.NUM_REP(NumRep),
		.NUM_ROW(NUM_ROW),
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
		.Treset(TExpRst),
		.TdrainR_d(TdrainR_d),
		.TdrainF_d(TdrainF_d)
	);


	//wire [31:0] RO_Tcolumn_t7, RO_T1_t7, RO_T2_t7, RO_T3_t7, RO_T4_t7, RO_T5_t7, RO_T6_t7, RO_T7_t7, RO_T8_t7, RO_Treset_t7; 
	wire [8:0] ROWADD_RO_t7;
	Readout_v1_T7 #(
			.NUM_ADC_BITS(T7_NUM_ADC_BITS)) 
	u_Readout(
		.rst				(wirerst[0]),
		.trigger_i			(ex_trigger),
		.re_busy			(re_busy_t7),
		.TX_CLK				(TX_CLKi),
		.TX_CLKx2			(TX_CLKi2),

		.ROWADD				(ROWADD_RO_t7),
		.SET_ROW			(SET_ROW_RO),
		.SET_ROW_DONE 		(SET_ROW_DONE_RO),

		.PIXLEFTBUCK_SEL	(PIX_LEFTBUCK_SEL_t7),
		.ODDCOL_EN			(ODDCOL_EN_t7),
		.PRECH_COL			(COL_PRECH_12_t7),
		.ADC_RST			(ADC_RST_t7),
		.ADC_CLK			(ADC_CLK_out_t7),

		.RST_BAR_LTCHD		(RST_BAR_LTCHD_t7),
		.LOAD_IN			(LOAD_IN_t7),
		.ADC_DATA_VALID		(ADC_DATA_VALID_t7),

		.PIXREAD_SEL		(PIXREAD_SEL_t7),
		.ADC_BIAS_EN		(ADC_BIAS_EN_t7),
		.COLL_EN			(COLL_EN_t7),
		.PIXRES				(PIXRES_t7),

        .Tcolumn (RO_Tcolumn_t7),
		.T1     (RO_T1_t7),
        .T2_1   (RO_T2_1_t7),
        .T2_0   (RO_T2_0_t7),
        .T3     (RO_T3_t7),
        .T4     (RO_T4_t7),
        .T5     (RO_T5_t7),
        .T6     (RO_T6_t7),        
        .T7     (RO_T7_t7),
        .T8     (RO_T8_t7),
        .T9     (RO_T9_t7),
        .TADC	(RO_TADC_t7),
		.NUM_ROW(RO_NUM_ROW_t7),
		.T_RO_Wait(T_RO_Wait)		
	);
	wire [17:1] DIGOUT;
	DIGOUT_test u_DIGOUT_test(
		.clk			(TX_CLKi),
		.rst			(~re_busy),
		.RST_BAR_LTCHD	(RST_BAR_LTCHD_t7),
		.ADC_DATA_VALID	(ADC_DATA_VALID),
		.DIGOUT			(DIGOUT[17:1])
	);

    	
	ADCtoFIFO i_adc_fifo(
        .rst(wirerst[0]),
//        .adc_clk0_i(TXCLK_OUT),
        .adc_clk0_i(TX_CLKi),
        .adc_gr0_valid(ADC_DATA_VALID),
//        .adc_gr0_valid(1),
        .ch_data_i(DIGOUT[17:1]),
        .p0_rd_clk(TX_CLKi),
        .p0_rd_en(1),
        .p0_rd_data_cnt(pipe0_in_rd_count),
        .p0_full(pipe0_in_full),
        .p0_empty(pipe0_in_empty),
        .p0_valid(pipe0_in_valid),
        .p0_data_o(pipe0_in_rd_data)
    );

	wire [9:0] ROWADD_DEC;
    set_row_decoder exp_ro_row_decoder(
		.clk(TX_CLKi),
		.rst(wirerst[0]),

		.ROWADD_MU(ROWADD_EXP),
		.ROWADD_RO(ROWADD_RO_t7[9:0]),
		.SET_ROW_MU(DES2ND),
		.SET_ROW_RO(SET_ROW_RO),
	
		.SET_ROW_DONE_MU(SET_ROW_DONE_MU),
		.SET_ROW_DONE_RO(SET_ROW_DONE_RO),
		.DEC_SEL(DEC_SEL),     
		.DEC_EN(DEC_EN),      
		.ROWADD_op(ROWADD_DEC[9:0]),    
	
		.T_DEC_SEL_0(T_DEC_SEL_0[31:0]),
		.T_DEC_SEL_1(T_DEC_SEL_1[31:0]),
		.T_DEC_EN_0(T_DEC_EN_0[31:0]), 
		.T_DEC_EN_1(T_DEC_EN_1[31:0]), 
		.T_DONE_1(T_DONE_1[31:0])    	
	);
//	assign ROWADD = (re_busy) ? ROWADD_RO : ROWADD_EXP;
	assign ROWADD = ROWADD_DEC;
	
	assign re_busy            = re_busy_t7           ;
	assign ROWADD_RO          = ROWADD_RO_t7         ;
	assign PIXREAD_EN         = PIXREAD_SEL_t7       ;
	assign PIX_LEFTBUCK_SEL   = PIX_LEFTBUCK_SEL_t7  ;
	assign PIX_RIGHTBUCK_SEL  = PIX_LEFTBUCK_SEL_t7  ;
	assign COL_PRECH_12       = COL_PRECH_12_t7      ;
	assign COLL_EN            = COLL_EN_t7           ;
	assign ODDCOL_EN          = ODDCOL_EN_t7         ;
	assign LOAD_IN            = LOAD_IN_t7           ;
	assign ADC_RST            = ADC_RST_t7           ;
	assign ADC_DATA_VALID     = ADC_DATA_VALID_t7    ;
	
	//set initial values
	    integer cnt_busy = 0;
    always @(posedge clk_100) begin
		if (rst) begin
			//ex_trigger <= 1'b0;
			cnt_busy <= cnt_busy + 1;
			if (cnt_busy >= 20) begin
			     rst <= 1'b0;
			     cnt_busy <= 1'b0;
			end
		end 
    end

    //set initial values	
	initial begin
			Select[31:0] = 32'h00000000;
			wirerst[0] = 1;		
	#20		wirerst[0] = 0;
	
	
	end

endmodule
