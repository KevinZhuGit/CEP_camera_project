`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/27/2018 01:03:07 PM
// Design Name:
// Module Name: patternToSensors
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


module patternToSensors_T7(

		input wire clk, 	//clk for reading mstream
		input wire stream_clk,  //clk for writing pattern
		input wire reset,


	    //flags for the fifo which outputs MSTREAM data to sensor,

		//ODDR inputs
		//input wire reset_oddr,  ----- don't think we need these signals
		//input wire set_oddr,

		input wire [31:0]Num_Pat,
		output wire [19:0]MSTREAMOUT,
		input wire stream_en_i,
		output reg stream_en_o,

		//flags for the fifo containing input MSTREAM32 data
		input wire [255:0] MSTREAM32,
		input wire empty,
		input wire valid,
		output wire rd_en


    );


	//flags for the fifo which outputs MSTREAM data to sensor
	wire wr_en_f1;
	wire full_f1;
    wire almost_full_f1;
    wire empty_f1;

	//input and output data for the fifo which outputs MSTREAM data to sensor
	wire [255:0]DI_f1;
	wire [31:0]DO_f1;

	//controls enable signals for fifos as well as the
	//pattern mstream pattern bits that goes to fifos
	load_pattern_v0 controlLoading(
		.clk(clk),
		.rst(reset),

		.pat_in(MSTREAM32),
		.pat_fifo_rd_en(rd_en),

		.camfifo_empty(empty),
		.camfifo_valid(valid),
		.FIFO_empty(empty_f1),
		.FIFO_full(almost_full_f1),

		.FIFO_wr(wr_en_f1),
		.Pat_out(DI_f1),

		.Num_Pat(Num_Pat)

	);

	//fifo_w32_4096_r32_4096_ib fifo_pattern_to_sensors(
	//fifo_w32_8192_r32_8192_ib fifo_pattern_to_sensors(
	//fifo_w32_65536_r32_65536_ib fifo_pattern_to_sensors(
	//fifo_w32_131072_r32_131072_ib fifo_pattern_to_sensors(

	wire [11:0] rd_test_cnt;
	wire [8:0] wr_test_cnt;
	fifo_w256_512_r32_4096_ib fifo_pattern_to_sensors(
				.rst(reset),
				.wr_clk(clk),
				.rd_clk(stream_clk),
				.din(DI_f1),
				.wr_en(wr_en_f1),
				.rd_en(stream_en_i),
				.dout(DO_f1),
				.full(full_f1),
        .almost_full(almost_full_f1),
				.empty(empty_f1),
				.valid(),
				.rd_data_count(rd_test_cnt),
				.wr_data_count(wr_test_cnt)

			);

	// 1 clk delay to sensor
	always @(posedge stream_clk) begin
		stream_en_o <= stream_en_i;
	end


	// For 20 MSTREAM channels, the 16 data values [k] are passed as such:
	// 0 0 0 1 2 3 ... 12 13 14 15 15 15
	// That is, a pad/dupe of 2 channels at each end
	genvar i; // 3 channels at the start
	genvar j; // 3 channels at the end
	genvar k; // 14 channels in the middle

	generate for ( i = 0; i < 2; i = i+1 ) begin
		// ODDR: Output Double Data Rate Output Register with Set, Reset
		// and Clock Enable.
		// 7 Series
		// Xilinx HDL Libraries Guide, version 14.3
		ODDR #(
		//.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		.DDR_CLK_EDGE("SAME_EDGE"),
		.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
		.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) MSTREAM_OUTPUTS (
			.Q(MSTREAMOUT[i]), // 1-bit DDR output
			.C(stream_clk), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
			.D1(DO_f1[0]), // 1-bit data input (positive edge)
			.D2(DO_f1[16]), // 1-bit data input (negative edge)
			.R(0/*reset_oddr*/), // 1-bit reset
			.S(0/*set_oddr*/) // 1-bit set
		);
	end
	endgenerate

	generate for ( j = 18; j < 20; j = j+1 ) begin
		// ODDR: Output Double Data Rate Output Register with Set, Reset
		// and Clock Enable.
		// 7 Series
		// Xilinx HDL Libraries Guide, version 14.3
		ODDR #(
		//.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		.DDR_CLK_EDGE("SAME_EDGE"),
		.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
		.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) MSTREAM_OUTPUTS (
			.Q(MSTREAMOUT[j]), // 1-bit DDR output
			.C(stream_clk), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
			.D1(DO_f1[15]), // 1-bit data input (positive edge)
			.D2(DO_f1[31]), // 1-bit data input (negative edge)
			.R(0/*reset_oddr*/), // 1-bit reset
			.S(0/*set_oddr*/) // 1-bit set
		);
	end
	endgenerate

	generate for ( k = 0; k < 16; k = k+1 ) begin
		// ODDR: Output Double Data Rate Output Register with Set, Reset
		// and Clock Enable.
		// 7 Series
		// Xilinx HDL Libraries Guide, version 14.3
		ODDR #(
		//.DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
		.DDR_CLK_EDGE("SAME_EDGE"),
		.INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
		.SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
		) MSTREAM_OUTPUTS (
			.Q(MSTREAMOUT[k+2]), // 1-bit DDR output
			.C(stream_clk), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
			.D1(DO_f1[k]), // 1-bit data input (positive edge)
			.D2(DO_f1[k+16]), // 1-bit data input (negative edge)
			.R(0/*reset_oddr*/), // 1-bit reset
			.S(0/*set_oddr*/) // 1-bit set
		);
	end
	endgenerate

endmodule
