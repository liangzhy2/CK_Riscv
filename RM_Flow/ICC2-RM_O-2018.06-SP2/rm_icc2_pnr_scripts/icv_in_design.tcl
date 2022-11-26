##########################################################################################
# Tool: IC Compiler II
# Script: icv_in_design.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $ICV_IN_DESIGN_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${CHIP_FINISH_BLOCK_NAME} -to ${DESIGN_NAME}/${ICV_IN_DESIGN_BLOCK_NAME}
current_block ${DESIGN_NAME}/${ICV_IN_DESIGN_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for chip_finish and icv_in_design are different
if {$DESIGN_STYLE == "hier"} {
   if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_ICV_IN_DESIGN != $BLOCK_ABSTRACT_FOR_CHIP_FINISH)} {
      puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_CHIP_FINISH to $BLOCK_ABSTRACT_FOR_ICV_IN_DESIGN abstracts for all blocks."
      change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_ICV_IN_DESIGN
      report_abstracts
   }
}


if {$ICV_IN_DESIGN_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$ICV_IN_DESIGN_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $ICV_IN_DESIGN_ACTIVE_SCENARIO_LIST
}

## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

########################################################################
## Pre signoff_check_drc and signoff_fix_drc customizations
########################################################################
if {[file exists [which $TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT]"
        source $TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT
} elseif {$TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT != ""} {
        puts "RM-error: TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT($TCL_USER_ICV_IN_DESIGN_PRE_SCRIPT) is invalid. Please correct it."
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


########################################################################
## signoff_check_drc and signoff_fix_drc
########################################################################

## Runset for signoff_check_drc
if {[file exists [which $ICV_IN_DESIGN_DRC_CHECK_RUNSET]]} {
	puts "RM-info: Setting signoff.check_drc.runset to [which $ICV_IN_DESIGN_DRC_CHECK_RUNSET]"
	set_app_options -name signoff.check_drc.runset -value $ICV_IN_DESIGN_DRC_CHECK_RUNSET
} elseif {$ICV_IN_DESIGN_DRC_CHECK_RUNSET != ""} {
	puts "RM-error: ICV_IN_DESIGN_DRC_CHECK_RUNSET($ICV_IN_DESIGN_DRC_CHECK_RUNSET) is invalid. Please correct it."
}

if {[get_app_option_value -name signoff.check_drc.runset] != ""} {

	########################################################################
	## signoff_check_drc
	########################################################################
	save_block ;# Save to disk is required as ICV reads from disk file instead of memory
	set_app_options -name signoff.check_drc.run_dir -value $ICV_IN_DESIGN_DRC_CHECK_RUNDIR ;# RM default z_check_drc
	signoff_check_drc -error_data $ICV_IN_DESIGN_DRC_CHECK_RUNDIR ;# RM default z_check_drc

	## Note: Ideally results from signoff_check_drc should be reviewed and corrective action
	#  taken on appropriate app.options before invoking signoff_fix_drc.
	#  Note that signoff.fix_drc.max_errors_per_rule defaults at 1000. If more than 1000 DRC violations
	#  are reported of a specific type, this error type will be excluded from fixing. This condition
	#  may indicate that there is some other issue with the design.

	if {$ICV_IN_DESIGN_ADR} {

	########################################################################
	## signoff_fix_drc (controlled by ICV_IN_DESIGN_ADR, default true)
	########################################################################
	#  Specify valid ICV_IN_DESIGN_ADR_DPT_RULES if you want signoff_fix_drc to be used for DPT rules fixing
	#  Review the signoff_fix_drc/result_summary.rpt for complete details of signoff_fix_drc

		########################################################################
		## signoff_fix_drc for non-DPT
		########################################################################
		set_app_options -name signoff.fix_drc.init_drc_error_db -value $ICV_IN_DESIGN_DRC_CHECK_RUNDIR ;# RM default z_check_drc
		set_app_options -name signoff.fix_drc.run_dir -value $ICV_IN_DESIGN_ADR_RUNDIR ;# RM default z_adr
		set_app_options -name signoff.fix_drc.custom_guidance -value off

		## signoff_drc_check after fixing
		if {$ICV_IN_DESIGN_ADR_DPT_RULES != ""} {
			signoff_fix_drc -unselect_rules $ICV_IN_DESIGN_ADR_DPT_RULES
		} else {
			signoff_fix_drc
		}
		save_block

		set_app_options -name signoff.check_drc.run_dir -value $ICV_IN_DESIGN_POST_ADR_RUNDIR ;# RM default z_post_adr
		signoff_check_drc -error_data $ICV_IN_DESIGN_POST_ADR_RUNDIR ;# RM default z_post_adr

		########################################################################
		## signoff_fix_drc for DPT
		########################################################################
		if {$ICV_IN_DESIGN_ADR_DPT_RULES != ""} {
			set_app_options -name signoff.fix_drc.init_drc_error_db -value $ICV_IN_DESIGN_POST_ADR_RUNDIR ;# RM default z_post_adr
			set_app_options -name signoff.fix_drc.run_dir -value $ICV_IN_DESIGN_ADR_DPT_RUNDIR ;# RM default z_adr_with_dpt
			set_app_options -name signoff.fix_drc.custom_guidance -value dpt

			signoff_fix_drc -select_rules $ICV_IN_DESIGN_ADR_DPT_RULES
			save_block
	
			## signoff_drc_check after DPT fixing
			set_app_options -name signoff.check_drc.run_dir -value $ICV_IN_DESIGN_POST_ADR_DPT_RUNDIR ;# RM default z_post_adr_with_dpt
			signoff_check_drc -error_data $ICV_IN_DESIGN_POST_ADR_DPT_RUNDIR ;# RM default z_post_adr_with_dpt
			set_app_options -name signoff.fix_drc.custom_guidance -value off
		}
	}
} else {
	puts "RM-error: signoff.check_drc.runset is not specified. Please set it through ICV_IN_DESIGN_DRC_CHECK_RUNSET!" 
	puts "RM-info: signoff_check_drc and signoff_fix_drc are both skipped." 
}

####################################
## Metal fill creation	
####################################
## Metal fill creation command
if {$ICV_IN_DESIGN_METAL_FILL} {

if {$ICV_IN_DESIGN_METAL_FILL_RUNDIR != ""} {
	puts "RM-info: Setting signoff.create_metal_fill.run_dir to $ICV_IN_DESIGN_METAL_FILL_RUNDIR"
	set_app_options -name signoff.create_metal_fill.run_dir -value $ICV_IN_DESIGN_METAL_FILL_RUNDIR
}

if {$ICV_IN_DESIGN_METAL_FILL_TRACK_BASED == "off"} {

## Non track-based metal fill setup

	##  A valid runset is required for non track-based metal fill. Specify runset for signoff_create_metal_fill
	if {[file exists [which $ICV_IN_DESIGN_METAL_FILL_RUNSET]]} {
		puts "RM-info: Setting signoff.create_metal_fill.runset to [which $ICV_IN_DESIGN_METAL_FILL_RUNSET]"
		set_app_options -name signoff.create_metal_fill.runset -value $ICV_IN_DESIGN_METAL_FILL_RUNSET
	} elseif {$ICV_IN_DESIGN_METAL_FILL_RUNSET != ""} {
		puts "RM-error: ICV_IN_DESIGN_METAL_FILL_RUNSET($ICV_IN_DESIGN_METAL_FILL_RUNSET) is invalid. Please correct it."
	}

	if {[get_app_option_value -name signoff.create_metal_fill.runset] != ""} {
		set create_metal_fill_cmd "signoff_create_metal_fill"
	} else {
		puts "RM-error: signoff.create_metal_fill.runset is not specified. Please set it through ICV_IN_DESIGN_METAL_FILL_RUNSET!" 
		puts "RM-warning: signoff_create_metal_fill is skipped."
	}
} else {

## Track-based metal fill setup


	## For track-based metal fill creation, it is recommended to specify foundry node for -track_fill in order to use -fill_all_track
	if {$ICV_IN_DESIGN_METAL_FILL_TRACK_BASED != "generic"} {
		set create_metal_fill_cmd "signoff_create_metal_fill -track_fill $ICV_IN_DESIGN_METAL_FILL_TRACK_BASED -fill_all_tracks true"
	} else {
		set create_metal_fill_cmd "signoff_create_metal_fill -track_fill $ICV_IN_DESIGN_METAL_FILL_TRACK_BASED"
	}

	## Track-based metal fill creation: optionally specify a ICV_IN_DESIGN_METAL_FILL_TRACK_BASED_PARAMETER_FILE  
	if {$ICV_IN_DESIGN_METAL_FILL_TRACK_BASED_PARAMETER_FILE != "auto" && [file exists [which $ICV_IN_DESIGN_METAL_FILL_TRACK_BASED_PARAMETER_FILE]]} {
		lappend create_metal_fill_cmd -track_fill_parameter_file $ICV_IN_DESIGN_METAL_FILL_TRACK_BASED_PARAMETER_FILE
	}
}

## Metal fill creation
if {[info exists create_metal_fill_cmd] && $create_metal_fill_cmd != ""} {
	## Timing-driven
	if {$ICV_IN_DESIGN_METAL_FILL_TIMING_DRIVEN_THRESHOLD != ""} {
		lappend create_metal_fill_cmd -timing_preserve_setup_slack_threshold $ICV_IN_DESIGN_METAL_FILL_TIMING_DRIVEN_THRESHOLD

		# Extraction options
		set_extraction_options -real_metalfill_extraction none

		# Optional app options to block fill creation on critical nets. Below are examples.
		# 	set_app_options -name signoff.create_metal_fill.space_to_nets -value {{M1 4x} {M2 4x} ...}
		# 	set_app_options -name signoff.create_metal_fill.space_to_clock_nets -value {{M1 5x} {M2 5x} ...}
		# 	set_app_options -name signoff.create_metal_fill.space_to_nets_on_adjacent_layer -value {{M1 3x} {M2 3x} ...}
		# 	set_app_options -name signoff.create_metal_fill.fix_density_error -value true
		# 	set_app_options -name signoff.create_metal_fill.apply_nondefault_rules -value true
	}

	save_block ;# this is required before ICV operations since ICV reads from disk file instead of memory

	puts "RM-info: Running $create_metal_fill_cmd"
	eval $create_metal_fill_cmd

	save_block ;# this is recommended in case there are subsequent ICV operations added by the user after signoff_create_metal_fill 

	if {[get_app_option_value -name signoff.check_drc.runset] != ""} {
		set_app_options -name signoff.check_drc.fill_view_data -value read_if_uptodate
		set_app_options -name signoff.check_drc.run_dir -value $ICV_IN_DESIGN_POST_METAL_FILL_RUNDIR ;# RM default z_MFILL_after
		puts "RM-info: Running signoff_check_drc"
		signoff_check_drc -error_data $ICV_IN_DESIGN_POST_METAL_FILL_RUNDIR ;# RM default z_MFILL_after
	} else {
		puts "RM-warning: signoff.check_drc.runset is not specified. Please set it through ICV_IN_DESIGN_DRC_CHECK_RUNSET!" 
		puts "RM-warning: The signoff_check_drc command after signoff_create_metal_fill is skipped."
	}

	set_extraction_options -real_metalfill_extraction floating
}
}

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
	derive_hier_antenna_property -design ${DESIGN_NAME}/${ICV_IN_DESIGN_BLOCK_NAME}
}

####################################
## Post signoff_create_metal_full customizations
####################################
if {[file exists [which $TCL_USER_ICV_IN_DESIGN_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ICV_IN_DESIGN_POST_SCRIPT]"
        source $TCL_USER_ICV_IN_DESIGN_POST_SCRIPT
} elseif {$TCL_USER_ICV_IN_DESIGN_POST_SCRIPT != ""} {
        puts "RM-error: TCL_USER_ICV_IN_DESIGN_POST_SCRIPT($TCL_USER_ICV_IN_DESIGN_POST_SCRIPT) is invalid. Please correct it."
}

####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


print_message_info -ids * -summary
echo [date] > icv_in_design

exit 

