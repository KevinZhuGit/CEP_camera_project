
`timescale 1ns/100ps
//`default_nettype none

module ddr3_test_v1
	(
	(* KEEP = "TRUE" *)input  wire          clk,
	(* KEEP = "TRUE" *)input  wire          reset,
	(* KEEP = "TRUE" *)input  wire          writes_en,
	(* KEEP = "TRUE" *)input  wire          reads_en,
	(* KEEP = "TRUE" *)input  wire          test_en,  // enable mask readback test
	(* KEEP = "TRUE" *)input  wire          calib_done,
	(* KEEP = "TRUE" *)output reg  [2:0]    img_cnt,
	// for mask size
	(* KEEP = "TRUE" *)input  wire [31:0]   NUM_PAT,
	(* KEEP = "TRUE" *)input  wire [31:0]   NUM_REP,
	//DDR Input Buffer (ib_)
	(* KEEP = "TRUE" *)output wire          ib0_re,
	(* KEEP = "TRUE" *)input  wire [255:0]  ib0_data,
	(* KEEP = "TRUE" *)input  wire [6:0]    ib0_count,
	(* KEEP = "TRUE" *)input  wire          ib0_valid,
	(* KEEP = "TRUE" *)input  wire          ib0_empty,
	//DDR Output Buffer (ob_)
	(* KEEP = "TRUE" *)output wire          ob0_we,
	(* KEEP = "TRUE" *)output wire [255:0]  ob0_data,
	(* KEEP = "TRUE" *)input  wire [6:0]    ob0_count,
	(* KEEP = "TRUE" *)input  wire          ob0_full,
	//DDR Input Buffer (ib_)
	(* KEEP = "TRUE" *)output wire          ib1_re,
	(* KEEP = "TRUE" *)input  wire [255:0]  ib1_data,
	(* KEEP = "TRUE" *)input  wire [6:0]    ib1_count,
	(* KEEP = "TRUE" *)input  wire          ib1_valid,
	(* KEEP = "TRUE" *)input  wire          ib1_empty,
	//DDR Output Buffer (ob_)
	(* KEEP = "TRUE" *)output wire          ob1_we,
	(* KEEP = "TRUE" *)output wire [255:0]  ob1_data,
	(* KEEP = "TRUE" *)input  wire [6:0]    ob1_count,
	(* KEEP = "TRUE" *)input  wire          ob1_full,

	(* KEEP = "TRUE" *)input  wire          app_rdy,
	(* KEEP = "TRUE" *)output reg           app_en,
	(* KEEP = "TRUE" *)output reg  [2:0]    app_cmd,
	(* KEEP = "TRUE" *)output reg  [29:0]   app_addr,

	(* KEEP = "TRUE" *)input  wire [255:0]  app_rd_data,
	(* KEEP = "TRUE" *)input  wire          app_rd_data_end,
	(* KEEP = "TRUE" *)input  wire          app_rd_data_valid,

	(* KEEP = "TRUE" *)input  wire          app_wdf_rdy,
	(* KEEP = "TRUE" *)output reg           app_wdf_wren,
	(* KEEP = "TRUE" *)output reg  [255:0]  app_wdf_data,
	(* KEEP = "TRUE" *)output reg           app_wdf_end,
	(* KEEP = "TRUE" *)output wire [31:0]   app_wdf_mask
	);

localparam IMG_ROW = 320;
localparam IMG_COL = 108;
localparam IMG_CH = 4;
localparam IMG_TAP = 2;
localparam IMG_BYTE = 2;
localparam IMG_SIZE = IMG_ROW*IMG_COL*IMG_CH*IMG_TAP*IMG_BYTE/4;

localparam MASK_CH = 16;
reg [31:0] MASK_SIZE;
always @(posedge clk) MASK_SIZE <= 320*MASK_CH*NUM_PAT*NUM_REP;


localparam FIFO_SIZE           = 128;
//localparam BURST_UI_WORD_COUNT = 2'd1; //(WORD_SIZE*BURST_MODE/UI_SIZE) = BURST_UI_WORD_COUNT : 32*8/256 = 1
//localparam ADDRESS_INCREMENT   = 5'd8; // UI Address is a word address. BL8 Burst Mode = 8.
localparam BURST_UI_WORD_COUNT = 5'd16; // burst times
localparam ADDRESS_UNIT   = 9'd8; // UI Address is a word address. BL8 Burst Mode = 8.
localparam ADDRESS_INCREMENT   = BURST_UI_WORD_COUNT*ADDRESS_UNIT;

(* KEEP = "TRUE" *)reg  [29:0] cmd_byte_addr_wr;
(* KEEP = "TRUE" *)reg  [29:0] cmd_byte_addr_rd;
(* KEEP = "TRUE" *)reg  [29:0] img_byte_addr_wr;
(* KEEP = "TRUE" *)reg  [29:0] img_byte_addr_rd;
(* KEEP = "TRUE" *)reg  [4:0]  burst_count;
(* KEEP = "TRUE" *)reg  [4:0]  write_count;
(* KEEP = "TRUE" *)reg  [4:0]  read_count;

(* KEEP = "TRUE" *)reg         write_mode;
(* KEEP = "TRUE" *)reg         read_mode;
(* KEEP = "TRUE" *)reg         run_mode;
(* KEEP = "TRUE" *)reg         reset_d;

reg           ib_re;
wire [255:0]  ib_data;
wire          ib_valid;
reg           ob_we;
reg  [255:0]  ob_data;
reg ch0_en;
reg ch1_en;
reg wdf_flag;
reg app_flag;

assign ib0_re    = (ch0_en)? ib_re     : 0;
assign ob0_we    = (ch0_en)? ob_we     : 0;
assign ob0_data  = (ch0_en)? ob_data   : 0;

assign ib1_re    = (ch1_en)? ib_re     : 0;
assign ob1_we    = (ch1_en)? ob_we     : 0;
assign ob1_data  = (ch1_en)? ob_data   : 0;

assign ib_data   = (ch0_en)? ib0_data  : (ch1_en)? ib1_data  : 0;
assign ib_valid  = (ch0_en)? ib0_valid : (ch1_en)? ib1_valid : 0;


assign app_wdf_mask = 16'h0000;

always @(posedge clk) write_mode <= writes_en;
always @(posedge clk) read_mode <= reads_en;
always @(posedge clk) run_mode <= test_en; // enable running mode
always @(posedge clk) reset_d <= reset;


(* KEEP = "TRUE" *)integer state;
localparam s_idle    = 0,
           s_write_0 = 10,
           s_write_1 = 11,
           s_write_2 = 12,
           s_read_0  = 20,
           s_read_1  = 21,
           s_read_2  = 22;

	// image start addr
	localparam img_start_addr = 512*1024*256;
	initial img_byte_addr_wr = img_start_addr;
	initial img_byte_addr_rd = img_start_addr;
	initial img_cnt 				 = 0;

always @(posedge clk) begin
	if (reset_d) begin
		state             <= s_idle;
		burst_count       <= 5'b0;
		cmd_byte_addr_wr  <= 0;
		cmd_byte_addr_rd  <= 0;
		app_en            <= 1'b0;
		app_cmd           <= 3'b0;
		app_addr          <= 28'b0;
		app_wdf_wren      <= 1'b0;
		app_wdf_end       <= 1'b0;
		ch0_en 			<= 0;
		ch1_en 			<= 0;
	end else begin
		app_en            <= 1'b0;
		app_wdf_wren      <= 1'b0;
		app_wdf_end       <= 1'b0;
		ib_re             <= 1'b0;
		ob_we             <= 1'b0;

		case (state)
			s_idle: begin
				//burst_count <= BURST_UI_WORD_COUNT-1;
				//write_count <= BURST_UI_WORD_COUNT-1;
				burst_count <= BURST_UI_WORD_COUNT-1;
				write_count <= BURST_UI_WORD_COUNT-1;
				read_count  <= 0;
				wdf_flag		<= 1;
				app_flag		<= 1;

				//if(img_byte_addr_wr==img_start_addr+IMG_SIZE*2-ADDRESS_INCREMENT) begin
				//	img_byte_addr_wr<=img_start_addr;
				//end
				//if(img_byte_addr_rd==img_start_addr+IMG_SIZE*2-ADDRESS_INCREMENT) begin
				//	img_byte_addr_rd<=img_start_addr;
				//end
				//if(cmd_byte_addr_rd==MASK_SIZE-ADDRESS_INCREMENT) begin
				//	cmd_byte_addr_rd<=0;
				//end

				if (calib_done==1 && write_mode==1 && (ib0_count >= BURST_UI_WORD_COUNT)) begin
					app_addr <= cmd_byte_addr_wr;
					cmd_byte_addr_wr <= cmd_byte_addr_wr + ADDRESS_INCREMENT;
					ch0_en <= 1;
					ch1_en <= 0;
					state <= s_write_0;

					// Check to ensure that the output buffer has enough space
					// for a burst
				end else if (calib_done==1 && read_mode==1) begin

					// write image data priority 1
					if(run_mode && ib1_count >= BURST_UI_WORD_COUNT) begin
						app_addr <= img_byte_addr_wr;
						ch0_en <= 0;
						ch1_en <= 1;
						state <= s_write_0;
						if(img_byte_addr_wr==img_start_addr+IMG_SIZE*2-ADDRESS_INCREMENT)
							img_byte_addr_wr<=img_start_addr;
						else
							img_byte_addr_wr <= img_byte_addr_wr + ADDRESS_INCREMENT;

					// read image data priority 2
					end else if(run_mode && img_byte_addr_wr!=img_byte_addr_rd && ob1_count<(FIFO_SIZE-2-BURST_UI_WORD_COUNT)) begin
						app_addr <= img_byte_addr_rd;
						ch0_en <= 0;
						ch1_en <= 1;
						state <= s_read_0;
						if(img_byte_addr_rd==img_start_addr+IMG_SIZE*2-ADDRESS_INCREMENT)
							img_byte_addr_rd<=img_start_addr;
						else
							img_byte_addr_rd <= img_byte_addr_rd + ADDRESS_INCREMENT;

					// read mask data priority 2
					end else if(ob0_count<(FIFO_SIZE-2-BURST_UI_WORD_COUNT)) begin
						app_addr <= cmd_byte_addr_rd;
						ch0_en <= 1;
						ch1_en <= 0;
						state <= s_read_0;
						if(cmd_byte_addr_rd==MASK_SIZE-ADDRESS_INCREMENT)
							cmd_byte_addr_rd<=0;
						else
							cmd_byte_addr_rd <= cmd_byte_addr_rd + ADDRESS_INCREMENT;

					end

				end
			end

			s_write_0: begin
				state <= s_write_1;
				ib_re <= 1'b1;
				if(ch1_en) begin
					if(img_byte_addr_wr==img_start_addr+ADDRESS_INCREMENT) begin
						img_cnt <= img_cnt + 1'b1;
					end else if(img_byte_addr_wr==img_start_addr+IMG_SIZE+ADDRESS_INCREMENT) begin
						img_cnt <= img_cnt + 1'b1;
					end
				end
			end

			s_write_1: begin
				ib_re <= 1'b1;
				if(ib_valid==1) begin
					app_wdf_data <= ib_data;
					app_wdf_wren <= 1'b1;
					app_wdf_end <= 1'b1;
					app_en    <= 1'b1;
					app_cmd <= 3'b000;
					state <= s_write_2;
				end
			end

			s_write_2: begin
				if (app_wdf_rdy == 1'b1) begin
					if (write_count == 3'd0) begin
						wdf_flag <= 0;
					end else begin
						app_wdf_data <= ib_data;
						app_wdf_wren <= 1'b1;
						app_wdf_end <= 1'b1;
						write_count <= write_count - 1;
					end
					if(write_count>2)
						ib_re <= 1'b1;
				end else if (wdf_flag) begin
					app_wdf_wren <= 1'b1;
					app_wdf_end <= 1'b1;
				end

				if (app_rdy == 1'b1) begin
					if(burst_count == 3'd0) begin
						app_flag <= 0;
						if (write_count == 3'd0)
							state <= s_idle;
					end else begin
						app_addr <= app_addr + ADDRESS_UNIT;
						burst_count <= burst_count - 1'b1;
						app_en    <= 1'b1;
						app_cmd <= 3'b000;
						//state <= s_write_0;
					end
				//end else (burst_count != 3'd0) begin
				end else if(app_flag) begin
					app_en    <= 1'b1;
					app_cmd <= 3'b000;
				end

			end


			s_read_0: begin
				app_en    <= 1'b1;
				app_cmd <= 3'b001;
				state <= s_read_1;
				if(ch1_en) begin
					if(img_byte_addr_rd==img_start_addr+IMG_SIZE-ADDRESS_INCREMENT) begin
						img_cnt <= img_cnt - 1'b1;
					end else if(img_byte_addr_rd==img_start_addr+IMG_SIZE*2-ADDRESS_INCREMENT) begin
						img_cnt <= img_cnt - 1'b1;
					end
				end
			end

			s_read_1: begin
				if (app_rdy == 1'b1) begin
      		if (burst_count == 3'd0) begin
      		  state <= s_read_2;
      		end else begin
      		  app_addr <= app_addr + ADDRESS_UNIT;
      		  burst_count <= burst_count - 1'b1;
      		  app_en  <= 1'b1;
      		  app_cmd <= 3'b001;
      		  if (app_rd_data_valid == 1'b0)
      		      read_count <= read_count + 1;
      		end
      	end else begin
      		app_en  <= 1'b1;
      		app_cmd <= 3'b001;
					if (app_rd_data_valid == 1'b1)
      			read_count <= read_count - 1;
      	end

				if (app_rd_data_valid == 1'b1) begin
      		ob_data <= app_rd_data;
      		ob_we <= 1'b1;
				end
			end

      s_read_2: begin
				if (app_rd_data_valid == 1'b1) begin
      		ob_data <= app_rd_data;
      		ob_we <= 1'b1;
      		if (read_count == 3'd0) begin
      		    state <= s_idle;
      		end else begin
      		    read_count <= read_count - 1'b1;
      		end
      	end
      end

		endcase
	end
end


endmodule
