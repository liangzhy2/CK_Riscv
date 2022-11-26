puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: mcmm_example.explicit.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## Note :
#  1. To see the full list of mode / corner / scenario specific commands, 
#      refer to SolvNet 1777585 : "Multicorner-multimode constraint classification" 
#
#  2. Corner operating conditions are recommended to be specified directly through 
#     set_process_number, set_voltage and set_temperature
#
#	The PVT resolution function always finds the closest PVT match between the operating conditions and 
#      	the library pane.
#	A Corner operating condition may be specified directly with the set_process_number, set_voltage and 
#	set_temperature commands or indirectly with the set_operating_conditions command.
#	The set_process_label command may be used to distinguish between library panes with the same PVT 
#	values but different process labels.

##############################################################################################
# The following is a sample script to create one shared mode, two corners, and two scenarios,
# with mode, corner, and scenario constraints all explicitly provided, 
# which you can expand to accomodate your design.

# Reading of the TLUPlus files should be done beforehand,
# so the parasitic models can be referred to in the constraints.
# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
# read_parasitic_tech_example.tcl is provided as an example.
##############################################################################################

########################################
## Variables
########################################
## Mode constraints; expand the section as needed
set mode1 				"" ;# name for mode1	
set mode_constraints($mode1)            "" ;# for mode1 specific SDC constraints

## Corner constraints; expand it as needed
set corner1 				"" ;# name of corner1	
set corner_constraints($corner1)        "" ;# for corner1 specific SDC constraints 

set corner2 				"" ;# name of corner2	
set corner_constraints($corner2)        "" ;# for corner2 specific SDC constraints 

## Scenario constraints; expand it as needed; "::" is used as the separator following time.scenario_auto_name_separator default
set scenario1 				"${mode1}::${corner1}" ;# scenario1 with mode1 and corner1
set scenario_constraints($scenario1)    "" ;# for scenario1 specific SDC constraints

set scenario2 				"${mode1}::${corner2}" ;# scenario1 with mode1 and corner2
set scenario_constraints($scenario2)    "" ;# for scenario2 specific SDC constraints

########################################
## Create modes, corners, and scenarios first
########################################
remove_modes -all; remove_corners -all; remove_scenarios -all

foreach m [array name mode_constraints] {
	puts "RM-info: create_mode $m"
	create_mode $m
}

foreach c [array name corner_constraints] {
	puts "RM-info: create_corner $c"
	create_corner $c
}

foreach s [array name scenario_constraints] {
	set m [lindex [split $s :] 0]
	set c [lindex [split $s :] end]
	create_scenario -name $s -mode $m -corner $c
}

########################################
## Populate constraints 
########################################
## Populate mode contraints
foreach m [array name mode_constraints] {
	current_mode $m

	current_scenario [index_collection [get_scenarios -mode $m] 0] 
	# ensures a current_scenario exists in case provided mode constraints are actually scenario specific

	puts "RM-info: current_mode $m"
	puts "RM-info: source $mode_constraints($m)"
	source $mode_constraints($m)
}

## Populate corner contraints
#  Please ensure parasitics are assigned to the corners properly
foreach c [array name corner_constraints] {
	current_corner $c

	current_scenario [index_collection [get_scenarios -corner $c] 0] 
	# ensures a current_scenario exists in case provided corner constraints are actually scenario specific

	puts "RM-info: current_corner $c"
	puts "RM-info: source $corner_constraints($c)"
	source $corner_constraints($c)

	# pls ensure $corner_constraints($c) includes set_parasitic_parameters command for the corresponding corner,
	# for example, set_parasitic_parameters -late_spec $parasitics1 -early_spec $parasitics2,
	# where the command points to the parasitics read by the read_parasitic_tech commands.
	# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
	# read_parasitic_tech_example.tcl is provided as an example.
}

## Populate scenario constraints
foreach s [array name scenario_constraints] {
	current_scenario $s
	puts "RM-info: current_scenario $s"
	puts "RM-info: source $scenario_constraints($s)"
	source $scenario_constraints($s)
}

########################################
## Configure analysis settings for scenarios
########################################
# Below are just examples to show usage of set_scenario_status (actual usage shold depend on your objective)
# scenario1 is a setup scenario and scenario2 is a hold scenario
set_scenario_status $scenario1 -none -setup true -hold false -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
set_scenario_status $scenario2 -none -setup false -hold true -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true

redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_scenarios.rpt {report_scenarios} 

## Note :
#  To remove duplicate modes, corners, and scenarios, and to improve runtime and capacity,
#  without loss of constraints, try the following command :
#	remove_duplicate_timing_contexts

puts "RM-info: Completed script [info script]\n"

