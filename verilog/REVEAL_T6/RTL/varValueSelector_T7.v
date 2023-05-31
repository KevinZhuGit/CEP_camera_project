`timescale 1ns / 1ps

module varValueSelector_T7 (
	input wire wr_en,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varAddress,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varValueIn, 		// Input Value of the variable
	output reg [31:0] varValueOut,		// Output Value of the variable
	input wire clk,

output reg [31:0] numPattern,
	output reg [31:0] Texp_ctrl,
	output reg [31:0] Tdes2_d,
	output reg [31:0] Tdes2_w,
	output reg [31:0] Tmsken_d,
	output reg [31:0] Tmsken_w,
	output reg [31:0] Tgsub_w,
	output reg [31:0] Tgl_Res,
	output reg [31:0] Tproj_dly,
	output reg [31:0] Tadd,
	output reg [31:0] NumRep,
	output reg [31:0] NumGsub,
	output reg [31:0] TExpRST,
	output reg [31:0] Tdrain_w,
	output reg [31:0] imgCountTrig,
	output reg [31:0] TdrainR_d,
	output reg [31:0] TdrainF_d,
//	output reg [31:0] TLedOn,
	output reg [31:0] Select,
	output reg [31:0] CAM_TG_pulseWid,
	output reg [31:0] CAM_TG_HoldTime,
	output reg [31:0] CAM_TG_delay,
	output reg [31:0] MASK_SIZE,
	output reg [31:0] IMG_SIZE,
	output reg [31:0] T_DEC_SEL_0,
	output reg [31:0] T_DEC_SEL_1,
	output reg [31:0] T_DEC_EN_0,
	output reg [31:0] T_DEC_EN_1,
	output reg [31:0] T_DONE_1,
	output reg [31:0] MSTREAM_Select,
	output reg [31:0] MU_NUM_ROW,
	output reg [31:0] SUB_IMG_SIZE,
	output reg [31:0] ADC1_Tcolumn,
	output reg [31:0] ADC1_T1,
	output reg [31:0] ADC1_T2_1,
	output reg [31:0] ADC1_T2_0,
	output reg [31:0] ADC1_T3,
	output reg [31:0] ADC1_T4,
	output reg [31:0] ADC1_T5,
	output reg [31:0] ADC1_T6,
	output reg [31:0] ADC1_T7,
	output reg [31:0] ADC1_T8,
	output reg [31:0] ADC1_T9,
	output reg [31:0] ADC1_TADC,
	output reg [31:0] ADC1_NUM_ROW,
	output reg [31:0] ADC1_Wait,
	output reg [31:0] T_MU_wait,
	output reg [31:0] ADC2_Tcolumn,
	output reg [31:0] ADC2_T1,
	output reg [31:0] ADC2_T2_1,
	output reg [31:0] ADC2_T2_0,
	output reg [31:0] ADC2_T3,
	output reg [31:0] ADC2_T4,
	output reg [31:0] ADC2_T5,
	output reg [31:0] ADC2_T6,
	output reg [31:0] ADC2_T7,
	output reg [31:0] ADC2_T8,
	output reg [31:0] ADC2_T9,
	output reg [31:0] ADC2_TADC,
	output reg [31:0] ADC2_NUM_ROW,
	output reg [31:0] ADC2_Wait,
//	output reg [31:0] T_MU_wait,
	output reg [31:0] TrigNo,
	output reg [31:0] TrigOffTime,
	output reg [31:0] TrigOnTime,
	output reg [31:0] UNIT_SUB_IMG_SIZE,
	output reg [31:0] N_SUBREADOUTS,
	output reg [31:0] SPI_CONTROL, 
	output reg [31:0] I2C_DATA   ,
	output reg [31:0] I2C_CONTROL,
	output reg [31:0] ROWADD_INCRMNT,
	output reg [31:0] TrigWaitTime,  	
	output reg [31:0] TLEDNo,
	output reg [31:0] TLEDOff,
	output reg [31:0] TLEDOn,
	output reg [31:0] TLEDWait
);


	reg defActive;
	initial begin
		numPattern = 2;  //
		Texp_ctrl = 30000;  //
		Tdes2_d = 2;  //
		Tdes2_w = 4;  //
		Tmsken_d = 3;  //
		Tmsken_w = 14;  //
		Tgsub_w = 100;  //
		Tgl_Res = 200;  //
		Tproj_dly = 19000;  //
		Tadd = 3;  //
		NumRep = 1;  //
		NumGsub = 0;  //
		TExpRST = 19010;  //
		Tdrain_w = 13;  //
		imgCountTrig = 60000;  //
		TdrainR_d = 10;  //
		TdrainF_d = 10;  //
//		TLedOn = 1000;  //
		Select = 32'hFFFFFFFF;  //
		CAM_TG_pulseWid = 15000;  //
		CAM_TG_HoldTime = 13000;  //
		CAM_TG_delay = 10000;  //
		MASK_SIZE = 320*16*100*1;  // IMG_ROW*MASK_CH*NUM_PAT*NUM_REP (assuming 100 subframes and 1 rep)
		IMG_SIZE = 245760;  // '= (480*40*17*2*12*256/255)/32 = IMG_ROW*IMG_COL*IMG_CH*IMG_TAP*IMG_BITS*256/240 bits, divide 32 to get 32 bit words
		T_DEC_SEL_0 = 4;  // 
		T_DEC_SEL_1 = 1;  // 
		T_DEC_EN_0 = 4;  // 
		T_DEC_EN_1 = 2;  // 
		T_DONE_1 = 4;  // 
		MSTREAM_Select = 0;  // 
		MU_NUM_ROW = 480;  // 
		SUB_IMG_SIZE = 480*680*1024/32;  // 
		ADC1_Tcolumn = 352;  // 
		ADC1_T1 = 10;  // 
		ADC1_T2_1 = 320*16*100*1;  // 
		ADC1_T2_0 = 5;  // IMG_ROW*MASK_CH*NUM_PAT*NUM_REP (assuming 100 subframes and 1 rep)
		ADC1_T3 = 240;  // '= (480*40*17*2*12*256/255)/32 = IMG_ROW*IMG_COL*IMG_CH*IMG_TAP*IMG_BITS*256/240 bits, divide 32 to get 32 bit words
		ADC1_T4 = 242;  // 
		ADC1_T5 = 4;  // 
		ADC1_T6 = 1;  // 
		ADC1_T7 = 22;  // 
		ADC1_T8 = 2;  // 
		ADC1_T9 = 22;  // 
		ADC1_TADC = 20;  // 
		ADC1_NUM_ROW = 480;  // 
		ADC1_Wait = 1024;  // 
		T_MU_wait = 2048;  // 
		ADC2_Tcolumn = 46;  // 
		ADC2_T1 = 6;  // 
		ADC2_T2_1 = 0;  // 
		ADC2_T2_0 = 2;  // 
		ADC2_T3 = 0;  // 
		ADC2_T4 = 1;  // 
		ADC2_T5 = 1;  // 
		ADC2_T6 = 1;  // 
		ADC2_T7 = 22;  // 
		ADC2_T8 = 2;  // 
		ADC2_T9 = 22;  // 
		ADC2_TADC = 12;  // 
		ADC2_NUM_ROW = 480;  // 
		ADC2_Wait = 1;  // 
		T_MU_wait = 2048;  // 
		TrigNo = 1;  // 
		TrigOffTime = 1;  // 
		TrigOnTime = 3142;  // 
		UNIT_SUB_IMG_SIZE = 480*680*1/32*256/255;
		N_SUBREADOUTS = 8;
		SPI_CONTROL = 0;
		I2C_DATA    = 0;
		I2C_CONTROL  = 0;
		ROWADD_INCRMNT = 0;
		TrigWaitTime = 100;
		TLEDNo    = 1;
		TLEDOff   = 100;
		TLEDOn    = 10;
		TLEDWait  = 1;

    end
    
    initial begin
    end
    
always @(posedge clk) begin
	if(wr_en) begin
		case(varAddress)
			32'd0: numPattern = varValueIn;
			32'd1: Texp_ctrl = varValueIn;
			32'd2: Tdes2_d = varValueIn;
			32'd3: Tdes2_w = varValueIn;
			32'd4: Tmsken_d = varValueIn;
			32'd5: Tmsken_w = varValueIn;
			32'd6: Tgsub_w = varValueIn;
			32'd7: Tgl_Res = varValueIn;
			32'd8: Tproj_dly = varValueIn;
			32'd9: Tadd = varValueIn;
			32'd10: NumRep = varValueIn;
			32'd11: NumGsub = varValueIn;
			32'd12: TExpRST = varValueIn;
			32'd13: Tdrain_w = varValueIn;
			32'd14: imgCountTrig = varValueIn;
			32'd15: TdrainR_d = varValueIn;
			32'd16: TdrainF_d = varValueIn;
//			32'd17: TLedOn = varValueIn;
			32'd18: Select = varValueIn;
			32'd19: CAM_TG_pulseWid = varValueIn;
			32'd20: CAM_TG_HoldTime = varValueIn;
			32'd21: CAM_TG_delay = varValueIn;
			32'd22: MASK_SIZE = varValueIn;
			32'd23: IMG_SIZE = varValueIn;
			32'd24: T_DEC_SEL_0 = varValueIn;
			32'd25: T_DEC_SEL_1 = varValueIn;
			32'd26: T_DEC_EN_0 = varValueIn;
			32'd27: T_DEC_EN_1 = varValueIn;
			32'd28: T_DONE_1 = varValueIn;
			32'd29: MSTREAM_Select = varValueIn;
			32'd30: MU_NUM_ROW = varValueIn;
			32'd31: SUB_IMG_SIZE = varValueIn;
			32'd32: ADC1_Tcolumn = varValueIn;
			32'd33: ADC1_T1 = varValueIn;
			32'd34: ADC1_T2_1 = varValueIn;
			32'd35: ADC1_T2_0 = varValueIn;
			32'd36: ADC1_T3 = varValueIn;
			32'd37: ADC1_T4 = varValueIn;
			32'd38: ADC1_T5 = varValueIn;
			32'd39: ADC1_T6 = varValueIn;
			32'd40: ADC1_T7 = varValueIn;
			32'd41: ADC1_T8 = varValueIn;
			32'd42: ADC1_T9 = varValueIn;
			32'd43: ADC1_TADC = varValueIn;
			32'd44: ADC1_NUM_ROW = varValueIn;
			32'd45: ADC1_Wait = varValueIn;
			32'd46: T_MU_wait = varValueIn;
			32'd47: ADC2_Tcolumn = varValueIn;
			32'd48: ADC2_T1 = varValueIn;
			32'd49: ADC2_T2_1 = varValueIn;
			32'd50: ADC2_T2_0 = varValueIn;
			32'd51: ADC2_T3 = varValueIn;
			32'd52: ADC2_T4 = varValueIn;
			32'd53: ADC2_T5 = varValueIn;
			32'd54: ADC2_T6 = varValueIn;
			32'd55: ADC2_T7 = varValueIn;
			32'd56: ADC2_T8 = varValueIn;
			32'd57: ADC2_T9 = varValueIn;
			32'd58: ADC2_TADC = varValueIn;
			32'd59: ADC2_NUM_ROW = varValueIn;
			32'd60: ADC2_Wait = varValueIn;
			32'd61: T_MU_wait = varValueIn;
			32'd62: TrigNo = varValueIn;
			32'd63: TrigOffTime = varValueIn;
			32'd64: TrigOnTime = varValueIn;
			32'd65: UNIT_SUB_IMG_SIZE = varValueIn;
			32'd66: N_SUBREADOUTS = varValueIn;
			32'd67: SPI_CONTROL = varValueIn;
			32'd68: I2C_DATA    = varValueIn;
			32'd69: I2C_CONTROL  = varValueIn;
			32'd70: ROWADD_INCRMNT = varValueIn;
			32'd71: TrigWaitTime =  varValueIn;
			32'd72: TLEDNo   = varValueIn;
			32'd73: TLEDOff  = varValueIn;
			32'd74: TLEDOn   = varValueIn;
			32'd75: TLEDWait = varValueIn;
			default:  ;// nothing
		endcase // varAddress
	end
end

always @(posedge clk) begin
	if(~wr_en) begin
		case(varAddress)
			32'd0: varValueOut = numPattern;
			32'd1: varValueOut = Texp_ctrl;
			32'd2: varValueOut = Tdes2_d;
			32'd3: varValueOut = Tdes2_w;
			32'd4: varValueOut = Tmsken_d;
			32'd5: varValueOut = Tmsken_w;
			32'd6: varValueOut = Tgsub_w;
			32'd7: varValueOut = Tgl_Res;
			32'd8: varValueOut = Tproj_dly;
			32'd9: varValueOut = Tadd;
			32'd10: varValueOut = NumRep;
			32'd11: varValueOut = NumGsub;
			32'd12: varValueOut = TExpRST;
			32'd13: varValueOut = Tdrain_w;
			32'd14: varValueOut = imgCountTrig;
			32'd15: varValueOut = TdrainR_d;
			32'd16: varValueOut = TdrainF_d;
//			32'd17: varValueOut = TLedOn;
			32'd18: varValueOut = Select;
			32'd19: varValueOut = CAM_TG_pulseWid;
			32'd20: varValueOut = CAM_TG_HoldTime;
			32'd21: varValueOut = CAM_TG_delay;
			32'd22: varValueOut = MASK_SIZE;
			32'd23: varValueOut = IMG_SIZE;
			32'd24: varValueOut = T_DEC_SEL_0;
			32'd25: varValueOut = T_DEC_SEL_1;
			32'd26: varValueOut = T_DEC_EN_0;
			32'd27: varValueOut = T_DEC_EN_1;
			32'd28: varValueOut = T_DONE_1;
			32'd29: varValueOut = MSTREAM_Select;
			32'd30: varValueOut = MU_NUM_ROW;
			32'd31: varValueOut = SUB_IMG_SIZE;
			32'd32: varValueOut = ADC1_Tcolumn;
			32'd33: varValueOut = ADC1_T1;
			32'd34: varValueOut = ADC1_T2_1;
			32'd35: varValueOut = ADC1_T2_0;
			32'd36: varValueOut = ADC1_T3;
			32'd37: varValueOut = ADC1_T4;
			32'd38: varValueOut = ADC1_T5;
			32'd39: varValueOut = ADC1_T6;
			32'd40: varValueOut = ADC1_T7;
			32'd41: varValueOut = ADC1_T8;
			32'd42: varValueOut = ADC1_T9;
			32'd43: varValueOut = ADC1_TADC;
			32'd44: varValueOut = ADC1_NUM_ROW;
			32'd45: varValueOut = ADC1_Wait;
			32'd46: varValueOut = T_MU_wait;
			32'd47: varValueOut = ADC2_Tcolumn;
			32'd48: varValueOut = ADC2_T1;
			32'd49: varValueOut = ADC2_T2_1;
			32'd50: varValueOut = ADC2_T2_0;
			32'd51: varValueOut = ADC2_T3;
			32'd52: varValueOut = ADC2_T4;
			32'd53: varValueOut = ADC2_T5;
			32'd54: varValueOut = ADC2_T6;
			32'd55: varValueOut = ADC2_T7;
			32'd56: varValueOut = ADC2_T8;
			32'd57: varValueOut = ADC2_T9;
			32'd58: varValueOut = ADC2_TADC;
			32'd59: varValueOut = ADC2_NUM_ROW;
			32'd60: varValueOut = ADC2_Wait;
			32'd61: varValueOut = T_MU_wait;
			32'd62: varValueOut = TrigNo;
			32'd63: varValueOut = TrigOffTime;
			32'd64: varValueOut = TrigOnTime;
			32'd65: varValueOut = UNIT_SUB_IMG_SIZE;
			32'd66: varValueOut = N_SUBREADOUTS;
			32'd67: varValueOut = SPI_CONTROL; 
			32'd68: varValueOut = I2C_DATA;    
			32'd69: varValueOut = I2C_CONTROL;  
			32'd70: varValueOut = ROWADD_INCRMNT;
			32'd71: varValueOut = TrigWaitTime;
			32'd72: varValueOut = TLEDNo;
			32'd73: varValueOut = TLEDOff;
			32'd74: varValueOut = TLEDOn;
			32'd75: varValueOut = TLEDWait;
			default: varValueOut = 0; 
		endcase // varAddress
	end
end


endmodule
