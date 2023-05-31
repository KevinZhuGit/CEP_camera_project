`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 03:19:19 PM
// Design Name: 
// Module Name: adc1bit_to_fifo
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


module adc1bit_to_fifo(
  	input	wire 		rst,
	input   wire        rst_adc_parser,
	input	wire 		adc_clk0_i,   // for write  in charge channel 0 to 2
	input	wire 		adc_gr0_valid,
	input	wire [16:0] ch_data_i,  // channel data in

	// read out port0
	input  wire				p0_rd_clk,
	input  wire				p0_rd_en,
	output wire 			p0_full,
	output wire 			p0_empty,
	output wire 			p0_valid,
	output wire [5:0]       p0_rd_data_cnt,
	output wire [255:0] 	p0_data_o

	//Test Outputs
	//output valid_wo,
	//output valid_w,
	//output valid_i
    );
    
    
endmodule
