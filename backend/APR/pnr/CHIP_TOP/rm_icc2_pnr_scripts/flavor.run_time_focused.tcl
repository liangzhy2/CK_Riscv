puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.run_time_focused.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for run time considerations
#  Please source this file at the end of icc2_pnr_setup.tcl

set PREROUTE_TIMING_OPTIMIZATION_EFFORT "medium"	;# low|medium|high; tool default low; RM default high;
					;# sets opt.timing.effort to enable the corresponding effort of timing optimization in preroute

set PREROUTE_POWER_OPTIMIZATION_EFFORT	"medium" ;# low|medium|high; tool default low; RM default high;
					;# sets opt.power.effort to the specified effort;

set PREROUTE_ROUTE_AWARE_ESTIMATION	false ;# true|false; tool default false; RM default true;	
					;# sets opt.common.use_route_aware_estimation to use layer-aware parasitics in preroute extraction;

set PREROUTE_ENHANCED_LOW_POWER_PLACEMENT_EFFORT "none" ;# none|low|medium|high; tool default low; optional in RM;
					;# sets place.coarse.enhanced_low_power_effort to reduce net switching power; set it to low/medium/high to enable the feature;
					;# higher values makes the coarse placer focus on optimizing net switching power, at possible cost of other metrics (e.g. wire length and rouability);
					;# affects place_opt final_place phase, clock_opt final_opto phase, and create_placement;
					;# this feature ignores the value of place.coarse.low_power_placement app option.

set PLACE_OPT_GR_BASED_HFSDRC		false ;# true|false; tool default false; RM default true;	
					;# sets place_opt.initial_drc.global_route_based to 1 to enable GR-based buffering (GRopto) in HFSDRC phase

set PLACE_OPT_FINAL_PLACE_EFFORT	"medium" ;# high|medium; tool default medium; RM default high;  	
					;# sets place_opt.final_place.effort to specified value to control the effort of final coarse placement in place_opt 

set PLACE_OPT_CONGESTION_EFFORT		"medium" ;# high|medium|none; tool default medium; RM default high;	
					;# sets place_opt.congestion.effort to specified value to control congestion alleviation effort in place_opt final_place phase;
					;# expect a significant increase in run time at high effort.

set CLOCK_OPT_GLOBAL_ROUTE_OPT		false ;# true|false; tool default false; RM default true; 
					;# enables Global Route Based Optimization by setting clock_opt.flow.enable_global_route_opt 
					;# and route_opt.flow.enable_power to true, sources routing settings, and runs clock_opt -from global_route_opt;
					;# this feature is added to route_auto.tcl; if enabled, it replaces route_global command;

set ROUTE_OPT_CCD_IN_FIRST_RUN		false ;# true|false; tool default false; RM default true;	
					;# sets route_opt.flow.enable_ccd to true to enable CCD in first route_opt;
					;# sets ccd.post_route_buffer_removal to performs buffer removal during route_opt CCD.
puts "RM-info: Completed script [info script]\n"
