`timescale 1ns / 100ps

module ADCtoFIFO_v0(
  input	wire 			rst,
	input	wire 			adc_clk0_i,   // for write  in charge channel 0 to 2
	input	wire 			adc_gr0_valid,
  input	wire [2:0] ch_data_i,  // channel data in

	// read out port0
	input  wire					p0_rd_clk,
	input  wire					p0_rd_en,
	output wire 				p0_full,
	output wire 				p0_empty,
	output wire 				p0_valid,
	output wire [6:0]          p0_rd_data_cnt,
	output wire [255:0] 	        p0_data_o

	//Test Outputs
	//output valid_wo,
	//output valid_w,
	//output valid_i
    );

	wire [2:0] valid_w;
	wire [2:0] valid_wo;
	wire [47:0] data_w; // 9 chs data
	wire [47:0] data_wo; // 9 chs data
	reg valid_i_small;
	wire valid_i, valid_i_big;
    wire [20:0] rd_data_count;

	genvar i;
	generate
		for(i=0;i<3;i=i+1) begin: ch_0to2
			ADC_parser i0_adc_parser(
				.clk(adc_clk0_i),
				.valid_i(adc_gr0_valid),
				.bit_i(ch_data_i[i]),
				.valid_o(valid_w[i]),
				.data_o(data_w[16*(i+1)-1:16*i])
			);
	   end
	endgenerate

	wire valid;
	wire almost_full;
	wire [63:0] data_s;

	fifo_w64_512_r256_128 pipeIn_img_inst (
		.rst(rst),                         
		.wr_clk(adc_clk0_i),                
		.rd_clk(p0_rd_clk),                        
		.wr_en(valid_w[0]),                   
		.din  ({data_w[31:0],16'h0000,data_w[47:32]}),     
		.rd_en(p0_rd_en),                    
		.dout (p0_data_o),               
		.full (p0_full),                  
		.almost_full(),     
		.empty(p0_empty),                 
		.valid(p0_valid),                 
		.rd_data_count(p0_rd_data_cnt),      
		.wr_data_count()       
	);

	//fifo_w64_4096_r64_4096_ib i_fifo_w64_r64_ib(
	//	.rst(rst),
	//	.wr_clk(adc_clk0_i),
	//	.wr_en(valid_w[0]),
	//	.din({data_w[31:0],16'h0000,data_w[47:32]}),
	//	.rd_clk(p0_rd_clk),
	//	.rd_en(valid&(~almost_full)),
	//	.dout(data_s),
	//	.empty(),
	//	.full(),
	//	.prog_full(p0_prg_full),
	//	.valid(valid)
	//);

	//fifo_w64_65536_r32_131072_cb i_fifo_w64_r32_cb(
	//	.rst(rst),
	//	.clk(p0_rd_clk),
	//	.wr_en(valid&(~almost_full)),
	//	.din(data_s),
	//	.rd_en(p0_rd_en),
	//	.dout(p0_data_o),
	//	.rd_data_count(p0_rd_data_cnt),
	//	.empty(p0_empty),
	//	.full(p0_full),
	//	.almost_full(almost_full)
	//);


endmodule

