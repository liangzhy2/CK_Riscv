##########################################################################################
# Tool: IC Compiler II
# Script: pt_eco_incremental_2.tcl
# Purpose: Galaxy incremental ECO flow
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_1_BLOCK_NAME} -to ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}
current_block ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}
link_block

####################################
## Common settings for this step
####################################
## For non-persistent settings that need to be re-applied in a new ICC-II session 
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

####################################
## eco_step_2: ICC-II
####################################
record_signoff_eco_changes -start -input eco_step_2.tcl ;# this is the ECO change file generated from pt_eco_incremental_1.tcl
	
	########################################
	## Legalize ECO cells (MPI mode)
	########################################
	set place_eco_cells_cmd "place_eco_cells -eco_changed_cells -legalize_only -legalize_mode minimum_physical_impact -displacement_threshold $PT_ECO_DISPLACEMENT_THRESHOLD"
	if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != "" || $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST != ""} {
		lappend place_eco_cells_cmd -remove_filler_references "$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST"
	}
	puts "RM-info: $place_eco_cells_cmd"
	eval ${place_eco_cells_cmd}

	########################################
	## ECO routing
	########################################
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

	save_block

	########################################################
	## Incremental signoff_create_metal_fill in changed area
	########################################################
	## You can perform incremental signoff_create_metal_fill here.
	#  Please refer to chip_finish.tcl for details about signoff_create_metal_fill
	#  Ensure to append the option "-auto_eco true" to the signoff_create_metal_fill command to refill in the automatically detected changed area
	#	signoff_create_metal_fill -auto_eco true ...
	#	save_block 

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

record_signoff_eco_changes -stop -def
save_lib

####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	set REPORT_PREFIX $PT_ECO_INCREMENTAL_2_BLOCK_NAME
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


####################################
## eco_step_2: StarRC
####################################
#  The following steps are to be done in a StarRC session
#  Purpose: generate GPD for the subsequent PT session 
#  Note: STAR_DIRECTORY and GPD are the same as what has been used during initialization (pt_eco_incremental_1.tcl)
#
#	NDM_DATABASE: ${DESIGN_LIBRARY}
#	BLOCK: ${PT_ECO_INCREMENTAL_2_BLOCK_NAME}
#       STAR_DIRECTORY: star_${DESIGN_NAME}
#	ECO_MODE: YES
#	NETLIST_INCREMENTAL: YES
#	GPD: eco_step_1.gpd
#
#  Insert your standard StarRC commands here

####################################
## eco_step_2: PrimeTime
####################################
#  The following steps are to be done in a PT session
#  Purpose: write ECO change file for ICC-II
#	restore_session eco_step_1
#	read_eco_change ${DESIGN_LIBRARY}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}/attach/design.signoff.eco.data/design.incr.pt 
#	read_parasitics -format gpd -eco eco_step_1.gpd
#	update_timing
#	save_session eco_step_2 
#
#	#################################################################################
#	Assess Timing/DRC in PrimeTime to determine if another ECO iteration is needed.
#       If needed, continue with PT-ECO commands
#	#################################################################################
#
#	set_eco_options -physical_design_path \
#	${DESIGN_LIBRARY}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}/attach/design.signoff.eco.data/design.full.def.gz
#
#	## Insert your PT-ECO commands (physical_mode) here
#
#	write_changes eco_step_2.tcl

########################################################################
## If more iterations are needed, 
## repeat the same steps in this script (pt_eco_incremental_2.tcl)
########################################################################


print_message_info -ids * -summary
echo [date] > pt_eco_incremental_2

exit 

