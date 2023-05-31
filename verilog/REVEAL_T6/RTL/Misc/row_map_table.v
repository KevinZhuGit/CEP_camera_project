`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/21/2022 02:08:55 AM
// Design Name: 
// Module Name: row_map_table
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


module row_map_table(
	input  wire clk,
	input  wire [8:0] rowadd_in,
	output wire [8:0] rowadd_out,
	
	input  wire [8:0] mem_write_addr,
	input  wire [8:0] mem_write_data,
	input  wire 	  we 	
    );

/* Instnatiation template
	row_map_table map_rows_adc2(
		.clk(TX_CLKi),
		.rowadd_in(rowadd_in[8:0]),
		.rowadd_out(rowadd_out[8:0]),
		
		.mem_write_addr(mem_write_addr[8:0]), // address to write
		.mem_write_data(mem_write_data[8:0]), // what to write
		.we(mem_write_en)					  // when to write
	);
											  // why to write????????
*/
	wire [8:0] addr;
	reg  [8:0] mem_write_data_i, mem_write_addr_i;
	reg [31:0] we_delay=0, timer = 0;
	reg [31:0] state = 1;
	reg wAddrSelect, we2;
	localparam s_idle 			= 32'b1<<0;
	localparam s_set_addr_data 	= 32'b1<<1;
	localparam s_set_we   		= 32'b1<<2; 

	always @(posedge clk) begin
		case(state)
			s_idle: begin
				state 			  <= we ? s_set_addr_data : s_idle;
				mem_write_data_i  <= mem_write_data;
				mem_write_addr_i  <= mem_write_addr;  
				wAddrSelect       <= 0;
				we2   			  <= 0;
			end
			
			s_set_addr_data: begin
				state 			  <= s_set_we;
				mem_write_data_i  <= mem_write_data_i;
				mem_write_addr_i  <= mem_write_addr_i;  
				wAddrSelect       <= 1;
				we2 			  <= 0;  
			end
			
			s_set_we: begin
				state             <= s_idle;
				mem_write_data_i  <= mem_write_data_i;
				mem_write_addr_i  <= mem_write_addr_i;  
				wAddrSelect       <= 1;
				we2    	           <= 1;  		
			end
			
			default:
				state 			 <= s_idle;
		endcase
	end 


	assign addr[8:0] = wAddrSelect ? mem_write_addr_i[8:0] : rowadd_in[8:0]; 
	dist_mem_w9_d512 your_instance_name (
      .a(addr[8:0]),      // input wire [8 : 0] a
      .d(mem_write_data_i[8:0]),      // input wire [8 : 0] d
      .clk(clk),  // input wire clk
      .we(we2),    // input wire we
//      .spo(rowadd_out[8:0])  // output wire [8 : 0] spo
      .qspo(rowadd_out[8:0])  // output wire [8 : 0] spo
    );    


endmodule
