##########################################################################################
# Tool: IC Compiler II
# Script: eco_opt.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 
set REPORT_PREFIX $ECO_OPT_BLOCK_NAME

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${ECO_OPT_FROM_BLOCK_NAME} -to ${DESIGN_NAME}/${ECO_OPT_BLOCK_NAME}
current_block ${DESIGN_NAME}/${ECO_OPT_BLOCK_NAME}
link_block

if {![check_license -quiet "Digital-AF"]} {
        puts "RM-error: Unable to find Digital-AF license. Exiting...."
        exit 
}
if {$ECO_OPT_PT_PATH == ""} {
        puts "RM-error: ECO_OPT_PT_PATH is not specified. ECO_OPT_PT_PATH is required. Exiting...."
        exit 
}

if {$ECO_OPT_ACTIVE_SCENARIO_LIST == "rm_activate_all_scenarios"} {
	set_scenario_status -active true [all_scenarios]
} elseif {$ECO_OPT_ACTIVE_SCENARIO_LIST != ""} {
	set_scenario_status -active false [get_scenarios -filter active]
	set_scenario_status -active true $ECO_OPT_ACTIVE_SCENARIO_LIST
}

####################################
## Common settings for this step
####################################
## For non-persistent settings that need to be re-applied in a new ICC-II session
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo settings.non_persistent.tcl


####################################
## Pre-eco_opt customizations
####################################
if {[file exists [which $TCL_USER_ECO_OPT_PRE_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ECO_OPT_PRE_SCRIPT]"
        source $TCL_USER_ECO_OPT_PRE_SCRIPT
} elseif {$TCL_USER_ECO_OPT_PRE_SCRIPT != ""} {
        puts "RM-error: TCL_USER_ECO_OPT_PRE_SCRIPT($TCL_USER_ECO_OPT_PRE_SCRIPT) is invalid. Please correct it."
}

####################################
## report_app_options & report_lib_cell_purpose	
####################################
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_lib_cell_purpose {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

####################################
## Core commands
####################################
## Use ECO_OPT_DB_PATH to specify search path to all db locations, if not already in your search_path.
#  Currently PT needs to read db.
if {$ECO_OPT_DB_PATH != ""} { 
	lappend search_path $ECO_OPT_DB_PATH
}

## Recommended to do check_legality and check_route first to ensure design is DRC/legalization clean before eco_opt.
#	redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_legality {check_legality}
#	redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_route {check_route}

################################################
## Set PT options
################################################
#  Use "set_pt_options -help" to check all the available options of set_pt_options
#  set_host_options example:
#	set_host_options -name eco_opt_host_option -submit_command "/lsf/bin/bsub -R \"rusage\[mem=$MEM\]"
#	set_pt_options -host_options eco_opt_host_option 
set set_pt_options_cmd "set_pt_options -pt_exec $ECO_OPT_PT_PATH"

if {$ECO_OPT_WORK_DIR != ""} {lappend set_pt_options_cmd -work_dir $ECO_OPT_WORK_DIR}

if {[file exists [which $ECO_OPT_PRE_LINK_SCRIPT]]} {
	lappend set_pt_options_cmd -pre_link_script $ECO_OPT_PRE_LINK_SCRIPT
} elseif {$ECO_OPT_PRE_LINK_SCRIPT != ""} {
	puts "RM-error: ECO_OPT_PRE_LINK_SCRIPT($ECO_OPT_PRE_LINK_SCRIPT) is invalid. Please correct it."
}

if {[file exists [which $ECO_OPT_POST_LINK_SCRIPT]]} {
	lappend set_pt_options_cmd -post_link_script $ECO_OPT_POST_LINK_SCRIPT
} elseif {$ECO_OPT_POST_LINK_SCRIPT != ""} {
	puts "RM-error: ECO_OPT_POST_LINK_SCRIPT($ECO_OPT_POST_LINK_SCRIPT) is invalid. Please correct it."
}

puts "RM-info: Running $set_pt_options_cmd"
eval $set_pt_options_cmd
redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.report_pt_options {report_pt_options}

################################################
## Enable StarRC in-design extraction (optional)
################################################
#  Config file is required to properly set up StarRC run
if {[file exists [which $ECO_OPT_STARRC_CONFIG_FILE]]} {
	set_app_options -name extract.starrc_mode -value true
	set_starrc_options -config $ECO_OPT_STARRC_CONFIG_FILE ;# example: route_opt.starrc_config_example.txt
	redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.report_starrc_options.rpt {report_starrc_options} 
} elseif {$ECO_OPT_STARRC_CONFIG_FILE != ""} {
	puts "RM-error: ECO_OPT_STARRC_CONFIG_FILE($ECO_OPT_STARRC_CONFIG_FILE) is invalid. Please correct it."
}

################################################
## Check and show PT QoR
################################################
#  Use "check_pt_qor -help" to check all the available options of check_pt_qor 
redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_pt_qor.pre.rpt {check_pt_qor}
redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_pt_qor.pre.summary.rpt {check_pt_qor -type summary}

################################################
## Perform PT-ECO
################################################
#  Use "eco_opt -help" to check all the available options of eco_opt 
set eco_opt_cmd "eco_opt"
if {$ECO_OPT_TYPE != ""} {lappend eco_opt_cmd -type $ECO_OPT_TYPE}
puts "RM-info: Running $eco_opt_cmd"
eval $eco_opt_cmd

################################################
## Check and show PT QoR
################################################
#  Use "check_pt_qor -help" to check all the available options of check_pt_qor 
redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_pt_qor.post.rpt {check_pt_qor}
redirect -tee -file ${REPORTS_DIR}/${ECO_OPT_BLOCK_NAME}.check_pt_qor.post.summary.rpt {check_pt_qor -type summary}

####################################
## Post-eco_opt customizations
####################################
if {[file exists [which $TCL_USER_ECO_OPT_POST_SCRIPT]]} {
        puts "RM-info: Sourcing [which $TCL_USER_ECO_OPT_POST_SCRIPT]"
        source $TCL_USER_ECO_OPT_POST_SCRIPT
} elseif {$TCL_USER_ECO_OPT_POST_SCRIPT != ""} {
	puts "RM-error: TCL_USER_ECO_OPT_POST_SCRIPT($TCL_USER_ECO_OPT_POST_SCRIPT) is invalid. Please correct it."
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
	set REPORT_PREFIX $ECO_OPT_BLOCK_NAME
	puts "RM-info: Sourcing [which $REPORT_QOR_SCRIPT]"
	source $REPORT_QOR_SCRIPT
}


print_message_info -ids * -summary
echo [date] > eco_opt

exit 

