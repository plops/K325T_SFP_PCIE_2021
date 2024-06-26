##############################################################################
##      _______      _______                                                ##
##     / ____\ \    / /_   _|                                               ##
##    | |  __ \ \  / /  | |                                                 ##
##    | | |_ | \ \/ /   | |                                                 ##
##    | |__| |  \  /   _| |_                                                ##
##     \_____|   \/   |_____|                                               ##
##                                                                          ##
## Copyright (c) 2012-2015 GVI.  All rights reserved.                       ##
##                                                                          ##
## THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY   ##
## KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE      ##
## IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A               ##
## PARTICULAR PURPOSE.                                                      ##
##                                                                          ##
## Website: http://www.gvi-tech.com/                                        ##
## Email: support@gvi-tech.com                                              ##
##                                                                          ##
##############################################################################

# Xilinx AR 62034: this is a workaround for Vivado version 2014.2 and 2014.3.
# This issue will be fixed in the Vivado 2014.4 release

#set_property IOSTANDARD LVCMOS25 [get_ports emcclk]
#set_property PACKAGE_PIN B26 [get_ports emcclk]

set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type2 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property CFGBVS VCCO [current_design]

set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
set_property PACKAGE_PIN N16 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports link_up]
set_property PACKAGE_PIN U22 [get_ports link_up]

set_property PACKAGE_PIN U21 [get_ports Dbg_LED]
set_property IOSTANDARD LVCMOS33 [get_ports Dbg_LED]


##############################################################################
# Start: PCIE Related Constraints
##############################################################################

set_property PACKAGE_PIN D6 [get_ports pcie_refclkin_p]
set_property PACKAGE_PIN D5 [get_ports pcie_refclkin_n]

set_property LOC PCIE_X0Y0 [get_cells inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/pcie_top_i/pcie_7x_i/pcie_block_i]
# set_property LOC IBUFDS_GTE2_X0Y1 [get_cells {inst_gvi_pcie/pcie_wrapper/refclk_ibuf}]
# PCIe Lane 0
set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells {inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN B6 [get_ports {pci_exp_rxp[0]}]
# PCIe Lane 1
set_property LOC GTXE2_CHANNEL_X0Y6 [get_cells {inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN C4 [get_ports {pci_exp_rxp[1]}]
# PCIe Lane 2
set_property LOC GTXE2_CHANNEL_X0Y5 [get_cells {inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN E4 [get_ports {pci_exp_rxp[2]}]
# PCIe Lane 3
set_property LOC GTXE2_CHANNEL_X0Y4 [get_cells {inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN G4 [get_ports {pci_exp_rxp[3]}]


create_clock -period 10.000 [get_pins {inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK}]
#
set_false_path -through [get_pins inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/pcie_top_i/pcie_7x_i/pcie_block_i/PLPHYLNKUPN]
set_false_path -through [get_pins inst_gvi_pcie/pcie_wrapper/pcie_k7_gen2x4/U0/inst/pcie_top_i/pcie_7x_i/pcie_block_i/PLRECEIVEDHOTRST]

#------------------------------------------------------------------------------
# Asynchronous Paths
#------------------------------------------------------------------------------
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXELECIDLE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXPHINITDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXPHALIGNDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXDLYSRESETDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXDLYSRESETDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXPHALIGNDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXCDRLOCK]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/CFGMSGRECEIVEDPMETO]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/CPLLLOCK]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/QPLLLOCK]


create_clock -period 10.000 -name pcie_ref_clk [get_ports pcie_refclkin_p]

set_false_path -to [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0]
set_false_path -to [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1]

create_generated_clock -name clk_125mhz_x0y0 [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/mmcm_i/CLKOUT0]
create_generated_clock -name clk_250mhz_x0y0 [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/mmcm_i/CLKOUT1]
create_generated_clock -name clk_125mhz_mux_x0y0 -source [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0] -divide_by 1 [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]
#
create_generated_clock -name clk_250mhz_mux_x0y0 -source [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1] -divide_by 1 -add -master_clock clk_250mhz_x0y0 [get_pins inst_gvi_pcie/pcie_wrapper/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]
#
set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0
set_false_path -from [get_ports sys_rst_n]

##############################################################################
# END: PCIE Related Constraints
##############################################################################



set_operating_conditions -voltage {vcco33 1.500}


set_property IOSTANDARD LVCMOS25 [get_ports emcclk]


set_property CONFIG_MODE BPI16 [current_design]








