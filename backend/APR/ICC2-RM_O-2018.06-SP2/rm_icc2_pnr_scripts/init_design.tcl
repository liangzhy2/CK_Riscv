##########################################################################################
# Tool: IC Compiler II
# Script: init_design.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

########################################################################
## Design creation/import (depends on value of INIT_DESIGN_INPUT)
########################################################################
## ASCII flow : creates the library & block from individual ASCII input files
if {$INIT_DESIGN_INPUT == "ASCII"} {
	puts "RM-info: Sourcing [which init_design.from_ascii.tcl]"
	source -echo init_design.from_ascii.tcl
}

## DC_ASCII flow : creates the library & block from DC write_icc2_files output files
if {$INIT_DESIGN_INPUT == "DC_ASCII"} {
	puts "RM-info: Sourcing [which init_design.from_dc_ascii.tcl]"
	source -echo init_design.from_dc_ascii.tcl
}

## DP_RM_NDM flow : imports the library & block from DP-RM completed database
if {$INIT_DESIGN_INPUT == "DP_RM_NDM"} {
	puts "RM-info: Sourcing [which init_design.from_dp_rm_ndm.tcl]"
	source -echo init_design.from_dp_rm_ndm.tcl
}

redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_ref_libs {report_ref_libs}

########################################################################
## Additional timer related setups : POCV	
########################################################################
if {$POCV_CORNER_FILE_MAPPING_LIST != ""} {
	## Read POCV coefficient data and distance-based derate tables to reduce pessimism and improve accuracy of the results.
	#  Specify a list of corner and its associated POCV file in pairs, as POCV is corner dependant.
	foreach pair $POCV_CORNER_FILE_MAPPING_LIST {
		set corner [lindex $pair 0]	
		set file [lindex $pair 1]	
		if {[file exists [which $file]]} {
			puts "RM-info: Corner $corner: reading POCV file $file"
	        	read_ocvm -corners $corner $file
		} else {
	        	puts "RM-error: Corner $corner: POCV file $file is not found"
	      	}
	}

	## Enable POCV analysis
	set_app_options -name time.pocvm_enable_analysis -value true ;# tool default false; enables POCV
	reset_app_options time.aocvm_enable_analysis ;# reset it to prevent POCV being overriden by AOCV
	
	## Enable distance analysis
	#	set_app_options -name time.ocvm_enable_distance_analysis -value true
	
	## Enable constraint and slew variation if there're pre-existing library LVF constraints
	#	set_app_options -name time.enable_constraint_variation -value true ;# tool default false
	#	set_app_options -name time.enable_slew_variation -value true ;# tool default false
	
	## Specify the number of standard deviations used in POCV analysis
	#  The larger the value, the more violations there will be 
	#	set_app_options -name time.pocvm_corner_sigma -value 3.5 -block [current_block] ;# default 3
	
	## Use OCV derates to fill gaps in POCV data
	#  To completely ignore OCV derate settings:  
	#	set_app_options -name time.ocvm_precedence_compatibility -value true
	#  To consider both OCV and POCV derate settings:
	#	set_app_options -name time.ocvm_precedence_compatibility -value false
	
	## Set and report POCV guard band (per corner)
	#  Use the set_timing_derate command to specify POCV guard band, which affects the mean and sensit
	#  values in the timing report. For ex, if value is the same across corners:
	#	set_timing_derate -cell_delay -pocvm_guardband -early 0.97 -corner [all_corners]
	#  Or if value is different per corner:
	#	set_timing_derate -cell_delay -pocvm_guardband -early 0.97 -corner corner1
	#	set_timing_derate -cell_delay -pocvm_guardband -early 0.98 -corner corner2, ... etc
	#  To report guard band:
	#	report_timing_derate -pocvm_guardband -corner [all_corners]
	
	## Set and report scaling factor (per corner)
	#  It affects sensit which equals to sensit * scaling factor. For ex, if value is the same across corners:
	#	set_timing_derate -cell_delay -pocvm_coefficient_scale_factor -early 0.95 -corner [all_corners]
	#  Or if value is different per corner:
	#	set_timing_derate -cell_delay -pocvm_coefficient_scale_factor -early 0.95 -corner corner1
	#	set_timing_derate -cell_delay -pocvm_coefficient_scale_factor -early 0.96 -corner corner2, ... etc
	#  To report scale factor:
	#	report_timing_derate -pocvm_coefficient_scale_factor -corner [all_corners]
}

########################################################################
## Additional timer related setups : AOCV (mutually exclusive with POCV)
########################################################################
## Read AOCV derate factor table to reduce pessimism and improve accuracy of the results.
#  Specify a list of corner and its associated AOCV table in pairs, as AOCV is corner dependant.
if {![get_app_option_value -name time.pocvm_enable_analysis] && $AOCV_CORNER_TABLE_MAPPING_LIST != ""} {
	foreach pair $AOCV_CORNER_TABLE_MAPPING_LIST {
		set corner [lindex $pair 0]	
		set table [lindex $pair 1]	
		if {[file exists [which $table]]} {
			puts "RM-info: Corner $corner: reading AOCV table file $table"
	        	read_ocvm -corners $corner $table
		} else {
	        	puts "RM-error: Corner $corner: AOCV table file $table is not found"
	      	}
	}
	
	## Set user-specified instance based random coefficient for the AOCV analysis 
	#  Example : set_aocvm_coefficient <value> [get_lib_cells <lib_cell>]

	## AOCV is enabled in clock_opt_cts.tcl after CTS is done
}

########################################################################
## Additional timer related setups : create path groups 	
########################################################################
if {$CREATE_IO_PATH_GROUPS} {
	## Tool auto creates 3 IO path groups : in2reg_default, reg2out_default, and in2out_default
	set_app_options -name time.enable_io_path_groups -value true  
}

## Optionally create a register to register group
#  set cur_mode [current_mode]
#  foreach_in_collection mode [all_modes] {
#  	current_mode $mode;
#  	group_path -name reg2reg -from [all_clocks] -to [all_clocks] ;# creates register to register path group   
#  }
#  current_mode $cur_mode

## Optionally increase path group weight on critical path groups, for ex:
#  It is recommended to increase path group weight to at least 15 for critical ones 
#	group_path -name clk_gate_enable -weight 15
#	group_path -name xyz -weight 15

redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_path_groups {report_path_groups -nosplit -modes [all_modes]}

########################################################################
## Additional timer related setups : remove propagated clocks	
########################################################################
## Remove all propagated clocks
set cur_mode [current_mode]
foreach_in_collection mode [all_modes] {
	current_mode $mode
	remove_propagated_clocks [all_clocks]
	remove_propagated_clocks [get_ports]
	remove_propagated_clocks [get_pins -hierarchical]
}
current_mode $cur_mode

# To set clock gating check :
# set cur_mode [current_mode]
# foreach_in_collection mode [all_modes] {
#	current_mode $mode
#	set_clock_gating_check -setup 0 [current_design]
#	set_clock_gating_check -hold  0 [current_design]
# }
# current_mode $cur_mode


########################################################################
## Additional power related setups : power derate	
########################################################################
## Power derating factors can affect power analysis and power optimization
#  To set power derating factors on objects, use set_power_derate command
#  Examples
#	set_power_derate 0.98 -scenarios [current_scenario] -leakage -internal
#	set_power_derate 0.9 -switching [get_lib_cells my_lib/cell1] 
#	set_power_derate 0.5 -group {memory} 
#  To report and get power derating factors
#	report_power_derate ...
#  To remove all power derating factors when no arguments are specified
#	reset_power_derate


if {$TCL_USER_CONNECT_PG_NET_SCRIPT != ""} {
	if {[file exists [which $TCL_USER_CONNECT_PG_NET_SCRIPT]]} {
		puts "RM-info: Sourcing [which $TCL_USER_CONNECT_PG_NET_SCRIPT]"
  		source $TCL_USER_CONNECT_PG_NET_SCRIPT
	} elseif {$TCL_USER_CONNECT_PG_NET_SCRIPT != ""} {
		puts "RM-error: TCL_USER_CONNECT_PG_NET_SCRIPT($TCL_USER_CONNECT_PG_NET_SCRIPT) is invalid. Please correct it."
	}
} else {
	connect_pg_net
	# For non-MV designs with more than one PG, you should use connect_pg_net in manual mode.
}

####################################
## MV setup :
## provide a customized MV script	
####################################
## A Tcl script placeholder for your MV setup commands,such as create_voltage_area, placement bound, 
#  power switch creation and level shifter insertion, etc
if {[file exists [which $TCL_MV_SETUP_FILE]]} {
	puts "RM-info: Sourcing [which $TCL_MV_SETUP_FILE]"
	source -echo $TCL_MV_SETUP_FILE
} elseif {$TCL_MV_SETUP_FILE != ""} {
	puts "RM-error: TCL_MV_SETUP_FILE($TCL_MV_SETUP_FILE) is invalid. Please correct it."
}

## For a sample script to insert, assign, and connect power switches, 
#  refer to power_switch_example.tcl


####################################
## Power and ground network creation	
####################################
## A Tcl script placeholder for your power ground network creation commands, such as create_pg*, 
#  set_pg_strategy, and compile_pg, etc.
if {[file exists [which $TCL_PG_CREATION_FILE]]} {
	puts "RM-info: Sourcing [which $TCL_PG_CREATION_FILE]"
	source -echo $TCL_PG_CREATION_FILE
} elseif {$TCL_PG_CREATION_FILE != ""} {
	puts "RM-error: TCL_PG_CREATION_FILE($TCL_PG_CREATION_FILE) is invalid. Please correct it."
}

## Create standard cell PG rail

#  Example : rm_icc2_pnr_scripts/init_design_std_cell_rail_example.tcl

## Verify technology routing DRC and illegal overlaps of PG net objects.
#	check_pg_drc


####################################
## Boundary cells
####################################

## Boundary cells: to be added around the boundaries of objects, such as voltage areas, macros, blockages, and the core area
#	set_boundary_cell_rules ... 
#	report_boundary_cell_rules
#	compile_boundary_cells
#	check_boundary_cells

####################################
## Tap cells
####################################
#  Example : create_tap_cells -lib_cell myLib/Cell1 -distance 30 -pattern every_row

####################################
## Post-init_design customizations
####################################
if {[file exists [which $TCL_USER_INIT_DESIGN_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_INIT_DESIGN_POST_SCRIPT]"
        source $TCL_USER_INIT_DESIGN_POST_SCRIPT
} elseif {$TCL_USER_INIT_DESIGN_POST_SCRIPT != ""} {
        puts "RM-error: TCL_USER_INIT_DESIGN_POST_SCRIPT($TCL_USER_INIT_DESIGN_POST_SCRIPT) is invalid. Please correct it."
}

save_upf ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.save_upf
save_block -as ${DESIGN_NAME}/${INIT_DESIGN_BLOCK_NAME}

####################################
## Sanity checks and QoR Report	
####################################
if {$REPORT_QOR} {
	set REPORT_PREFIX $INIT_DESIGN_BLOCK_NAME
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT ;# reports with zero interconnect delay

	## Check the technology file before starting place and route flow
	write_tech_file ${REPORTS_DIR}/${REPORT_PREFIX}.tech_file.dump
}


print_message_info -ids * -summary
echo [date] > init_design

exit 

