// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Wed Jul  8 06:19:36 2020
// Host        : raulgoolLinuxPC running 64-bit Ubuntu 20.04 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/raulgool/Documents/UofT/Project/CameraSystems/T6/src/vivado/IP/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a75tfgg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_400, clk_200, clk_100, clk_050, clk_022, 
  clk_015, clk_010, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_400,clk_200,clk_100,clk_050,clk_022,clk_015,clk_010,clk_in1" */;
  output clk_400;
  output clk_200;
  output clk_100;
  output clk_050;
  output clk_022;
  output clk_015;
  output clk_010;
  input clk_in1;
endmodule
