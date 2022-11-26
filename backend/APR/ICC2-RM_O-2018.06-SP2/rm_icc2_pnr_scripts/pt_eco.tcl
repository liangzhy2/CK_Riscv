##########################################################################################
# Tool: IC Compiler II
# Script: pt_eco.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $PT_ECO_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PT_ECO_FROM_BLOCK_NAME} -to ${DESIGN_NAME}/${PT_ECO_BLOCK_NAME}
current_block ${DESIGN_NAME}/${PT_ECO_BLOCK_NAME}
link_block

if {$PT_ECO_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$PT_ECO_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $PT_ECO_ACTIVE_SCENARIO_LIST
}

####################################
## Common settings for this step
####################################
## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl


####################################
## Pre-PT ECO customizations
####################################
if {[file exists [which $TCL_USER_PT_ECO_PRE_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_PT_ECO_PRE_SCRIPT]"
        source $TCL_USER_PT_ECO_PRE_SCRIPT
} elseif {$TCL_USER_PT_ECO_PRE_SCRIPT != ""} {
        puts "RM-error: TCL_USER_PT_ECO_PRE_SCRIPT($TCL_USER_PT_ECO_PRE_SCRIPT) is invalid. Please correct it."
}

redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

####################################
## PT ECO
####################################
## Clear eco_change_status for all eco cells
#  -quiet used in case there is no cell with defined(eco_change_status) exists
remove_attribute [get_cell -quiet -hier -filter "defined(eco_change_status)"] eco_change_status

## PT ECO - both Freeze Silicon and Non-Freeze Silicon ECO flows are supported 
if {$PT_ECO_MODE == "freeze_silicon"} {

	puts "RM-info: Running freeze silicon PT-ECO flow"
	
	## Add and place spare cells if you haven't done so.
	#  Note : typically done much earlier; use TCL_USER_SPARE_CELL_PRE_SCRIPT to specify a script before place_opt;
	#         use TCL_USER_SPARE_CELL_POST_SCRIPT to specify a script after place_opt; 
	#	  refer to place_opt.spare_cell.tcl as an example
	
	## Enable freeze silicon ECO
	set_app_options -name design.eco_freeze_silicon_mode -value true
	set_app_options -name design.eco_allow_all_commands -value true

	## PT ECO change list; generated in PT-SI by write_changes command
	if {[file exists [which $PT_ECO_CHANGE_FILE]]} {
	        puts "RM-info: Sourcing [which $PT_ECO_CHANGE_FILE]"
	        source $PT_ECO_CHANGE_FILE
	}
	set_app_options -name design.eco_freeze_silicon_mode -value false
	
	## Check freeze silicon availability
	redirect -file ${REPORTS_DIR}/${PT_ECO_BLOCK_NAME}.check_freeze_silicon {check_freeze_silicon}
	
	## ECO placement
	place_freeze_silicon
	
} else {

	puts "RM-info: Running non-freeze silicon PT-ECO flow"
	## PT ECO change list; generated in PT-SI by write_changes -format icctcl command,
	#  which is compatible with both ICC and ICC II
	if {[file exists [which $PT_ECO_CHANGE_FILE]]} {
	        puts "RM-info: Sourcing [which $PT_ECO_CHANGE_FILE]"
	        source $PT_ECO_CHANGE_FILE
	}
	
	## Legalize ECO cells (MPI mode)
	set place_eco_cells_cmd "place_eco_cells -eco_changed_cells -legalize_only -legalize_mode minimum_physical_impact -displacement_threshold $PT_ECO_DISPLACEMENT_THRESHOLD"
	if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != "" || $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST != ""} {
		lappend place_eco_cells_cmd -remove_filler_references "$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST"
	}
	puts "RM-info: $place_eco_cells_cmd"
	eval ${place_eco_cells_cmd}

}

connect_pg_net
redirect -file ${REPORTS_DIR}/${PT_ECO_BLOCK_NAME}.check_legality {check_legality -verbose} 

## ECO routing
#  Turn off timing-driven and crosstalk-driven for ECO routing 
set_app_options -name route.global.timing_driven    -value false
set_app_options -name route.track.timing_driven     -value false
set_app_options -name route.detail.timing_driven    -value false 
set_app_options -name route.global.crosstalk_driven -value false 
set_app_options -name route.track.crosstalk_driven  -value false 
route_eco -utilize_dangling_wires true -reroute modified_nets_first_then_others -open_net_driven true 

########################################
## Reinsert filler cells in changed area
########################################
## Metal filler (decap cells)
if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != ""} {
	set create_stdcell_filler_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST] area]]
	set create_stdcell_filler_metal_cmd "create_stdcell_filler -lib_cell [list $create_stdcell_filler_metal_lib_cell_sorted]"
	if {$CHIP_FINISH_METAL_FILLER_PREFIX != ""} {
		lappend create_stdcell_filler_metal_cmd -prefix $CHIP_FINISH_METAL_FILLER_PREFIX
	}
	puts "RM-info: $create_stdcell_filler_metal_cmd"
	eval ${create_stdcell_filler_metal_cmd}
	connect_pg_net
	remove_stdcell_fillers_with_violation -post_eco true ;# -post_eco true option is required in PT-ECO flow
}

## Non-metal filler
if {$CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST != ""} {
	set create_stdcell_filler_non_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST] area]]
	set create_stdcell_filler_non_metal_cmd "create_stdcell_filler -lib_cell [list $create_stdcell_filler_non_metal_lib_cell_sorted]"
	if {$CHIP_FINISH_NON_METAL_FILLER_PREFIX != ""} {
		lappend create_stdcell_filler_non_metal_cmd -prefix $CHIP_FINISH_NON_METAL_FILLER_PREFIX
	}
	puts "RM-info: $create_stdcell_filler_non_metal_cmd"
	eval ${create_stdcell_filler_non_metal_cmd}
	connect_pg_net
}

########################################################
## Incremental signoff_create_metal_fill in changed area
########################################################
## You can perform incremental signoff_create_metal_fill here.
#  Please refer to chip_finish.tcl for details about signoff_create_metal_fill
#  Ensure to append the option "-auto_eco true" to the signoff_create_metal_fill command to refill in the automatically detected changed area
#	save_block
#	signoff_create_metal_fill -auto_eco true ...

####################################
## Post-PT ECO customizations
####################################
if {[file exists [which $TCL_USER_PT_ECO_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_PT_ECO_POST_SCRIPT]"
        source $TCL_USER_PT_ECO_POST_SCRIPT
}

if {$TCL_USER_CONNECT_PG_NET_SCRIPT != ""} {
	if {[file exists [which $TCL_USER_CONNECT_PG_NET_SCRIPT]]} {
		puts "RM-info: Sourcing [which $TCL_USER_CONNECT_PG_NET_SCRIPT]"
  		source $TCL_USER_CONNECT_PG_NET_SCRIPT
	} else {
		puts "RM-error: TCL_USER_CONNECT_PG_NET_SCRIPT($TCL_USER_CONNECT_PG_NET_SCRIPT) is invalid. Please correct it."
	}
} else {
	connect_pg_net
	# For non-MV designs with more than one PG, you should use connect_pg_net in manual mode.
}

save_block
save_lib

####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


print_message_info -ids * -summary
echo [date] > pt_eco

exit 

