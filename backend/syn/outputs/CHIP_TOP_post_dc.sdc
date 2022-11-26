###################################################################

# Created by write_sdc on Sat Nov 26 03:48:05 2022

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -power mW -voltage V       \
-current mA
set_max_area 0
set_load -pin_load 2 [get_ports led_test]
create_clock [get_ports sys_clk]  -period 20  -waveform {0 10}
set_clock_latency 1.5  [get_clocks sys_clk]
set_clock_uncertainty -setup 1  [get_clocks sys_clk]
set_clock_uncertainty -hold 0.3  [get_clocks sys_clk]
set_clock_transition -min -fall 0.3 [get_clocks sys_clk]
set_clock_transition -min -rise 0.3 [get_clocks sys_clk]
set_clock_transition -max -fall 0.3 [get_clocks sys_clk]
set_clock_transition -max -rise 0.3 [get_clocks sys_clk]
set_input_delay -clock sys_clk  10  [get_ports sys_rst_n]
set_output_delay -clock sys_clk  10  [get_ports led_test]
