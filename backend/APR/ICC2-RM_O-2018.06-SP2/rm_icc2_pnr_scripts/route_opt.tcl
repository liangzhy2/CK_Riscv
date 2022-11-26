##########################################################################################
# Tool: IC Compiler II
# Script: route_opt.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $ROUTE_OPT_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${ROUTE_AUTO_BLOCK_NAME} -to ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
current_block ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
link_block

## The following only applies to hierarchical designs
## Swap abstracts if abstracts specified for route_auto and route_opt are different
if {$DESIGN_STYLE == "hier"} {
	if {$USE_ABSTRACTS_FOR_BLOCKS != "" && ($BLOCK_ABSTRACT_FOR_ROUTE_OPT != $BLOCK_ABSTRACT_FOR_ROUTE_AUTO)} {
		puts "RM-info: Swapping from $BLOCK_ABSTRACT_FOR_ROUTE_AUTO to $BLOCK_ABSTRACT_FOR_ROUTE_OPT abstracts for all blocks."
		change_abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_ROUTE_OPT
		report_abstracts
	}
}

if {$ROUTE_OPT_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$ROUTE_OPT_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $ROUTE_OPT_ACTIVE_SCENARIO_LIST
}

## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl

## For route_opt specific settings
puts "RM-info: Sourcing [which settings.route_opt.tcl]"
source -echo settings.route_opt.tcl

####################################
## Setup for PT delay calculation
####################################
# - PrimeTime delay calculation engine is OBD in route_opt if 2018.06 CLIB is present on a routed design 
#   and with CCS receiver (time.enable_ccs_rcv_cap) on. There is no need to specify db files.
# - If 2018.06 CLIB is not available and you want to enable PrimeTime delay calculation manually,
#   specify db path through $ROUTE_OPT_PT_DELAY_CALCULATION_DB_PATH, and RM script will set the appropriate settings.
# - Recommended settings for PrimeTime delay calculation engine
set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design ;# tool default disabled; enables AWP
set_app_options -name time.awp_compatibility_mode -value false ;# tool default true; false enables new AWP engine that is more aligned with PT
set_app_options -name time.enable_ccs_rcv_cap -value true ;# tool default false; enables CCS receiver model; required
set_app_options -name time.enable_si_timing_windows -value true ;# tool default false; enables timing window analysis during crosstalk analysis.  

## Explicitly enables PrimeTime delay calculation if ROUTE_OPT_PT_DELAY_CALCULATION_DB_PATH is specified
#  When specified, it is assumed that 2018.06 CLIB is not available to trigger PrimeTime delay calculation engine automatically
#  Note - only needed if 2018.06 CLIB is not available
if {$ROUTE_OPT_PT_DELAY_CALCULATION_DB_PATH != ""} { 
	lappend search_path $ROUTE_OPT_PT_DELAY_CALCULATION_DB_PATH
	set_app_options -name time.use_pt_delay -value true
}


####################################
## Pre-route_opt customizations
####################################
if {[file exists [which $TCL_USER_ROUTE_OPT_PRE_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_PRE_SCRIPT]"
        source $TCL_USER_ROUTE_OPT_PRE_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_PRE_SCRIPT != ""} {
	puts "RM-error : TCL_USER_ROUTE_OPT_PRE_SCRIPT($TCL_USER_ROUTE_OPT_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
## report_app_options & report_lib_cell_purpose	
####################################
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

####################################
## Post route optimization	
####################################
compute_clock_latency

## The following only applies to designs with physical hierarchy
## Ignore the sub-blocks (bound to abstracts) internal timing paths
if {$DESIGN_STYLE == "hier" && $PHYSICAL_HIERARCHY_LEVEL != "bottom"} {
	set_timing_paths_disabled_blocks  -all_sub_blocks
}

if {[file exists [which $TCL_USER_ROUTE_OPT_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_SCRIPT]"
        source $TCL_USER_ROUTE_OPT_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_SCRIPT != ""} {
	puts "RM-error: TCL_USER_ROUTE_OPT_SCRIPT($TCL_USER_ROUTE_OPT_SCRIPT) is invalid. Please correct it."
} else {

########################################################################
## First route_opt
########################################################################
## route_opt CCD in the first route_opt (RM default enabled)
#  Note: Global-scoped and needs to be re-applied in a new session
puts "RM-info: Setting route_opt.flow.enable_ccd to $ROUTE_OPT_CCD_IN_FIRST_RUN"
set_app_option -name route_opt.flow.enable_ccd -value $ROUTE_OPT_CCD_IN_FIRST_RUN ;# tool default false
puts "RM-info: Setting ccd.post_route_buffer_removal to $ROUTE_OPT_CCD_IN_FIRST_RUN"
set_app_option -name ccd.post_route_buffer_removal -value $ROUTE_OPT_CCD_IN_FIRST_RUN ;# tool default false

puts "RM-info: Running first route_opt"
route_opt
save_block -as ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}_1

## To disable soft-rule-based timing optimization during ECO routing, uncomment the following.
#  This is to limit spreading which can touch multiple routes and impact convergence.
#	set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false


########################################################################
## Second route_opt
########################################################################
## route_opt CCD in the second route_opt (RM default disabled)
puts "RM-info: Setting route_opt.flow.enable_ccd to $ROUTE_OPT_CCD_IN_SECOND_RUN for the second route_opt"
set_app_option -name route_opt.flow.enable_ccd -value $ROUTE_OPT_CCD_IN_SECOND_RUN ;# tool default false

## (Optional) enable PBA during PrimeTime delay calculation
if {$ROUTE_OPT_PT_DELAY_CALCULATION_WITH_PBA} {
	set_app_options -name time.pba_optimization_mode -value path 
	;# tool default false; enables path-based analysis during route_opt
	;# set it to exhaustive to apply an exhaustive path search algorithm to determine worst pba path to an endpoint
	
	## Disable CCD when PBA is enabled, if CCD is not already disabled
	if {[get_app_option_value -name route_opt.flow.enable_ccd]} {
		set_app_options -name route_opt.flow.enable_ccd -value false
	}
}

## (Optional) enable StarRC in-design extraction
#  Config file is required to properly set up StarRC run
if {[file exists [which $ROUTE_OPT_STARRC_CONFIG_FILE]]} {
	set_app_options -name extract.starrc_mode -value true
	set_starrc_in_design -config $ROUTE_OPT_STARRC_CONFIG_FILE ;# example: route_opt.starrc_config_example.txt
} elseif {$ROUTE_OPT_STARRC_CONFIG_FILE != ""} {
	puts "RM-error: ROUTE_OPT_STARRC_CONFIG_FILE($ROUTE_OPT_STARRC_CONFIG_FILE) is invalid. Please correct it."
}

puts "RM-info: Running second route_opt"
route_opt
save_block -as ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}_2

if {!$ROUTE_OPT_SKIP_THIRD_RUN} {

########################################################################
## Third route_opt
########################################################################
## Reset route_opt CCD for the last route_opt (if enabled earlier)
if {[get_app_option_value -name route_opt.flow.enable_ccd]} {
	puts "RM-info: Resetting route_opt.flow.enable_ccd (tool default false) for the third route_opt"
	reset_app_options route_opt.flow.enable_ccd ;# tool default false
}
## Reset power recovery for the last route_opt (if enabled earlier)
if {[get_app_option_value -name route_opt.flow.enable_clock_power_recovery] != "auto"} {
	puts "RM-info: Resetting route_opt.flow.enable_clock_power_recovery (tool default auto) for the third route_opt"
	reset_app_options route_opt.flow.enable_clock_power_recovery ;# tool default auto
}
## Reset clock DRC fixing for the last route_opt (if enabled earlier)
if {[get_app_option_value -name route_opt.flow.enable_ccd_clock_drc_fixing] != "auto"} {
	puts "RM-info: Resetting route_opt.flow.enable_ccd_clock_drc_fixing (tool default auto) for the third route_opt"
	reset_app_options route_opt.flow.enable_ccd_clock_drc_fixing ;# tool default auto
}

## Size-only is recommended for the last route_opt in the flow
#  Please uncomment and set the app option to a value appropriate to your library models, 
#  such as footprint, equal, or equal_or_smaller  
set_app_options -name route_opt.flow.size_only_mode -value equal_or_smaller

puts "RM-info: Running third route_opt"
route_opt

} else {puts "RM-info: Skipping third route_opt. ROUTE_OPT_SKIP_THIRD_RUN = true"}

}

####################################
## Targeted endpoint optimization	
####################################
## To optimize specific endpoints for setup, hold, or max_tran, specify the endpoints in a file 
#  by using the -setup_endpoints, -hold_endpoints, or -max_transition options
#  For ex, 
#	set_route_opt_target_endpoints -setup_endpoints $your_setup_endpoints_file
#	route_opt

## To adjust the timing at specific endpoints for setup or hold (such as to adjust timing to achieve PT slack), 
#  specify the endpoints and slack information in a file by using the -setup_timing or -hold_timing options
#  For ex, 
#	set_route_opt_target_endpoints -setup_timing $your_setup_timing_file
#	report_qor -summary ;# generate report with adjusted timing before route_opt
#	route_opt
#	report_qor -summary ;# generate report with adjusted timing after route_opt
#	set_route_opt_target_endpoints -reset ;# remove adjusted timing
#	report_qor -summary ;# generate report without adjusted timing after route_opt


####################################
## Reshield after route_opt
####################################
if {$ROUTE_AUTO_CREATE_SHIELDS != "none" && $ROUTE_OPT_RESHIELD == "after_route_opt"} {
	create_shields ;# without specifying -nets option, all nets with shielding rules will be shielded 
}

####################################
## Post-route_opt customizations	
####################################
if {[file exists [which $TCL_USER_ROUTE_OPT_POST_SCRIPT]]} {
	puts "RM-info: Sourcing [which $TCL_USER_ROUTE_OPT_POST_SCRIPT]"
        source $TCL_USER_ROUTE_OPT_POST_SCRIPT
} elseif {$TCL_USER_ROUTE_OPT_POST_SCRIPT != ""} {
	puts "RM-error : TCL_USER_ROUTE_OPT_POST_SCRIPT($TCL_USER_ROUTE_OPT_POST_SCRIPT) is invalid. Please correct it."
}

## Example to resolve short violated nets
#  Note that remove and reroute nets could potentially degrade timing QoR.
#
#  set data [open_drc_error_data -name zroute.err]
#  open_drc_error_data -name zroute.err
#  if { [sizeof_collection [get_drc_errors -quiet -error_data zroute.err -filter "type_name==Short"] ] > 0} {
#      set remove_net ""
#      foreach_in_collection net [get_attribute [get_drc_errors -error_data zroute.err -filter "type_name==Short"] objects] {
#          set net_type [get_attribute $net net_type]
#         if {$net_type=="signal"} {append_to_collection remove_net $net}
#      }
#      remove_routes -detail_route -nets $remove_net
#      route_eco
#  }

## If there are remaining routing DRCs, you can use the following :
#	check_routes
#	route_detail -incremental true -initial_drc_from_input true

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
	derive_hier_antenna_property -design ${DESIGN_NAME}/${ROUTE_OPT_BLOCK_NAME}
}

####################################
## Report and output
####################################			 
if {$REPORT_QOR} {
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


print_message_info -ids * -summary
echo [date] > route_opt

exit 

