`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:08:22 06/06/2017 
// Design Name: 
// Module Name:    load_pattern 
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

module load_pattern_v0(
	input wire rst,
	input wire clk,
	
	input wire [255:0] pat_in,

	output reg pat_fifo_rd_en,
	
	input wire [31:0] Num_Pat,			// Number of patterns applied to the imager.
	// input FSMIND0,					// If high, the Exposure FSM (on OK) is active
	input wire FIFO_empty,
	input wire FIFO_full,
	input wire camfifo_empty,
	input wire camfifo_valid,
	
	output reg FIFO_wr,
	output wire [255:0] Pat_out
	);
	
  reg [31:0] num_streams;
  initial begin
      //num_streams = 32'd5120;
      num_streams = 32'd640;
  end

// -- Parameters
	integer state;
	localparam 	S_init 					= 1;
	localparam	S_RESET_ALL0 		= 2;	
	localparam	S_subc_pats 		= 3;	
	localparam	S_subc_last 		= 4;
	localparam	S_RESET_ALL1 		= 5;
	localparam	S_idle 					= 6;
	
	
//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------

	reg	[255:0] Pat_i;
	integer cntPat;
	integer cntMask;

//	initial	begin
//    state <= S_init;
//		FIFO_wr <= 0;
//		pat_fifo_rd_en <= 0;
//		cntPat <= 0;
//		cntMask <= 0;
//		Pat_i <= 0;
//	end


   always@(negedge clk)
      if (rst) begin
      	state <= S_init;
				FIFO_wr <= 0;
				cntPat <= 0;
				cntMask <= 0;
				pat_fifo_rd_en <= 0;
				Pat_i <= 0;
      end else begin
				FIFO_wr <= 0;
				pat_fifo_rd_en <= 0;

         case (state)
            
				S_init : begin
					cntPat <= 0;
					if (~FIFO_full)
						state <= S_RESET_ALL1;
            end
				
				//not needed for TOF
				S_RESET_ALL1: begin
					
					//if(cntPat < num_streams && ~(FIFO_full)) begin
					if(cntPat < 100) begin // add some delay
						//FIFO_wr <= 1;
						FIFO_wr <= 0;
						Pat_i <= 32'hffffffff;
						cntPat <= cntPat + 1;
					end else begin
						FIFO_wr <= 0;
						cntPat <= 0;
						cntMask <= 0;
						state <= S_subc_pats;
					end
				end
				
        //S_subc_pats : begin
				//	
				//	if(FIFO_full|camfifo_empty) begin
				//		FIFO_wr <= 0;
				//		pat_fifo_rd_en <= 0;
				//	end else if (cntPat < num_streams) begin
				//		cntPat <= cntPat + 1;
				//		FIFO_wr <= 1;
				//		pat_fifo_rd_en <= 1;
				//		Pat_i <= pat_in;
				//	end else begin
				//		cntPat <= 0;
				//		FIFO_wr <= 0;
				//		pat_fifo_rd_en <= 0;
				//		cntMask <= cntMask+1;
				//		if (cntMask >= Num_Pat - 1) begin
				//			cntMask <= 0;
				//			state <= S_subc_last;
				//		end
				//	end
      	//end
				
        S_subc_pats : begin
					
					if (cntPat < num_streams && camfifo_valid && (~FIFO_full)) begin
						cntPat <= cntPat + 1;
						FIFO_wr <= 1;
						pat_fifo_rd_en <= 1;
						Pat_i <= pat_in;
					end else begin
						cntPat <= 0;
						cntMask <= cntMask+1;
						if (cntMask >= Num_Pat - 1) begin
							cntMask <= 0;
							state <= S_subc_last;
						end
					end
      	end
				
				//applying all 0 mask
        S_subc_last : begin
					if(FIFO_full) begin
						FIFO_wr <= 0;
					//end else if (cntPat < num_streams && camfifo_valid && (~FIFO_full)) begin
					end else if (cntPat < 1) begin
						cntPat <= cntPat + 1;
						//FIFO_wr <= 1;
						FIFO_wr <= 0;
						Pat_i <= 32'd0;
					end else begin
						cntPat <= 0;
						FIFO_wr <= 0;
						state <= S_init;
					end
       end
				
       default : begin  // Fault Recovery
					state <= S_init;
       end   
      endcase
		end
	
	assign Pat_out = Pat_i;
	
endmodule

