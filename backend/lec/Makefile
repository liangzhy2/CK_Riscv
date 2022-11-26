# *********************************************************************************
# Project Name : FM Makefile
# Author       : Core_kingdom
# Website      : https://blog.csdn.net/weixin_40377195
# Create Time  : 2022-11-26
# File Name    : .v
# Module Name  :
# Called By    :
# Abstract     :
#
# 
# *********************************************************************************
# Modification History:
# Date         By              Version                 Change Description
# -----------------------------------------------------------------------
# 2022-11-26    Macro           1.0                     Original
#  
# *********************************************************************************

setup:
	@ test -d logs    | mkdir -p logs
	@ test -d scripts | mkdir -p scripts


gen_file: setup
	@ fm_mk_script ../syn/outputs/CHIP_TOP.svf -o ./scripts/rtl2syn.tcl

run: setup
	@ fm_shell -f ./scripts/rtl2syn.tcl | tee -i ./logs/rtl2syn.log

gui:
	@ fm_shell -gui

clean:
	@ rm -rf ./*.log 
	@ rm -rf ./formality_svf
