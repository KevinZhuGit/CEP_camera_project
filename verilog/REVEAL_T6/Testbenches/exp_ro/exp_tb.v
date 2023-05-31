`timescale 1ns / 1ps

module exp_tb();
  reg clk_200;
  reg clk_200_b;
  wire trig;
  reg re_busy;

  integer cnt_busy;

  reg rst;
  initial begin
    clk_200 <= 0;
    clk_200_b <= 1;
    rst = 0;
    re_busy <= 0;
  end
  always #2.5 clk_200 = ~clk_200;
  always #2.5 clk_200_b = ~clk_200_b;


  Exposure_v0 testing(
    .rst(rst),
    .CLK(clk_200),
    .CLKB(clk_200_b),
    .NUM_ROW(176),
    .EN_STREAM(),
    .PIXDRAIN(),
    .PIXGLOB_RES(),
    .ROWADD(),
    .trigger_o(trig),
    .re_busy(re_busy),
    .T_EXP(176*20),
    .T_reset(30),
    .T_m(16),
    .T_MU(176*16),
    .CLKMPRE()
    );

    always @ (clk_200) begin
      if (trig) begin
        cnt_busy <= 0;
        re_busy <= 1;
      end else if (re_busy) begin
        if (cnt_busy>=20) begin
          re_busy <= 0;
        end
        else begin
          cnt_busy <= cnt_busy + 1;
        end
      end
    end
endmodule
