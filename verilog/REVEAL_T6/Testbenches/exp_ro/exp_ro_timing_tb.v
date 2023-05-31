`timescale 1ns / 1ps

module exp_ro_timing_tb();

	reg rst;

	//CLOCK SIGNALS
	reg clk_200; always #2.5 clk_200=~clk_200;   // 200MHz
	reg clk_100; always #5 clk_100=~clk_100;   // 100MHz

	/*
	reg [31:0] Num_Pat;
	reg [31:0] Num_Rep;
	reg [31:0] exp_time;

	reg TX_CLK;
	reg ADC_CLK;
	*/

	//HANDSHAKE SIGNALS
	wire ex_trigger;
	wire re_busy;


	//ROWADD
	wire [9:0] ROWADD;
	wire [9:0] ROWADD_EXP;
	wire [9:0] ROWADD_RO;

	assign ROWADD = re_busy ? ROWADD_RO : ROWADD_EXP;

	//EXPOSURE WIRES
	//wire PIXTG;
	wire PIXROWMASK;
 	wire DES;
	wire MASK_EN;
	wire PIXGLOB_RES;
	wire PIXVTG_GLOB;
	//wire CLKMPRE_EN;
	//wire EN_STREAM;
	wire PIXDRAIN;
	wire PIXGSUBC;
	wire EXP;
	wire SYNC;
	wire STDBY;

	//READOUT WIRES
	wire COL_L_EN;
	wire COL_PRECH;
	wire CP_MUX_IN;
	wire MUX_START;
	wire PIXRES;
	wire PH1;
	wire PGA_RES;
	wire SAMP_R;
	wire SAMP_S;
	wire READ_R;
	wire READ_S;

	//EXPOSURE PARAMETERS
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
	
	//READOUT PARAMETERS
	parameter
		RO_T1	= 1724,
		RO_T2	= 862,
		RO_T3	= 2,
		RO_T4	= 3,
		RO_T5	= 2,
		RO_T6	= 20,

		NUM_ROW	= 20;

	//EXPOSURE MODULE INSTANTIATION
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

	Readout_v1 readout_inst (
		.rst		(rst),
		.CLK		(clk_100),
		.trigger_i	(ex_trigger),
		.re_busy	(re_busy),

		.ROWADD		(ROWADD_RO),

		.COL_L_EN	(COL_L_EN),
		.COL_PRECH	(COL_PRECH),
		.CP_MUX_IN	(CP_MUX_IN),
		.MUX_START	(MUX_START),
		.PIXRES		(PIXRES),
		.PH1		(PH1),
		.PGA_RES	(PGA_RES),
		.SAMP_R		(SAMP_R),
		.SAMP_S		(SAMP_S),
		.READ_R		(READ_R),
		.READ_S		(READ_S),

		.T1		(RO_T1),
		.T2		(RO_T2),
		.T3		(RO_T3),
		.T4		(RO_T4),
		.T5		(RO_T5),
		.T6		(RO_T6),

		.NUM_ROW	(NUM_ROW)
	);

	initial begin
		clk_200=0;
		clk_100=0;
		rst=1;

		#100 rst = 0;
	end

	//--------------------------------------------------
	//EXPOSURE TIMING TEST
	//--------------------------------------------------
	
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

	//--------------------------------------------------
	//EXPOSURE TIMING TEST
	//--------------------------------------------------
	initial begin: RO_T1_TIME
		integer ROW_ORIGINAL;
		integer ROW_CHANGE;
		integer difference;

		@(ROWADD_RO);
		ROW_ORIGINAL = $time;

		@(ROWADD_RO);
		ROW_ORIGINAL = $time;

		@(ROWADD_RO);
		ROW_CHANGE = $time;

		difference = ROW_CHANGE-ROW_ORIGINAL;

		$display("RO_T1 Start Time: %d", ROW_ORIGINAL);
		$display("RO_T1 End Time: %d", ROW_CHANGE);

		// checking
		if (difference == RO_T1*10) begin
			$display("RO_T1: Same simulation time as expected\n");
		end else begin
			$display("RO_T1: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", RO_T1*10, difference);
		end

	end

	initial begin: RO_T2_TIME

		integer falling_COL_L_EN;
		integer rising_COL_L_EN;
		integer difference;

		@(posedge COL_L_EN);
		rising_COL_L_EN = $time;

		@(negedge COL_L_EN);
		falling_COL_L_EN = $time;

		difference = falling_COL_L_EN-rising_COL_L_EN;

		$display("RO_T2 Start Time: %d", rising_COL_L_EN);
		$display("RO_T2 End Time: %d", falling_COL_L_EN);

		// checking
		if (difference == RO_T2*10) begin
			$display("RO_T2: Same simulation time as expected\n");
		end else begin
			$display("RO_T2: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", RO_T2*10, difference);
		end

	end

	initial begin: RO_T3_TIME

		integer rising_PRECH_COL;
		integer falling_PRECH_COL;
		integer difference;

		@(posedge COL_PRECH);
		rising_PRECH_COL = $time;

		@(negedge COL_PRECH);
		falling_PRECH_COL = $time;

		difference = falling_PRECH_COL-rising_PRECH_COL;

		$display("RO_T3 Start Time: %d", rising_PRECH_COL);
		$display("RO_T3 End Time: %d", falling_PRECH_COL);

		// checking
		if (difference == RO_T3*10) begin
			$display("RO_T3: Same simulation time as expected\n");
		end else begin
			$display("RO_T3: Wrong simulation time\n");
			$display("Expected: %d\nActual: %d\n", RO_T3*10, difference);
		end

	end

	initial begin: RO_T4_TIME

		integer rising_MUX_START;
		integer falling_MUX_START;
		integer difference;

		@(posedge MUX_START);
		rising_MUX_START = $time;

		@(negedge MUX_START);
		falling_MUX_START = $time;

		difference = falling_MUX_START-rising_MUX_START;

		$display("RO_T4 Start Time: %d", rising_MUX_START);
		$display("RO_T4 End Time: %d", falling_MUX_START);

		// checking
		if (difference == RO_T4*10) begin
			$display("RO_T4: Same simulation time as expected\n");
		end else begin
			$display("RO_T4: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T4*10, difference);

		end
	end

	initial begin: RO_T5_TIME

		integer rising_PRECH_COL;
		integer rising_CP_MUX_IN;
		integer difference;

		@(posedge COL_PRECH);
		rising_PRECH_COL = $time;

		@(posedge CP_MUX_IN);
		rising_CP_MUX_IN = $time;

		difference = rising_CP_MUX_IN-rising_PRECH_COL;

		$display("RO_T5 Start Time: %d", rising_PRECH_COL);
		$display("RO_T5 End Time: %d", rising_CP_MUX_IN);

		// checking
		if (difference == RO_T5*10) begin
			$display("RO_T5: Same simulation time as expected\n");
		end else begin
			$display("RO_T5: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T5*10, difference);
		end
	end

	initial begin: RO_T6_TIME

		integer rising_CP_MUX_IN;
		integer rising_CP_MUX_IN_2ND;
		integer difference;

		@(posedge CP_MUX_IN);
		rising_CP_MUX_IN = $time;

		@(posedge CP_MUX_IN);
		rising_CP_MUX_IN_2ND = $time;

		difference = rising_CP_MUX_IN_2ND - rising_CP_MUX_IN;

		$display("RO_T6 Start Time: %d", rising_CP_MUX_IN);
		$display("RO_T6 End Time: %d", rising_CP_MUX_IN_2ND);

		// checking
		if (difference == RO_T6*10) begin
			$display("RO_T6: Same simulation time as expected\n");
		end else begin
			$display("RO_T6: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T6*10, difference);
		end
	end
endmodule
