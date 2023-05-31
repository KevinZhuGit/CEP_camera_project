// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Wed Jul  8 07:32:18 2020
// Host        : raulgoolLinuxPC running 64-bit Ubuntu 20.04 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/raulgool/Documents/UofT/Project/CameraSystems/T6/src/vivado/IP/adc_ro_buffer_fifo/adc_ro_buffer_fifo_stub.v
// Design      : adc_ro_buffer_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a75tfgg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2019.2" *)
module adc_ro_buffer_fifo(wr_clk, wr_rst, rd_clk, rd_rst, din, wr_en, rd_en, 
  dout, full, empty, valid)
/* synthesis syn_black_box black_box_pad_pin="wr_clk,wr_rst,rd_clk,rd_rst,din[15:0],wr_en,rd_en,dout[15:0],full,empty,valid" */;
  input wr_clk;
  input wr_rst;
  input rd_clk;
  input rd_rst;
  input [15:0]din;
  input wr_en;
  input rd_en;
  output [15:0]dout;
  output full;
  output empty;
  output valid;
endmodule