##########################################################################################
# Tool: IC Compiler II
# Script: chip_finish.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $CHIP_FINISH_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME} -to ${DESIGN_NAME}/${CHIP_FINISH_BLOCK_NAME}
current_block ${DESIGN_NAME}/${CHIP_FINISH_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for route_opt and chip_finish are different
if {$DESIGN_STYLE == "hier"} {
   if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_CHIP_FINISH != $BLOCK_ABSTRACT_FOR_ROUTE_OPT)} {
      puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_ROUTE_OPT to $BLOCK_ABSTRACT_FOR_CHIP_FINISH abstracts for all blocks."
      change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_CHIP_FINISH
      report_abstracts
   }
}


if {$CHIP_FINISH_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$CHIP_FINISH_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $CHIP_FINISH_ACTIVE_SCENARIO_LIST
}

## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

## Disable soft-rule-based timing optimization during ECO routing.
#  This is to limit spreading which can touch multiple nets and impact convergence.
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

####################################
## Pre-chip_finish customizations
####################################
if {[file exists [which $TCL_USER_CHIP_FINISH_PRE_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_CHIP_FINISH_PRE_SCRIPT]"
        source $TCL_USER_CHIP_FINISH_PRE_SCRIPT
} elseif {$TCL_USER_CHIP_FINISH_PRE_SCRIPT != ""} {
        puts "RM-error: TCL_USER_CHIP_FINISH_PRE_SCRIPT($TCL_USER_CHIP_FINISH_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
## report_app_options & report_lib_cell_purpose	
####################################
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
    set_timing_paths_disabled_blocks  -all_sub_blocks
}


####################################
## Filler cell insertion
####################################
## Below are the commands for creating standard cell metal and non-metal fillers.
#  For designs with a smallest cell size of 2 sites, to prevent 1x gaps,
#  append either the option -smallest_cell_size 2 or -rules {no_1x}
#  For designs with a smallest cell size of 3 sites, to prevent 1x and 2x gaps,
#  append the option -smallest_cell_size 3

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

	remove_stdcell_fillers_with_violation
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

## To remove filler cells in the design :
#	remove_cells [get your_filler_cells]

####################################
## Signal EM analysis and fix	
####################################
	## Loading EM constraint is required for EM analysis and fixing.
	if {[file exists [which $CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FILE]]} {
		set read_signal_em_constraints_cmd "read_signal_em_constraints $CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FILE"
		switch -regexp $CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FORMAT {
			"ITF"      {lappend read_signal_em_constraints_cmd -format ITF}
			"ALF"      {lappend read_signal_em_constraints_cmd -format ALF}
		}
		puts "RM-info: $read_signal_em_constraints_cmd"
		eval $read_signal_em_constraints_cmd
  
		## Loading and setting switching activity is optional
		#  ex, set_switching_activity -rise_toggle_rate <positive number> -fall_toggle_rate -static_probability <0to1> [get_nets -hier *]
		if {[file exists [which $CHIP_FINISH_SIGNAL_EM_SAIF]]} {
			read_saif $CHIP_FINISH_SIGNAL_EM_SAIF
		} elseif {$CHIP_FINISH_SIGNAL_EM_SAIF != ""} {
			puts "RM-error: CHIP_FINISH_SIGNAL_EM_SAIF($CHIP_FINISH_SIGNAL_EM_SAIF) is invalid. Please correct it."
		}

		## Signal EM analysis and fixing require CHIP_FINISH_SIGNAL_EM_SCENARIO to be specified, active, and enabled for setup and hold
		if {$CHIP_FINISH_SIGNAL_EM_SCENARIO != ""} {
			if {[regexp $CHIP_FINISH_SIGNAL_EM_SCENARIO [get_object_name [get_scenarios -filter "setup&&hold&&active"]]]} {
				## Recommended to have SI enabled so delta transition and coupling capacitance are considered in signal EM analysis
				if {![get_app_option_value -name time.si_enable_analysis]} {
					set RM_current_value_enable_si false
					set_app_options -name time.si_enable_analysis -value true
				}

				set RM_current_value_scenario [current_scenario]
				current_scenario $CHIP_FINISH_SIGNAL_EM_SCENARIO
				redirect -tee -file ${REPORTS_DIR}/chip_finish.report_signal_em {report_signal_em -violated}

				if {$CHIP_FINISH_SIGNAL_EM_FIXING} {
				## Fix all EM violations in the whole design including clock and signal nets.
				#  The command uses information from the current mode and corner. 
					fix_signal_em
					redirect -tee -file ${REPORTS_DIR}/chip_finish.report_signal_em.post {report_signal_em -violated}
				}
				current_scenario ${RM_current_value_scenario}

				## Restore user default of time.si_enable_analysis
				if {[info exists RM_current_value_enable_si] && !${RM_current_value_enable_si}} {
					set_app_options -name time.si_enable_analysis -value false
				}
			} else {
				puts "RM-error: CHIP_FINISH_SIGNAL_EM_SCENARIO must be active and enabled for setup and hold. Signal EM analysis and fixing are skipped."
			}
		} else {
			puts "RM-error: CHIP_FINISH_SIGNAL_EM_SCENARIO is not specified. Signal EM analysis and fixing are skipped."
		}
	} elseif {$CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FILE != ""} {
		puts "RM-error: CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FILE($CHIP_FINISH_SIGNAL_EM_CONSTRAINT_FILE) is invalid. Please correct it."
	}



####################################
## Post-chip_finish customizations
####################################
if {[file exists [which $TCL_USER_CHIP_FINISH_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_CHIP_FINISH_POST_SCRIPT]"
        source $TCL_USER_CHIP_FINISH_POST_SCRIPT
} elseif {$TCL_USER_CHIP_FINISH_POST_SCRIPT != ""} {
        puts "RM-error: TCL_USER_CHIP_FINISH_POST_SCRIPT($TCL_USER_CHIP_FINISH_POST_SCRIPT) is invalid. Please correct it."
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
        if {$USE_ABSTRACTS_FOR_SIGNAL_EM_ANALYSIS == "true"} {
                set_app_options -name abstract.enable_signal_em_analysis -value true
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
	derive_hier_antenna_property -design ${DESIGN_NAME}/${CHIP_FINISH_BLOCK_NAME}
}

####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


print_message_info -ids * -summary
echo [date] > chip_finish

exit 

