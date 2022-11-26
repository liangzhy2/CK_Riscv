##########################################################################################
# Tool: IC Compiler II
# Script: place_opt.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $PLACE_OPT_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${INIT_DESIGN_BLOCK_NAME} -to ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}
current_block ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}
link_block

## For top and intermediate level of hierarchical designs, check the editability of the sub-blocks;
## if the editability is true for any sub-block, set it to false
## In RM, we are setting the editability of all the sub-blocks to false in the init_design.tcl script
## The following check is implemented to ensure that the editability of the sub-blocks is set to false in flows not running the init_design.tcl script
if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
      	foreach_in_collection c [get_blocks -hierarchical] {
	  	if {[get_editability -blocks ${c}] == true } {
	     	set_editability -blocks ${c} -value false
   	  	}
      	}
	report_editability -blocks [get_blocks -hierarchical]
}

## Active scenarios for place_opt 
#  Include CTS scenarios if you are enabling CTS related features during place_opt,
#  such as PLACE_OPT_OPTIMIZE_ICGS, PLACE_OPT_TRIAL_CTS, or PLACE_OPT_MSCTS
if {$PLACE_OPT_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$PLACE_OPT_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $PLACE_OPT_ACTIVE_SCENARIO_LIST
}

## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

## For place_opt specific settings (including settings that should be set before place_opt) 
puts "RM-info: Sourcing [which settings.place_opt.tcl]"
source -echo settings.place_opt.tcl

if {$PLACE_OPT_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name opt.common.user_instance_name_prefix -value $PLACE_OPT_USER_INSTANCE_NAME_PREFIX
	if {$PLACE_OPT_OPTIMIZE_ICGS || $PLACE_OPT_TRIAL_CTS} {
		set_app_options -name cts.common.user_instance_name_prefix -value ${PLACE_OPT_USER_INSTANCE_NAME_PREFIX}_cts
	} 
} 



####################################
## read_saif 
####################################
## read_saif is recommended for features such as PREROUTE_ENHANCED_LOW_POWER_PLACEMENT_EFFORT (set to a value other than none), 
#  and PREROUTE_POWER_OPTIMIZATION_MODE (set to total or dynamic)
if {[file exists [which $SAIF_FILE]]} {
	if {$SAIF_FILE_POWER_SCENARIO != ""} {
		set read_saif_cmd "read_saif $SAIF_FILE -scenarios $SAIF_FILE_POWER_SCENARIO"
	} else {
		set read_saif_cmd "read_saif $SAIF_FILE"
	}
	if {$SAIF_FILE_SOURCE_INSTANCE != ""} {lappend read_saif_cmd -strip_path $SAIF_FILE_SOURCE_INSTANCE}
	if {$SAIF_FILE_TARGET_INSTANCE != ""} {lappend read_saif_cmd -path $SAIF_FILE_TARGET_INSTANCE}
	puts "RM-info: Running $read_saif_cmd"
	eval $read_saif_cmd
} elseif {$SAIF_FILE != ""} {
	puts "RM-error: SAIF_FILE($SAIF_FILE) is invalid. Please correct it."	
}

####################################
## Spare cell insertion before place_opt 
####################################
if {[file exists [which $TCL_USER_SPARE_CELL_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_SPARE_CELL_PRE_SCRIPT]"
	source $TCL_USER_SPARE_CELL_PRE_SCRIPT
} elseif {$TCL_USER_SPARE_CELL_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_SPARE_CELL_PRE_SCRIPT($TCL_USER_SPARE_CELL_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
## Pre-place_opt customizations
####################################
if {[file exists [which $TCL_USER_PLACE_OPT_PRE_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_PRE_SCRIPT]"
	source $TCL_USER_PLACE_OPT_PRE_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_PRE_SCRIPT != ""} {
	puts "RM-error: TCL_USER_PLACE_OPT_PRE_SCRIPT($TCL_USER_PLACE_OPT_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
## report_app_options & report_lib_cell_purpose	
####################################
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

####################################
## Core commands
####################################
## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks -all_sub_blocks
}

if {[file exists [which $TCL_USER_PLACE_OPT_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_SCRIPT]"
        source $TCL_USER_PLACE_OPT_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_SCRIPT != ""} {
        puts "RM-error:TCL_USER_PLACE_OPT_SCRIPT($TCL_USER_PLACE_OPT_SCRIPT) is invalid. Please correct it."
} else {

###################################
## Clock NDR modeling at place_opt
###################################
## Model the congestion impact of clock NDR 
#  Clock NDRs are created in settings.place_opt.tcl. The mark_clock_trees command makes place_opt recognize them.
if {$PLACE_OPT_MODEL_CLOCK_NDR && !($PLACE_OPT_OPTIMIZE_ICGS || $PLACE_OPT_TRIAL_CTS)} {
	puts "RM-info: Running mark_clock_trees -routing_rules to model clock NDR impact during place_opt"
	mark_clock_trees -routing_rules
}

###################################
## Regular MSCTS at place_opt 
###################################
if {$PLACE_OPT_MSCTS} {
	## Define MSCTS critical scenario as current_scenario as this will be the scenario considered for tap assignment
	if {$PLACE_OPT_MSCTS_CRITICAL_SCENARIO != ""} {
		set cur_scenario [get_object_name [current_scenario]]
		current_scenario $PLACE_OPT_MSCTS_CRITICAL_SCENARIO
	}

	if {[file exists [which $TCL_REGULAR_MSCTS_FILE]]} {
		set_app_options -name place_opt.flow.enable_multisource_clock_trees -value true
	        puts "RM-info: Sourcing [which $TCL_REGULAR_MSCTS_FILE]"
        	source $TCL_REGULAR_MSCTS_FILE
		save_block -as ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}_MSCTS

	} elseif {$TCL_REGULAR_MSCTS_FILE != ""} {
        	puts "RM-error: TCL_REGULAR_MSCTS_FILE($TCL_REGULAR_MSCTS_FILE) is invalid. Please correct it."
	}

	if {$PLACE_OPT_MSCTS_CRITICAL_SCENARIO != ""} {current_scenario $cur_scenario}
}

####################################
## Two pass place_opt
####################################	

	########################################################################
	## First pass
	########################################################################
	## Flow with non-SPG inputs ($PLACE_OPT_SPG_FLOW set to false)
	if {!$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running place_opt -from initial_place -to initial_place" ;# initial_place phase is buffering-aware with CDR
		place_opt -from initial_place -to initial_place
		puts "RM-info: Running place_opt -from initial_drc -to initial_drc"
		place_opt -from initial_drc -to initial_drc
		puts "RM-info: Running update_timing -full"
		update_timing -full
	} 

	## Flow with SPG inputs ($PLACE_OPT_SPG_FLOW set to true)
	if {$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: For designs starting with SPG input, seed placement comes from SPG, so the first pass is skipped."
	}

	########################################################################
	## Second pass	
	########################################################################
	## Trial clock tree  (optional)
	#  Enabled only if PLACE_OPT_OPTIMIZE_ICGS is not enabled since tool will enable this feature automatically,
	#  if PLACE_OPT_OPTIMIZE_ICGS is enabled
	if {$PLACE_OPT_TRIAL_CTS && !$PLACE_OPT_OPTIMIZE_ICGS} {
		set_app_options -name place_opt.flow.trial_clock_tree -value true ;# default false
	}

	## ICG optimization  (optional)
	#  Automatic ICG optimization that performs early clock synthesis (starting in initial_drc phase), 
	#  timing-driven ICG splitting (initial_opto phase), and clock-aware placement (final_place phase)
	if {$PLACE_OPT_OPTIMIZE_ICGS} {
		set_app_option -name place_opt.flow.optimize_icgs -value true ;# default false
		if {$PLACE_OPT_OPTIMIZE_ICGS_CRITICAL_RANGE != ""} {
			set_app_options -name place_opt.flow.optimize_icgs_critical_range -value $PLACE_OPT_OPTIMIZE_ICGS_CRITICAL_RANGE ;# default 0.75
		}
	}

	## Flow with non-SPG inputs ($PLACE_OPT_SPG_FLOW set to false)
	if {!$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running create_placement -incremental -timing_driven -congestion"
		# Note: to increase the congestion alleviation effort, add -congestion_effort high
		create_placement -incremental -timing_driven -congestion
		save_block -as ${DESIGN_NAME}/${PLACE_OPT_BLOCK_NAME}_two_pass_placement

		puts "RM-info: Running place_opt -from initial_drc -to initial_opto"
		place_opt -from initial_drc -to initial_opto
	} 

	## Flow with SPG inputs ($PLACE_OPT_SPG_FLOW set to true)
	if {$PLACE_OPT_SPG_FLOW} {
		puts "RM-info: Running place_opt -to initial_opto with place_opt.flow.do_spg true"
		set_app_option -name place_opt.flow.do_spg -value true 
		place_opt -to initial_opto
	}

	## Multi-bit banking (optional) 
	if {$PLACE_OPT_MULTIBIT_BANKING} {
		set identify_multibit_cmd "identify_multibit -register -no_dft_opt -apply"
		if {$PLACE_OPT_MULTIBIT_BANKING_CELL_INSTANCE_LIST != ""} {
			lappend identify_multibit_cmd -cells $PLACE_OPT_MULTIBIT_BANKING_CELL_INSTANCE_LIST
		}
		if {$PLACE_OPT_MULTIBIT_BANKING_EXCLUDED_INSTANCE_LIST != ""} {
			lappend identify_multibit_cmd -exclude_instance $PLACE_OPT_MULTIBIT_BANKING_EXCLUDED_INSTANCE_LIST
		}
		puts "RM-info: Running $identify_multibit_cmd"
		eval $identify_multibit_cmd
	}

	puts "RM-info: Running place_opt -from final_place"
	place_opt -from final_place

	## Multi-bit de-banking (optional)
	if {$PLACE_OPT_MULTIBIT_DEBANKING} {
		set split_multibit_cmd "split_multibit -slack_threshold 0"
		if {$PLACE_OPT_MULTIBIT_DEBANKING_CELL_INSTANCE_LIST != ""} {
			lappend split_multibit_cmd -cells $PLACE_OPT_MULTIBIT_DEBANKING_CELL_INSTANCE_LIST
		}
		if {$PLACE_OPT_MULTIBIT_DEBANKING_EXCLUDED_INSTANCE_LIST != ""} {
			lappend split_multibit_cmd -exclude_instance $PLACE_OPT_MULTIBIT_DEBANKING_EXCLUDED_INSTANCE_LIST
		}
		puts "RM-info: Running $split_multibit_cmd"
		eval $split_multibit_cmd

		puts "RM-info: Running place_opt -from final_place"
		place_opt -from final_place
	}

}

####################################
## Post-place_opt customizations
####################################
if {[file exists [which $TCL_USER_PLACE_OPT_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_PLACE_OPT_POST_SCRIPT]"
        source $TCL_USER_PLACE_OPT_POST_SCRIPT
} elseif {$TCL_USER_PLACE_OPT_POST_SCRIPT != ""} {
        puts "RM-error:TCL_USER_PLACE_OPT_POST_SCRIPT($TCL_USER_PLACE_OPT_POST_SCRIPT) is invalid. Please correct it."
}

####################################
## Spare cell insertion after place_opt 
####################################
if {[file exists [which $TCL_USER_SPARE_CELL_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_SPARE_CELL_POST_SCRIPT]"
	source $TCL_USER_SPARE_CELL_POST_SCRIPT
} elseif {$TCL_USER_SPARE_CELL_POST_SCRIPT != ""} {
	puts "RM-error: TCL_USER_SPARE_CELL_POST_SCRIPT($TCL_USER_SPARE_CELL_POST_SCRIPT) is invalid. Please correct it."
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
echo [date] > place_opt

exit 

