`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2022 09:49:40 PM
// Design Name: 
// Module Name: Readout_Full_T7
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


module Readout_Full_T7(
	input wire rst,

	input  wire adc1_start_trigger,
	output wire adc1_busy,

	input  wire adc2_start_trigger,
	output wire adc2_busy,


  	input wire TX_CLK, 
	input wire TX_CLKx2, 

  	output wire [8:0] ROWADD,
  	output wire SET_ROW,   
	input  wire SET_ROW_DONE,
	
  	output wire PIXLEFTBUCK_SEL,
  	output wire ODDCOL_EN,
  	output wire PRECH_COL,
  	output wire ADC_RST,
  	output wire ADC_CLK,

  	output wire RST_BAR_LTCHD,
  	output wire LOAD_IN,
	output wire ADC_DATA_VALID,

	output wire PIXREAD_SEL,
  	output wire ADC_BIAS_EN,
	output wire COLL_EN,
	output wire PIXRES,
  
	input wire [31:0] ADC1_Tcolumn,
	input wire [31:0] ADC1_T1,
	input wire [31:0] ADC1_T2_1,
	input wire [31:0] ADC1_T2_0,
	input wire [31:0] ADC1_T3,
	input wire [31:0] ADC1_T4,
	input wire [31:0] ADC1_T5,
	input wire [31:0] ADC1_T6,
	input wire [31:0] ADC1_T7,
	input wire [31:0] ADC1_T8,
	input wire [31:0] ADC1_T9,
	input wire [31:0] ADC1_TADC,	
	input wire [31:0] ADC1_NUM_ROW,
	input wire [31:0] ADC1_Wait,

	input wire [31:0] ADC2_Tcolumn,
	input wire [31:0] ADC2_T1,
	input wire [31:0] ADC2_T2_1,
	input wire [31:0] ADC2_T2_0,
	input wire [31:0] ADC2_T3,
	input wire [31:0] ADC2_T4,
	input wire [31:0] ADC2_T5,
	input wire [31:0] ADC2_T6,
	input wire [31:0] ADC2_T7,
	input wire [31:0] ADC2_T8,
	input wire [31:0] ADC2_T9,
	input wire [31:0] ADC2_TADC,	
	input wire [31:0] ADC2_NUM_ROW,
	input wire [31:0] ADC2_Wait
    );

	wire [8:0] ADC1_ROWADD, ADC2_ROWADD;
    Readout_v1_T7 ADC1(
		.rst				(rst),
		.trigger_i			(adc1_start_trigger),
		.re_busy			(adc1_busy),
		.TX_CLK				(TX_CLK),
		.TX_CLKx2			(TX_CLKx2),
		
		.ROWADD				(ADC1_ROWADD),
		.SET_ROW			(ADC1_SET_ROW),
		.SET_ROW_DONE 		(SET_ROW_DONE),
		
		.PIXLEFTBUCK_SEL	(ADC1_PIX_LEFTBUCK_SEL),
		.ODDCOL_EN			(ADC1_ODDCOL_EN),
		.PRECH_COL			(ADC1_COL_PRECH_12),
		.ADC_RST			(ADC1_ADC_RST),
		.ADC_CLK			(ADC1_ADC_CLK_out),
		.RST_BAR_LTCHD		(ADC1_RST_BAR_LTCHD),
		.LOAD_IN			(ADC1_LOAD_IN),
		.ADC_DATA_VALID		(ADC1_ADC_DATA_VALID),
		.PIXREAD_SEL		(ADC1_PIXREAD_SEL),
		.ADC_BIAS_EN		(ADC1_ADC_BIAS_EN),
		.COLL_EN			(ADC1_COLL_EN),
		.PIXRES				(ADC1_PIXRES),
		
		.Tcolumn            (ADC1_Tcolumn),
		.T1                 (ADC1_T1),
		.T2_1               (ADC1_T2_1),
		.T2_0               (ADC1_T2_0),
		.T3                 (ADC1_T3),
		.T4                 (ADC1_T4),
		.T5                 (ADC1_T5),
		.T6                 (ADC1_T6),        
		.T7                 (ADC1_T7),
		.T8                 (ADC1_T8),
		.T9                 (ADC1_T9),
		.TADC	            (ADC1_TADC),
		.NUM_ROW            (ADC1_NUM_ROW),
		.T_RO_Wait          (ADC1_Wait)		
    );

    Readout_1bit_T7 ADC2(
		.rst				(rst),
		.trigger_i			(adc2_start_trigger),
		.re_busy			(adc2_busy),
		.TX_CLK				(TX_CLK),
		.TX_CLKx2			(TX_CLKx2),
		
        .ROWADD             (ADC2_ROWADD),
		.SET_ROW            (ADC2_SET_ROW),
		.SET_ROW_DONE       (SET_ROW_DONE),
		
		.PIXLEFTBUCK_SEL    (ADC2_PIX_LEFTBUCK_SEL),
		.ODDCOL_EN          (ADC2_ODDCOL_EN),
		.PRECH_COL          (ADC2_COL_PRECH_12),
		.ADC_RST            (ADC2_ADC_RST),
		.ADC_CLK            (ADC2_ADC_CLK_out),
		.RST_BAR_LTCHD      (ADC2_RST_BAR_LTCHD),
		.LOAD_IN            (ADC2_LOAD_IN),
		.ADC_DATA_VALID     (ADC2_ADC_DATA_VALID),
		.PIXREAD_SEL        (ADC2_PIXREAD_SEL),
		.ADC_BIAS_EN        (ADC2_ADC_BIAS_EN),
		.COLL_EN            (ADC2_COLL_EN),
		.PIXRES             (ADC2_PIXRES),
		
		.Tcolumn            (ADC2_Tcolumn),
		.T1                 (ADC2_T1),
		.T2_1               (ADC2_T2_1),
		.T2_0               (ADC2_T2_0),
		.T3                 (ADC2_T3),
		.T4                 (ADC2_T4),
		.T5                 (ADC2_T5),
		.T6                 (ADC2_T6),        
		.T7                 (ADC2_T7),
		.T8                 (ADC2_T8),
		.T9                 (ADC2_T9),
		.TADC               (ADC2_TADC),
		.NUM_ROW            (ADC2_NUM_ROW),
		.T_RO_Wait          (ADC2_Wait)     
    );
    
	assign ROWADD            = adc2_busy ? ADC2_ROWADD            : ADC1_ROWADD            ;
    assign SET_ROW           = adc2_busy ? ADC2_SET_ROW           : ADC1_SET_ROW           ;

    assign PIXLEFTBUCK_SEL   = adc2_busy ? ADC2_PIX_LEFTBUCK_SEL  : ADC1_PIX_LEFTBUCK_SEL  ;
    assign ODDCOL_EN         = adc2_busy ? ADC2_ODDCOL_EN         : ADC1_ODDCOL_EN         ;
    assign PRECH_COL         = adc2_busy ? ADC2_COL_PRECH_12      : ADC1_COL_PRECH_12      ;
    assign ADC_RST           = adc2_busy ? ADC2_ADC_RST           : ADC1_ADC_RST           ;
    assign ADC_CLK           = adc2_busy ? ADC2_ADC_CLK_out       : ADC1_ADC_CLK_out       ;
    assign RST_BAR_LTCHD     = adc2_busy ? ADC2_RST_BAR_LTCHD     : ADC1_RST_BAR_LTCHD     ;
    assign LOAD_IN           = adc2_busy ? ADC2_LOAD_IN           : ADC1_LOAD_IN           ;
    assign ADC_DATA_VALID    = adc2_busy ? ADC2_ADC_DATA_VALID    : ADC1_ADC_DATA_VALID    ;
    assign PIXREAD_SEL       = adc2_busy ? ADC2_PIXREAD_SEL       : ADC1_PIXREAD_SEL       ;
    assign ADC_BIAS_EN       = adc2_busy ? ADC2_ADC_BIAS_EN       : ADC1_ADC_BIAS_EN       ;
    assign COLL_EN           = adc2_busy ? ADC2_COLL_EN           : ADC1_COLL_EN           ;
    assign PIXRES            = adc2_busy ? ADC2_PIXRES            : ADC1_PIXRES            ;    

endmodule
