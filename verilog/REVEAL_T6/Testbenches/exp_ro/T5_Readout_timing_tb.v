`timescale 1ns / 1ps

module T5_Readout_timing_tb();

	reg clk_200;
	reg clk_100;
	reg rst;

	reg [31:0] Num_Pat;
	reg [31:0] Num_Rep;
	reg [31:0] exp_time;

	reg TX_CLK;
	reg ADC_CLK;




//RO
	//output signals
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

    wire [9:0] ROWADD;
	wire [9:0] ROWADD_EXP;
	wire [9:0] ROWADD_RO;
	wire ADC_DATA_VALID;
	//This is used to indicate when to serialize adc data from three channels
	wire ADC_DATA_SER;

	wire rd_en_pattern;

	wire ex_trigger;

	wire re_busy;
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
			EXP_T9		= 1;

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


	Exposure_v1 testing(
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



	parameter
		RO_T1	= 1724,
		RO_T2	= 862,
		RO_T3	= 2,
		RO_T4	= 3,
		RO_T5	= 2,
		RO_T6	= 20,

		NUM_ROW	= 20;

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
/*
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
*/

// always @(posedge clk_100) begin
// 		if (rst) begin
// 			ex_trigger <= 1'b0;
// 			cnt_busy <= cnt_busy + 1;
// 			if (cnt_busy >= 20) begin
// 			     rst <= 1'b0;
// 			     cnt_busy <= 1'b0;
// 			end
// 		end else if (~re_busy) begin
// 		    if (cnt_busy >= 20) begin
// 		      ex_trigger <= 1'b1;
// 		      cnt_busy <= 0;
// 		    end else begin
// 		      cnt_busy <= cnt_busy + 1;
// 		      ex_trigger <= 1'b0;
// 		    end
// 		end else begin
// 			ex_trigger <= 1'b0;
// 		end
// 	end

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
