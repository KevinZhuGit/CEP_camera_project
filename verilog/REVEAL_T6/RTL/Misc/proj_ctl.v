`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2020 04:57:24 PM
// Design Name: 
// Module Name: proj_ctl
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


//  Instantiation 
/*
proj_ctl DUT(
    .clk(clk),                      // input clk                     
    .trig_in(trig_in),              // proj_trg generated by exposure
    .trig_out(trig_out),            // Off time for projector        
    .trigNo(trigNo),                // On time for projector         
    .projOffTime(projOffTime),      // Number of triggers            
    .projOnTime(projOnTime)         // output trigger                
);
*/
module proj_ctl(
    input wire clk,                 // input clk
    input wire trig_in,             // proj_trg generated by exposure
    input wire [31:0] projOffTime,  // Off time for projector
    input wire [31:0] projOnTime,   // On time for projector
    input wire [31:0] trigNo,       // Number of triggers
    output reg trig_out             // output trigger
    );
    
    localparam s_idle   = 3'b000;
    localparam s_on     = 3'b001;
    localparam s_off    = 3'b010;
    
    integer cnt_trig    = 0;
    integer cnt_trigNo  = 0;
    integer state       = 0;
    
    reg trigReg;
    
    always @ (posedge clk) begin
        case(state)
            s_idle: begin
                trig_out <= 0;
                state <= trig_in ? s_on : s_idle;                                       // Start ON when input trigger is asserted
                cnt_trig <= 0;                                                          // reset the counter
                cnt_trigNo <= 0;                                                        // reset the projection trigger number
            end
            s_on: begin
                trig_out    <= 1;                                                       // assert the output trigger
                state       <= (cnt_trig == projOnTime-1) ? s_off         : s_on;         // change state after certain number of clk cycles
                cnt_trig    <= (cnt_trig == projOnTime-1) ? 0             : cnt_trig + 1; // count projector ON time
                cnt_trigNo  <= (cnt_trig == projOnTime-1) ? cnt_trigNo + 1: cnt_trigNo;   // counter number of projector triggers
            end
            s_off: begin
                trig_out    <= 0;                                                                                       // de-assert the output trigger
                state       <= (cnt_trig == projOffTime)? ((cnt_trigNo == trigNo) ? s_idle : s_on) : s_off;        // change state to on or idle
                cnt_trig    <= (cnt_trig == projOffTime) ? 0                                            : cnt_trig + 1; // count projector OFF time
            end
            default: begin
                trig_out    <= 0;
                state       <= s_idle;
                cnt_trig    <= 0;
                cnt_trigNo  <= 0;
            end
        endcase
    end
    
endmodule