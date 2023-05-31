`timescale 1ns / 1ps

module T5_Readout_v4_timing_tb();

	reg rst;

	reg ex_trigger;	//switch this to wire when testing with exposure module
	wire re_busy;
	
	reg PGA_en;

	wire COL_L_EN;
	wire PIXRES;
	wire COL_PRECH;
	wire PGA_RES;
	wire PH1;
	wire SAMP_S;
	wire SAMP_R;

	wire READ_R;
	wire READ_S;
	wire MUX_START;
	wire CP_MUX_IN;

	//clk (MHz)
	reg clk_100; initial clk_100 = 1'b0; always #5 clk_100 = ~clk_100; 
	reg clk_010; initial clk_010 = 1'b0; always #0.5 clk_010 = ~clk_010; 

	parameter
		RO_T1	= 1724,
		RO_T2	= 862,
		RO_T3	= 2,
		RO_T4	= 3,
		RO_T5	= 2,
		RO_T6	= 20,
		RO_T7	= 9,
		RO_T8	= 11,
		RO_T9	= 431,
		RO_T10	= 2,
		RO_T11	= 2,
		RO_T12	= 10,
		RO_T13	= 2,
		RO_T14	= 200,

		NL	= 2,
		NR	= 2,

		Tlat1	= 25,
		Tlat2	= 25,


		NumRow	= 20;

	Readout_v5 readout_inst (
		.rst		(rst),
		.CLK		(clk_100),
		.trigger	(ex_trigger),
		.re_busy	(re_busy),
		
		.PGA_en     (PGA_en),

		.ROWADD		(ROWADD),

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
		.T7		(RO_T7),
		.T8		(RO_T8),
		.T9		(RO_T9),
		.T10		(RO_T10),
		.T11		(RO_T11),
		.T12		(RO_T12),
		.T13		(RO_T13),
		.T14		(RO_T14),

		.NL		(NL),
		.NR		(NR),

		.adc_clk(clk_010),
	   .adc1_out_clk	(clk_010),
	   .adc2_out_clk	(clk_010),
	   .Tlat1		(Tlat1),
	   .Tlat2		(Tlat2),
	   .adc1_dat_valid	(adc1_dat_valid_pga_on),
	   .adc2_dat_valid	(adc2_dat_valid_pga_on),

		.NUM_ROW	(NumRow)
	);

	//set initial values
	initial begin
		rst		= 1'b1;
		ex_trigger	= 1'b0;
		PGA_en = 1'b1;
	end

	
	
	integer cnt_busy = 0;
    always @(posedge clk_100) begin
		if (rst) begin
			ex_trigger <= 1'b0;
			cnt_busy <= cnt_busy + 1;
			if (cnt_busy >= 20) begin
			     rst <= 1'b0;
			     cnt_busy <= 1'b0;
			end
		end else if (~re_busy) begin
		    if (cnt_busy >= 20) begin
		      ex_trigger <= 1'b1;
		      cnt_busy <= 0;
		    end else begin
		      cnt_busy <= cnt_busy + 1;
		      ex_trigger <= 1'b0;
		    end
		end else begin
			ex_trigger <= 1'b0;
		end
	end
    
    
    //set initial values
    
	initial begin
	   rst = 1'b1;
	end

	initial begin: RO_T1_TIME
		integer ROW_ORIGINAL;
		integer ROW_CHANGE;
		integer difference;

		@(ROWADD);
		ROW_ORIGINAL = $time;

		@(ROWADD);
		ROW_ORIGINAL = $time;

		@(ROWADD);
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

	initial begin: RO_T7_TIME

		integer readr_1;
		integer readr_2;
		integer difference;

		@(posedge READ_R);
		readr_1= $time;

		@(negedge READ_R);
		readr_2 = $time;

		difference = readr_2 - readr_1; 

		$display("RO_T7 Start Time: %d", readr_1);
		$display("RO_T7 End Time: %d", readr_2);

		// checking
		if (difference == RO_T7*10) begin
			$display("RO_T7: Same simulation time as expected\n");
		end else begin
			$display("RO_T7: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T7*10, difference);
		end
	end

	initial begin: RO_T8_TIME

		integer reads_1;
		integer reads_2;
		integer difference;

		@(posedge CP_MUX_IN);
		reads_1 = $time;

		@(posedge READ_S);
		reads_2 = $time;

		difference = reads_2 - reads_1; 

		$display("RO_T8 Start Time: %d", reads_1);
		$display("RO_T8 End Time: %d", reads_2);

		// checking
		if (difference == RO_T8*10) begin
			$display("RO_T8: Same simulation time as expected\n");
		end else begin
			$display("RO_T8: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T8*10, difference);
		end
	end

	initial begin: RO_T9_TIME

		integer pixres_1;
		integer pixres_2;
		integer difference;

		@(posedge COL_PRECH);
		pixres_1 = $time;

		@(posedge PIXRES);
		pixres_2 = $time;

		difference = pixres_2 - pixres_1; 

		$display("RO_T9 Start Time: %d", pixres_1);
		$display("RO_T9 End Time: %d", pixres_2);

		// checking
		if (difference == RO_T9*10) begin
			$display("RO_T9: Same simulation time as expected\n");
		end else begin
			$display("RO_T9: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T9*10, difference);
		end
	end

	initial begin: RO_T10_TIME

		integer pixres_3;
		integer pixres_4;
		integer difference;

		@(posedge PIXRES);
		pixres_3 = $time;

		@(negedge PIXRES);
		pixres_4 = $time;

		difference = pixres_4 - pixres_3; 

		$display("RO_T10 Start Time: %d", pixres_3);
		$display("RO_T10 End Time: %d", pixres_4);

		// checking
		if (difference == RO_T10*10) begin
			$display("RO_T10: Same simulation time as expected\n");
		end else begin
			$display("RO_T10: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T10*10, difference);
		end
	end

	initial begin: RO_T11_TIME

		integer pgares_1;
		integer pgares_2;
		integer difference;

		@(posedge PGA_RES);
		pgares_1 = $time;

		@(negedge PGA_RES);
		pgares_2 = $time;

		difference = pgares_2 - pgares_1; 

		$display("RO_T11 Start Time: %d", pgares_1);
		$display("RO_T11 End Time: %d", pgares_2);

		// checking
		if (difference == RO_T11*10) begin
			$display("RO_T11: Same simulation time as expected\n");
		end else begin
			$display("RO_T11: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T11*10, difference);
		end
	end

	initial begin: RO_T12_TIME

		integer ph1_1;
		integer ph1_2;
		integer difference;

		@(posedge PH1);
		ph1_1 = $time;

		@(posedge PH1);
		ph1_2 = $time;

		difference = ph1_2 - ph1_1; 

		$display("RO_T12 Start Time: %d", ph1_1);
		$display("RO_T12 End Time: %d", ph1_2);

		// checking
		if (difference == RO_T12*10) begin
			$display("RO_T12: Same simulation time as expected\n");
		end else begin
			$display("RO_T12: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T12*10, difference);
		end
	end

	initial begin: RO_T13_TIME

		integer samps_1;
		integer samps_2;
		integer difference;

		@(posedge PGA_RES);
		samps_1 = $time;

		@(posedge SAMP_S);
		samps_2 = $time;

		difference = samps_2 - samps_1; 

		$display("RO_T13 Start Time: %d", samps_1);
		$display("RO_T13 End Time: %d", samps_2);

		// checking
		if (difference == RO_T13*10) begin
			$display("RO_T13: Same simulation time as expected\n");
		end else begin
			$display("RO_T13: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T13*10, difference);
		end
	end

	initial begin: RO_T14_TIME

		integer sampr_1;
		integer sampr_2;
		integer difference;

		@(posedge SAMP_S);
		sampr_1 = $time;

		@(negedge SAMP_S);
		sampr_2 = $time;

		difference = sampr_2 - sampr_1; 

		$display("RO_T14 Start Time: %d", sampr_1);
		$display("RO_T14 End Time: %d", sampr_2);

		// checking
		if (difference == RO_T14*10) begin
			$display("RO_T14: Same simulation time as expected\n");
		end else begin
			$display("RO_T14: Wrong simulation time");
			$display("Expected: %d\nActual: %d\n", RO_T14*10, difference);
		end
	end
endmodule
