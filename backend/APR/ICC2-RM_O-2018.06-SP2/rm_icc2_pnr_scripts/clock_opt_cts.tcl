##########################################################################################
# Tool: IC Compiler II
# Script: clock_opt_cts.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $CLOCK_OPT_CTS_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME} -to ${DESIGN_NAME}/${CLOCK_OPT_CTS_BLOCK_NAME}
current_block ${DESIGN_NAME}/${CLOCK_OPT_CTS_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for place_opt and clock_opt_cts are different
if {$DESIGN_STYLE == "hier"} {
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_CLOCK_OPT_CTS != $BLOCK_ABSTRACT_FOR_PLACE_OPT)} {
		puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_PLACE_OPT to $BLOCK_ABSTRACT_FOR_CLOCK_OPT_CTS abstracts for all blocks."
		change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_CLOCK_OPT_CTS
		report_abstracts
	}
}


if {$CLOCK_OPT_CTS_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$CLOCK_OPT_CTS_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $CLOCK_OPT_CTS_ACTIVE_SCENARIO_LIST
}

## For non-persistent settings that need to be re-applied in a new ICC-II session 
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

## For CTS and post-CTS optimization specific settings
#  Note - common CTS settings that can be set upfront and also clock NDR setup, 
#         are covered by settings.place_opt.tcl 
puts "RM-info: Sourcing [which settings.clock_opt_cts.tcl]"
source -echo settings.clock_opt_cts.tcl

if {$CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name cts.common.user_instance_name_prefix -value $CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX
	if {[get_app_option_value -name clock_opt.flow.enable_ccd]} {
		# If CCD is enabled, set both opt and cts user prefix as it can work on both data and clock paths
		set_app_options -name opt.common.user_instance_name_prefix -value ${CLOCK_OPT_CTS_USER_INSTANCE_NAME_PREFIX}_opt
	}
}

####################################
## Pre-CTS customizations	
####################################
if {[file exists [which $TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT]"
	source $TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT($TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT) is invalid. Please correct it."
}
## Sample commands that can be included in $TCL_USER_CLOCK_OPT_CTS_PRE_SCRIPT :
#	    set_clock_uncertainty -setup 0.05 [all_clocks] -scenarios [all_scenarios]
#	    set_clock_uncertainty -hold  0.01 [all_clocks] -scenarios [all_scenarios]

####################################
## report_app_options & report_lib_cell_purpose	
####################################
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

####################################
## Pre-CTS checks	
####################################
## Check for netlist, constraints, or setup issues that could hurt CTS results
redirect -file ${REPORTS_DIR}/${CLOCK_OPT_CTS_BLOCK_NAME}.pre_cts.check_clock_tree {check_clock_tree}

## Report CTS constraints and settings that have been applied
redirect -file ${REPORTS_DIR}/${CLOCK_OPT_CTS_BLOCK_NAME}.pre_cts.report_clock_settings {report_clock_settings}

####################################
## Core commands	
####################################
## Enabled if used by top level closure flow
if {$DESIGN_STYLE == "hier"} { 
	## Promote clock tree exceptions from blocks to top
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && $PROMOTE_CLOCK_BALANCE_POINTS} {
		promote_clock_data -auto_clock connected -balance_points
	}
}

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks  -all_sub_blocks
}

########################################################################
## Multisource clock tree synthesis (MSCTS)
########################################################################
#  Specify a Tcl script for MSCTS setup and creation
#  Two examples are provided in rm_icc2_pnr_scripts: mscts_example.regular.tcl and mscts_example.structural.tcl 
if {$CLOCK_OPT_MSCTS_CRITICAL_SCENARIO != ""} {
	set cur_scenario [get_object_name [current_scenario]]
	current_scenario $CLOCK_OPT_MSCTS_CRITICAL_SCENARIO
}
## Run structural MSCTS followed by Regular MSCTS if both structure present in the design
if {[file exists [which $TCL_STRUCTURAL_MSCTS_FILE]]} {
        puts "RM-info: Sourcing [which $TCL_STRUCTURAL_MSCTS_FILE]"
        source $TCL_STRUCTURAL_MSCTS_FILE
} elseif {$TCL_STRUCTURAL_MSCTS_FILE != ""} {
        puts "RM-error: TCL_STRUCTURAL_MSCTS_FILE($TCL_STRUCTURAL_MSCTS_FILE) is invalid. Please correct it."
}
## Run regular MSCTS
if {[file exists [which $TCL_REGULAR_MSCTS_FILE]]} {
	if {!$PLACE_OPT_MSCTS} {
        	puts "RM-info: Sourcing [which $TCL_REGULAR_MSCTS_FILE]"
        	source $TCL_REGULAR_MSCTS_FILE
		# Run Tap assignment
		synthesize_multisource_clock_taps
	} else  {
		# Propagate clock for timer to see actual transitions on the Htree before CTS
        	synthesize_clock_trees -propagate_only
	
		# Run clock mesh simulation with clocks propagated 
		analyze_subcircuit -net $MSCTS_CLOCK_MESH_NAME \
		-from [get_pins -filter "direction==in&&port_type!=power&&port_type!=ground" -of [get_cells -physical *mscts_mesh_driver*]]  \
		-MSCTS_ANALYZE_DRIVER_FILES $MSCTS_ANALYZE_DRIVER_FILES \
		-MSCTS_ANALYZE_SPICE_HEADER_FILES $MSCTS_ANALYZE_SPICE_HEADER_FILES \
		-clock $MSCTS_CLOCK \
		-configuration { \
			-scenario_name $MSCTS_ANALYZE_SCENARIO \
			-max_spice_header_files $MSCTS_ANALYZE_SCENARIO_MAX_SPICE_HEADER_FILES \
			-min_spice_header_files $MSCTS_ANALYZE_SCENARIO_MIN_SPICE_HEADER_FILES \
		} \
		-simulator hspice \
		-name clk_mesh_analysis_cts
	}
} elseif {$TCL_REGULAR_MSCTS_FILE != ""} {
        puts "RM-error: TCL_REGULAR_MSCTS_FILE($TCL_REGULAR_MSCTS_FILE) is invalid. Please correct it."
}
if {[file exists [which $TCL_REGULAR_MSCTS_FILE]] || [file exists [which $TCL_STRUCTURAL_MSCTS_FILE]]} { 
	save_block -as ${DESIGN_NAME}/${CLOCK_OPT_CTS_BLOCK_NAME}_MSCTS
}
if {$CLOCK_OPT_MSCTS_CRITICAL_SCENARIO != ""} {current_scenario $cur_scenario}
## MSCTS ends

## Reminder: Include flops as part of the cts lib cell purpose list :
#  CCD can size flops to improve timing. Please make sure flops are enabled for CTS to allow sizing during CCD.
#  If you are using set_lib_cell_purpose.tcl, set CTS_LIB_CELL_PATTERN_LIST to specify the lib cells.

if {[file exists [which $TCL_USER_CLOCK_OPT_CTS_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_CTS_SCRIPT]"
        source $TCL_USER_CLOCK_OPT_CTS_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_CTS_SCRIPT != ""} {
	puts "RM-error: TCL_USER_CLOCK_OPT_CTS_SCRIPT($TCL_USER_CLOCK_OPT_CTS_SCRIPT) is invalid. Please correct it."
} else {

puts "RM-info: Running clock_opt -from build_clock -to build_clock command"
clock_opt -from build_clock -to build_clock


puts "RM-info: Running clock_opt -from route_clock -to route_clock command"
clock_opt -from route_clock -to route_clock

## If redundant via insertion on clock nets is required here, uncomment the commands below:
#	## Source ICC-II via mapping file for redundant via insertion	
#	if {[file exists [which $TCL_USER_REDUNDANT_VIA_MAPPING_FILE]]} {
#		puts "RM-info: Sourcing [which $TCL_USER_REDUNDANT_VIA_MAPPING_FILE]"
#		source $TCL_USER_REDUNDANT_VIA_MAPPING_FILE
#		report_via_mapping
#	## Source ICC via mapping file that contains define_zrt_redundant_vias commands
#	} elseif {[file exists [which $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE]]} {
#		puts "RM-info: Sourcing [which $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE]"
#		add_via_mapping -from_icc_file $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE
#		report_via_mapping
#	} else {
#		puts "RM-warning: No valid redundant via mapping file has been specified."
#	}
#
#	add_redundant_vias -nets [get_nets -physical_context -of [get_clock_tree_pins]]
}

####################################
## Enable AOCV (recommended after CTS is completed)	
####################################
if {![get_app_option_value -name time.pocvm_enable_analysis] && $AOCV_CORNER_TABLE_MAPPING_LIST != ""} {
	## Enable the AOCV analysis
	set_app_options -name time.aocvm_enable_analysis -value true ;# default false
	
	## Enable the AOCV distance analysis
	#  AOCV analysis will consider path distance when calculating AOCVM derate
	#	set_app_options -name time.ocvm_enable_distance_analysis -value true ;# default false
	
	## Set the configuration for the AOCV analysis
	#	set_app_options -name time.aocvm_analysis_mode -value separate_launch_capture_depth ;# default separate_launch_capture_depth
}

####################################
## Bus routing	
####################################
## Below is an example to route the bus
#	## Define the bus
#	create_bundle -name {bus1}  [get_nets my_bus_net_*]
#	
#	## Define, set the bus constraints
#	create_bus_routing_style -for {bus1} -valid_layers {M5 M6} -layer_widths {M5 0.4 M6 0.4} -layer_spacings {M5 0.4 M6 0.4} -force bus1
#	
#	## Route the bus
#	route_custom -nets {bus1}

####################################
## Post-CTS customizations	
####################################
if {[file exists [which $TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT]"
        source $TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT
} elseif {$TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT != ""} {
        puts "RM-error: TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT($TCL_USER_CLOCK_OPT_CTS_POST_SCRIPT) is invalid. Please correct it."
}

####################################
## Propagate all clocks 
####################################
## This should be used only when additional modes/scenarios are activated after CTS is done.
#  Get inactive scenarios, activate them, mark them as propagated, and then deactivate them.
#	if {[sizeof_collection [get_scenarios -filter active==false -quiet]] > 0} {
#	        set active_scenarios [get_scenarios -filter active]
#	        set inactive_scenarios [get_scenarios -filter active==false]
#
#	        set_scenario_status -active false [get_scenarios $active_scenarios]
#	        set_scenario_status -active true [get_scenarios $inactive_scenarios]
#
#	        synthesize_clock_trees -propagate_only ;# only works on active scenarios
#	        set_scenario_status -active true [get_scenarios $active_scenarios]
#	        set_scenario_status -active false [get_scenarios $inactive_scenarios]
#	}

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

####################################
## Create abstract and frame
####################################
## Enabled for hierarchical designs; for bottom and intermediate levels of physical hierarchy
if {$DESIGN_STYLE == "hier"} {
        if {$USE_ABSTRACTS_FOR_POWER_ANALYSIS == "true"} {
                set_app_options -name abstract.annotate_power -value true
        }
        if { $PHYSICAL_HIERARCHY_LEVEL == "bottom" } {
                create_abstract -read_only
        } elseif { $PHYSICAL_HIERARCHY_LEVEL == "intermediate"} {
            if { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "nested"} {
                ## Create nested abstract for the intermediate level of physical hierarchy
                create_abstract -read_only
            } elseif { $ABSTRACT_TYPE_FOR_MPH_BLOCKS == "flattened"} {
                ## Create flattened abstract for the intermediate level of physical hierarchy
                create_abstract -read_only -preserve_block_instances false
            }
        }
        create_frame -block_all true
}


####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


if {$REPORT_QOR_REPORT_CONGESTION} {
	redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}
	if {[info exists env(DISPLAY)]} {
		gui_start
		#gui_execute_menu_item -menu "View->Layout View"
		gui_execute_menu_item -menu "View->Map->Global Route Congestion"
		gui_write_window_image -format png -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.png
		gui_stop
	} else {
		puts "RM-info: env(DISPLAY) is not defined. Global route congestion map snapshot is skipped."
	}
}

print_message_info -ids * -summary
echo [date] > clock_opt_cts

exit 

