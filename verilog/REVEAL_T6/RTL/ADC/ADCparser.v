`timescale 1ns / 100ps

module ADC_parser(
	input wire clk,
	input wire rst,
	input wire valid_i,
	input wire bit_i,
	output reg valid_o,
	output wire [14:0] data_o  
);

	reg [31:0] data_reg; 
	reg [4:0] cnt;
	
	initial begin
	   cnt <= 0;
	   data_reg <= 0;
	end

	always @(posedge clk) begin
		if(rst) begin
			data_reg 	<= 0;
			cnt 		<= 0;
			valid_o 	<= 0;
		end else begin
			if(valid_i) begin
				data_reg[31:0] <= {data_reg[30:0],bit_i};  // shift 15 times get data
				if(cnt == 14) begin
					cnt 	<= 0;
					valid_o <= 1;
				end else begin
					cnt 	<= cnt+1;
					valid_o <= 0;
				end
			end else begin
				data_reg 	<= data_reg;
				cnt 		<= cnt;
				valid_o 	<= 0;
			end
		end
	end

	assign data_o[14:0] = data_reg[14:0];

endmodule
