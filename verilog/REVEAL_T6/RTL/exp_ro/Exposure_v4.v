`timescale 1ns / 1ps
//flipped exp_ctrl and mask

module Exposure_v4(
  input wire rst,
  input wire CLKM,

  input wire [31:0] NUM_SUB,

  output reg EN_STREAM,
  output reg MASK_EN,
  output reg PIXDRAIN,
  output reg PIXGLOB_RES,
  output reg PIXVTG_GLOB,
  output reg PIXREAD_EN,
  output reg EXP,
  output reg PIXGSUBC,
  output reg PIXROWMASK,
  output reg DES,
  output reg SYNC,
  output reg STDBY,
  output reg [9:0]ROWADDT,
  output reg [9:0]ROWADDB,

  output reg trigger_o,
  input wire re_busy,
  input wire [31:0] T_stdby,
  input wire [31:0] T_reset,
  input wire [31:0] Tgl_res,
  input wire [31:0] Texp_ctrl,
  input wire [31:0] T1,
  input wire [31:0] T2,
  input wire [31:0] T3,
  input wire [31:0] T4,
  input wire [31:0] T5,
  input wire [31:0] T6,
  input wire [31:0] T7,
  input wire [31:0] T8,
  input wire [31:0] T9


  );


  //integer cnt_Tm;

  reg [31:0] cnt_T_reset;
  reg [31:0] cnt_Tgl_res;
  reg [31:0] cnt_Texp_ctrl;
  reg [31:0] cnt_T1;
  reg [31:0] cnt_DES;
  reg [31:0] cnt_T_stdby;
  reg [31:0] cnt_SYNC;
  reg [31:0] cnt_sub;
  reg [31:0] cnt_sub_first;
  reg [31:0] cnt_sub_ROW_3_0;
  reg [31:0] cnt_ROW;
  reg [31:0] cnt_ROW_b;
  reg [31:0] cnt_sub_MSTREAM;
  reg set_sub;
  reg MASK_ONCE;
  wire long_MASK;
  assign long_MASK = ((T7+T8)>T1);

  initial begin
    //HS_state <= 1;
    //EXP_state <= 1;
    cnt_T_stdby <= 0;
    MASK_ONCE <= 1;
    cnt_sub_MSTREAM <= 0;
    cnt_sub <= 0;
    set_sub <= 0;
    cnt_T_reset <= 0;
    cnt_Tgl_res <= 0;
    cnt_Texp_ctrl <= 0;
    cnt_ROW <= 0;
    cnt_T1 <= 0;
    cnt_DES <= 0;

    cnt_SYNC <= 0;
    cnt_sub_first <= 0;
    cnt_sub_ROW_3_0 <= 0;
  end

  reg done_exp;
  reg trig_start;

  //initial last_once <= 0;

  initial done_exp <= 0;
  initial trig_start <= 0;

  integer HS_state;
  integer EXP_state;
  //reg [2:0] HS_state;
  //reg [7:0] EXP_state;

  localparam  HS_idle = 3'b001;
  localparam  HS_start = 3'b010;
  localparam  HS_wait = 3'b100;

  localparam  EXP_idle = 8'b00000001;//1
  localparam  EXP_reset = 8'b00000010;//2
  localparam  EXP_sub_first = 8'b00000100;//4
  localparam  EXP_sub_ROW_3_0 = 8'b00001000;//8
  localparam  EXP_sub_T1_first = 8'b00010000;//16
  localparam  EXP_sub_T1_regular = 8'b00100000;//32
  localparam  EXP_exp_ctrl = 8'b01000000;//64
  localparam  EXP_stdby = 8'b10000000;



  // always @(posedge CLK) reset_r <= T_reset;
  // always @(posedge CLK) half_Tm <= T_m/2;
  // always @(posedge CLK) MU_r <= T_MU;
  // always @ (posedge CLK) EXP_r <= T_EXP;
  // always @ (posedge CLK) ROWADDT <= cnt_T_MU;
  // always @ (posedge CLK) sub_r <= NUM_SUB;
  // always @ (posedge CLK) NUM_ROW_r <= NUM_ROW;


  always @(posedge CLKM) begin
    if (rst) begin
      HS_state <= HS_idle;
      trigger_o <= 0;
      trig_start <= 0;

    end else begin
      //handshaking state machine
      case(HS_state)
        HS_idle: begin
          trigger_o <= 0;
          if (~re_busy) begin
            HS_state <= HS_start;
            trig_start <= 1;

          end else begin
            trig_start <= 0;
          end
        end

        HS_start: begin
          trigger_o <= 0;
          trig_start <= 0;

          if (done_exp) begin
          //if (done_exp && ~MU_busy) begin
            HS_state <= HS_wait;
          end
        end

        HS_wait: begin
          trigger_o <= 1;
          trig_start <= 0;

          if (re_busy) begin
            HS_state <= HS_idle;
          end
        end

        default: begin

          HS_state <= HS_idle;
        end
      endcase
    end
  end

  always @ (posedge CLKM) begin
    if (rst) begin
      done_exp <= 0;
      set_sub <= 0;
      cnt_sub <= 0;
      cnt_T_reset <= 0;
      cnt_Tgl_res <= 0;
      cnt_Texp_ctrl <= 0;
      cnt_T1 <= 0;
      cnt_DES <= 0;
      cnt_T_stdby <= 0;
      cnt_SYNC <= 0;
      cnt_sub_first <= 0;
      cnt_sub_ROW_3_0 <= 0;
      cnt_ROW <= 0;
      cnt_ROW_b <= 322;
      cnt_sub_MSTREAM <= 0;
      MASK_ONCE <= 1;
      EXP_state <= EXP_idle;
    end else begin
      case (EXP_state)
        EXP_idle: begin
          done_exp <= 0;
          if (trig_start) begin
            EXP_state <= EXP_reset;
          end
        end

        EXP_reset: begin
          cnt_T_stdby <= 0;
          MASK_ONCE <= 1;
          done_exp <= 0;
          cnt_sub_MSTREAM <= 0;
          set_sub <= 0;
          cnt_sub <= 0;
          cnt_T_reset <= 0;
          cnt_Tgl_res <= 0;
          cnt_Texp_ctrl <= 0;
          cnt_T1 <= 0;
          cnt_DES <= 0;
          cnt_SYNC <= 0;
          cnt_sub_first <= 0;
          cnt_sub_ROW_3_0 <= 0;
          cnt_ROW <= 0;
      		cnt_ROW_b <= 322;
          if (cnt_T_reset >= T_reset-1) begin
            cnt_T_reset <= 0;
            EXP_state <= EXP_sub_first;
          end else begin
            cnt_T_reset <= cnt_T_reset + 1;
          end

        end

        EXP_sub_first: begin
          cnt_Tgl_res <= cnt_Tgl_res + 1;
          if (cnt_sub_first >= T1*160+Texp_ctrl+62) begin
            cnt_sub_first <= 0;
            EXP_state <= EXP_sub_ROW_3_0;
          end else begin
            cnt_sub_first <= cnt_sub_first + 1;
          end
        end

        EXP_exp_ctrl: begin
          if (cnt_Texp_ctrl >= Texp_ctrl-1) begin
            cnt_Texp_ctrl <= 0;
            set_sub <= 0;
            //if (cnt_sub >= NUM_SUB) begin
            //  EXP_state <= EXP_stdby;
            //end else begin
            EXP_state <= EXP_sub_ROW_3_0;
            //end
          end else begin
            cnt_Texp_ctrl <= cnt_Texp_ctrl + 1;
          end
        end

        EXP_sub_ROW_3_0: begin
          if (~set_sub) begin
            set_sub <= 1;
            cnt_sub <= cnt_sub + 1;
          end
          if (cnt_sub_ROW_3_0 >= T1*4-1) begin
            cnt_sub_ROW_3_0 <= 0;
            EXP_state <= EXP_sub_T1_first;
          end else begin
            cnt_sub_ROW_3_0 <= cnt_sub_ROW_3_0 + 1;
          end

        end

        EXP_sub_T1_first: begin
          if (cnt_T1 >= T1-1) begin
            cnt_T1 <= 0;
            //cnt_ROW <= cnt_ROW + 4;
            cnt_ROW <= cnt_ROW + 8;
            cnt_ROW_b <= cnt_ROW_b + 8;
            MASK_ONCE <= 1;
           	EXP_state <= EXP_sub_T1_regular;
          end else begin
            cnt_T1 <= cnt_T1 + 1;
          end
        end

        EXP_sub_T1_regular: begin
          if (MASK_ONCE && cnt_T1 >= T7+T8-T1) begin
            MASK_ONCE <= 0;
          end
          if (cnt_T1 >= T1-1) begin
            cnt_T1 <= 0;


            if (cnt_sub_MSTREAM >= 2) begin
              cnt_sub_MSTREAM <= 0;
              //if (cnt_ROW >= 320) begin
              if (cnt_ROW >= 320) begin
                cnt_ROW <= 0;
      			cnt_ROW_b <= 322;
                if (cnt_sub>=NUM_SUB) begin
                    EXP_state <= EXP_stdby;
                end else begin
                    EXP_state <= EXP_exp_ctrl;
                end

              end else begin
                EXP_state <= EXP_sub_T1_first;
              end
            end else begin
              cnt_sub_MSTREAM <= cnt_sub_MSTREAM + 1;
              EXP_state <= EXP_sub_T1_regular;
            end
            //EXP_state <= EXP_sub_T1_regular;
          end else begin
            cnt_T1 <= cnt_T1 + 1;
          end
        end



        EXP_stdby: begin
          if (cnt_T_stdby >= T_stdby-1) begin
            cnt_T_stdby <= 0;
            done_exp <= 1;
            EXP_state <= EXP_idle;
          end else begin
            cnt_T_stdby <= cnt_T_stdby + 1;
          end
        end
        default: begin
          EXP_state <= EXP_idle;
        end

      endcase
    end
  end

  always @ (posedge CLKM) begin
    case (EXP_state)
      EXP_idle: begin
        STDBY    		<= 0;
        EXP      		<= 1;
        PIXDRAIN 		<= 1;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 1;
        PIXROWMASK  <= 0;
        DES         <= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= 0;
        ROWADDB 			<= 0;
        PIXGSUBC 		<= 0;
      end

      EXP_reset: begin
        STDBY 			<= 1;
        EXP 				<= 1;
        PIXDRAIN 		<= 1;
        PIXGLOB_RES <= 1;
        PIXVTG_GLOB <= 1;
        PIXREAD_EN  <= 0;
        PIXROWMASK 	<= 0;
        DES 				<= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= 0;
        ROWADDB 			<= 0;
        PIXGSUBC 		<= 0;
      end

      EXP_sub_first: begin
        STDBY 			<= 1;
        EXP 				<= 0;
        PIXDRAIN 		<= 0;
        PIXGSUBC 		<= 0;
        PIXGLOB_RES <= (cnt_Tgl_res < Tgl_res) ? 1 : 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        PIXROWMASK  <= 0;
        DES 				<= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= 0;
        ROWADDB 			<= 0;
      end

      EXP_sub_ROW_3_0: begin
        STDBY 			<= 1;
        PIXROWMASK 	<= 0;
        PIXGSUBC 		<= 0;
        //PIXGSUBC 		<= (cnt_sub_ROW_3_0 < T9) ? 1 : 0;
        EXP 				<= 0;
        PIXDRAIN 		<= 0;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        DES 				<= (((cnt_sub_ROW_3_0 < (T1+T2+T3)) && (cnt_sub_ROW_3_0 >= (T1+T2))) || ((cnt_sub_ROW_3_0 < (T1+T1+T2+T3)) && (cnt_sub_ROW_3_0 >= (T1+T1+T2))) || ((cnt_sub_ROW_3_0 < (T1+T1+T1+T2+T3)) && (cnt_sub_ROW_3_0 >= (T1+T1+T1+T2)))) ? 1 : 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 1;
        ROWADDT 			<= (cnt_sub_ROW_3_0 < T6) ? ROWADDT : 0;
        ROWADDB 			<= (cnt_sub_ROW_3_0 < T6) ? ROWADDB : 0;
      end

      EXP_sub_T1_first: begin
        STDBY 			<= 1;
        EXP 				<= 0;
        PIXROWMASK 	<= 1;
        PIXDRAIN 		<= 0;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        PIXGSUBC 		<= (ROWADDT==312) ?( (cnt_T1 >= T4+T5 && cnt_T1 < T4+T5+T9)? 1:0):0;
        DES 				<= (cnt_T1 < (T2+T3) && cnt_T1 >= T2) ? 1 : 0;
        SYNC 				<= (cnt_T1 < (T4+T5) && cnt_T1 >= T4) ? 1 : 0;
        MASK_EN 		<= (cnt_T1 < (T7+T8) && cnt_T1 >= T7) ? 1 : 0;
        //EN_STREAM <= (cnt_T1 < (T7+T8) && cnt_T1 >= T7) ? 1 : 0;
        EN_STREAM 	<= (cnt_ROW==312)? 0:1;
        ROWADDT 			<= (cnt_T1 < T6) ? ROWADDT : cnt_ROW[9:0];
        ROWADDB 			<= (cnt_T1 < T6) ? ROWADDB : cnt_ROW_b[9:0];
      end

      EXP_sub_T1_regular: begin
        STDBY 			<= 1;
        DES 				<= (ROWADDT<312)?((cnt_T1 < (T2+T3) && cnt_T1 >= T2) ? 1 : 0):0;
        SYNC 				<= 0;
        MASK_EN 		<= (long_MASK) ? ((cnt_T1 < (T7+T8-T1) && MASK_ONCE) ? 1 : 0) : 0;
        //EN_STREAM <= (long_MASK) ? ((cnt_T1 < (T7+T8-T1) && MASK_ONCE) ? 1 : 0) : 0;
        EN_STREAM 	<= (ROWADDT==312)? 0:1;
        EXP 				<= 0;
        PIXDRAIN 		<= 0;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        ROWADDT 			<= ROWADDT;
        ROWADDB 			<= ROWADDB;
        PIXGSUBC 		<= 0;
      end

      EXP_exp_ctrl: begin
        STDBY 			<= 1;
        EXP 				<= 0;
        PIXROWMASK 	<= 0;
        PIXDRAIN 		<= 0;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        PIXGSUBC 		<= 0;
        //DES 			<= (cnt_Texp_ctrl < (T2+T3) && cnt_Texp_ctrl >= T2) ? 1 : 0;
        //SYNC 			<= (cnt_Texp_ctrl < (T4+T5) && cnt_Texp_ctrl >= T4) ? 1 : 0;
        //MASK_EN 	<= (cnt_Texp_ctrl < (T7+T8) && cnt_Texp_ctrl >= T7) ? 1 : 0;
        DES 				<= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        //EN_STREAM <= (cnt_Texp_ctrl < (T7+T8) && cnt_Texp_ctrl >= T7) ? 1 : 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= ROWADDT;
        ROWADDB 			<= ROWADDB;
      end

      EXP_stdby: begin
        STDBY 			<= 0;
        EXP 				<= 0;
        PIXDRAIN 		<= 0;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        PIXROWMASK  <= 0;
        DES 				<= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= ROWADDT;
        ROWADDB 			<= ROWADDB;
        PIXGSUBC 		<= 0;
      end

      default: begin
        STDBY 			<= 0;
        EXP 				<= 1;
        PIXGSUBC 		<= 0;
        PIXDRAIN 		<= 1;
        PIXGLOB_RES <= 0;
        PIXVTG_GLOB <= 0;
        PIXREAD_EN  <= 0;
        PIXROWMASK  <= 0;
        DES 				<= 0;
        SYNC 				<= 0;
        MASK_EN 		<= 0;
        EN_STREAM 	<= 0;
        ROWADDT 			<= 0;
        ROWADDB 			<= 0;
      end

    endcase
  end

endmodule
