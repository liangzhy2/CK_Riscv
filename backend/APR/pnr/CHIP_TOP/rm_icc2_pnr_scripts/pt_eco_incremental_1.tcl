##########################################################################################
# Tool: IC Compiler II
# Script: pt_eco_incremental_1.tcl
# Purpose: Galaxy incremental ECO flow - initialization
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_FROM_BLOCK_NAME} -to ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_1_BLOCK_NAME}
current_block ${DESIGN_NAME}/${PT_ECO_INCREMENTAL_1_BLOCK_NAME}
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
## eco_step_1: ICC-II
####################################
#  The following command establishes the initial design data reference (NDM, verilog, DEF) for 
#  ICC-II, StarRC, and PrimeTime
record_signoff_eco_changes -init -def

save_lib

####################################
## eco_step_1: StarRC
####################################
#  The following steps are to be done in a StarRC session
#  Purpose: generate GPD for the subsequent PT session
#	NDM_DATABASE: ${DESIGN_LIBRARY}
#	BLOCK: ${PT_ECO_INCREMENTAL_1_BLOCK_NAME}
#	ECO_MODE: YES
#	NETLIST_INCREMENTAL: YES
#	GPD: eco_step_1.gpd
#  	## Insert your standard StarRC commands here

####################################
## eco_step_1: PrimeTime
####################################
#  The following steps are to be done in a PT session
#  Purpose: write ECO change file for ICC-II
#	read_verilog ${DESIGN_LIBRARY}/${PT_ECO_INCREMENTAL_1_BLOCK_NAME}/attach/design.signoff.eco.data/design.full.v.gz
#	link
#	read_parasitics eco_step_1.gpd 
#	
#	## Source your MCMM/timing constraints here
#	update_timing -full
#
#	save_session eco_step_1 
#	set_eco_options -physical_design_path \
#	${DESIGN_LIBRARY}/${PT_ECO_BLOCK_NAME}/attach/design.signoff.eco.data/design.full.def.gz
#
#	## Insert your PT-ECO commands (physical_mode) here
#	write_changes eco_step_1.tcl



print_message_info -ids * -summary
echo [date] > pt_eco_incremental_1

exit 

