# -----------------------------------------------------------------------------
# create_project.tcl  -  (re)creates the Radiant project lscc/pinout_check.rdf
# Run with Radiant 2026.1:   radiantc scripts/create_project.tcl
# The project file and implementation folder are deleted and rebuilt; sources
# are referenced in place.
# -----------------------------------------------------------------------------
set root [file normalize [file join [file dirname [info script]] ..]]
set prj  pinout_check
set dir  [file join $root lscc]

if {[file exists [file join $dir $prj.rdf]]} {
  file delete -force [file join $dir $prj.rdf] [file join $dir impl_1] \
                     [file join $dir ${prj}1.sty] [file join $dir .setting.ini]
}
file mkdir $dir

# prj_create changes the working directory, so only absolute paths below
prj_create -name $prj -impl impl_1 -dev LFCPNX-100-9CBG256I \
           -performance 9_High-Performance_1.0V -synthesis synplify -dir $dir

# Lattice IP (generated for LFCPNX-100-9CBG256I)
foreach ipx {
  src/ip/osc_clk/osc_clk.ipx
  src/ip/sys_pll/sys_pll.ipx
  src/ip/lpddr4_mc/lpddr4_mc.ipx
  src/ip/csi2_rx_2l_1500/csi2_rx_2l_1500.ipx
  src/ip/eth_2p5g_lane0/eth_2p5g_lane0.ipx
} {
  prj_add_source [file join $root $ipx]
}

prj_add_source [file join $root src rtl pinout_check_top.sv]

prj_add_source [file join $root constraints pinout_check.sdc]
prj_add_source [file join $root constraints pinout_check.pdc]

prj_set_top_module pinout_check_top
prj_save
prj_close
