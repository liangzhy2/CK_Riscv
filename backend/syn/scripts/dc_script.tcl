# *********************************************************************************
# Project Name : DC-SYN
# Author       : Core_kingdom
# Website      : https://blog.csdn.net/weixin_40377195
# Create Time  : 2022-08-31
# File Name    : 
# Module Name  :
# Called By    :
# Abstract     :
#
# 
# *********************************************************************************
# Modification History:
# Date         By              Version                 Change Description
# -----------------------------------------------------------------------
# 2022-08-31    Macro           1.0                     Original
#  
# *********************************************************************************

set DESIGN "CHIP_TOP"

set designkit "/project/designkit"
#设置搜索路径
set search_path "${designkit}/TSMC_90/aci/sc-x/synopsys ${designkit}/TSMC_90/aci/sc-x/symbols ${designkit}/TSMC_90/aci/sc-x/libsi ${designkit}/TSMC_90/aci/sc-x/libspm /project/CK_Riscv/libs/DP_SRAM ./ ${designkit}/TSMC_90/aci/sc-x/symbols/synopsys"   


set synthetic_library "/opt/synopsys/dc_2018/libraries/syn/dw_foundation.sldb"
#设置标准元件库
set target_library " slow.db SRAM_4096_32_ff_1.1_125.0_syn.db"     
#set link_library   "* $target_library /home/ICer/ic_prjs/CK_Riscv/libs/DP_SRAM"
set link_library   "* $target_library $synthetic_library"
#设置标准元件图标库
set symbol_library " tsmc090.sdb "  

set access_internal_pins true

#设置reports文件夹
set report_path "./reports"    
#设置outputs文件夹
set output_path "./outputs"    

# define ALIB generate directory
set_app_var alib_library_analysis_path "./work"

# svf creation
set_svf ${output_path}/${DESIGN}.svf

#读取verilog设计文件
source ./input/files.tcl

# define current block name
current_design ${DESIGN}   
#工艺库链接
link   
uniquify -force


set     design_name     [get_object_name [current_design]]

#设置线负载模型
#set_wire_load_model -name "smic18_wl10"    
# set_wire_load_mode top


#设置时钟，周期156ns，脉宽0-78ns
create_clock -period 20 -waveform {0 10} [get_ports sys_clk]  -name sys_clk    

#分频64后的时钟
#create_generated_clock  [get_pins div/clk_div] -source [get_ports sys_clk]  -divide_by 64 -name clk_div   

#延迟时间2.5ns
set_clock_latency 1.5 sys_clk 
#翻转时间0.3ns
set_clock_transition 0.3 sys_clk   
#建立时间1.5ns
set_clock_uncertainty 1.0 -setup sys_clk   
#保持时间0.3ns
set_clock_uncertainty 0.3 -hold sys_clk    

#设置输入驱动强度为0get_ports
set_drive 0 [list sys_clk sys_rst_n ]      
#设置驱动单元
#set_driving_cell -lib_cell NAND2X1  in   

#设置输入延时35ns
set_input_delay  10 -clock [get_clocks sys_clk] {sys_rst_n}   
#设置输出延时35ns
set_output_delay 10 -clock [get_clocks sys_clk] [get_ports led_test]  
#设置输出负载为2pF
set_load          2        [all_outputs]    
set_max_fanout  2000 [all_outputs] 
set_max_area 0



check_design > $report_path/check_design_before_compile.rpt
check_timing > $report_path/check_timing_before_compile.rpt


compile
compile -incremental_mapping -map_effort high

#时序描述
write_sdf -version 2.1         $output_path/${design_name}_post_dc.sdf   
write -f ddc -hier -output     $output_path/${design_name}_post_dc.ddc

#网表
write -f verilog -hier -output $output_path/${design_name}_post_dc.v   
#约束
write_sdc                      $output_path/${design_name}_post_dc.sdc  

#close svf
set_svf -off

report_constraint -all_violators -verbose          > $report_path/constraint.rpt
report_qor                > $report_path/qor.rpt
report_power              > $report_path/power.rpt
report_area               > $report_path/area.rpt
report_cell               > $report_path/cell.rpt
report_clock              > $report_path/sys_clk.rpt
report_hierarchy          > $report_path/hierarchy.rpt
report_design             > $report_path/design.rpt
report_reference          > $report_path/reference.rpt
report_timing             > $report_path/timing.rpt

check_design > $report_path/check_design_post_compile.rpt
check_timing > $report_path/check_timing_post_compile.rpt

exit
#start_gui
