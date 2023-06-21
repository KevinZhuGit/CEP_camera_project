`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:41:36 09/20/2017 
// Design Name: 
// Module Name:    spi_master 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module spi_master_v1 (
	input wire rst,
  input wire clk,
  input wire wr_clk,
  input wire wr_en,
  input wire [31:0] wr_data,

  input wire MISO,
  output wire MOSI,
  output wire SPI_CLK,
  output wire [7:0] SPI_SS
    );

	parameter CLK_RATIO = 100; //ratio of clk to SPI_CLK
	parameter SS_SPACE = 20; //number of clock cycle times to hold ss low before starting and after enrd_datag spi_clk and data transmission
	parameter NUM = 1; 
	 
	 
	reg [NUM*16-1:0] shift_out;
	reg [15:0] counter;
	reg [15:0] NUM_cnt;
	reg [7: 0] SS_i;
	reg [7: 0] SS_tmp;
	reg [31:0] clk_div;
	reg running;
	reg SPI_CLK_i;
	reg CPOL;
	reg CPHA;
  wire [15:0] rd_data;
  reg rd_en;//trigger to start transmission
	wire valid; 


	initial running = 0;
	initial SS_i = 0;
	initial SPI_CLK_i = 0;

	reg [5:0] state=0;
	localparam S_init=0;
	localparam S_idle=1;
	localparam S_load=2;
	localparam S_run=3;
	localparam S_last=4;

	always @(posedge clk) begin
		if(rst) begin
			state <= S_init;
			clk_div <= 5000;//5000000;	// 60ms delay for TI adc
			shift_out <= 0;
			counter <= 0;
			SS_i <= 0;
			CPOL <= 0;
			CPHA <= 0;
			rd_en <= 0;
			NUM_cnt <= NUM+1;
		end else begin
			rd_en <= 0;
			case(state)

				S_init: begin		// initialization delay
					if (clk_div > 0) begin 
						clk_div <= clk_div - 1; 
					end else begin
						state <= S_idle;
					end
					SPI_CLK_i<=0;
				end

				S_idle: begin
					if (clk_div > 0) begin 
						clk_div <= clk_div - 1; 
					end else begin
						if(valid) begin
							rd_en <= 1;
							state <= S_load;
						end
					end
					SPI_CLK_i<=0;
					shift_out <=0; 
				end

				S_load: begin
					if(NUM_cnt == 0)  begin
						clk_div <= CLK_RATIO * SS_SPACE; // set clk_div
						state <= S_run;
						NUM_cnt <= NUM+1;
					end else if(valid) begin
						if(NUM_cnt==1) begin
							{CPHA, CPOL, SS_i} <= {rd_data[9], rd_data[8], rd_data[7:0]};
						end else begin
							rd_en <= 1;
							shift_out <={shift_out[NUM*16-16:0], rd_data[15:0]}; // latch next command
						//shift_out <= rd_data[15:0]; // latch next command
						end
						NUM_cnt <= NUM_cnt - 1;
					end
					SPI_CLK_i<=0;
				end

				S_run: begin
					if (clk_div > 0) begin // after trigger if clk_div > 0
						clk_div <= clk_div - 1; // wait clk_div 
						if(clk_div == CLK_RATIO+1) begin
							SPI_CLK_i <= CPOL ^ CPHA; // reset spi clk	
							counter <= (CPOL ^ CPHA) ? NUM*16-1 : NUM*16; 
						end
					end else begin
						clk_div <= CLK_RATIO; // spi clk = CLK_RATIO * clk
						SPI_CLK_i<= ~SPI_CLK_i; // toggle the clock
						if ((SPI_CLK_i != (CPOL ^ CPHA))) begin
							shift_out <= {1'b0, shift_out[NUM*16-1:1]}; // shift out data
							counter <= counter - 1;
						end
					end
					if (counter == 0 && clk_div == 0) begin
						state <= S_last;
						clk_div <= CLK_RATIO*5; // last delay
					end
				end

				S_last: begin
					if(clk_div>0) begin
						clk_div <= clk_div - 1; // wait clk_div 
					end else begin
						clk_div <= CLK_RATIO; // last delay

						if(SS_i!=0) begin
							SS_i <= 0;  // for load the data
							//SS_tmp <= SS_i;
						end else begin
							//SS_i <= SS_tmp;
							state <= S_idle;
						end

					end
				end

			endcase
		end
	end
	 
	assign SPI_CLK = (SPI_CLK_i & state == S_run);

	assign SPI_SS = ~SS_i;
	assign MOSI = shift_out[0];



fifo_w32_16_r16_32_ib i_cmd (
	.rst(rst),
	.wr_clk(wr_clk),
	.rd_clk(clk),
	.din(wr_data), 
	.wr_en(wr_en),
	.rd_en(rd_en),
	.dout(rd_data), 
	.full(),
	.empty(),
	.valid(valid)
);
endmodule

