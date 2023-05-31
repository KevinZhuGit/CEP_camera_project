`timescale 1ns / 1ps

module readout_tb();
	reg rst;
	
	wire [7:0] ROWADD;

	reg ex_trigger;	//switch this to wire when testing with exposure module
	wire re_busy;

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

		Tlat	= 8,


		NumRow	= 20;

		Readout_v4 readout_inst (
			.rst		(rst),
			.CLK		(clk_100),
			.trigger	(ex_trigger),
			.re_busy	(re_busy),

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

			.adc_clk	(clk_010),
			.Tlat		(Tlat),
			.dat_valid	(dat_valid),

			.NUM_ROW	(NumRow)
		);

	//set initial values
	initial begin
		rst		= 1'b1;
		ex_trigger	= 1'b0;
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
/*
	always @(posedge clk_100) begin
		if (rst) begin
			ex_trigger <= 1'b0;
		end else if (STDBY) begin
			#100
			ex_trigger <= 1'b1;
			#10
			ex_trigger <= 1'b0;
		end else begin
			ex_trigger <= 1'b0;
		end
	end
	*/
endmodule
