`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2019 06:13:44 PM
// Design Name: 
// Module Name: counter
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
counter #(.N(Number_of_bits)) dut(
    .clk(clk),
    .dout(dout[N-1:0]));
*/

module counter
    #(parameter N = 16)
    (
    input wire clk,
    output wire [N-1:0] dout
    );

reg [N-1:0] counter = 0;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign dout[N-1:0] = counter[N-1:0];
     
endmodule
