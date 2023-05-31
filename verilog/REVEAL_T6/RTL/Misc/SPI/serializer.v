`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:47:29 12/06/2017 
// Design Name: 
// Module Name:    serializer_new 
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
//module serializer_new(CLK100MHZ,enable,DATA,Reset,SRI,CLK,LD_n,CurrentStateS,ser_counter,dec_counter,data_latched,data_buffer);
//input enable;
//input CLK100MHZ;
//input [11:0]DATA;
//input Reset;
//output reg SRI;
//output reg CLK;
//output reg LD_n;
//output [5:0] CurrentStateS;
//output reg dec_counter;
//assign CurrentStateS = CurrentState;
module serializer(CLK100MHZ,enable,DATA,Reset,SRI,CLK,LD_n);//,CurrentState);
input wire enable;
input wire CLK100MHZ;
input [15:0]DATA;
input wire Reset;
output reg SRI;
output reg CLK;
output reg LD_n;


initial LD_n = 1'b1; //this is an active low signal
initial SRI = 1'b0;
initial CLK = 1'b0;
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Wire Declaration
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
wire done150,done300;

reg [15:0] data_latched;
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Serializer Reg
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----

reg [5:0]ser_counter;
initial ser_counter = 6'd100;

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Reg Declaration
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
reg en150,en300,ser_cnt_reset,ser_cnt_sub,data_init,data_shift;
initial en150 = 0;
initial en300 = 0;
initial ser_cnt_reset=0;
initial ser_cnt_sub =0;
initial data_init = 0;
initial data_shift = 0;

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// State Encoding
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
localparam STATE_Idle = 6'd0 ,
STATE_1 = 6'd1 ,
STATE_2 = 6'd2 ,
STATE_3 = 6'd3 ,
STATE_4 = 6'd4 ,
STATE_5 = 6'd5 ,
STATE_6 = 6'd6 ,
STATE_7 = 6'd7 ,
STATE_8 = 6'd8 ,
STATE_9 = 6'd9 ,
STATE_Reset = 6'd10;
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// State reg Declarations
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
reg [5:0] CurrentState;
reg [5:0] NextState;
initial CurrentState = STATE_Idle;

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Outputs
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----


// multi -bit outputs
always@ ( posedge CLK100MHZ ) begin
	
	case ( CurrentState )
		STATE_Reset: begin
			ser_cnt_reset <= 1;
			ser_cnt_sub <= 0;
			SRI <= 0;
			LD_n <= 1;
			CLK <= 0;
			en150 <= 0;
			en300 <= 0;
			data_shift <= 0;
			data_init <= 0;
		end
		STATE_Idle: begin
			ser_cnt_reset <= 1;
			ser_cnt_sub <= 0;
			SRI <= 0;
			LD_n <= 1;
			CLK <= 0;
			en150 <= 0;
			en300 <= 0;
			data_shift <= 0;
			data_init <= 1;
		end
		STATE_1: begin
			SRI <= data_latched[15];
			ser_cnt_reset <= 0;
			ser_cnt_sub <= 0;
			LD_n <= 0;
			CLK <= 0;
			en150 <= 0;
			en300 <= 0;
			data_shift <= 0;
			data_init <= 0;
			
		end
		STATE_2: begin
			SRI <= data_latched[15];
			ser_cnt_reset <= 0;
			ser_cnt_sub <= 0;
			LD_n <= 0;
			CLK <= 0;
			en150 <= 1;
			en300 <= 0;
			data_shift <= 0;
			data_init <= 0;
			
		end
		STATE_3: begin
			SRI <=data_latched[15];
			ser_cnt_reset<= 0;
			ser_cnt_sub <=0;
			LD_n <=0;
			CLK <=1;
			en150<= 0;
			en300 <=0;
			data_shift<= 0;
			data_init <=0;
		end
		STATE_4: begin
			SRI <=data_latched[15];
			ser_cnt_reset<= 0;
			ser_cnt_sub <=0;
			LD_n <=0;
			CLK<= 1;
			en150<= 0;
			en300 <=1;
			data_shift <=0;
			data_init <=0;
		end
		STATE_5: begin
			SRI<= data_latched[15];
			ser_cnt_reset <=0;
			ser_cnt_sub<= 0;
			LD_n <=0;
			CLK <=0;
			en150 <=1;
			en300 <=0;
			data_shift <=0;
			data_init <=0;
		end
		STATE_6: begin
			SRI <=data_latched[15];
			ser_cnt_reset <=0;
			ser_cnt_sub <=1;
			LD_n <=0;
			CLK <=0;
			en150 <=0;
			en300 <=0;
			data_shift <=1;
			data_init <=0;
		end
		STATE_7: begin
			SRI <=0;
			ser_cnt_reset <=0;
			ser_cnt_sub <=0;
			LD_n <=0;
			CLK <=0;
			en150 <=1;
			en300 <=0;
			data_shift <=0;
			data_init <=0;
		end
		STATE_8: begin
			SRI <=0;
			ser_cnt_reset <=0;
			ser_cnt_sub <=0;
			LD_n <=0;
			CLK <=0;
			en150 <=0;
			//en150 <=1;
			en300 <=0;
			data_shift <=0;
			data_init <=0;
		end
		STATE_9: begin
			SRI <=0;
			ser_cnt_reset <=1;
			ser_cnt_sub<= 0;
			LD_n <=1;
			CLK <=0;
			en150 <=0;
			en300 <=0;
			data_shift<= 0;
			data_init <=0;
		end
		default: begin
			ser_cnt_reset <= 1;
			ser_cnt_sub <= 0;
			SRI <= 0;
			LD_n <= 1;
			CLK <= 0;
			en150 <= 0;
			en300 <= 0;
			data_shift <= 0;
			data_init <= 1;
		end
		




	endcase
end
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Synchronous State - Transition always@ ( posedge Clock ) block
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
always@ ( posedge CLK100MHZ ) begin
	if ( Reset ) CurrentState <= STATE_Reset ;
	else CurrentState <= NextState ;
end
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Conditional State - Transition always@ ( * ) block
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
always@ ( * ) begin
	NextState = CurrentState ;
	case ( CurrentState )
		STATE_Reset: begin
			if(Reset) NextState = STATE_Reset;
			else NextState = STATE_Idle;
		end
		STATE_Idle : begin
			if(enable) NextState = STATE_1;
			else NextState = STATE_Idle;
		end
		STATE_1 : begin
			if(ser_counter == 0) NextState = STATE_7;
			else NextState = STATE_2;
		end
		STATE_2 : begin
			if (done150) NextState = STATE_3 ;
			else NextState = STATE_2;
		end
		STATE_3 : begin
			NextState = STATE_4 ;
		end
		STATE_4 : begin
			if (done300) NextState = STATE_5 ;
			else NextState = STATE_4;
		end
		STATE_5 : begin
		    if (done150) NextState = STATE_6 ;
			else NextState = STATE_5 ;
		end
		STATE_6 : begin
		    NextState = STATE_1 ;
			//if (done150) NextState = STATE_1 ;
			//else NextState = STATE_6;
		end
		STATE_7 : begin
			if(done150) NextState = STATE_8 ;
			else NextState = STATE_7;
		end
		STATE_8 : begin
			//if (done150) NextState = STATE_9 ;
			//else NextState = STATE_8;
			NextState = STATE_9;
		end
		STATE_9 : begin
			NextState = STATE_Idle ;
		end
		default: begin
			NextState = STATE_Idle;
		end
	endcase
end
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
wait_counter cnt150(.enable(en150),.clk(CLK100MHZ),.trigger(done150));
wait_counter cnt300(.enable(en300),.clk(CLK100MHZ),.trigger(done300));
always@(posedge ser_cnt_reset or posedge ser_cnt_sub)begin
	if(ser_cnt_reset) ser_counter[5:0] <= 6'd16;
	else ser_counter[5:0] <= ser_counter[5:0] - 6'd1;
	//else if(ser_cnt_sub) ser_counter[5:0] <= ser_counter[5:0] - 6'd1;
	//else ser_counter[5:0] <= ser_counter[5:0];
end
//wire data_update;
//assign data_update = data_shift | data_init | Reset;
//always@(posedge data_update)begin
//	if(Reset) data_latched[11:0] <= 12'b0;
//	else if(data_init) data_latched[11:0] <= DATA[11:0];
//	else data_latched[11:0] <= data_latched[11:0] << 1;
//	//else if(data_shift) data_latched[11:0] <= data_latched[11:0] << 1;
////	else data_latched <= data_latched;
//
//end
always@(posedge CLK100MHZ)begin
	if (Reset) data_latched[15:0] <= 16'b0;
	else if (data_init) data_latched[15:0] <= DATA[15:0];
	else if (data_shift) data_latched[15:0] <= data_latched[15:0] << 1;
	else data_latched[15:0] <= data_latched[15:0];
end


endmodule
