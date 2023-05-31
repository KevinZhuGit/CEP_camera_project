`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2022 07:36:45 PM
// Design Name: 
// Module Name: dist_mem_tb
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


module dist_mem_tb(

    );
	reg clk_100; initial clk_100 = 1'b0; always #5   clk_100 = ~clk_100; 
    reg clk_200; initial clk_200 = 1'b0; always #2.5 clk_200 = ~clk_200; 
    reg clk_7  ; initial clk_7   = 1'b0; always #35  clk_7   = ~clk_7; 
    reg clk_1  ; initial clk_1   = 1'b0; always #500  clk_1   = ~clk_1; 
    wire CLKMi, TX_CLKi, TX_CLKi2;
    assign CLKMi = clk_100;
    assign TX_CLKi  = clk_100;
    assign TX_CLKi2 = clk_200;
    reg rst;

    wire [8:0] ROWADD;
	
	reg  [31:0] ROWADD_RO_t7, mem_write_addr, mem_write_data;
	reg we, we2;
	wire [8:0] ROWADD_ADC2_MAPPED;
	
	row_map_table map_rows_adc2(
    	.clk(clk_100),
    	.rowadd_in(ROWADD_RO_t7[8:0]),
    	.rowadd_out(ROWADD_ADC2_MAPPED[8:0]),
    	
    	.mem_write_addr(mem_write_addr[8:0]), // address to write
    	.mem_write_data(mem_write_data[8:0]), // what to write
    	.we(we2)					  // when to write
    );
    
    wire [31:0] ROWADD_check = 0;
    assign ROWADD_check = {ROWADD_RO_t7[8:1],2'b0} - {0,ROWADD_ADC2_MAPPED[8:1],1'b0};  
    
    always @(posedge clk_1) begin
    	ROWADD_RO_t7 	<= we | ROWADD_RO_t7==240 ? 0 : ROWADD_RO_t7 + 1;
    end 

	reg [31:0] state=1;
	localparam s_idle 			= 32'b1<<0;
	localparam s_we   			= 32'b1<<1;
	localparam s_set_addr_data 	= 32'b1<<2;
	localparam s_set_we   		= 32'b1<<3; 

	always @(posedge clk_7) begin
		case(state)
			s_idle: begin
				state 			<= we ? s_set_addr_data : s_idle;
				we2   			<= 0;
				mem_write_data 	<= mem_write_data;
				mem_write_addr  <= mem_write_addr;  
			end
			
			s_set_addr_data: begin
				state 			<= s_set_we;
				mem_write_data 	<= mem_write_addr + 1;
				mem_write_addr  <= mem_write_addr==240 ? 0 : mem_write_addr+1;
				we2    	        <= 0;  
			end
			
			s_set_we: begin
				state           <= s_idle;
				mem_write_data 	<= mem_write_data;
				mem_write_addr  <= mem_write_addr;
				we2    	        <= 1;  		
			end
		endcase
	end
	
	initial begin
		ROWADD_RO_t7 = 0;
		we = 0;
		mem_write_data = 0;
		mem_write_addr = 0;
		#48000 we = 1;
		#48000 we = 0;
	end
endmodule
