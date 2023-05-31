-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
-- Date        : Wed Jul  8 06:19:36 2020
-- Host        : raulgoolLinuxPC running 64-bit Ubuntu 20.04 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/raulgool/Documents/UofT/Project/CameraSystems/T6/src/vivado/IP/clk_wiz_0/clk_wiz_0_stub.vhdl
-- Design      : clk_wiz_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a75tfgg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_wiz_0 is
  Port ( 
    clk_400 : out STD_LOGIC;
    clk_200 : out STD_LOGIC;
    clk_100 : out STD_LOGIC;
    clk_050 : out STD_LOGIC;
    clk_022 : out STD_LOGIC;
    clk_015 : out STD_LOGIC;
    clk_010 : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end clk_wiz_0;

architecture stub of clk_wiz_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_400,clk_200,clk_100,clk_050,clk_022,clk_015,clk_010,clk_in1";
begin
end;
