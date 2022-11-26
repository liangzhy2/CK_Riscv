
set_property IOSTANDARD LVCMOS33 [get_ports rstn_in]
set_property PACKAGE_PIN M4 [get_ports rstn_in]

set_property PACKAGE_PIN U22 [get_ports sclk_in]
set_property IOSTANDARD LVCMOS33 [get_ports sclk_in]

set_property SLEW SLOW [get_ports led_test]
set_property IOSTANDARD LVCMOS33 [get_ports led_test]
set_property PACKAGE_PIN N17 [get_ports led_test]



set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]




