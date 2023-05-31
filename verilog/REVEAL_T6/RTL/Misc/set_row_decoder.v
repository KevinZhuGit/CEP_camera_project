`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2022 09:49:43 AM
// Design Name: 
// Module Name: set_row_decoder
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


module set_row_decoder (
    input wire          clk,
    input wire          rst,

    input wire [9:0]    ROWADD_MU,
    input wire [9:0]    ROWADD_RO,
    input wire          SET_ROW_MU,
    input wire          SET_ROW_RO,

    output reg         DEC_SEL,
    output reg         DEC_EN,
    output reg         SET_ROW_DONE_MU,
    output reg         SET_ROW_DONE_RO,
    output reg [9:0]   ROWADD_op,


    input wire [31:0]   T_DEC_SEL_0,
    input wire [31:0]   T_DEC_SEL_1,
    input wire [31:0]   T_DEC_EN_0,
    input wire [31:0]   T_DEC_EN_1,
    input wire [31:0]   T_DONE_1
    );

/* Instnatiation template
    set_row_decoder exp_ro_row_decoder(
    	.clk(clk),
    	.rst(rst),

    	.ROWADD_MU(ROWADD_MU[9:0]),
    	.ROWADD_RO(ROWADD_RO[9:0]),
    	.SET_ROW_MU(SET_ROW_MU),
    	.SET_ROW_RO(SET_ROW_RO),
    
    	.SET_ROW_DONE_MU(SET_ROW_DONE_MU),
    	.SET_ROW_DONE_RO(SET_ROW_DONE_RO),
    	.DEC_SEL(DEC_SEL),     
    	.DEC_EN(DEC_EN),      
    	.ROWADD_op(ROWADD_op[9:0]),    
    
    	.T_DEC_SEL_0(T_DEC_SEL_0[31:0]),
    	.T_DEC_SEL_1(T_DEC_SEL_1[31:0]),
    	.T_DEC_EN_0(T_DEC_EN_0[31:0]), 
    	.T_DEC_EN_1(T_DEC_EN_1[31:0]), 
    	.T_DONE_1(T_DONE_1[31:0])    	
    );
    */
    
    reg [2:0] state;
    reg [31:0] timer;
    initial begin
        state = S_monitor;
        timer = 1;
    end
    localparam S_monitor = 0, S_mu = 1, S_ro = 2, S_wait_mu = 3, S_wait_ro = 4;
    always @ (posedge clk) begin
        if(rst) begin
            state <= S_monitor;
            timer <= 1;
        end
        else begin
            case (state)
                S_monitor: begin
                    timer <= 1;
//                    if(SET_ROW_MU) state <= S_mu;
//                    else if(SET_ROW_RO) state <= S_ro;
//                    else state <= S_monitor;
                    state <= SET_ROW_MU ? S_mu : (SET_ROW_RO ? S_ro : S_monitor); 
                end
                S_mu: begin
                    timer <= timer + 1;
                    state <= (timer < T_DEC_SEL_0) ? S_mu : S_wait_mu;
                end
                S_ro: begin
                    timer <= timer + 1;
                    state <= (timer < T_DEC_SEL_0) ? S_ro : S_wait_ro;
                end
                S_wait_mu: begin
                    timer <= 1;
                    state <= SET_ROW_MU ? S_wait_mu : S_monitor;
                end
                S_wait_ro: begin
                    timer <= 1;
                    state <= SET_ROW_RO ? S_wait_ro : S_monitor;
                end
             endcase
        end                    
     end
     
     always @ (posedge clk) begin
        if(rst) begin
            DEC_SEL <= 0;
            DEC_EN <= 0;
            ROWADD_op <= 0;
            SET_ROW_DONE_MU <= 0;
            SET_ROW_DONE_RO <= 0;
        end
        else begin
            case (state)
                S_monitor: begin
                    DEC_SEL 		<= SET_ROW_MU ? 0 : SET_ROW_RO;
                    DEC_EN 			<= 0;
                    ROWADD_op 		<= SET_ROW_MU ? ROWADD_MU : (SET_ROW_RO ? ROWADD_RO : 0);
                    SET_ROW_DONE_MU <= 0;
                    SET_ROW_DONE_RO <= 0;
                end
                S_mu: begin
                    DEC_SEL 		<= 0;
                    DEC_EN 			<= (T_DEC_EN_1  <= timer && timer < T_DEC_EN_0);
                    ROWADD_op 		<= (T_DEC_SEL_1 <= timer && timer < T_DEC_EN_0) ? ROWADD_op : 0;
                    SET_ROW_DONE_MU <= (T_DONE_1    <= timer);
                    SET_ROW_DONE_RO <= 0;
                end
                S_ro: begin
                    DEC_SEL 		<= 1;
                    DEC_EN  		<= (T_DEC_EN_1  <= timer && timer < T_DEC_EN_0);
                    ROWADD_op 		<= (T_DEC_SEL_1 <= timer && timer < T_DEC_EN_0) ? ROWADD_op : 0;
                    SET_ROW_DONE_MU <= 0;
                    SET_ROW_DONE_RO <= (T_DONE_1    <= timer);
                end
                S_wait_mu: begin
                    DEC_SEL 		<= 0;
                    DEC_EN 			<= 0;
                    ROWADD_op 		<= 0;
                    SET_ROW_DONE_MU <= SET_ROW_MU;
                    SET_ROW_DONE_RO <= 0;
                end
                S_wait_ro: begin
                    DEC_SEL 		<= 0;
                    DEC_EN 			<= 0;
                    ROWADD_op 		<= 0;
                    SET_ROW_DONE_MU <= 0;
                    SET_ROW_DONE_RO <= SET_ROW_RO;
                end      
             endcase
        end                    
     end
endmodule
