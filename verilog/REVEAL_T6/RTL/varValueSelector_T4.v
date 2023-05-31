`timescale 1ns / 1ps

module varValueSelector_T4 (
	input wire wr_en,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varAddress,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varValueIn, 		// Input Value of the variable
	output reg [31:0] varValueOut,		// Output Value of the variable
	output reg [31:0] numPattern,      
	output reg [31:0] LedNum,      
	output reg [31:0] LedDly,      
	output reg [31:0] LedExp,      
	output reg [31:0] LedCtl,      
	output reg [31:0] LedSeq,      
	output reg [31:0] Texp_ctrl,
	output reg [31:0] Tdes2_d,
	output reg [31:0] Tdes2_w,
	output reg [31:0] Tmsken_d,
	output reg [31:0] Tmsken_w,
	output reg [31:0] Tgsub_w,
	output reg [31:0] Tgl_Res,
	output reg [31:0] Tproj_dly,
	output reg [31:0] ADDR,
	output reg [31:0] Select,

	output reg [31:0] Tadc,
	output reg [31:0] T1,
	output reg [31:0] T2,
	output reg [31:0] T3,
	output reg [31:0] T4,
	output reg [31:0] T5,
	output reg [31:0] T6,
	output reg [31:0] T7,
	output reg [31:0] T8,
	output reg [31:0] TOSR,
    output reg [31:0] Tbuck,
    output reg [31:0] Tadd,
    output reg [31:0] NumRep,
    output reg [31:0] NumGsub,
	output reg [31:0] TExpRST,
	output reg [31:0] Tdrain_w,
	output reg [31:0] TReadRST,
	output reg [31:0] imgCountTrig,
	output reg [31:0] TdrainR_d,
	output reg [31:0] TdrainF_d,
	output reg [31:0] TLedOn,
	output reg [31:0] ADDRExpStart,
	output reg [31:0] Tproj_Trig_On,
	output reg [31:0] Tproj_Trig_Off,
	output reg [31:0] Tproj_Trig_Number,
	output reg [31:0] TskipExposure_CoolDown,
	output reg [31:0] CAM_TG_pulseWidth,
	output reg [31:0] CAM_TG_HoldTime,
	output reg [31:0] CAM_TG_delay,
	output reg [31:0] NumExp		
);


	reg defActive;
	initial begin
		//TGL_RES width after exposure
        Tgl_Res = 200;
		//DES2 Delay
        Tdes2_d = 2;
		//DES2 Width
        Tdes2_w = 4;
		//MASK_EN Delay
        Tmsken_d = 3;
		//MASK_EN Width
        Tmsken_w = 14;
		//PIXGSUBC width
        Tgsub_w = 100;
        //Drain delay
        TdrainR_d = 10;
        TdrainF_d = 10;
        
        //contrast LED
        TLedOn    = 1000;
        
		//Controllable Exp Time min 200000
        Texp_ctrl = 30000; //This must be at least 1ms (200000 clk cycles)
        numPattern = 2;
		//PRECH_COL Width
        T1 = 5;
		//ADC_EN Negative Delay
        T2 = 100;
		//DATA_LOAD_Width
        T3 = 20;
		//RST_ADC Width
        T4 = 10;
		//RST_ADC_Falling Edge Delay
        T5 = 14;
		//RST_OUTMUX Width
        T6 = 6;
		//DIGOUT Starting Delay
        T7 = 17;
		//DIGOUT Number of valid TX_CLK_OUT Cycles
        T8 = 14;
        Tbuck = 118 * 14;
        //TRST = 10;
        TExpRST = 19010;
        TReadRST = 100;
		//Number of ADC_Cycle in one conversion
        TOSR = 115;
		//ADC_CLK. No. of TX_CLK per ADC_CLK
        Tadc = 13;                
        Tadd = 3;                
				Tproj_dly = 19000;
				NumRep = 1;
				NumGsub = 0;
				Tdrain_w = 13;
				ADDR = 0;
				Select = 0;
				LedNum = 4;
				LedDly = 1;
				LedExp = 100;
				LedCtl = 0; // control led on/off 0/1
				LedSeq = 32'h87654321; // control the flash sequence of 8 leds
				
        imgCountTrig = 60000; // number of words for imgoutput fifo to trigger imread
        
        Tproj_Trig_On           = 32'd100;
        Tproj_Trig_Off          = 32'd100;
        Tproj_Trig_Number       = 32'd1;
        
        TskipExposure_CoolDown  = 32'd1000;
        
        CAM_TG_pulseWidth       = 32'd15000;
        CAM_TG_HoldTime         = 32'd13000;
        CAM_TG_delay            = 32'd10000;
        
        NumExp                  = 32'd1;    //number of exposure before one readout

    end
    
    initial begin
    end
    
always @(*) begin
	if(wr_en) begin
		case(varAddress)
			32'd1:  numPattern = varValueIn;
			32'd2:  Texp_ctrl  = varValueIn;
			32'd3:  Tdes2_d 	 = varValueIn;
			32'd4:  Tdes2_w 	 = varValueIn;
			32'd5:  Tmsken_d 	 = varValueIn;
			32'd6:  Tmsken_w 	 = varValueIn;
			32'd7:  Tgsub_w  	 = varValueIn;
			32'd8:  Tgl_Res  	 = varValueIn;
			32'd10: Tadc 	     = varValueIn;
			32'd11: T1 		     = varValueIn;
			32'd12: T2 		     = varValueIn;
			32'd13: T3		     = varValueIn;
			32'd14: T4		     = varValueIn;
			32'd15: T5		     = varValueIn;
			32'd16: T6		     = varValueIn;
			32'd17: T7		     = varValueIn;
			32'd18: T8		     = varValueIn;
			32'd19: TOSR 	     = varValueIn;
			32'd20: Tbuck      = varValueIn;
			32'd21: TExpRST    = varValueIn;
			32'd22: Tadd 	     = varValueIn;
			32'd23: Tproj_dly        = varValueIn;
			32'd24: NumRep	         = varValueIn;
			32'd25: TReadRST         = varValueIn;
			32'd26: NumGsub          = varValueIn;
			32'd27: Tdrain_w         = varValueIn;
			32'd28: Select           = varValueIn;
			32'd29: ADDR             = varValueIn;
			32'd30: LedNum           = varValueIn;
			32'd31: LedDly           = varValueIn;
			32'd32: LedExp           = varValueIn;
			32'd33: LedCtl           = varValueIn;
			32'd34: LedSeq           = varValueIn;
			32'd35: imgCountTrig     = varValueIn;
			32'd36: TdrainR_d        = varValueIn;
			32'd37: TdrainF_d        = varValueIn;
			32'd38: TLedOn           = varValueIn;
            32'd39: Tproj_Trig_On	 		= varValueIn;
			32'd40: Tproj_Trig_Off	 		= varValueIn;
			32'd41: Tproj_Trig_Number	 	= varValueIn;
			32'd42: TskipExposure_CoolDown	= varValueIn;
			32'd43: CAM_TG_pulseWidth	 	= varValueIn;
			32'd44: CAM_TG_HoldTime	 		= varValueIn;
			32'd45: CAM_TG_delay	 		= varValueIn;
			32'd46: NumExp                  = varValueIn;
			
			default:  ;// nothing
			//default: begin 
			//	numPattern = numPattern;
			//	Texp_ctrl  = Texp_ctrl;
			//	Tdes2_d 	 = Tdes2_d;
			//	Tdes2_w 	 = Tdes2_w;
			//	Tmsken_d 	 = Tmsken_d;
			//	Tmsken_w 	 = Tmsken_w;
			//	Tgsub_w  	 = Tgsub_w;
			//	Tgl_Res  	 = Tgl_Res;
			//	Tadc 	     = Tadc 	    ;
			//	T1 		     = T1 		    ;
			//	T2 		     = T2 		    ;
			//	T3		     = T3		    ;
			//	T4		     = T4		    ;
			//	T5		     = T5		    ;
			//	T6		     = T6		    ;
			//	T7		     = T7		    ;
			//	T8		     = T8		    ;
			//	TOSR 	     = TOSR 	    ;
			//	Tbuck      = Tbuck     ;
			//	TRST 	     = TRST 	    ;
			//	Tadd 	     = Tadd 	    ;
			//	Tproj_dly  = Tproj_dly;
			//end
		endcase // varAddress
	end
end

always @(*) begin
	if(~wr_en) begin
		case(varAddress)
			32'd1:  varValueOut = numPattern;
			32'd2:  varValueOut = Texp_ctrl;
			32'd3:  varValueOut = Tdes2_d;
			32'd4:  varValueOut = Tdes2_w;
			32'd5:  varValueOut = Tmsken_d;
			32'd6:  varValueOut = Tmsken_w;
			32'd7:  varValueOut = Tgsub_w;
			32'd8:  varValueOut = Tgl_Res;
			32'd10: varValueOut = Tadc;
			32'd11: varValueOut = T1;
			32'd12: varValueOut = T2;
			32'd13: varValueOut = T3;
			32'd14: varValueOut = T4;
			32'd15: varValueOut = T5;
			32'd16: varValueOut = T6;
			32'd17: varValueOut = T7;
			32'd18: varValueOut = T8;
			32'd19: varValueOut = TOSR;
			32'd20: varValueOut = Tbuck;
			32'd21: varValueOut = TExpRST;
			32'd22: varValueOut = Tadd;
			32'd23: varValueOut = Tproj_dly;
			32'd24: varValueOut = NumRep;
			32'd25: varValueOut = TReadRST;
			32'd26: varValueOut = NumGsub;
			32'd27: varValueOut = Tdrain_w;
			32'd28: varValueOut = Select;
			32'd29: varValueOut = ADDR;
			32'd30: varValueOut = LedNum;
			32'd31: varValueOut = LedDly;
			32'd32: varValueOut = LedExp;
			32'd33: varValueOut = LedCtl;
			32'd34: varValueOut = LedSeq;
			32'd35: varValueOut = imgCountTrig;
			32'd36: varValueOut = TdrainR_d;
			32'd37: varValueOut = TdrainF_d;
			32'd38: varValueOut = TLedOn;
		    32'd39: varValueOut = Tproj_Trig_On;    
			32'd40: varValueOut = Tproj_Trig_Off;   
			32'd41: varValueOut = Tproj_Trig_Number;
			32'd42: varValueOut = TskipExposure_CoolDown;
			32'd43: varValueOut = CAM_TG_pulseWidth;
			32'd44: varValueOut = CAM_TG_HoldTime;
            32'd45: varValueOut = CAM_TG_delay;
            32'd46: varValueOut = NumExp;
			default: varValueOut = 0; 
		endcase // varAddress
	end
end


endmodule
