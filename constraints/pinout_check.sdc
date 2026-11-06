# -----------------------------------------------------------------------------
# pinout_check.sdc  -  pre-synthesis constraints (Synplify Pro)
# Post-route timing uses constraints/pinout_check.pdc, which declares the same
# board clocks plus the IP-internal clocks on their driver pins.
# -----------------------------------------------------------------------------
create_clock -name {ddr_refclk}   -period 10.0     [get_ports ddr_refclk_i]
create_clock -name {eth_refclk_p} -period 6.4      [get_ports eth_refclk_p]
create_clock -name {mipi_clk_p}   -period 1.333333 [get_ports mipi_clk_p]
create_clock -name {aclk}         -period 6.666667 [get_nets aclk]
create_clock -name {pclk}         -period 20.0     [get_nets pclk]
create_clock -name {byte_clk}     -period 5.333333 [get_nets byte_clk]

set_clock_groups -asynchronous \
  -group [get_clocks {ddr_refclk}] \
  -group [get_clocks {aclk}] \
  -group [get_clocks {pclk}] \
  -group [get_clocks {eth_refclk_p}] \
  -group [get_clocks {mipi_clk_p byte_clk}]
