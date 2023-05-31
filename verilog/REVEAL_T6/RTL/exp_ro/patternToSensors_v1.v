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


module patternToSensors_v1(

		input wire clk, 	//clk for reading mstream
		input wire stream_clk,  //clk for writing pattern
		input wire reset,


	    //flags for the fifo which outputs MSTREAM data to sensor,

		//ODDR inputs
		//input wire reset_oddr,  ----- don't think we need these signals
		//input wire set_oddr,

		input wire [31:0]Num_Pat,
		output wire [15:0]MSTREAMOUT,
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
    wire almost_full_f1;
    wire almost_full_f2;
    wire empty_f1;

	//input and output data for the fifo which outputs MSTREAM data to sensor
	wire [255:0]DI_f1;
	wire [31:0]DO_f1;
	wire [31:0]DO_f2;

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

	wire [31:0] data_w;
	wire [11:0] rd_test_cnt;
	wire [8:0] wr_test_cnt;
	wire valid_w;

	assign MSTREAMOUT = data_w[15:0];

	fifo_w256_512_r32_4096_ib pattern_to_sensors_buf(
				.rst(reset),
				.wr_clk(clk),
				.rd_clk(stream_clk),
				.din(DI_f1),
				.wr_en(wr_en_f1),
//				.rd_en(valid_w&~almost_full_f2),
				.rd_en(stream_en_i),
//				.dout(DO_f1),
				.dout(data_w),
				.full(),
        .almost_full(almost_full_f1),
				.empty(empty_f1),
//				.valid(valid_w),
				.valid(),
				.rd_data_count(rd_test_cnt),
				.wr_data_count(wr_test_cnt)

			);

//	fifo_w32_32_r16_64_ib fifo_pattern_to_sensors(
//				.rst(reset),
//				.wr_clk(clk),
//				.rd_clk(stream_clk),
//				.din(DO_f1),
//				.wr_en(valid_w&~almost_full_f2),
//				.rd_en(stream_en_i),
//				.dout(MSTREAMOUT),
//				.full(),
//        .almost_full(almost_full_f2),
//				.empty(),
//				.valid()
//			);
//
	// 1 clk delay to sensor
	always @(posedge stream_clk) begin
		stream_en_o <= stream_en_i;
	end


endmodule
