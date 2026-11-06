set device "LFCPNX-100"
set device_int "jd5d80"
set package "CBG256"
set package_int "CBG256"
set speed "9_High-Performance_1.0V"
set speed_int "12"
set operation "Industrial"
set family "LFCPNX"
set architecture "jd5d00"
set partnumber "LFCPNX-100-9CBG256I"
set WRAPPER_INST "lscc_2p5_gbe_top_inst"
set PMI_FAMILY "LFCPNX"
set IP_OPTION "MAC + PHY"
set SPEED_SEL "16-bit GMII"
set HOST_IF "APB"
set DATA_INTERFACE "APB"
set ADDR_WIDTH 32
set DATA_WIDTH 32
set DYN_SPEED_SEL 0
set MC_ADDR_FILT 0
set TX_PAUSE_PORTS 0
set STATS_CNTR 0
set STATS_WIDTH 32
set TX_STATS_CNTR 1
set RX_STATS_CNTR 1
set FAST_MODE 0
set LOOPBACK_MODE "No Loopback"
set LANE_ID_MPPHY "AUTO"
set LANE_ID "0"
set PMA_REFCLK "sdq0_refclk"
set PHY_RX_TERM_ACDC_L0 "0b1"
set PHY_RX_DFE_BYPASS_L0 "ENABLED"
set PHY_RX_EQ_DFE_TAP1_L0 "0b00001111"
set PHY_RX_EQ_ATT_LVL_L0 "0b000"
set GEN12_ENA_POST_A1A2 "ENABLED"
set GEN12_ENA_PREA0 "ENABLED"
set GEN12_ENA_POST_A0 "ENABLED"
set GEN3_ENA_POST_A1A2 "DISABLED"
set GEN3_ENA_PREA0 "DISABLED"
set GEN3_ENA_POST_A0 "DISABLED"
set PRTAD 0
set PMI_DEPTH 8192
set DEBUG_ON 0


if { $radiant(stage) == "premap" } {

    set_false_path -from [get_ports reset_n_i]

}

if { $family eq "LAV-AT" } {
    set rst_pin_name PD
    set rstn_pin_name CD
} else {
    set rst_pin_name LSR
    set rstn_pin_name LSR
}

##############################
# 2.5G Ethernet constraints
##############################
if {($PMI_FAMILY == "LFCPNX") && ($IP_OPTION == "MAC + PHY")} {
#    create_clock -name {pad_refclkn_i}  -period 6.4   [get_ports pad_refclkn_i]
#    create_clock -name {pad_refclkp_i}  -period 6.4   [get_ports pad_refclkp_i]
#    create_clock -name {refclkn0_ext_i} -period 6.4   [get_ports refclkn0_ext_i]
#    create_clock -name {refclkp0_ext_i} -period 6.4   [get_ports refclkp0_ext_i]
#    create_clock -name {refclkn1_ext_i} -period 6.4   [get_ports refclkn1_ext_i]
#    create_clock -name {refclkp1_ext_i} -period 6.4   [get_ports refclkp1_ext_i]
#    create_clock -name {sd_pll_refclk_i} -period 6.4  [get_ports sd_pll_refclk_i]
#    create_clock -name {sysbus_clk_i}    -period 10   [get_ports sysbus_clk_i]
#    create_clock -name {phy_pcs_clkin_i} -period 6.4  [get_ports phy_pcs_clkin_i]
#
#    create_clock -name {phy_tx_clk_o} -period 5.76 [get_pins *.lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.*.u_PCSX*_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcsx*_merge.PCSX*_inst/CH*_PIPE_PCS_TXCLKOUT]
#    create_clock -name {phy_rx_clk_o} -period 5.76 [get_pins *.lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.*.u_PCSX*_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcs_merge_pcsx*_merge.PCSX*_inst/CH*_RXOUTCLK]
#
    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*tx_rx_status_sync*_inst/*u_lscc_cdc_pulse/*u_lscc_sync/*.dout*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*tx_stat_link_ok_r*/CE]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*tx_stat_link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_stat_link_ok_r*/CE]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_stat_link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_link_ok_r0*/DF]

    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/*stat*snap_r*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/rd_data_buff*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/mismtch_stretch*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*fifo_wr_discard*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*addr_mis_match_sth*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/aml/*hashbit_r*/DF]

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.PCSX*_inst.*.PCSX*_inst/CH*_PIPE_RX_CLKREQ] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*.*.lscc_2p5_gbephy_inst/*xg_txrdy_o*.*/*] \
                   -datapath_only 5.76

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.*.*.*PCSX*_inst/CH*_PIPE_PHY_STATUS] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_2p5_gbephy_inst/*phyrdy_o*/*] \
                   -datapath_only 5.76

    #set_max_delay  -from [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/tmac_buf/do_read*/Q] \
    #               -to   [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_axis2fifo/axis_tdata_r*/DF] \
    #               -datapath_only 6.4
    
    #set_max_delay  -from [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/rmac_buf/rx_byten_Z*/Q] \
    #               -to   [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/u_fifo2axis/rx_byte_en_r*io*/D] \
    #               -datapath_only 6.4


}
if {($PMI_FAMILY == "LFCPNX") && ($IP_OPTION == "MAC only")} {
#    create_clock -name {sysbus_clk_i} -period 10   [get_ports sysbus_clk_i]
#    create_clock -name {rxmac_clk_i}  -period 5.76 [get_ports rxmac_clk_i]
#    create_clock -name {txmac_clk_i}  -period 5.76 [get_ports txmac_clk_i]

    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*tx_rx_status_sync*_inst/*u_lscc_cdc_pulse/*u_lscc_sync/*.dout*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*tx_stat_link_ok_r*/CE]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*tx_stat_link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_stat_link_ok_r*/CE]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_stat_link_ok_r*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*/*u_lscc_cdc_pulse*/u_lscc_sync/*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*rx_link_ok_r0*/DF]

    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/*stat*snap_r*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/rd_data_buff*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/mismtch_stretch*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*fifo_wr_discard*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*addr_mis_match_sth*/DF]
    set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/aml/*hashbit_r*/DF]

    #set_max_delay  -from [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/tmac_buf/do_read*/Q] \
    #               -to   [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_axis2fifo/axis_tdata_r*/DF] \
    #               -datapath_only 6.4
    
    #set_max_delay  -from [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/rmac_buf/rx_byten_Z*/Q] \
    #               -to   [get_pins */lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/u_fifo2axis/rx_byte_en_r*io*/D] \
    #               -datapath_only 6.4


}
if {($PMI_FAMILY == "LFCPNX") && ($IP_OPTION == "PHY only")} {
#    create_clock -name {pad_refclkn_i}  -period 6.4   [get_ports pad_refclkn_i]
#    create_clock -name {pad_refclkp_i}  -period 6.4   [get_ports pad_refclkp_i]
#    create_clock -name {refclkn0_ext_i} -period 6.4   [get_ports refclkn0_ext_i]
#    create_clock -name {refclkp0_ext_i} -period 6.4   [get_ports refclkp0_ext_i]
#    create_clock -name {refclkn1_ext_i} -period 6.4   [get_ports refclkn1_ext_i]
#    create_clock -name {refclkp1_ext_i} -period 6.4   [get_ports refclkp1_ext_i]
#    create_clock -name {sd_pll_refclk_i} -period 6.4  [get_ports sd_pll_refclk_i]
#    create_clock -name {sysbus_clk_i}    -period 10   [get_ports sysbus_clk_i]
#    create_clock -name {phy_pcs_clkin_i} -period 6.4  [get_ports phy_pcs_clkin_i]
#    create_clock -name {phy_tx_clk_i}    -period 5.76 [get_ports phy_tx_clk_i]
#    create_clock -name {phy_rx_clk_i}    -period 5.76 [get_ports phy_rx_clk_i]
#
    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.PCSX*_inst.*.PCSX*_inst/CH*_PIPE_RX_CLKREQ] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*.*.lscc_2p5_gbephy_inst/*xg_txrdy_o*.*/*] \
                   -datapath_only 5.76

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.*.*.*PCSX*_inst/CH*_PIPE_PHY_STATUS] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_2p5_gbephy_inst/*phyrdy_o*/*] \
                   -datapath_only 5.76
}

if {($PMI_FAMILY == "LAV-AT") && ($IP_OPTION == "MAC + PHY")} {
#    create_clock -name {phy_pcs_clkin_i} -period 6.4   [get_ports phy_pcs_clkin_i]
#    create_clock -name {pad_refclkn_i}   -period 6.4   [get_ports pad_refclkn_i]
#    create_clock -name {pad_refclkp_i}   -period 6.4   [get_ports pad_refclkp_i]
#    create_clock -name {sysbus_clk_i}    -period 10    [get_ports sysbus_clk_i]
#    create_clock -name {rxmac_clk_i}     -period 5.76   [get_ports rxmac_clk_i]
#    create_clock -name {txmac_clk_i}     -period 5.76   [get_ports txmac_clk_i]
#
#    create_clock -name {phy_tx_gclk_o*} -period 6.4 [get_pins -hierarchical {*lscc_2p5_gbe_top_inst*/*.lscc_2p5_gbephy_inst*/*/lscc_mpphy_inst*/*MPPHYX*_MPQ*_merge*/*TXOUTGCLK_PLL* }]
#    create_clock -name {phy_tx_clk_o} -period 6.4 [get_pins -hierarchical {*lscc_2p5_gbe_top_inst*/*.lscc_2p5_gbephy_inst*/*/lscc_mpphy_inst*/MPPHYX*_MPQ*_merge*/*TXOUTCLK_L* }]
#    create_clock -name {phy_rx_gclk_o} -period 6.4 [get_pins -hierarchical {*lscc_2p5_gbe_top_inst*/*.lscc_2p5_gbephy_inst/*/lscc_mpphy_inst/MPPHYX*_MPQ*_merge*/RXOUTGCLK_L* }]
#    create_clock -name {phy_rx_clk_o} -period 6.4 [get_pins -hierarchical {*lscc_2p5_gbe_top_inst*/*.lscc_2p5_gbephy_inst/*/lscc_mpphy_inst/MPPHYX*_MPQ*_merge*/RXOUTCLK_L* }]
#    create_clock -name {lmmi_clk_o} -period 10 [get_pins *lscc_2p5_gbe_top_inst/*.lscc_2p5_gbephy_inst*/*/*lscc_mpphy_inst*/*_merge_lmmi_arbiter*.*lmmi_clk_o_*/Z]

    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]

    # set false related to AXI4-L
    if {($HOST_IF == "AXI4-lite")} {
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*.u_lscc_statistics_cnt/*_stat*snap_r*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*u_lscc_mac_mgmt/*axi4l_cpu_if.u_lscc_cpu_if*/*rd_data_buff_r*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/axi4l_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*u_ten_gbemac_core/mac/rmac/fsm/*mismtch_stretch_*/SP]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/axi4l_cpu_if.u_lscc_cpu_if/mc_table*reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*u_ten_gbemac_core/mac/rmac/fsm/*mismtch_stretch_*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/axi4l_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*u_ten_gbemac_core/mac/rmac/fsm/*fifo_wr_discard*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/axi4l_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*u_ten_gbemac_core/mac/rmac/fsm/*flop_addr_mis_match_*/D]
    } else {
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/*stat*snap_r*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/*rd_data_buff*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*mismtch_stretch*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*fifo_wr_discard*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/fsm/*addr_mis_match_sth*/D]
        set_false_path -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/apb_cpu_if.u_lscc_cpu_if/mc_table_*_reg*/Q] -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/u_ten_gbemac_core/mac/rmac/aml/*hashbit_r*/D]
    }

    set_max_delay  -from [get_pins -hierarchical {*lscc_2p5_gbe_top_inst/*.lscc_2p5_gbephy_inst/*/*/*.hotplug_q*.u_hotplug_ctl_q*/rx_data_en_q*_o/Q}] \
                   -to   [get_pins -hierarchical {*lscc_2p5_gbe_top_inst/*lscc_2p5_gbephy_inst/*/*/*MPPHYX*_MPQ*_merge/*RX_DATA_EN*}] \
                   -datapath_only 6.4

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.PCSX*_inst.*.PCSX*_inst/CH*_PIPE_RX_CLKREQ] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*.*.lscc_2p5_gbephy_inst/*xg_txrdy_o*.*/*] \
                   -datapath_only 5.76

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.*.*.*PCSX*_inst/CH*_PIPE_PHY_STATUS] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_2p5_gbephy_inst/*phyrdy_o*/*] \
                   -datapath_only 5.76

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_ten_gbe_mac_inst/*tx_rx_status_sync*_inst*/*.u_lscc_cdc_pulse/u_lscc_sync/*.dout*/Q] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*.lscc_ten_gbe_mac_inst/u_lscc_mac_mgmt/*u_lscc_statistics_cnt/*link_ok_r*/*] \
                   -datapath_only 5.76

}
if {($PMI_FAMILY == "LAV-AT") && ($IP_OPTION == "MAC only")} {
#    create_clock -name {sysbus_clk_i}   -period 10    [get_ports sysbus_clk_i]
#    create_clock -name {rxmac_clk_i}    -period 5.76   [get_ports rxmac_clk_i]
#    create_clock -name {txmac_clk_i}    -period 5.76   [get_ports txmac_clk_i]
#
    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]
}
if {($PMI_FAMILY == "LAV-AT") && ($IP_OPTION == "PHY only")} {
#    create_clock -name {pad_refclkn_i}  -period 6.4   [get_ports pad_refclkn_i]
#    create_clock -name {pad_refclkp_i}  -period 6.4   [get_ports pad_refclkp_i]
#    create_clock -name {sysbus_clk_i}    -period 10   [get_ports sysbus_clk_i]
#    create_clock -name {phy_pcs_clkin_i} -period 6.4  [get_ports phy_pcs_clkin_i]
#    create_clock -name {phy_tx_clk_i}    -period 5.76 [get_ports phy_tx_clk_i]
#    create_clock -name {phy_rx_clk_i}    -period 5.76 [get_ports phy_rx_clk_i]

    # set false path to lscc reset synchronizer
    set_false_path -to [get_pins -hierarchical */async_reset_mode.u_lscc_reset_async/rstn_sync*/$rstn_pin_name]

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.lscc_mpcs_top_inst.PCSX*_inst.*.PCSX*_inst/CH*_PIPE_RX_CLKREQ] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*.*.lscc_2p5_gbephy_inst/*xg_txrdy_o*.*/*] \
                   -datapath_only 5.76

    set_max_delay  -from [get_pins -hierarchical *lscc_2p5_gbe_top_inst.*.lscc_2p5_gbephy_inst.u_mpcs_ten_gbe_wrap.u_mpcs_twopointfive_gbe.*.*.*PCSX*_inst/CH*_PIPE_PHY_STATUS] \
                   -to [get_pins -hierarchical *lscc_2p5_gbe_top_inst/*lscc_2p5_gbephy_inst/*phyrdy_o*/*] \
                   -datapath_only 5.76
}



