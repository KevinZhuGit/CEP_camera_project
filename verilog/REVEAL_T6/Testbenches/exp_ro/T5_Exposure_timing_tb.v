`timescale 1ns / 1ps

module T5_Exposure_timing_tb();

	reg clk_200;
	reg clk_100;
	reg rst;

	reg [31:0] Num_Pat;
	reg [31:0] Num_Rep;
	reg [31:0] exp_time;

	reg TX_CLK;
	reg ADC_CLK;




//RO
	wire COL_L_EN;
	wire PIXRES_L;
	wire PIXRES_R;
	wire PRECH_COL;
	wire PGA_RES;
	wire CK_PH1;
	wire SAMP_S;
	wire SAMP_R;

	wire READ_R;
	wire READ_S;
	wire MUX_START;
	wire CP_MUX_IN;


	wire [8:0] ROWADD_EXP;
	wire [8:0] ROWADD_RO;
	wire ADC_DATA_VALID;
	//This is used to indicate when to serialize adc data from three channels
	wire ADC_DATA_SER;

	wire rd_en_pattern;

	wire ex_trigger;

	reg re_busy;
	initial re_busy <= 0;
  integer cnt_busy;
	initial cnt_busy <= 0;

	assign ROWADD = re_busy ? ROWADD_RO : ROWADD_EXP;


	parameter
			EXP_Treset = 20,
			EXP_Tgl_res = 10,
			EXP_Texp_ctrl = 16,
			EXP_T1		= 16,
			EXP_T2		= 1,
			EXP_T3		= 1,
			EXP_T4		= 1,
			EXP_T5		= 1,
			EXP_T6		= 1,
			EXP_T7		= 1,
			EXP_T8		= 1,
			EXP_T9		= 1,
			EXP_T_stdby = 100;

	wire PIXTG;
	wire PIXROWMASK;
 	wire DES;
	wire MASK_EN;
	wire PIXGLOB_RES;
	wire PIXVTG_GLOB;
	wire CLKMPRE_EN;
	wire EN_STREAM;
	wire PIXDRAIN;
	wire PIXGSUBC;
	wire EXP;
	wire SYNC;
	wire STDBY;


	Exposure_v2 Exposure_inst(
	.STDBY(STDBY),
	.NUM_SUB(3),
	.rst(rst),
	.CLKM(clk_100),
	.MASK_EN(MASK_EN),
	.PIXDRAIN(PIXDRAIN),
	.PIXGLOB_RES(PIXGLOB_RES),
	.PIXVTG_GLOB(PIXVTG_GLOB),
	.EXP(EXP),
	.PIXGSUBC(PIXGSUBC),
	.PIXROWMASK(PIXROWMASK),
	.DES(DES),
	.T_stdby(EXP_T_stdby),
	.SYNC(SYNC),
	.ROWADD(ROWADD_EXP),
	.trigger_o(ex_trigger),
	.re_busy(re_busy),
	.T_reset(EXP_Treset),
	.Tgl_res(EXP_Tgl_res),
	.Texp_ctrl(EXP_Texp_ctrl),
	.T1(EXP_T1),
	.T2(EXP_T2),
	.T3(EXP_T3),
	.T4(EXP_T4),
	.T5(EXP_T5),
	.T6(EXP_T6),
	.T7(EXP_T7),
	.T8(EXP_T8),
	.T9(EXP_T9)
	);


	// parameter
	// 		NUM_SAMP	= 2,
	// 		NUM_ROW		= 4,
	// 		T_PIX		= 100,
	//
	// 		T1		= 100,
	// 		T2		= 8620,
	// 		T3		= 20,
	// 		T4		= 400,
	// 		T5L		= 2000/NUM_SAMP,
	// 		T5R		= 2000/NUM_SAMP,
	// 		T6		= 10,
	// 		T7		= 10,
	// 		T8		= 40,
	// 		T9		= 30,
	// 		T10		= 10;
	//
	// 	Readout_v0 readout_inst (
	// 		.rst		(rst),
	//
	// 		.CLK		(clk_100),
	// 		.trigger_i	(ex_trigger),
	// 		.re_busy	(re_busy),
	//
	// 		.ROWADD		(ROWADD_RO),
	//
	// 		.COL_L_EN	(COL_L_EN),
	// 		.PIXRES_L	(PIXRES_L),
	// 		.PIXRES_R	(PIXRES_R),
	// 		.STDBY		(STDBY),
	// 		.PRECH_COL	(PRECH_COL),
	// 		.PGA_RES	(PGA_RES),
	// 		.CK_PH1		(CK_PH1),
	// 		.SAMP_S		(SAMP_S),
	// 		.SAMP_R		(SAMP_R),
	//
	// 		.READ_R		(READ_R),
	// 		.READ_S		(READ_S),
	// 		.MUX_START	(MUX_START),
	// 		.CP_COLMUX_IN	(CP_MUX_IN),
	//
	// 		.T1		(T1),
	// 		.T2		(T2),
	// 		.T3		(T3),
	// 		.T4		(T4),
	// 		.T5L		(T5L),
	// 		.T5R		(T5R),
	// 		.T6		(T6),
	// 		.T7		(T7),
	// 		.T8		(T8),
	// 		.T9		(T9),
	// 		.T10		(T10),
	//
	// 		.T_PIX		(T_PIX),
	// 		.NUM_SAMPL	(NUM_SAMP),
	// 		.NUM_SAMPR	(NUM_SAMP),
	//
	// 		.NUM_ROW	(NUM_ROW)
	// 	);

	always @ (clk_100) begin
      if (ex_trigger) begin
        cnt_busy <= 0;
        re_busy <= 1;
      end else if (re_busy) begin
        if (cnt_busy>=20) begin
          re_busy <= 0;
        end
        else begin
          cnt_busy <= cnt_busy + 1;
        end
      end
    end


	always #2.5 clk_200=~clk_200;   // 200MHz
	always #5 clk_100=~clk_100;   // 200MHz
	always #70 ADC_CLK=~ADC_CLK;   // 200MHz
	// always #23.333333 TX_CLK=~TX_CLK;

	reg enable;

	initial begin
		clk_200=0;
		clk_100=0;
		rst=1;
		// TX_CLK=0;
		ADC_CLK=0;
		Num_Pat=3;
		Num_Rep=3;
		exp_time=500;
		enable = 1;
		TX_CLK=0;

		#100 rst = 0;
	end

	initial begin: Tgl_res_TIME
		integer rising_PIXGLOB_RES;
		integer falling_PIXGLOB_RES;
		integer difference;

		@(posedge PIXGLOB_RES);
		rising_PIXGLOB_RES = $time;

		@(negedge PIXGLOB_RES);
		falling_PIXGLOB_RES = $time;

		difference = falling_PIXGLOB_RES-rising_PIXGLOB_RES-(EXP_Treset*10);

		$display("Tgl_res Start Time: %d", rising_PIXGLOB_RES+(EXP_Treset*10));
		$display("Tgl_res End Time: %d", falling_PIXGLOB_RES);

		// checking
		if (difference == EXP_Tgl_res*10) begin
			$display("Tgl_res: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("Tgl_res: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", EXP_Tgl_res*10, difference);
			$finish;
		end

	end

	initial begin: Texp_ctrl_TIME
		integer rising_PIXROWMASK;
		integer rising_PIXGSUBC_2ND;
		integer difference;

		@(posedge PIXROWMASK);
		rising_PIXROWMASK = $time;

		@(posedge PIXGSUBC);
		rising_PIXGSUBC_2ND = $time;

		difference = rising_PIXGSUBC_2ND-rising_PIXROWMASK-(EXP_T1*10*324);

		$display("Texp_ctrl Start Time: %d", rising_PIXROWMASK+(EXP_T1*10*324));
		$display("Texp_ctrl End Time: %d",rising_PIXGSUBC_2ND);

		// checking
		if (difference == EXP_Texp_ctrl*10) begin
			$display("Texp_ctrl: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("Texp_ctrl: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", EXP_Texp_ctrl*10, difference);
			$finish;
		end

	end

	initial begin: T1_TIME
		integer rising_DES;
		integer rising_DES_2ND;
		integer difference;

		@(posedge DES);
		rising_DES = $time;

		@(posedge DES);
		rising_DES_2ND = $time;

		difference = rising_DES_2ND-rising_DES;

		$display("T1 Start Time: %d", rising_DES);
		$display("T1 End Time: %d", rising_DES_2ND);

		// checking
		if (difference == EXP_T1*10) begin
			$display("T1: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T1: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", EXP_T1*10, difference);
			$finish;
		end

	end

	initial begin: T2_TIME

		integer rising_PIXGSUBC;
		integer rising_DES;
		integer difference;

		@(posedge PIXGSUBC);
		rising_PIXGSUBC = $time;

		@(posedge DES);
		rising_DES = $time;

		difference = rising_DES-rising_PIXGSUBC - (EXP_T1*10);

		$display("T2 Start Time: %d", rising_PIXGSUBC+(EXP_T1*10));
		$display("T2 End Time: %d", rising_DES);

		// checking
		if (difference == EXP_T2*10) begin
			$display("T2: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T2: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", EXP_T2*10, difference);
			$finish;
		end

	end

	initial begin: T3_TIME

		integer rising_DES;
		integer falling_DES;
		integer difference;

		@(posedge DES);
		rising_DES = $time;

		@(negedge DES);
		falling_DES = $time;

		difference = falling_DES-rising_DES;

		$display("T3 Start Time: %d", rising_DES);
		$display("T3 End Time: %d", falling_DES);

		// checking
		if (difference == EXP_T3*10) begin
			$display("T3: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T3: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", EXP_T3*10, difference);
			$finish;
		end

	end

	initial begin: T4_TIME

		integer rising_PIXGSUBC;
		integer rising_SYNC;
		integer difference;

		@(posedge PIXGSUBC);
		rising_PIXGSUBC = $time;

		@(posedge SYNC);
		rising_SYNC = $time;

		difference = rising_SYNC-rising_PIXGSUBC - (EXP_T1*10*4);

		$display("T4 Start Time: %d", rising_PIXGSUBC + (EXP_T1*10*4));
		$display("T4 End Time: %d", rising_SYNC);

		// checking
		if (difference == EXP_T4*10) begin
			$display("T4: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T4: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T4*10, difference);
			$finish;

		end
	end

	initial begin: T5_TIME

		integer falling_SYNC;
		integer rising_SYNC;
		integer difference;

		@(posedge SYNC);
		rising_SYNC = $time;

		@(negedge SYNC);
		falling_SYNC = $time;

		difference = falling_SYNC-rising_SYNC;

		$display("T5 Start Time: %d", rising_SYNC);
		$display("T5 End Time: %d", falling_SYNC);

		// checking
		if (difference == EXP_T5*10) begin
			$display("T5: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T5: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T5*10, difference);
			$finish;
		end
	end

	initial begin: T6_TIME

		integer rising_SYNC;
		integer changing_ROW;
		integer difference;

		@(posedge SYNC);
		rising_SYNC = $time;

		@(ROWADD_EXP);
		changing_ROW = $time;

		difference = changing_ROW-rising_SYNC - (EXP_T1*10*4)+EXP_T4*10;

		$display("T6 Start Time: %d", rising_SYNC + (EXP_T1*10*4)-(EXP_T4*10));
		$display("T6 End Time: %d", changing_ROW);

		// checking
		if (difference == EXP_T6*10) begin
			$display("T6: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T6: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T6*10, difference);
			$finish;
		end
	end

	initial begin: T7_TIME
		integer rising_PIXGSUBC;
		integer rising_MASK_EN;
		integer difference;

		@(posedge PIXGSUBC);
		rising_PIXGSUBC = $time;

		@(posedge MASK_EN);
		rising_MASK_EN = $time;

		difference = rising_MASK_EN-rising_PIXGSUBC - (EXP_T1*10*4);

		$display("T7 Start Time: %d", rising_PIXGSUBC + (EXP_T1*10*4));
		$display("T7 End Time: %d", rising_MASK_EN);

		// checking
		if (difference == EXP_T7*10) begin
			$display("T7: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T7: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T7*10, difference);
			$finish;
		end
	end

	initial begin: T8_TIME
		integer falling_MASK_EN;
		integer rising_MASK_EN;
		integer difference;

		@(posedge MASK_EN);
		rising_MASK_EN = $time;

		@(negedge MASK_EN);
		falling_MASK_EN = $time;

		difference = falling_MASK_EN-rising_MASK_EN;

		$display("T8 Start Time: %d", rising_MASK_EN);
		$display("T8 End Time: %d", falling_MASK_EN);


		// checking
		if (difference == EXP_T8*10) begin
			$display("T8: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T8: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T8*10, difference);
			$finish;
		end
	end

	initial begin: T9_TIME
		integer falling_PIXGSUBC;
		integer rising_PIXGSUBC;
		integer difference;

		@(posedge PIXGSUBC);
		rising_PIXGSUBC = $time;

		@(negedge PIXGSUBC);
		falling_PIXGSUBC = $time;

		difference = falling_PIXGSUBC-rising_PIXGSUBC;

		$display("T9 Start Time: %d", rising_PIXGSUBC);
		$display("T9 End Time: %d", falling_PIXGSUBC);


		// checking
		if (difference == EXP_T9*10) begin
			$display("T9: Same simulation time as expected, %d\n",difference);
		end else begin
			$display("T9: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", EXP_T9*10, difference);
			$finish;
		end
	end

	// start time comparative analysis
	// tells us if T1 and T3 start at the same time
	// integer prech_time, data_time, time_diff;
	//
  //   always @ (posedge PRECH_COL)
  //    	prech_time = $time;
	//
  //   always @ (posedge DATA_LOAD) begin: TIMING_ANALYSIS
  //     	data_time = $time;
  //      	time_diff = data_time - prech_time;
	//
	// 	// enable is set to 0 when data_load goes high
  //       if (time_diff == 0 && enable == 1) begin
	// 		// $display ("T1 start time: %d", prech_time);
	// 		// $display ("T3 start time: %d", data_time);
  //       	$display ("***T1 and T3 started at the same time!***\n");
  //           enable = 0;
  //           disable TIMING_ANALYSIS; // disable once I have read the first time stamp
  //       end else if (enable == 1) begin
  //          	$display ("***T1 and T3 did NOT start at the same time. Time difference: %d ns***\n", time_diff);
  //           enable = 0;
  //           disable TIMING_ANALYSIS;
  //       end
	//
  //   end

endmodule
