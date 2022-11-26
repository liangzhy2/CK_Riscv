# *********************************************************************************
# Project Name : DC Makefile
# Author       : Core_kingdom
# Website      : https://blog.csdn.net/weixin_40377195
# Create Time  : 2022-08-31
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
# 2022-08-31    Macro           1.0                     Original
#  
# *********************************************************************************

setup:
	@ test -d logs  || mkdir -p logs
	@ test -d work  || mkdir -p work
	@ test -d input || mkdir -p input

generate:
	@ perl ./scripts/gen_file.pl

run: setup generate
	@ dc_shell -f scripts/dc_script.tcl | tee -i ./logs/run.log

shell:
	@ dc_shell

clean :
	@ rm -rf *.log *.svf *.txt *.log
	@ rm -rf outputs/* reports/* logs/*.log
	@ rm -rf modules_list module_file.list files.tcl 
