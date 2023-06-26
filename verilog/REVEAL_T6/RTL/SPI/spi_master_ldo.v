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

module spi_master_ldo (
	input wire rst,
	input wire clk,
	input wire wr_clk,
	input wire wr_en,
	input wire [31:0] wr_data,

	input  wire	MISO,	// not enabled
	output wire MOSI,
	output reg  SPI_CLK,
	output reg  [7:0] SPI_SS
);


parameter CLK_RATIO = 20;		// ratio of input clk to SPI_CLK, used for SPI_CLK width
parameter Transfer_setup = 20;	// Transfer setup time (Tcss in manual)
parameter Transfer_end = 15; 	// Transfer end time, used to guarantee SS high width (Tcsw in manual) between transfers
parameter data_length = 11;		// how many bits of data need to be shifted out


reg  [data_length-1:0]	shift_out;	// shift register that stores data to send out
reg  [7:0]              SPI_SS_i;
reg  [7:0] 				clk_div;	// general clk divider for hold times and state durations
reg  [7:0]				SPI_div;	// counter for SPI_clk duration
wire [15:0] 			rd_data;
reg						SPI_CLK_i;
reg						rd_en;
wire					valid;


// State Assignment
reg [2:0] state;

localparam	
	S_idle			= 0,
	S_load_Data		= 1,
	S_load_SS		= 2,
	S_setup			= 3,
	S_trasnfer		= 4,
	S_end			= 5;



// FSM State Table
always @(posedge clk) begin
	if (rst) begin
		state <= S_idle;
	end else begin
		case (state)
			S_idle: begin
				state <= valid ? S_load_Data : S_idle;	//valid signal is tigger for FSM
			end

			S_load_Data: begin
				state <= S_load_SS;
			end

			S_load_SS: begin
				state <= S_setup;
			end

			S_setup: begin
				state <= (clk_div == 0) ? S_trasnfer : S_setup;
			end

			S_trasnfer: begin
				state <= (clk_div == 0) ? S_end : S_trasnfer;
			end

			S_end: begin
				state <= (clk_div == 0) ? S_idle : S_end;
			end
		endcase	
	end
end


// FSM Logic Table
always @(posedge clk) begin
	if (rst) begin
		shift_out	<= 0;
		SPI_SS_i	<= 0;
		SPI_CLK_i	<= 0;
		SPI_div		<= 0;
		clk_div		<= 0;
		rd_en		<= 0;	
	end else begin
		case (state)
			S_idle: begin				
				shift_out	<= 0;
				SPI_SS_i	<= 0;
				SPI_CLK_i	<= 0;
				SPI_div		<= 0;
				clk_div		<= 0;
				rd_en		<= valid ? 1 : 0;
			end

			S_load_Data: begin
				shift_out	<= rd_data[data_length-1:0];
				SPI_SS_i	<= 0;
				SPI_CLK_i	<= 0;
				SPI_div		<= 0;
				clk_div		<= 0;
				rd_en		<= 1;
			end

			S_load_SS: begin
				shift_out	<= shift_out;
				SPI_SS_i	<= rd_data[7:0];
				SPI_CLK_i	<= 0;
				SPI_div		<= 0;
				clk_div		<= Transfer_setup;
				rd_en		<= 0;
			end

			S_setup: begin
				shift_out	<= shift_out;
				SPI_SS_i	<= SPI_SS_i;
				SPI_CLK_i	<= (clk_div == 0) ? 1 : 0;
				SPI_div		<= (clk_div == 0) ? CLK_RATIO : 0;
				clk_div		<= (clk_div == 0) ? (data_length) : (clk_div - 1);
				rd_en		<= 0;
			end

			S_trasnfer: begin
				shift_out	<= (SPI_div == 0 && SPI_CLK) ? {shift_out[data_length-2:0], 1'b0} : shift_out;
				SPI_SS_i	<= SPI_SS_i;
				SPI_CLK_i	<= (SPI_div == 0) ? ~SPI_CLK_i : SPI_CLK_i;
				SPI_div		<= (SPI_div == 0) ? CLK_RATIO : SPI_div - 1;
				clk_div		<= (clk_div == 0) ? Transfer_end : ((SPI_div == 0 && SPI_CLK) ? clk_div - 1 : clk_div);
				rd_en		<= 0;
			end

			S_end: begin
				shift_out	<= 0;
				SPI_SS_i	<= 0;
				SPI_CLK_i	<= 0;
				SPI_div		<= 0;
				clk_div		<= clk_div - 1;
				rd_en		<= 0;
			end
		endcase	
	end
end


assign MOSI = shift_out[data_length-1];


// D-FF to remove glitches
always @(posedge clk) begin
	SPI_CLK <= SPI_CLK_i;
	SPI_SS 	<= ~SPI_SS_i;
end


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