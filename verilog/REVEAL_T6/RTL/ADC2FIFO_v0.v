`timescale 1ns / 1ps

module ADC2FIFO_v0(
    input wire      rst,

    input wire 		adc1_dat_valid,
    input wire 		adc2_dat_valid,
		
    input wire      [7:0] ADC1_DATA_RAW,
    input wire      ADC1_DATA_CLK,
    input wire      [7:0] ADC2_DATA_RAW,
    input wire      ADC2_DATA_CLK,

    output wire     FIFO_IN_TRIG,

    input wire 		rd_clk,
    input wire 		rd_en,
    output wire     [255:0] rd_data,
    output wire     full,
    output wire     empty,
    output wire     valid,
    output wire     [6:0] rd_data_count
);

    wire [15:0] ADC1_DATA;
    wire [15:0] ADC2_DATA;

    T2_ADC_RO T2_ADC_Inst1(
        .DATA_IN_FROM_PINS1(ADC1_DATA_RAW),
        .DATA_IN_TO_DEVICE1(ADC1_DATA),
        .CLK_IN(ADC1_DATA_CLK),
        .CLK_EN(1)
    );

    T2_ADC_RO T2_ADC_Inst2(
        .DATA_IN_FROM_PINS1(ADC2_DATA_RAW),
        .DATA_IN_TO_DEVICE1(ADC2_DATA),
        .CLK_IN(ADC2_DATA_CLK),
        .CLK_EN(1)
    );


    wire valid1;
    wire valid2;
	wire [15:0] adc1_dat;
	wire [15:0] adc2_dat;
    assign FIFO_IN_TRIG = valid1 & valid2;

    // ADC1 Buffer fifo
    fifo_w16_64_r16_64 adc_fifo1(
        .rst(rst),
        .wr_clk(ADC1_DATA_CLK),
        .wr_en(adc1_dat_valid),
        .din(ADC1_DATA),

        .rd_clk(rd_clk),
        .rd_en(FIFO_IN_TRIG),
        .dout(adc1_dat),

        .empty(),
        .full(),
        .valid(valid1)
    );

    // ADC2 Buffer fifo
    fifo_w16_64_r16_64 adc_fifo2(
        .rst(rst),
        .wr_clk(ADC2_DATA_CLK),
        .wr_en(adc2_dat_valid),
        .din(ADC2_DATA),

        .rd_clk(rd_clk),
        .rd_en(FIFO_IN_TRIG),
        .dout(adc2_dat),

        .empty(),
        .full(),
        .valid(valid2)
    );

    // adc to ram fifo
    fifo_w32_1024_r256_128 adc_ram_fifo(
        .rst(rst),

        .wr_clk(rd_clk),
        .wr_en(FIFO_IN_TRIG),
        .din({adc1_dat, adc2_dat}),

        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .dout(rd_data),
        
        .full(full),
        .empty(empty),
        .valid(valid),
        .rd_data_count(rd_data_count),
        .wr_data_count()
    );


endmodule // ADC_RO
