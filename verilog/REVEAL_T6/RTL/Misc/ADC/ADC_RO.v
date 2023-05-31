`timescale 1ns / 1ps

module ADC_RO(
    input wire      rst,
    input wire      clk_100,
    input wire      CP_MUX_IN,
    input wire      MUX_START,
    input wire      ADC_INCLK,

    output reg      ADC1_SHR,
    input wire      [7:0] ADC1_DATA_RAW,
    input wire      ADC1_DATA_CLK,
    output reg      ADC2_SHR,
    input wire      [7:0] ADC2_DATA_RAW,
    input wire      ADC2_DATA_CLK,

    output reg      FIFO_IN_TRIG_DeSerial,
    output wire     FIFO_IN_CLK_DeSerial,
    output wire     [47:0] FIFO_IN_DATA1_DeSerial,
    output wire     [47:0] FIFO_IN_DATA2_DeSerial,

    output wire     FIFO_IN_TRIG,
    input wire      FIFO_IN_CLK,
    output wire     [15:0] FIFO_IN_DATA1,
    output wire     [15:0] FIFO_IN_DATA2,

    output wire     OK_FIFO_Start_Trig,
    output wire     [31:0] OK_FIFO_DATA_OUT,
    input wire      OK_FIFO_OUT_TRIG,
    input wire      OK_CLK,
    output wire     OK_FIFO_EMPTY,

    output wire     RAM_FIFO_FULL,
    output wire     RAM_FIFO_EMPTY,
    output wire     [255:0] RAM_FIFO_DOUT,
    input wire      RAM_FIFO_CLK,
    input wire      RAM_FIFO_RD_EN,
    output wire     RAM_FIFO_VALID,
    output wire     [6:0] RAM_FIFO_RD_COUNT,
    output wire     [9:0] RAM_FIFO_WR_COUNT,

    // DEBUG ONLY
    output wire     [8:0] DEBUG,
    output wire     [31:0] DEBUG_WIRE
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

    /**NOTE configuration */
    parameter COL_NUM = 43;

    localparam  S_IDLE      = 16'b1 << 0,
                S_START     = 16'b1 << 1,
                S_READ      = 16'b1 << 2,
                S_WAIT      = 16'b1 << 3,
                S_SAVE      = 16'b1 << 4,
                S_WAIT_FOR_NEXT_CP        = 16'b1 << 5,
                S_WAIT_FOR_ADC_CLK_L      = 16'b1 << 6,
                S_WAIT_FOR_ADC_CLK_H      = 16'b1 << 7;
    reg [15:0] current_state, next_state;
    reg [15:0] lat_cnt;     // lat3 counter
    reg ADC_en, ADC1_done, ADC2_done, ADC_start;
    reg start_trig;
    reg [7:0] start_cnt;
    reg [15:0] col_cnt;

    initial current_state = S_IDLE;
    initial next_state = S_IDLE;

    reg early_CP_MUX_IN;

    always @(posedge clk_100) begin
        if (rst) current_state <= S_IDLE;
        else current_state <= next_state;

        case (current_state)
            S_IDLE: begin
                col_cnt <= 0;
            end 
            S_READ: begin
                early_CP_MUX_IN <= 1;
            end
            S_WAIT: begin
                if (~CP_MUX_IN) begin
                    early_CP_MUX_IN <= 0;
                end
            end
            S_SAVE: begin
                col_cnt <= col_cnt + 1;                
            end
            default: begin
            end
        endcase
    end


    always @(*) begin
        ADC_en = 0;
        FIFO_IN_TRIG_DeSerial = 0;
        case (current_state)
            S_IDLE: begin   // 0x1
                next_state = (MUX_START) ? S_START : S_IDLE;
            end 
            S_START: begin  // 0x2
                next_state = CP_MUX_IN ? (S_READ) : S_START;
            end
            S_WAIT_FOR_ADC_CLK_L: begin // 0x4
                next_state = ADC_INCLK ? S_READ: S_WAIT_FOR_ADC_CLK_L;
            end
            S_WAIT_FOR_ADC_CLK_H: begin // 0x8
                next_state = ADC_INCLK ? S_WAIT_FOR_ADC_CLK_H : S_WAIT_FOR_ADC_CLK_L;
            end
            S_READ: begin   // 0x10
                ADC_en = 1;
                next_state = ADC_start ? S_WAIT : S_READ;
            end
            S_WAIT: begin   // 0x20
                // if (ADC_start)
                // ADC_en = 0; // in case the signal is captured multiple times
                next_state = (ADC1_done & ADC2_done) ? S_SAVE : S_WAIT;
            end
            S_SAVE: begin   // 0x40
                next_state = (col_cnt >= COL_NUM - 1) ? S_IDLE : S_WAIT_FOR_NEXT_CP;
                FIFO_IN_TRIG_DeSerial = 1;
            end
            S_WAIT_FOR_NEXT_CP: begin
                next_state = (CP_MUX_IN & early_CP_MUX_IN) ? S_WAIT_FOR_NEXT_CP : S_START;
            end
            default: next_state = S_IDLE;
        endcase
    end

    always @(posedge ADC_INCLK) begin
        ADC_start = ADC_en; // sync the adc enable signal
    end

    /** Read from ADC */
    localparam  S_IDLE_ADC   = 16'b1 << 0,   // 0x1
                S_READ_ADC   = 16'b1 << 1,   
                S_DONE_ADC   = 16'b1 << 2,   
                S_WAIT_ADC   = 16'b1 << 3;   

    // data from two
    reg [47:0] DATA_FROM_ADC1;
    reg [47:0] DATA_FROM_ADC2;
    assign FIFO_IN_DATA1_DeSerial = DATA_FROM_ADC1;
    assign FIFO_IN_DATA2_DeSerial = DATA_FROM_ADC2;

    assign FIFO_IN_CLK_DeSerial = clk_100;
    // assign FIFO_IN_CLK = ADC1_DATA_CLK;
    reg [15:0] buffer_data1;
    reg [15:0] buffer_data2;
    reg buffer_trig1, buffer_trig2;
    // assign FIFO_IN_DATA1 = FIFO_IN_DATA1_reg;
    // assign FIFO_IN_DATA2 = FIFO_IN_DATA2_reg;

    reg [15:0] ADC1_state, ADC2_state; // current state
    // reg [15:0] ADC1_ns, ADC2_ns; // next state    
    reg [7:0] temp_data1 [5:0];
    reg [47:0] temp_adc1;
    reg [47:0] temp_adc2;
    reg [7:0] temp_data2 [5:0];
    reg [7:0] data1_index, data2_index;

    initial begin
        ADC1_state <= S_IDLE_ADC;
        ADC2_state <= S_IDLE_ADC;

        temp_adc1 <= 48'b0;
        temp_adc2 <= 48'b0;

        data1_index <= 1;
        data2_index <= 1;

        temp_adc1 <= 0;

        ADC1_done <= 0;
        ADC2_done <= 0;  // TODO adc2
    end

    localparam DATA_BITS    = 16;

    always @(posedge ADC1_DATA_CLK) begin
        case (ADC1_state)
            S_IDLE_ADC: begin
                ADC1_done <= 0;
                ADC1_state <= (ADC_start) ? S_READ_ADC : S_IDLE_ADC;
                // data1_index <= (ADC1_DATA_CLK) ? 1 : 0;
                buffer_trig1 <= 0;
                data1_index <= 1;
                temp_adc1 <= (temp_adc1 << DATA_BITS) | ADC1_DATA;
            end
            S_READ_ADC: begin
                ADC1_state <= (data1_index < 3) ? S_READ_ADC : S_DONE_ADC;
                // ADC1_ns = S_DONE_ADC;
                buffer_data1 <= ADC1_DATA;
                buffer_trig1 <= 1;

                temp_adc1 <= (temp_adc1 << DATA_BITS) | ADC1_DATA;
                data1_index <= data1_index + 1;
            end
            S_DONE_ADC: begin
                ADC1_state <= S_WAIT_ADC;
                buffer_trig1 <= 0;
                DATA_FROM_ADC1 <= temp_adc1;
            end
            S_WAIT_ADC: begin
                ADC1_done <= 1;
                ADC1_state <= S_IDLE_ADC;
            end
            default: 
                ADC1_state <= S_IDLE_ADC;
        endcase
    end

    //  adc2 ro here
    always @(posedge ADC2_DATA_CLK) begin
        case (ADC2_state)
            S_IDLE_ADC: begin
                ADC2_done <= 0;
                ADC2_state <= (ADC_start) ? S_READ_ADC : S_IDLE_ADC;
                // data1_index <= (ADC1_DATA_CLK) ? 1 : 0;
                buffer_trig2 <= 0;
                data2_index <= 1;
                temp_adc2 <= (temp_adc2 << DATA_BITS) | ADC2_DATA;
            end
            S_READ_ADC: begin
                ADC2_state <= (data2_index < 3) ? S_READ_ADC : S_DONE_ADC;
                // ADC1_ns = S_DONE_ADC;
                buffer_trig2 <= 1;
                buffer_data2 <= ADC2_DATA;

                temp_adc2 <= (temp_adc2 << DATA_BITS) | ADC2_DATA;
                data2_index <= data2_index + 1;
            end
            S_DONE_ADC: begin
                ADC2_state <= S_WAIT_ADC;
                buffer_trig2<= 0;
                DATA_FROM_ADC2 <= temp_adc2;
            end
            S_WAIT_ADC: begin
                ADC2_done <= 1;
                ADC2_state <= S_IDLE_ADC;
            end
            default: 
                ADC2_state <= S_IDLE_ADC;
        endcase
    end
    
    // ALl fifo related to adc
    assign FIFO_IN_TRIG = buffer_valid1 & buffer_valid2;
    wire FIFO_CLK;
    assign FIFO_CLK = clk_100;

    // ADC1 Buffer fifo
    wire buffer_valid1;
    adc_ro_buffer_fifo adc_fifo1(
        .full(),
        .din(buffer_data1),
        .wr_en(buffer_trig1),

        .empty(),
        .dout(FIFO_IN_DATA1),
        .rd_en(FIFO_IN_TRIG),

        .wr_clk(ADC1_DATA_CLK),
        .wr_rst(rst),
        .rd_clk(FIFO_CLK),
        .rd_rst(rst),

        .valid(buffer_valid1)
    );

    // ADC2 Buffer fifo
    wire buffer_valid2;
    adc_ro_buffer_fifo adc_fifo2(
        .full(),
        .din(buffer_data2),
        .wr_en(buffer_trig2),

        .empty(),
        .dout(FIFO_IN_DATA2),
        .rd_en(FIFO_IN_TRIG),

        .wr_clk(ADC2_DATA_CLK),
        .wr_rst(rst),
        .rd_clk(FIFO_CLK),
        .rd_rst(rst),

        .valid(buffer_valid2)
    );

    // adc to ok fifo
    adc_ok_fifo adc_FIFO(
        .full(OK_FIFO_Start_Trig),
        .din({FIFO_IN_DATA1, FIFO_IN_DATA2}),
        .wr_en(FIFO_IN_TRIG),

        .empty(OK_FIFO_EMPTY),
        .dout(OK_FIFO_DATA_OUT),
        .rd_en(OK_FIFO_OUT_TRIG),

        .wr_clk(FIFO_CLK),
        .wr_rst(rst),
        .rd_rst(rst),
        .rd_clk(OK_CLK)
    );

    // adc to ram fifo
    fifo_w32_1024_r256_128 adc_ram_fifo(
        .full(RAM_FIFO_FULL),
        .din({FIFO_IN_DATA1, FIFO_IN_DATA2}),
        .wr_en(FIFO_IN_TRIG),

        .empty(RAM_FIFO_EMPTY),
        .dout(RAM_FIFO_DOUT),
        .rd_en(RAM_FIFO_RD_EN),

        .rst(rst),
        .wr_clk(FIFO_CLK),
        .rd_clk(RAM_FIFO_CLK),
        
        .valid(RAM_FIFO_VALID),
        .rd_data_count(RAM_FIFO_RD_COUNT),
        .wr_data_count(RAM_FIFO_WR_COUNT)
    );

endmodule // ADC_RO