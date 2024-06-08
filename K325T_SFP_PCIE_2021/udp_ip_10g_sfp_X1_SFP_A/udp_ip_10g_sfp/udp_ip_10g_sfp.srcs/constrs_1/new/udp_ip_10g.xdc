########## CLOCK  100M ##########
set_property PACKAGE_PIN F17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

##########  ##########
#SW1
set_property PACKAGE_PIN C26 [get_ports key1]
set_property IOSTANDARD LVCMOS33 [get_ports key1]
set_false_path -from [get_ports key1]

########## LED ##########
#LD4
set_property PACKAGE_PIN A19 [get_ports {led[0]}]
#LD3
set_property PACKAGE_PIN B20 [get_ports {led[1]}]
#LD2
set_property PACKAGE_PIN A20 [get_ports {led[2]}]
#LD1
set_property PACKAGE_PIN A17 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]


########## GTX CONSTRAINTS    156.25  ##########
set_property PACKAGE_PIN F6 [get_ports gtrefclk0_p]
set_property PACKAGE_PIN F5 [get_ports gtrefclk0_n]

########## --------- SFPA ------------##########
set_property PACKAGE_PIN D14 [get_ports sfp_tx_disable]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_disable]

set_property PACKAGE_PIN B6 [get_ports sfp_rx_p]
set_property PACKAGE_PIN B5 [get_ports sfp_rx_n]
set_property PACKAGE_PIN A4 [get_ports sfp_tx_p]
set_property PACKAGE_PIN A3 [get_ports sfp_tx_n]

set_clock_groups -name async_clock -asynchronous -group [get_clocks [get_clocks -of_objects [get_pins clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]] -group [get_clocks gtrefclk0_p]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CCLK_TRISTATE TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
