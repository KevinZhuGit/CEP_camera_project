vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm
vlib activehdl/fifo_generator_v13_2_4

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm
vmap fifo_generator_v13_2_4 activehdl/fifo_generator_v13_2_4

vlog -work xil_defaultlib  -sv2k12 \
"/opt/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/opt/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_4 -93 \
"../../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../../../IP/fifo_w256_512_r32_4096_ib/sim/fifo_w256_512_r32_4096_ib.v" \

vlog -work xil_defaultlib \
"glbl.v"

