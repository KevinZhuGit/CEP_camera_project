`timescale 1ns / 100ps

module varValueSelector (
	input wire wr_en,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varAddress,  		// Address of the variable whose value needs to be changed
	input wire [31:0] varValueIn, 		// Input Value of the variable
	output reg [31:0] varValueOut,		// Output Value of the variable

	output reg [31:0] T1_e,
	output reg [31:0] T2_e,
	output reg [31:0] T3_e,
	output reg [31:0] T4_e,
	output reg [31:0] T5_e,
	output reg [31:0] T6_e,
	output reg [31:0] T7_e,
	output reg [31:0] T8_e,
	output reg [31:0] T9_e,
	output reg [31:0] T1_r,
	output reg [31:0] T2_r,
	output reg [31:0] T3_r,
	output reg [31:0] T4_r,
	output reg [31:0] T5_r,
	output reg [31:0] T6_r,
	output reg [31:0] T7_r,
	output reg [31:0] T8_r,
	output reg [31:0] T9_r,
	output reg [31:0] T10_r,
	output reg [31:0] T11_r,
	output reg [31:0] T12_r,
	output reg [31:0] T13_r,
	output reg [31:0] T14_r,
	output reg [31:0] NL,
	output reg [31:0] NR,
	output reg [31:0] Tgl_res,
	output reg [31:0] T_stdby,
	output reg [31:0] Texp_ctrl,
	output reg [31:0] NumPat,
	output reg [31:0] T_reset,
	output reg [31:0] NumRow,
	output reg [31:0] Tlat1,
	output reg [31:0] Tlat2,
    output reg [31:0] mem_pat,
    output reg [31:0] DUTY1,
    output reg [31:0] DUTY2,
    output reg [31:0] DUTY3,
    output reg [31:0] DELAY1,
    output reg [31:0] DELAY2,
    output reg [31:0] DELAY3,
    output reg [31:0] PERIOD,
    output reg [31:0] RO_RowStart,
    output reg [31:0] PERIOD_CLKM
);


	reg defActive;
	initial begin
		T1_e = 16;
		T2_e = 1;
		T3_e = 1;
		T4_e = 2;
		T5_e = 1;
		T6_e = 1;
		T7_e = 4;
		T8_e = T1_e*4+1;
		T9_e = 10;
		T1_r = 1724;
		//T2_r = 862;
		T3_r = 2;
		T4_r = 3;
		T5_r = 20;
		T6_r = 10;
		//T2_r = 880;  // T5+T6*43
		T2_r = T5_r+T6_r*42;  // T5+T6*43
		T7_r = 4;
		T8_r = 6;
		T9_r = 431;
		T10_r = 2;
		T11_r = 2;
		T12_r = 10;
		T13_r = 2;
		T14_r = 200;
		NL = 2;
		NR= 2;
		Tgl_res = 10;
		T_stdby = 100;
		Texp_ctrl = 4000;
		NumPat = 1;
		T_reset = 10;
		NumRow = 320;
		Tlat1 = 23;
		Tlat2 = 23;
        mem_pat = 100;
		PERIOD = 100;
		DUTY1 = 0;
		DUTY2 = 0;
		DUTY3 = 0;
		DELAY1 = 0;
		DELAY2 = 0;
		DELAY3 = 0;
		RO_RowStart = 0;
		PERIOD_CLKM = 10;
    end

    initial begin
    end


always @(*) begin
	if(wr_en) begin
		case(varAddress)
			32'd1:  T1_e	     = varValueIn;
			32'd2:  T2_e	     = varValueIn;
			32'd3:  T3_e	     = varValueIn;
			32'd4:  T4_e	     = varValueIn;
			32'd5:  T5_e	     = varValueIn;
			32'd6:  T6_e	     = varValueIn;
			32'd7:  T7_e	     = varValueIn;
			32'd8:  T8_e	     = varValueIn;
			32'd9:  T9_e			 = varValueIn;
			32'd10: T1_r			 = varValueIn;
			32'd11: T2_r			 = varValueIn;
			32'd12: T3_r			 = varValueIn;
			32'd13: T4_r			 = varValueIn;
			32'd14: T5_r			 = varValueIn;
			32'd15: T6_r			 = varValueIn;
			32'd16: T7_r			 = varValueIn;
			32'd17: T8_r			 = varValueIn;
			32'd18: T9_r			 = varValueIn;
			32'd19: T10_r			 = varValueIn;
			32'd20: T11_r			 = varValueIn;
			32'd21: T12_r			 = varValueIn;
			32'd22: T13_r			 = varValueIn;
			32'd23: T14_r			 = varValueIn;
			32'd24: Tgl_res    = varValueIn;
			32'd25: T_stdby    = varValueIn;
			32'd26: Texp_ctrl  = varValueIn;
			32'd27: NumPat     = varValueIn;
			32'd28: T_reset    = varValueIn;
			32'd29: NumRow     = varValueIn;
			32'd30: Tlat1      = varValueIn;
			32'd31: Tlat2      = varValueIn;
			32'd32: NL			   = varValueIn;
			32'd33: NR			   = varValueIn;
            32'd34: mem_pat         = varValueIn;
            32'd35: DUTY1	= varValueIn;
            32'd36: DUTY2	= varValueIn;
            32'd37: DUTY3	= varValueIn;
			32'd38: DELAY1	= varValueIn;            			
			32'd39: DELAY2	= varValueIn;            			
			32'd40: DELAY3	= varValueIn;            								
			32'd41: PERIOD	= varValueIn;
			32'd42: RO_RowStart	= varValueIn;			         								
			32'd43: PERIOD_CLKM	= varValueIn;			         								
			default:  ;// nothing
		endcase // varAddress
	end else begin
		case(varAddress)
			32'd1:  varValueOut = T1_e	   ;
			32'd2:  varValueOut = T2_e	   ;
			32'd3:  varValueOut = T3_e	   ;
			32'd4:  varValueOut = T4_e	   ;
			32'd5:  varValueOut = T5_e	   ;
			32'd6:  varValueOut = T6_e	   ;
			32'd7:  varValueOut = T7_e	   ;
			32'd8:  varValueOut = T8_e	   ;
			32'd9:  varValueOut = T9_e		 ;
			32'd10: varValueOut = T1_r		 ;
			32'd11: varValueOut = T2_r		 ;
			32'd12: varValueOut = T3_r		 ;
			32'd13: varValueOut = T4_r		 ;
			32'd14: varValueOut = T5_r		 ;
			32'd15: varValueOut = T6_r		 ;
			32'd16: varValueOut = T7_r		 ;
			32'd17: varValueOut = T8_r		 ;
			32'd18: varValueOut = T9_r		 ;
			32'd19: varValueOut = T10_r		 ;
			32'd20: varValueOut = T11_r		 ;
			32'd21: varValueOut = T12_r		 ;
			32'd22: varValueOut = T13_r		 ;
			32'd23: varValueOut = T14_r		 ;
			32'd24: varValueOut = Tgl_res  ;
			32'd25: varValueOut = T_stdby  ;
			32'd26: varValueOut = Texp_ctrl;
			32'd27: varValueOut = NumPat   ;
			32'd28: varValueOut = T_reset  ;
			32'd29: varValueOut = NumRow   ;
			32'd30: varValueOut = Tlat1     ;
			32'd31: varValueOut = Tlat2    ;
			32'd32: varValueOut = NL		 ;
			32'd33: varValueOut = NR		 ;
            32'd34:  varValueOut = mem_pat;
            32'd35: varValueOut = DUTY1;
            32'd36: varValueOut = DUTY2;
            32'd37: varValueOut = DUTY3;
			32'd38: varValueOut = DELAY1;            			
			32'd39: varValueOut = DELAY2;            			
			32'd40: varValueOut = DELAY3;   
			32'd41: varValueOut = PERIOD;   
			32'd42: varValueOut = RO_RowStart;
			32'd43: varValueOut	= PERIOD_CLKM;
			default: varValueOut = 0;
		endcase // varAddress
	end
end

endmodule
