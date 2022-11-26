##########################################################################################
# Tool: IC Compiler II
# Script: clock_trunk_planning.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Open design
####################################
puts "RM-info : Opening library ${WORK_DIR}/${DESIGN_LIBRARY}"
open_lib ${WORK_DIR}/${DESIGN_LIBRARY} -ref_libs_for_edit

open_block ${DESIGN_NAME}/${CREATE_POWER_LABEL_NAME}

save_block -hier -force \
  -label ${CLOCK_TRUNK_PLANNING_LABEL_NAME}

close_lib -purge -force -all

puts "RM-info : Opening block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${CLOCK_TRUNK_PLANNING_LABEL_NAME}"
open_block ${WORK_DIR}/${DESIGN_LIBRARY}:${DESIGN_NAME}/${CLOCK_TRUNK_PLANNING_LABEL_NAME} -ref_libs_for_edit

################################################################################
# Pre-clock trunk planning customizations
################################################################################
if {[file exists [which $TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT]"
   source $TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT
} elseif {$TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT != ""} {
   puts "RM-error:TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT($TCL_USER_CLOCK_TRUNK_PLANNING_PRE_SCRIPT) is invalid. Please correct it."
}

if {$DISTRIBUTED} {
   set HOST_OPTIONS "-host_options block_script"
} else {
   set HOST_OPTIONS ""
}

####################################
# Check Design: Pre-Clock Trunk Planning
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_CLOCK_TRUNK_PLANNING}/check_design.pre_clock_trunk_planning \
    {check_design -ems_database check_design.pre_clock_trunk_planning.ems -checks dp_pre_clock_trunk_planning}
}

################################################################################
# Run BLOCK Level CTP 
################################################################################
if {$DP_BLOCK_REFS != ""} {
   #############################################################################
   # Specify TCL_CTS_CONSTRAINTS_FILE for top level and all blocks via map file
   #############################################################################
   if {[file exists $TCL_CTS_CONSTRAINTS_FILE]} {
      redirect -file ./cts_mapfile { foreach block $DP_BLOCK_REFS { echo "$block CTS_CONSTRAINT [file normalize $TCL_CTS_CONSTRAINTS_FILE]" } }
      set_constraint_mapping_file ./cts_mapfile
   }
   eval synthesize_clock_trunk_endpoints $HOST_OPTIONS -blocks [list $DP_BLOCK_REFS] 
}
if {$DP_BB_BLOCK_REFS != ""} {
   #############################################################################
   # Manually set clock trunk endpoints for Black Boxes
   #############################################################################
   # set_clock_trunk_endpoints [options]
}

report_clock_trunk_endpoints

################################################################################
# If abutted floorplan style:
#     - enable feedthrough creation for clock nets
#     - enable feedthrough creation for blocks, EXCEPT MIB blocks
#     - create frame view for all blocks to control top level routing behavior
################################################################################
if {$FLOORPLAN_STYLE == "abutted"} {
   set_app_options -name plan.pins.exclude_clocks_from_feedthroughs -value false
   set_block_pin_constraints -allow_feedthroughs true
   save_lib -all
   # Please make the necessary edits in block_create_frame.tcl
   # By default all layers below $MIN_ROUTING_LAYER are blocked
   eval run_block_script -script ./rm_icc2_dp_scripts/block_create_frame.tcl $HOST_OPTIONS \
                         -blocks [list [concat $DP_BLOCK_REFS $DP_BB_BLOCK_REFS]]
}

################################################################################
# Run TOP Level CTP 
################################################################################
synthesize_clock_trunks

################################################################################
# Place clock pins with trunk physical guidance 
################################################################################
push_down_clock_trunks
# Freeze clock pin placement if required
# set_locked_objects [get_clock_tree_pins -scan_all_hierarchical_pins -filter is_on_physical_boundary]

################################################################################
# Post-clock trunk planning customizations
################################################################################
if {[file exists [which $TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT]"
   source $TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT
} elseif {$TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT($TCL_USER_CLOCK_TRUNK_PLANNING_POST_SCRIPT) is invalid. Please correct it."
}

save_lib -all

print_message_info -ids * -summary
echo [date] > clock_trunk_planning

exit 

