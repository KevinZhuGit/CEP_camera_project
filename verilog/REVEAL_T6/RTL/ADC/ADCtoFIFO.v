`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/09/2022 03:05:07 PM
// Design Name: 
// Module Name: ADCtoFIFO
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


module ADCtoFIFO(
  	input	wire 			rst,
  	input   wire            rst_adc_parser,
	input	wire 		adc_clk0_i,   // for write  in charge channel 0 to 2
	input	wire 		adc_gr0_valid,
  	input	wire [16:0] ch_data_i,  // channel data in

	// read out port0
	input  wire					p0_rd_clk,
	input  wire					p0_rd_en,
	output wire 				p0_full,
	output wire 				p0_empty,
	output wire 				p0_valid,
	output wire [5:0]         	p0_rd_data_cnt,
	output wire [255:0] 	    p0_data_o

	//Test Outputs
	//output valid_wo,
	//output valid_w,
	//output valid_i
    );

	wire [20:0] valid_w;
	//wire [9:0] valid_wo;
	wire [256:0] data_w; // 9 chs data
	//wire [119:0] data_wo; // 9 chs data
	//reg valid_i_small;
	wire valid_i; //valid_i_big;
    //wire [20:0] rd_data_count;

	genvar i;
	generate
		for(i=0;i<17;i=i+1) begin: ch_0to2
			ADC_parser i0_adc_parser(
				.clk(adc_clk0_i),
				.rst(rst_adc_parser),
				.valid_i(adc_gr0_valid),
				.bit_i(ch_data_i[i]),
				.valid_o(valid_w[i]),
				.data_o(data_w[15*(i+1)-1:15*i])
			);
	   end
	endgenerate


	fifo_w256_128_r256_128_standard pipeIn_img_inst (
		.rst(rst),                         
		.wr_clk(adc_clk0_i),                
		.rd_clk(p0_rd_clk),                        
		.wr_en(valid_w[0]),                   
		.din  ({1'b0,data_w[254:0]}),     
		.rd_en(p0_rd_en),                    
		.dout (p0_data_o),               
		.full (p0_full),                  
		.almost_full(),     
		.empty(p0_empty),                 
		.valid(p0_valid),                 
		.rd_data_count(p0_rd_data_cnt),      
		.wr_data_count()       
	);

endmodule
