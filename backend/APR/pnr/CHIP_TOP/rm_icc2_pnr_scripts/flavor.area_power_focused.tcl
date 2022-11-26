puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.area_power_focused.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for area and power focused designs
#  Please source this file at the end of icc2_pnr_setup.tcl

set PREROUTE_AREA_RECOVERY_EFFORT 	"ultra" ;# high|low|medium|ultra; tool default low; RM default high;
					;# sets opt.area.effort to the specified value to trade off between TNS and area; higher effort can degrades TNS;

set PLACE_OPT_GR_BASED_HFSDRC		false ;# true|false; tool default false; RM default true;	
					;# sets place_opt.initial_drc.global_route_based to 1 to enable GR-based buffering (GRopto) in HFSDRC phase

set PLACE_OPT_CONGESTION_EFFORT		"medium" ;# high|medium|none; tool default medium; RM default high;	
					;# sets place_opt.congestion.effort to specified value to control congestion alleviation effort in place_opt final_place phase;
					;# expect a significant increase in run time at high effort.

set CLOCK_OPT_POWER_RECOVERY		"power" ;# auto|power|area|none; tool default auto; optional in RM;
					;# sets clock_opt.flow.enable_clock_power_recovery to the specified value

set ROUTE_OPT_CLOCK_POWER_RECOVERY	"power" ;# auto|none|power|area; tool default auto; RM default auto;
					;# sets route_opt.flow.enable_clock_power_recovery to specified value for power or area recovery in route_opt.
					;# Note: this feature affects both CCD and non-CCD route_opt; 
					;# if CCD is enabled, with auto, and with dynamic power scenario enabled in the design, route_opt will enable power recovery;
					;# set it to none to have it disabled; set it to area for area recovery or power if only leakage power scenario is enabled;
					;# if CCD is not enabled, with auto, this feature won't be enabled; set it to power or area to enable the feature.
puts "RM-info: Completed script [info script]\n"
