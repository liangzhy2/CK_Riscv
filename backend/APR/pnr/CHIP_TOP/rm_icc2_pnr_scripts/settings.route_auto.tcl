puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.route_auto.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## Timing and crosstalk driven
set_app_options -name route.track.timing_driven -value true
set_app_options -name route.detail.timing_driven -value true
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.crosstalk_driven -value true
# set_app_options -name route.global.timing_driven -value true ;# already set in settings.place_opt.tcl which is soured in the place_opt.tcl

## Noise threshold : used by router to identity the criticality of xtalk impact of the nets
#  Specify a lower number for the router to pick up more nets as xtalk critical nets.
#  For these nets, the router will try to reduce parallel routing as much as possible.
#	set_app_options -name route.common.threshold_noise_ratio -value 0.25

## Antenna
if {$ROUTE_AUTO_ANTENNA_FIXING} {
	if {[file exists [which $TCL_ANTENNA_RULE_FILE]]} {
		puts "RM-info: Sourcing [which $TCL_ANTENNA_RULE_FILE]"
		source $TCL_ANTENNA_RULE_FILE
	} elseif {$TCL_ANTENNA_RULE_FILE != ""} {
		puts "RM-error : ROUTE_AUTO_ANTENNA_FIXING is true but TCL_ANTENNA_RULE_FILE($TCL_ANTENNA_RULE_FILE) is invalid. Please correct it."
	}
}
## To disables antenna analysis and fix
#	set_app_options -name route.detail.antenna -value false ;# default true
#  To disables layer hopping for antenna fix
#	set_app_options -name route.detail.hop_layers_to_fix_antenna -value false ;# default true

## Redundant via insertion : mapping 
if {$REDUNDANT_VIA_INSERTION} {
## Source ICC-II via mapping file for redundant via insertion	
	if {[file exists [which $TCL_USER_REDUNDANT_VIA_MAPPING_FILE]]} {
		puts "RM-info: Sourcing [which $TCL_USER_REDUNDANT_VIA_MAPPING_FILE]"
		source $TCL_USER_REDUNDANT_VIA_MAPPING_FILE
		report_via_mapping
## Source ICC via mapping file that contains define_zrt_redundant_vias commands
	} elseif {[file exists [which $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE]]} {
		puts "RM-info: Sourcing [which $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE]"
		add_via_mapping -from_icc_file $TCL_USER_ICC_REDUNDANT_VIA_MAPPING_FILE
		report_via_mapping
	} else {
		puts "RM-warning: No valid redundant via mapping file has been specified."
	}

## Redundant via insertion : concurrent insertion 
#  For established nodes, run concurrent redundant via insertion during route_auto and route_opt.
	set_app_options -name route.common.post_detail_route_redundant_via_insertion -value medium ;# default off
}

## Redundant via insertion : starting layers 
## To insert redundant vias starting from lower layers first then process higher layers, set the following.
#  Depending on the design, redundant via insertion rates on DPT layers can be higher if insertion is done from lower to upper layers.
#	set_app_options -name route.detail.insert_redundant_vias_layer_order_low_to_high -value true ;# default false

## Timing : enable crosstalk analysis and the extraction of the routed nets along with their coupling caps
set_app_options -name time.si_enable_analysis -value true ;# default false

## GRLB handling (GRLB is default on in RM for 20nm and above)
## Prepare the design for final routing if GRLB (global route layer aware optimization) is enabled in preroute;
#  However if CLOCK_OPT_GLOBAL_ROUTE_OPT is also enabled along with GRLB, the following is not needed because
#  CLOCK_OPT_GLOBAL_ROUTE_OPT will automatically perform remove_route_aware_estimation  
if {[get_app_option_value -name opt.common.use_route_aware_estimation] != "false" && !($CLOCK_OPT_GLOBAL_ROUTE_OPT == "true")} {
	remove_route_aware_estimation
}

puts "RM-info: Completed script [info script]\n"
