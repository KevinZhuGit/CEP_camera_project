vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic" \
"/nobackup/RahulGulve/softies/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/nobackup/RahulGulve/softies/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/nobackup/RahulGulve/softies/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../../../../../../../../../Documents/Rain/T5/REVEAL_T5/src/verilog/REVEAL_T5/Work_Dir/REVEAL_T5.ip_user_files/ipstatic" \
"../../../../../../IP/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../../../IP/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

