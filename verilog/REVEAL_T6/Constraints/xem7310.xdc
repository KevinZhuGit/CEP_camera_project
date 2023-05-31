set_property PACKAGE_PIN F18 [get_ports {ddr3_dqs_p[3]}]
set_property PACKAGE_PIN K17 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN J17 [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN B21 [get_ports {ddr3_dqs_p[2]}]
set_property PACKAGE_PIN A21 [get_ports {ddr3_dqs_n[2]}]
set_property PACKAGE_PIN M22 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN N22 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN E18 [get_ports {ddr3_dqs_n[3]}]
############################################################################
# XEM7310 - Xilinx constraints file
#
# Pin mappings for the XEM7310.  Use this as a template and comment out
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2016 Opal Kelly Incorporated
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## FrontPanel Host Interface
############################################################################
set_property PACKAGE_PIN Y19 [get_ports {okHU[0]}]
set_property PACKAGE_PIN R18 [get_ports {okHU[1]}]
set_property PACKAGE_PIN R16 [get_ports {okHU[2]}]
set_property SLEW FAST [get_ports {okHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[*]}]

set_property PACKAGE_PIN W19 [get_ports {okUH[0]}]
set_property PACKAGE_PIN V18 [get_ports {okUH[1]}]
set_property PACKAGE_PIN U17 [get_ports {okUH[2]}]
set_property PACKAGE_PIN W17 [get_ports {okUH[3]}]
set_property PACKAGE_PIN T19 [get_ports {okUH[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUH[*]}]

set_property PACKAGE_PIN AB22 [get_ports {okUHU[0]}]
set_property PACKAGE_PIN AB21 [get_ports {okUHU[1]}]
set_property PACKAGE_PIN Y22 [get_ports {okUHU[2]}]
set_property PACKAGE_PIN AA21 [get_ports {okUHU[3]}]
set_property PACKAGE_PIN AA20 [get_ports {okUHU[4]}]
set_property PACKAGE_PIN W22 [get_ports {okUHU[5]}]
set_property PACKAGE_PIN W21 [get_ports {okUHU[6]}]
set_property PACKAGE_PIN T20 [get_ports {okUHU[7]}]
set_property PACKAGE_PIN R19 [get_ports {okUHU[8]}]
set_property PACKAGE_PIN P19 [get_ports {okUHU[9]}]
set_property PACKAGE_PIN U21 [get_ports {okUHU[10]}]
set_property PACKAGE_PIN T21 [get_ports {okUHU[11]}]
set_property PACKAGE_PIN R21 [get_ports {okUHU[12]}]
set_property PACKAGE_PIN P21 [get_ports {okUHU[13]}]
set_property PACKAGE_PIN R22 [get_ports {okUHU[14]}]
set_property PACKAGE_PIN P22 [get_ports {okUHU[15]}]
set_property PACKAGE_PIN R14 [get_ports {okUHU[16]}]
set_property PACKAGE_PIN W20 [get_ports {okUHU[17]}]
set_property PACKAGE_PIN Y21 [get_ports {okUHU[18]}]
set_property PACKAGE_PIN P17 [get_ports {okUHU[19]}]
set_property PACKAGE_PIN U20 [get_ports {okUHU[20]}]
set_property PACKAGE_PIN N17 [get_ports {okUHU[21]}]
set_property PACKAGE_PIN N14 [get_ports {okUHU[22]}]
set_property PACKAGE_PIN V20 [get_ports {okUHU[23]}]
set_property PACKAGE_PIN P16 [get_ports {okUHU[24]}]
set_property PACKAGE_PIN T18 [get_ports {okUHU[25]}]
set_property PACKAGE_PIN V19 [get_ports {okUHU[26]}]
set_property PACKAGE_PIN AB20 [get_ports {okUHU[27]}]
set_property PACKAGE_PIN P15 [get_ports {okUHU[28]}]
set_property PACKAGE_PIN V22 [get_ports {okUHU[29]}]
set_property PACKAGE_PIN U18 [get_ports {okUHU[30]}]
set_property PACKAGE_PIN AB18 [get_ports {okUHU[31]}]
set_property SLEW FAST [get_ports {okUHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[*]}]

set_property PACKAGE_PIN N13 [get_ports okAA]
set_property IOSTANDARD LVCMOS18 [get_ports okAA]


create_clock -period 9.920 -name okUH0 [get_ports {okUH[0]}]

set_input_delay -clock [get_clocks okUH0] -max -add_delay 8.000 [get_ports {okUH[*]}]
set_input_delay -clock [get_clocks okUH0] -min -add_delay 10.000 [get_ports {okUH[*]}]
set_multicycle_path -setup -from [get_ports {okUH[*]}] 2

set_input_delay -clock [get_clocks okUH0] -max -add_delay 8.000 [get_ports {okUHU[*]}]
set_input_delay -clock [get_clocks okUH0] -min -add_delay 2.000 [get_ports {okUHU[*]}]
set_multicycle_path -setup -from [get_ports {okUHU[*]}] 2

set_output_delay -clock [get_clocks okUH0] -max -add_delay 2.000 [get_ports {okHU[*]}]
set_output_delay -clock [get_clocks okUH0] -min -add_delay -0.500 [get_ports {okHU[*]}]

set_output_delay -clock [get_clocks okUH0] -max -add_delay 2.000 [get_ports {okUHU[*]}]
set_output_delay -clock [get_clocks okUH0] -min -add_delay -0.500 [get_ports {okUHU[*]}]


############################################################################
## System Clock
############################################################################
set_property DIFF_TERM FALSE [get_ports sys_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports sys_clk_p]

set_property DIFF_TERM FALSE [get_ports sys_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports sys_clk_n]
set_property PACKAGE_PIN W11 [get_ports sys_clk_p]
set_property PACKAGE_PIN W12 [get_ports sys_clk_n]

# LEDs #####################################################################
set_property PACKAGE_PIN A13 [get_ports {led[0]}]
set_property PACKAGE_PIN B13 [get_ports {led[1]}]
set_property PACKAGE_PIN A14 [get_ports {led[2]}]
set_property PACKAGE_PIN A15 [get_ports {led[3]}]
set_property PACKAGE_PIN B15 [get_ports {led[4]}]
set_property PACKAGE_PIN A16 [get_ports {led[5]}]
set_property PACKAGE_PIN B16 [get_ports {led[6]}]
set_property PACKAGE_PIN B17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[*]}]

# DRAM #####################################################################
set_property PACKAGE_PIN N18 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN L20 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN N20 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN K18 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN M18 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN K19 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN N19 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN L18 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN L16 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN L14 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN K14 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN M15 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN K16 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN M13 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN K13 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN L13 [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN D22 [get_ports {ddr3_dq[16]}]
set_property PACKAGE_PIN C20 [get_ports {ddr3_dq[17]}]
set_property PACKAGE_PIN E21 [get_ports {ddr3_dq[18]}]
set_property PACKAGE_PIN D21 [get_ports {ddr3_dq[19]}]
set_property PACKAGE_PIN G21 [get_ports {ddr3_dq[20]}]
set_property PACKAGE_PIN C22 [get_ports {ddr3_dq[21]}]
set_property PACKAGE_PIN E22 [get_ports {ddr3_dq[22]}]
set_property PACKAGE_PIN B22 [get_ports {ddr3_dq[23]}]
set_property PACKAGE_PIN A20 [get_ports {ddr3_dq[24]}]
set_property PACKAGE_PIN D19 [get_ports {ddr3_dq[25]}]
set_property PACKAGE_PIN A19 [get_ports {ddr3_dq[26]}]
set_property PACKAGE_PIN F19 [get_ports {ddr3_dq[27]}]
set_property PACKAGE_PIN C18 [get_ports {ddr3_dq[28]}]
set_property PACKAGE_PIN E19 [get_ports {ddr3_dq[29]}]
set_property PACKAGE_PIN A18 [get_ports {ddr3_dq[30]}]
set_property PACKAGE_PIN C19 [get_ports {ddr3_dq[31]}]
set_property SLEW FAST [get_ports {ddr3_dq[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[*]}]

set_property PACKAGE_PIN J21 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN J22 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN K21 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN H22 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN G13 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN G17 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN H15 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN G16 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN G20 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN M21 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN J15 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN G15 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN H13 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN K22 [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN L21 [get_ports {ddr3_addr[14]}]
set_property SLEW FAST [get_ports {ddr3_addr[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[*]}]

set_property PACKAGE_PIN H18 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN J19 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN H19 [get_ports {ddr3_ba[2]}]
set_property SLEW FAST [get_ports {ddr3_ba[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[*]}]

set_property PACKAGE_PIN J16 [get_ports ddr3_ras_n]
set_property SLEW FAST [get_ports ddr3_ras_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_ras_n]

set_property PACKAGE_PIN H17 [get_ports ddr3_cas_n]
set_property SLEW FAST [get_ports ddr3_cas_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_cas_n]

set_property PACKAGE_PIN J20 [get_ports ddr3_we_n]
set_property SLEW FAST [get_ports ddr3_we_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_we_n]

set_property PACKAGE_PIN F21 [get_ports ddr3_reset_n]
set_property SLEW FAST [get_ports ddr3_reset_n]
set_property IOSTANDARD LVCMOS15 [get_ports ddr3_reset_n]

set_property PACKAGE_PIN G18 [get_ports {ddr3_cke[0]}]
set_property SLEW FAST [get_ports {ddr3_cke[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke[*]}]

set_property PACKAGE_PIN H20 [get_ports {ddr3_odt[0]}]
set_property SLEW FAST [get_ports {ddr3_odt[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[*]}]

set_property PACKAGE_PIN L19 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN L15 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN D20 [get_ports {ddr3_dm[2]}]
set_property PACKAGE_PIN B20 [get_ports {ddr3_dm[3]}]
set_property SLEW FAST [get_ports {ddr3_dm[*]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[*]}]

set_property SLEW FAST [get_ports ddr3_dqs*]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_dqs*]

set_property PACKAGE_PIN J14 [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN H14 [get_ports {ddr3_ck_n[0]}]
set_property SLEW FAST [get_ports ddr3_ck*]
set_property IOSTANDARD DIFF_SSTL15 [get_ports ddr3_ck_*]

# GPIOs #####################################################################

#Bank 34
#MC1 51
set_property PACKAGE_PIN V2 [get_ports {TestIO[1]}]
#MC1 49
set_property PACKAGE_PIN U2 [get_ports {TestIO[2]}]
#MC1 45
set_property PACKAGE_PIN Y3 [get_ports {TestIO[3]}]
#MC1 43
set_property PACKAGE_PIN R2 [get_ports {TestIO[4]}]
#MC1 41
set_property PACKAGE_PIN R3 [get_ports {TestIO[5]}]
#MC1 37
set_property PACKAGE_PIN AB7 [get_ports {TestIO[6]}]
#MC1 33
set_property PACKAGE_PIN AB5 [get_ports {TestIO[7]}]
#MC1 31
set_property PACKAGE_PIN AA5 [get_ports {TestIO[8]}]
#MC1 29
set_property PACKAGE_PIN U5 [get_ports {TestIO[9]}]
#MC1 27
set_property PACKAGE_PIN T5 [get_ports {TestIO[10]}]
#MC1 25s
set_property PACKAGE_PIN V5 [get_ports {TestIO[11]}]
#MC1 23
set_property PACKAGE_PIN U6 [get_ports {TestIO[12]}]
#MC1 21
set_property PACKAGE_PIN T6 [get_ports {TestIO[13]}]
#Rest of the testIOs are connected to LASERIO
#TestIO LaserIO
#14     2
#15     4
#16     6
#17     14
#18     12
#19     10
#20     8
#--     9
#--     11

#MC1 19
set_property PACKAGE_PIN R6 [get_ports {TestIO[14]}]
#MC1 17
set_property PACKAGE_PIN Y9 [get_ports {TestIO[15]}]
#MC1 15
set_property PACKAGE_PIN W9 [get_ports {TestIO[16]}]
#MC1 20
set_property PACKAGE_PIN V7 [get_ports {TestIO[17]}]
#MC1 22
set_property PACKAGE_PIN W7 [get_ports {TestIO[18]}]
#MC1 24
set_property PACKAGE_PIN Y8 [get_ports {TestIO[19]}]
#MC1 26
set_property PACKAGE_PIN Y7 [get_ports {TestIO[20]}]

set_property IOSTANDARD LVCMOS33 [get_ports {TestIO[*]}]

#MC1 16
set_property PACKAGE_PIN V9 [get_ports LaserIO_9]
set_property IOSTANDARD LVCMOS33 [get_ports LaserIO_9]
#MC1 18
set_property PACKAGE_PIN V8 [get_ports LaserIO_11]
set_property IOSTANDARD LVCMOS33 [get_ports LaserIO_11]


####################################################
###################### IMAGER ######################
####################################################

######### MASKING ############
#MC2 61
set_property PACKAGE_PIN A1 [get_ports MASK_EN]
set_property IOSTANDARD LVCMOS12 [get_ports MASK_EN]
#MC2 59
set_property PACKAGE_PIN B1 [get_ports CLKM]
set_property IOSTANDARD LVCMOS12 [get_ports CLKM]
#MC2 49
set_property PACKAGE_PIN E2 [get_ports DES]
set_property IOSTANDARD LVCMOS12 [get_ports DES]
#MC2 65
set_property PACKAGE_PIN J4 [get_ports SYNC]
set_property IOSTANDARD LVCMOS12 [get_ports SYNC]
#MC1 50
set_property PACKAGE_PIN U3 [get_ports RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_N]


#mSTREAM <1:16>
#MC2 34
set_property PACKAGE_PIN J6 [get_ports {mSTREAM[1]}]
#MC2 58
set_property PACKAGE_PIN D1 [get_ports {mSTREAM[2]}]
#MC2 52
set_property PACKAGE_PIN F1 [get_ports {mSTREAM[3]}]
#MC2 54
set_property PACKAGE_PIN E1 [get_ports {mSTREAM[4]}]
#MC2 50
set_property PACKAGE_PIN G1 [get_ports {mSTREAM[5]}]
#MC2 46
set_property PACKAGE_PIN H2 [get_ports {mSTREAM[6]}]
#MC2 63
set_property PACKAGE_PIN K4 [get_ports {mSTREAM[7]}]
#MC2 57
set_property PACKAGE_PIN E3 [get_ports {mSTREAM[8]}]
#MC2 51
set_property PACKAGE_PIN D2 [get_ports {mSTREAM[9]}]
#MC2 45
set_property PACKAGE_PIN H3 [get_ports {mSTREAM[10]}]
#MC2 47
set_property PACKAGE_PIN G3 [get_ports {mSTREAM[11]}]
#MC2 43
set_property PACKAGE_PIN J1 [get_ports {mSTREAM[12]}]
#MC2 37
set_property PACKAGE_PIN K2 [get_ports {mSTREAM[13]}]
#MC2 39
set_property PACKAGE_PIN J2 [get_ports {mSTREAM[14]}]
#MC2 32
set_property PACKAGE_PIN K6 [get_ports {mSTREAM[15]}]
#MC2 41
set_property PACKAGE_PIN K1 [get_ports {mSTREAM[16]}]

set_property IOSTANDARD LVCMOS12 [get_ports {mSTREAM[*]}]


######### ROWDRIVER ############
#MC1 62 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AB2 [get_ports PIXREAD_EN]
set_property IOSTANDARD LVCMOS33 [get_ports PIXREAD_EN]
#MC1 58 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN Y1 [get_ports PIXLEFTBUCK_SEL]
set_property IOSTANDARD LVCMOS33 [get_ports PIXLEFTBUCK_SEL]

#MC2 62
set_property PACKAGE_PIN B2 [get_ports PIXDRAIN]
set_property IOSTANDARD LVCMOS12 [get_ports PIXDRAIN]
#MC2 60
set_property PACKAGE_PIN C2 [get_ports PIXGLOB_RES]
set_property IOSTANDARD LVCMOS12 [get_ports PIXGLOB_RES]
#MC2 44
set_property PACKAGE_PIN H5 [get_ports PIXRES]
set_property IOSTANDARD LVCMOS12 [get_ports PIXRES]
#MC2 42
set_property PACKAGE_PIN J5 [get_ports PIXVTG_GLOB]
set_property IOSTANDARD LVCMOS12 [get_ports PIXVTG_GLOB]
#MC2 38
set_property PACKAGE_PIN L3 [get_ports PIX_GSUBC]
set_property IOSTANDARD LVCMOS12 [get_ports PIX_GSUBC]
#MC2 40
set_property PACKAGE_PIN K3 [get_ports PIX_ROWMASK]
set_property IOSTANDARD LVCMOS12 [get_ports PIX_ROWMASK]




#MC2 30
set_property PACKAGE_PIN M2 [get_ports {ROWADD[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[0]}]
#MC2 26
set_property PACKAGE_PIN P1 [get_ports {ROWADD[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[1]}]
#MC2 22
set_property PACKAGE_PIN N2 [get_ports {ROWADD[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[2]}]
#MC2 24
set_property PACKAGE_PIN R1 [get_ports {ROWADD[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[3]}]
#MC2 28
set_property PACKAGE_PIN M3 [get_ports {ROWADD[4]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[4]}]
#MC2 20
set_property PACKAGE_PIN P2 [get_ports {ROWADD[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[5]}]
#MC2 18
set_property PACKAGE_PIN N5 [get_ports {ROWADD[6]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[6]}]
#MC2 16
set_property PACKAGE_PIN P6 [get_ports {ROWADD[7]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[7]}]
#MC2 53
set_property PACKAGE_PIN F3 [get_ports {ROWADD[8]}]
set_property IOSTANDARD LVCMOS12 [get_ports {ROWADD[8]}]
#MC1 64 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN Y13 [get_ports {ROWADD[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ROWADD[9]}]


########### READOUT ##############
#MC1 70 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AB13 [get_ports COL_L_EN]
set_property IOSTANDARD LVCMOS33 [get_ports COL_L_EN]
#MC2 21
set_property PACKAGE_PIN N3 [get_ports PGA_RES]
set_property IOSTANDARD LVCMOS12 [get_ports PGA_RES]
#MC2 25
set_property PACKAGE_PIN L4 [get_ports CK_PH1]
set_property IOSTANDARD LVCMOS12 [get_ports CK_PH1]
#MC2 17
set_property PACKAGE_PIN P4 [get_ports SAMP_R]
set_property IOSTANDARD LVCMOS12 [get_ports SAMP_R]
#MC2 29
set_property PACKAGE_PIN M5 [get_ports SAMP_S]
set_property IOSTANDARD LVCMOS12 [get_ports SAMP_S]
#MC2 19
set_property PACKAGE_PIN N4 [get_ports READ_R]
set_property IOSTANDARD LVCMOS12 [get_ports READ_R]
#MC2 15
set_property PACKAGE_PIN P5 [get_ports READ_S]
set_property IOSTANDARD LVCMOS12 [get_ports READ_S]
#MC1 68 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AA13 [get_ports STDBY]
set_property IOSTANDARD LVCMOS33 [get_ports STDBY]
#MC2 31
set_property PACKAGE_PIN M1 [get_ports MUX_START]
set_property IOSTANDARD LVCMOS12 [get_ports MUX_START]
#MC2 27
set_property PACKAGE_PIN M6 [get_ports RO_CLK_100]
set_property IOSTANDARD LVCMOS12 [get_ports RO_CLK_100]
#MC2 48
set_property PACKAGE_PIN G2 [get_ports CP_COLMUX_IN]
set_property IOSTANDARD LVCMOS12 [get_ports CP_COLMUX_IN]


#MC2 23
set_property PACKAGE_PIN L5 [get_ports COL_PRECH]
set_property IOSTANDARD LVCMOS12 [get_ports COL_PRECH]


########### ToF ##############
#MC1 66 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AA14 [get_ports EXP]
set_property IOSTANDARD LVCMOS33 [get_ports EXP]
#MC2 77
set_property PACKAGE_PIN H4 [get_ports FPGA_MOD0]
set_property IOSTANDARD LVCMOS12 [get_ports FPGA_MOD0]
#MC2 79
set_property PACKAGE_PIN G4 [get_ports FPGA_MOD90]
set_property IOSTANDARD LVCMOS12 [get_ports FPGA_MOD90]


####### IMAGE SENSOR SPI (IS-SPI) #########
#MC1 60 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AB3 [get_ports IS_SPI_DATA]
set_property IOSTANDARD LVCMOS33 [get_ports IS_SPI_DATA]
#MC1 54 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN W1 [get_ports IS_SPI_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports IS_SPI_CLK]
#MC1 48 #SLOWER SIGNAL GOING THROUGH LEVEL SHIFTER
set_property PACKAGE_PIN AB8 [get_ports IS_SPI_UPLOAD]
set_property IOSTANDARD LVCMOS33 [get_ports IS_SPI_UPLOAD]



####################################################
##################### PCB SPI ######################
####################################################

################## SPI CONTROLS ####################
#MC1 42
set_property PACKAGE_PIN Y6 [get_ports PCB_SPI_DIN]
set_property IOSTANDARD LVCMOS33 [get_ports PCB_SPI_DIN]
#MC1 44
set_property PACKAGE_PIN AA6 [get_ports PCB_SPI_DOUT]
set_property IOSTANDARD LVCMOS33 [get_ports PCB_SPI_DOUT]
#MC1 46
set_property PACKAGE_PIN AA8 [get_ports PCB_SPI_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports PCB_SPI_CLK]

############# SPI CHIP SELECT & RST ################
##### LDO #####
#MC1 30 #POT1 => VDDTG,VSSRES,VDDRES,VREF_PC
set_property PACKAGE_PIN W5 [get_ports CS_POT1]
set_property IOSTANDARD LVCMOS33 [get_ports CS_POT1]
#MC1 28 #POT2 => VDDPIX,AVDD33,VREF_SAMP1,VREF_SAMP2
set_property PACKAGE_PIN W6 [get_ports CS_POT2]
set_property IOSTANDARD LVCMOS33 [get_ports CS_POT2]
#MC1 34 #POT 1&2  RESET
set_property PACKAGE_PIN T4 [get_ports RS_POT]
set_property IOSTANDARD LVCMOS33 [get_ports RS_POT]
#MC1 32 #ADC FOR LDO
set_property PACKAGE_PIN R4 [get_ports CS_ADC_LDO]
set_property IOSTANDARD LVCMOS33 [get_ports CS_ADC_LDO]


##### ADC #####
#MC1 75 #ADC1
set_property PACKAGE_PIN Y16 [get_ports CS_ADC1]
set_property IOSTANDARD LVCMOS33 [get_ports CS_ADC1]
#MC1 61 #ADC2
set_property PACKAGE_PIN U1 [get_ports CS_ADC2]
set_property IOSTANDARD LVCMOS33 [get_ports CS_ADC2]

##### PLL #####
#MC1 47
set_property PACKAGE_PIN AA3 [get_ports CS_PLL]
set_property IOSTANDARD LVCMOS33 [get_ports CS_PLL]

#### IBIAS ####
#MC1 53
set_property PACKAGE_PIN W2 [get_ports CS_IBIAS]
set_property IOSTANDARD LVCMOS33 [get_ports CS_IBIAS]


####################################################
##################### PCB ADC ######################
####################################################

##### ADC CLOCK IN  #####
#MC1 52 #CLOCK FOR ADC-1&2
set_property PACKAGE_PIN V3 [get_ports ADC_CLK_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports ADC_CLK_OUT]
#MC1 39 #CLOCK FOR LDO-ADC
set_property PACKAGE_PIN AB6 [get_ports ADC_LDO_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports ADC_LDO_CLK]

##### ADC CLOCK OUT #####
#MC1 77 #OUTPUT CLOCK OF ADC 1
set_property PACKAGE_PIN V4 [get_ports ADC1_DATA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports ADC1_DATA_CLK]
#MC2 64 #OUTPUT CLOCK OF ADC 2
set_property PACKAGE_PIN U15 [get_ports ADC2_DATA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports ADC2_DATA_CLK]

##### ADC DATA OUT #####
# REFER TO lm98722.pdf

#ADC1
#MC1 73	#DATA OUTPUT CHANNEL 0-
set_property PACKAGE_PIN AB15 [get_ports {ADC1_DATA[0]}]
#MC1 71	#DATA OUTPUT CHANNEL 0+
set_property PACKAGE_PIN AA15 [get_ports {ADC1_DATA[1]}]
#MC1 69	#DATA OUTPUT CHANNEL 1-
set_property PACKAGE_PIN AB17 [get_ports {ADC1_DATA[2]}]
#MC1 67	#DATA OUTPUT CHANNEL 1+
set_property PACKAGE_PIN AB16 [get_ports {ADC1_DATA[3]}]
#MC1 74	#DATA OUTPUT CHANNEL 2-
set_property PACKAGE_PIN W16 [get_ports {ADC1_DATA[4]}]
#MC1 72	#DATA OUTPUT CHANNEL 2+
set_property PACKAGE_PIN W15 [get_ports {ADC1_DATA[5]}]
#MC2 73	#DATA OUTPUT CLOCK -
set_property PACKAGE_PIN V14 [get_ports {ADC1_DATA[6]}]
#MC1 71	#DATA OUTPUT CLOCK +
set_property PACKAGE_PIN V13 [get_ports {ADC1_DATA[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ADC1_DATA[*]}]

#ADC2
#MC2 69	#DATA OUTPUT CHANNEL 0-
set_property PACKAGE_PIN U16 [get_ports {ADC2_DATA[0]}]
#MC2 67	#DATA OUTPUT CHANNEL 0+
set_property PACKAGE_PIN T16 [get_ports {ADC2_DATA[1]}]
#MC2 70	#DATA OUTPUT CHANNEL 1-
set_property PACKAGE_PIN T15 [get_ports {ADC2_DATA[2]}]
#MC2 68	#DATA OUTPUT CHANNEL 1+
set_property PACKAGE_PIN T14 [get_ports {ADC2_DATA[3]}]
#MC2 74	#DATA OUTPUT CHANNEL 2-
set_property PACKAGE_PIN Y14 [get_ports {ADC2_DATA[4]}]
#MC2 72	#DATA OUTPUT CHANNEL 2+
set_property PACKAGE_PIN W14 [get_ports {ADC2_DATA[5]}]
#MC2 76	#DATA OUTPUT CLOCK -
set_property PACKAGE_PIN Y12 [get_ports {ADC2_DATA[6]}]
#MC2 75	#DATA OUTPUT CLOCK +
set_property PACKAGE_PIN Y11 [get_ports {ADC2_DATA[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ADC2_DATA[*]}]

##### ADC SAMPLE AND HOLD #####
#MC1 65 #ADC1
set_property PACKAGE_PIN AB1 [get_ports ADC1_SHR]
set_property IOSTANDARD LVCMOS33 [get_ports ADC1_SHR]
#MC1 63 #ADC2
set_property PACKAGE_PIN AA1 [get_ports ADC2_SHR]
set_property IOSTANDARD LVCMOS33 [get_ports ADC2_SHR]

####################################################
##################### PCB PLL ######################
####################################################
#MC1 57 ToF SIG
set_property PACKAGE_PIN Y2 [get_ports PLL_ToF]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_ToF]
#MC1 59 PLL SYNC
set_property PACKAGE_PIN T1 [get_ports PLL_SYNC]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_SYNC]

####################################################
############### PCB LEVEL CONVERTER ################
####################################################
#MC1 76 #ENABLE LEVEL CONVERTER
set_property PACKAGE_PIN AA16 [get_ports LC_EN]
set_property IOSTANDARD LVCMOS33 [get_ports LC_EN]


############################################################################
## Disable min delay analysis
############################################################################
# set_false_path -from [get_pins **] -to [get_pins **] -hold
# set_false_path -through **
set_false_path -through [get_pins {ti40/ep_trigger_reg[*]/C}]
set_false_path -through [get_pins {wi00/ep_dataout_reg[*]/C}]
set_false_path -through [get_pins {wi15/ep_dataout_reg[*]/C}]

set_false_path -through [get_pins {wi01/ep_dataout_reg[*]/C}]
set_false_path -through [get_pins {wi10/ep_dataout_reg[*]/C}]
set_false_path -through [get_pins {i_ddr3_ctl/img_cnt_reg[*]/C}]

set_clock_groups -asynchronous -group [get_clocks {mmcm0_clk0 okUH0}] -group [get_clocks {sys_clk_p clk_pll_i}]

set_property BEL AFF [get_cells {wi16/ep_dataout_reg[0]}]
set_property BEL DFF [get_cells {i_mask_order_cache/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_reg[4]}]
set_property LOC SLICE_X63Y192 [get_cells {wi16/ep_dataout_reg[0]}]
set_property LOC SLICE_X64Y195 [get_cells {i_mask_order_cache/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_reg[4]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {wi16/ep_dataout[0]}]
