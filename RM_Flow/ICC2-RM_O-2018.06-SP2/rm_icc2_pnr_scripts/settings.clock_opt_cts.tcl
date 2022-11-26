puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.clock_opt_cts.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## CTS restrictions 
#  The following will be applied at place_opt if ICG optimization, trial clock, or MSCTS is enabled there.
if {!($PLACE_OPT_OPTIMIZE_ICGS || $PLACE_OPT_TRIAL_CTS || $PLACE_OPT_MSCTS)} {
	# Set CTS dont touch cells	
	if {$CTS_DONT_TOUCH_CELL_LIST != ""} {set_dont_touch $CTS_DONT_TOUCH_CELL_LIST true}
	
	# Set CTS dont buffer nets	
	if {$CTS_DONT_BUFFER_NET_LIST != ""} {set_dont_touch [get_nets -segments $CTS_DONT_BUFFER_NET_LIST] true}
	
	# set CTS size only cells
	if {$CTS_SIZE_ONLY_CELL_LIST != ""} {set_size_only $CTS_SIZE_ONLY_CELL_LIST true}
}

## clock_opt CCD (RM default true)
#  Enables concurrent clock and data optimization (CCD) during clock_opt
#  Note: CCD flow by default enables local skew CTS/CTO under the hood.
puts "RM-info: Setting clock_opt.flow.enable_ccd to $CLOCK_OPT_CCD (tool default false)"
set_app_option -name clock_opt.flow.enable_ccd -value $CLOCK_OPT_CCD

## For non-CCD flow, to improve local skew of timing critical register pairs,
#  uncomment the following to enable local skew optimization during CTS and CTO:
#	set_app_options -name cts.compile.enable_local_skew -value true
#	set_app_options -name cts.optimize.enable_local_skew -value true

## For non-CCD flow, the clock SI prevention feature for minimizing the impact of SI from/on clock nets 
#  at postroute can be turned on by uncommenting the following application
#  options:
#	set_app_options -name cts.optimize.enable_congestion_aware_ndr_promotion -value true

## Enable power or area recovery from clock cells and registers during clock_opt (optional)
#  By default, it is set to auto which means in CCD flow, power recovery is on for the wns phase of clock_opt; 
#  while in non-CCD flow, auto means none.
puts "RM-info: Setting clock_opt.flow.enable_clock_power_recovery to $CLOCK_OPT_POWER_RECOVERY (tool default auto)"
set_app_option -name clock_opt.flow.enable_clock_power_recovery -value $CLOCK_OPT_POWER_RECOVERY

## GR-based CTS: congestion estimation and congestion-aware path finder for clock_opt build_clock phase (optional)
#  Can be enabled for better congestion estimation
puts "RM-info: Setting cts.compile.enable_global_route to $CTS_ENABLE_GLOBAL_ROUTE (tool default false)" 
set_app_option -name cts.compile.enable_global_route -value $CTS_ENABLE_GLOBAL_ROUTE

## Coarse placement effort for clock_opt final_opto phase (optional)
#  Can be enabled for better placement quality
puts "RM-info: Setting clock_opt.place.effort to $CLOCK_OPT_OPTO_PLACE_EFFORT (tool default medium)"
set_app_option -name clock_opt.place.effort -value $CLOCK_OPT_OPTO_PLACE_EFFORT

## Congestion effort for clock_opt final_opto phase (optional)
#  Can be enabled for better congestion alleviation
puts "RM-info: Setting clock_opt.congestion.effort to $CLOCK_OPT_OPTO_CONGESTION_EFFORT (tool default medium)"
set_app_option -name clock_opt.congestion.effort -value $CLOCK_OPT_OPTO_CONGESTION_EFFORT

puts "RM-info: Completed script [info script]\n"
