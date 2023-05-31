`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: RaulGool 
// 
// Create Date: 08/06/2019 01:29:11 PM
// Design Name: 
// Module Name: mask_rectangle
// Project Name: REVEAL_T5
// Target Devices: REVEAL_T5
// Tool Versions: 
// Description:  This module gates the mask mstream for rows between [row_t+1:row_b-1]
//              Default mask value(mstream_default) and gated mask value(mstream_in) value can be chosen by the user 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mask_rectangle(
    input clk,
    input [8:0] row_t,
    input [8:0] row_b,    
    input [8:0] rowadd,
    input [15:0] mstream_default,
    input [15:0] mstream_in,
    output reg [15:0] mstream_out
    );
    
always @(posedge clk) begin
    if((rowadd > row_t)&&(rowadd < row_b)) begin
    end else begin
        if(rowadd <row_b) begin
            mstream_out <= mstream_in;  
        end else begin 
            mstream_out <= mstream_default;       
        end
    end    
end
    
endmodule
