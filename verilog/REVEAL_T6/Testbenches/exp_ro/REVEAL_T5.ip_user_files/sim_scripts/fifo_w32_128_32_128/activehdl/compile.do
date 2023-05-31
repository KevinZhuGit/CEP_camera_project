vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm
vlib activehdl/fifo_generator_v13_2_4

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm
vmap fifo_generator_v13_2_4 activehdl/fifo_generator_v13_2_4

vlog -work xil_defaultlib  -sv2k12 \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_4 -93 \
"../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_4  -v2k5 \
"../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../../../IP/fifo_w32_128_32_128/sim/fifo_w32_128_32_128.v" \

vlog -work xil_defaultlib \
"glbl.v"

