module led_ctl (
	input wire rst,
	input wire clk,
	input wire [31:0] LedNum,
	input wire [31:0] LedDly,
	input wire [31:0] LedExp,
	input wire [31:0] LedSeq,
	input wire PROJ_TRG,
	output reg [7:0] trig
);

	
	integer led_state;
	integer delay_cnt;
	integer exp_cnt;

	localparam LS_0=0;
  localparam LS_1=1;
  localparam LS_2=2;
  localparam LS_3=3;
  localparam LS_4=4;
  localparam LS_5=5;
  localparam LS_6=6;
  localparam LS_7=7;
  localparam LS_8=8;
  localparam LS_9=9;
  localparam LS_10=10;

	reg [7:0] trig_ps;
	reg [7:0] trig_i;

	always @(posedge clk) begin
		if(rst) begin
			trig_i <= 0;
			trig_ps <= 0;
			delay_cnt <= 0;
			exp_cnt <= 0;
			led_state <= 0;
		end else begin
			case(led_state)
				LS_0: begin
					// wait for proj_trg signal
					trig_i <= 0;
					if(trig_i) trig_ps <= trig_i;
					if(PROJ_TRG) begin
						led_state <= 1;
						delay_cnt <= LedDly;
						exp_cnt <= LedExp;
					end
				end
				LS_1: begin
					// delay trigger
					if(delay_cnt==0) begin
						if(trig_ps==(8'h01<<(LedNum-1))) begin
							led_state <= 2;
						end else begin
							case(trig_ps)
								8'h00: led_state <= 2;
								8'h01: led_state <= 3;
								8'h02: led_state <= 4;
								8'h04: led_state <= 5;
								8'h08: led_state <= 6;
								8'h10: led_state <= 7;
								8'h20: led_state <= 8;
								8'h40: led_state <= 9;
								8'h80: led_state <= 2;
								default: led_state <= 0;
							endcase
						end
					end else begin
						delay_cnt <= delay_cnt - 1;
					end
				end
				LS_2: begin
					trig_i <= 8'h01;
					led_state <= 10;
				end
				LS_3: begin
					trig_i <= 8'h02;
					led_state <= 10;
				end
				LS_4: begin
					trig_i <= 8'h04;
					led_state <= 10;
				end
				LS_5: begin
					trig_i <= 8'h08;
					led_state <= 10;
				end
				LS_6: begin
					trig_i <= 8'h10;
					led_state <= 10;
				end
				LS_7: begin
					trig_i <= 8'h20;
					led_state <= 10;
				end
				LS_8: begin
					trig_i <= 8'h40;
					led_state <= 10;
				end
				LS_9: begin
					trig_i <= 8'h80;
					led_state <= 10;
				end
				LS_10: begin
					if(exp_cnt==0) begin
						if(~PROJ_TRG) led_state <= 0;
					end else begin
						exp_cnt <= exp_cnt - 1;
					end
				end
				default: begin
					trig_i <= 0;
					led_state <= 0;
				end
			endcase
		end
	end

	//assign trig=~trig_i;

	always @(*) begin
		case(LedSeq[3:0])
			1: trig[0] = ~trig_i[0];
			2: trig[0] = ~trig_i[1];
			3: trig[0] = ~trig_i[2];
			4: trig[0] = ~trig_i[3];
			5: trig[0] = ~trig_i[4];
			6: trig[0] = ~trig_i[5];
			7: trig[0] = ~trig_i[6];
			8: trig[0] = ~trig_i[7];
			default: trig[0] = ~trig_i[0];
		endcase
		case(LedSeq[7:4])
			1: trig[1] = ~trig_i[0];
			2: trig[1] = ~trig_i[1];
			3: trig[1] = ~trig_i[2];
			4: trig[1] = ~trig_i[3];
			5: trig[1] = ~trig_i[4];
			6: trig[1] = ~trig_i[5];
			7: trig[1] = ~trig_i[6];
			8: trig[1] = ~trig_i[7];
			default: trig[1] = ~trig_i[0];
		endcase
		case(LedSeq[11:8])
			1: trig[2] = ~trig_i[0];
			2: trig[2] = ~trig_i[1];
			3: trig[2] = ~trig_i[2];
			4: trig[2] = ~trig_i[3];
			5: trig[2] = ~trig_i[4];
			6: trig[2] = ~trig_i[5];
			7: trig[2] = ~trig_i[6];
			8: trig[2] = ~trig_i[7];
			default: trig[2] = ~trig_i[0];
		endcase
		case(LedSeq[15:12])
			1: trig[3] = ~trig_i[0];
			2: trig[3] = ~trig_i[1];
			3: trig[3] = ~trig_i[2];
			4: trig[3] = ~trig_i[3];
			5: trig[3] = ~trig_i[4];
			6: trig[3] = ~trig_i[5];
			7: trig[3] = ~trig_i[6];
			8: trig[3] = ~trig_i[7];
			default: trig[3] = ~trig_i[0];
		endcase
		case(LedSeq[19:16])
			1: trig[4] = ~trig_i[0];
			2: trig[4] = ~trig_i[1];
			3: trig[4] = ~trig_i[2];
			4: trig[4] = ~trig_i[3];
			5: trig[4] = ~trig_i[4];
			6: trig[4] = ~trig_i[5];
			7: trig[4] = ~trig_i[6];
			8: trig[4] = ~trig_i[7];
			default: trig[4] = ~trig_i[0];
		endcase
		case(LedSeq[23:20])
			1: trig[5] = ~trig_i[0];
			2: trig[5] = ~trig_i[1];
			3: trig[5] = ~trig_i[2];
			4: trig[5] = ~trig_i[3];
			5: trig[5] = ~trig_i[4];
			6: trig[5] = ~trig_i[5];
			7: trig[5] = ~trig_i[6];
			8: trig[5] = ~trig_i[7];
			default: trig[5] = ~trig_i[0];
		endcase
		case(LedSeq[27:24])
			1: trig[6] = ~trig_i[0];
			2: trig[6] = ~trig_i[1];
			3: trig[6] = ~trig_i[2];
			4: trig[6] = ~trig_i[3];
			5: trig[6] = ~trig_i[4];
			6: trig[6] = ~trig_i[5];
			7: trig[6] = ~trig_i[6];
			8: trig[6] = ~trig_i[7];
			default: trig[6] = ~trig_i[0];
		endcase
		case(LedSeq[31:28])
			1: trig[7] = ~trig_i[0];
			2: trig[7] = ~trig_i[1];
			3: trig[7] = ~trig_i[2];
			4: trig[7] = ~trig_i[3];
			5: trig[7] = ~trig_i[4];
			6: trig[7] = ~trig_i[5];
			7: trig[7] = ~trig_i[6];
			8: trig[7] = ~trig_i[7];
			default: trig[7] = ~trig_i[0];
		endcase
	end


endmodule
