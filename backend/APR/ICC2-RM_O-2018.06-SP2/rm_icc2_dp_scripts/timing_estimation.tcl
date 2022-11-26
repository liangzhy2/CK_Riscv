##########################################################################################
# Tool: IC Compiler II
# Script: timing_estimation.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

################################################################################
# Open design
################################################################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${PRE_TIMING_LABEL_NAME}

save_block -hier -force \
  -label ${TIMING_ESTIMATION_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${TIMING_ESTIMATION_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${TIMING_ESTIMATION_LABEL_NAME} -ref_libs_for_edit

####################################
## Pre-timing_estimation customizations
####################################
if {[file exists [which $TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT]"
   source $TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT
} elseif {$TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT($TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT) is invalid. Please correct it."
}

if {[file exists $TCL_TIMING_ESTIMATION_SETUP_FILE]} {
   puts "RM-info : Sourcing  TCL_TIMING_ESTIMATION_SETUP_FILE ($TCL_TIMING_ESTIMATION_SETUP_FILE)"
   source -echo $TCL_TIMING_ESTIMATION_SETUP_FILE
}

####################################
# Check Design: Pre-Timing Estimation
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_TIMING_ESTIMATION}/check_design.pre_timing_estimation \
    {check_design -ems_database check_design.pre_timing_estimation.ems -checks dp_pre_timing_estimation}
}
      
################################################################################
# Run timing estimation on the entire top design to ensure quality 
################################################################################
if {$DISTRIBUTED} {
   estimate_timing -host_options block_script
} else {
   estimate_timing 
}

report_timing -mode [all_modes] -corner estimated_corner > $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt
report_qor -corner estimated_corner > $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor
report_qor -summary > $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum

if {$DP_FLOW == "hier"} {
   ################################################################################
   # Clock Trunk Planning QoR analysis based on estimated CRP and estimated timing 
   ################################################################################
   if {$CTP_DERATE_PERCENT != ""} {
      set_timing_derate -clock -early [expr (100 - $CTP_DERATE_PERCENT) / 100.00]
      set_timing_derate -clock -late  [expr (100 + $CTP_DERATE_PERCENT) / 100.00]
   }
   report_clock_trunk_qor -sort_by wns_ocv > $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.ctp.qor
}

####################################
## Post-timing_estimation customizations
####################################
if {[file exists [which $TCL_USER_TIMING_ESTIMATION_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_TIMING_ESTIMATION_POST_SCRIPT]"
   source $TCL_USER_TIMING_ESTIMATION_POST_SCRIPT
} elseif {$TCL_USER_TIMING_ESTIMATION_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_TIMING_ESTIMATION_POST_SCRIPT($TCL_USER_TIMING_ESTIMATION_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > timing_estimation

exit 
