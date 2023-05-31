`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2022 03:59:41 PM
// Design Name: 
// Module Name: Proj_Trig_Gen
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


module Proj_Trig_Gen(
    input clk, trig_in,
    input [31:0] Proj_trig_num, Proj_trig_spacing, Proj_trig_width,
    output reg Trig_out
    );
    reg [31:0] cnt_num, cnt_spacing, cnt_width;
    reg start;
    initial begin
         start <= 1'b0;
         Trig_out <= 1'b0;
    end
    always @(posedge clk)begin
        if(trig_in) begin
            cnt_num <= 32'b0;
            cnt_spacing <= 32'b0;
            cnt_width <= 32'b0;
            start <= 1'b1;
        end
        else if(start) begin
            if(cnt_num == Proj_trig_num) begin
                start <= 1'b0;
                Trig_out <= 1'b0;
            end
            else if(cnt_width < Proj_trig_width) begin
                Trig_out <= 1'b1;
                cnt_width <= cnt_width + 1;
            end
            else begin
                if(cnt_spacing < Proj_trig_spacing - 1) begin
                    cnt_spacing <= cnt_spacing + 1;
                    Trig_out <= 1'b0;
                end
                else begin
                    cnt_width <= 32'b0;
                    cnt_spacing <= 32'b0;
                    cnt_num <= cnt_num +1;
                end
            end
         end   
    end
    
    
      
  
    
    
endmodule
