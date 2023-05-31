`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2019 06:23:27 PM
// Design Name: 
// Module Name: serializer_ctrl
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

//****************INSTANTIATION TEMPLATE****************
/*
serializer_ctrl dut(
    .clk(clk),
    .trigger_in(trigger_in),
    .trigger_out(trigger_out),
    .reset_out(reset_out)
    );
*/
module serializer_ctrl(
    input wire clk,
    input wire trigger_in,
    output reg trigger_out,
    output reg reset_out
    );
    
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// State Encoding
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
localparam 
    STATE_Idle = 8'h01,
    STATE_1 = 8'h02 ,
    STATE_2 = 8'h04 ,
    STATE_3 = 8'h08 ,
    STATE_4 = 8'h10 ,
    STATE_5 = 8'h20 ,
    STATE_6 = 8'h40 ,
    STATE_7 = 8'h80;
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
always @(posedge clk) begin
    case(CurrentState)
        STATE_Idle: begin
            trigger_out <= 0;
            reset_out   <= 0;
        end
        STATE_1: begin
            trigger_out <= 0;
            reset_out   <= 1;
        end    
        STATE_2: begin
            trigger_out <= 0;
            reset_out   <= 0;        
        end    
        STATE_3: begin
            trigger_out <= 1;
            reset_out   <= 0;
        end    
        STATE_4: begin
            trigger_out <= 0;
            reset_out   <= 0;
        end
        default: begin
            trigger_out <= 0;
            reset_out   <= 0;            
        end    
    endcase
end    

// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Synchronous State - Transition always@ ( posedge Clock ) block
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
always@ ( posedge clk ) begin
	CurrentState <= NextState ;
end


// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
// Conditional State - Transition always@ ( * ) block
// --- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- ----- ---- ---- -----
always@ (*) begin
    case ( CurrentState )
        STATE_Idle:
            NextState = trigger_in ? STATE_1 : STATE_Idle;
        STATE_1:
            NextState = STATE_2;
        STATE_2:
            NextState = STATE_3;
        STATE_3:
            NextState = STATE_4;
        STATE_4:
            NextState = trigger_in ? STATE_4 : STATE_Idle;
        default:
            NextState = STATE_Idle;                    
    endcase
end

    
endmodule
