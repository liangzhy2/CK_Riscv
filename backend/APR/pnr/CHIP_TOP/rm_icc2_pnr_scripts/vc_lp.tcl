#################################################################################
# Tool: Verification Compiler Low Power Static Signoff Script for IC Compiler II 
# Script: vclp.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
#################################################################################

## Enable the default behavior of sh_continue_on_error to be same as DC
set_app_var sh_continue_on_error true
set_app_var handle_hanging_crossover true
set_app_var enable_local_policy_match true
set_app_var upf_iso_filter_elements_with_applies_to ENABLE
set_app_var enable_multi_driver_analysis true
set_app_var implicit_scmr_pins true
set_app_var enable_verdi_debug true


source -echo -verbose ./rm_setup/icc2_pnr_setup.tcl
set_app_var link_library $LINK_LIBRARY

read_file -netlist -top $DESIGN_NAME ${OUTPUTS_DIR}/${WRITE_DATA_BLOCK_NAME}.vc_lp.v.gz

read_upf $OUTPUTS_DIR/${WRITE_DATA_BLOCK_NAME}.upf

check_lp -stage upf
check_lp -stage design
check_lp -stage pg

report_lp -file ${REPORTS_DIR}/${DESIGN_NAME}.vc_lp_report_violations.PGNETLIST.rpt
report_lp -verbose -file ${REPORTS_DIR}/${DESIGN_NAME}.vc_lp_report_violations.PGNETLIST.verbose.rpt

puts "RM-info: End script [info script]\n"
exit
