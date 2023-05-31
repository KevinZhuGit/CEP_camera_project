vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/xpm

vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap xpm questa_lib/msim/xpm

vlog -work xil_defaultlib -64 -sv \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/home/thomas/tools/Xilinx/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_tempmon.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ck_addr_cmd_delay.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_of_pre_fifo.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_cntlr.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_data.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_mux.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl_off_delay.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_skip_calib_tap.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_prbs_rdlvl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_tap_base.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_top.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_rdlvl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_group_io.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_samp.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_4lanes.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_edge.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_cc.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_po_cntlr.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrcal.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_lane.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_oclkdelay_cal.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_pd.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal_hr.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_top.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_if_post_fifo.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_edge_store.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_init.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_poc_meta.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_lim.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ip_top/mig_7series_v4_2_mem_intfc.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ip_top/mig_7series_v4_2_memc_ui_top_std.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ui/mig_7series_v4_2_ui_top.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ui/mig_7series_v4_2_ui_wr_data.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ui/mig_7series_v4_2_ui_rd_data.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ui/mig_7series_v4_2_ui_cmd.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ecc/mig_7series_v4_2_ecc_merge_enc.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ecc/mig_7series_v4_2_ecc_buf.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ecc/mig_7series_v4_2_ecc_gen.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ecc/mig_7series_v4_2_fi_xor.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ecc/mig_7series_v4_2_ecc_dec_fix.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_arb_mux.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_compare.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_mc.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_arb_select.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_arb_row_col.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_rank_mach.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_rank_common.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_col_mach.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_cntrl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_mach.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_state.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_queue.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/controller/mig_7series_v4_2_bank_common.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/clocking/mig_7series_v4_2_tempmon.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/clocking/mig_7series_v4_2_iodelay_ctrl.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/clocking/mig_7series_v4_2_clk_ibuf.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ddr3_256_32_mig_sim.v" \
"../../../../../../IP/ddr3_256_32/ddr3_256_32/user_design/rtl/ddr3_256_32.v" \

vlog -work xil_defaultlib \
"glbl.v"

