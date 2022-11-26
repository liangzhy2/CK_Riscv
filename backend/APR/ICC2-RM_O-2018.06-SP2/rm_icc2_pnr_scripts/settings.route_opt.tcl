puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: settings.route_opt.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## Power : power optimization during route_opt (RM default true)
#  The type of power optimization depends on scenario setup (set_scenario_status)
#  Global-scoped and needs to be re-applied in a new session
puts "RM-info: Setting route_opt.flow.enable_power to $ROUTE_OPT_POWER_OPTIMIZATION (tool default false)"
set_app_options -name route_opt.flow.enable_power -value $ROUTE_OPT_POWER_OPTIMIZATION

## CTS power or area recovery from clock cells and registers during route_opt
#  Note: this feature affects both CCD and non-CCD route_opt
#  - If CCD is enabled (route_opt.flow.enable_ccd = true), with auto (tool and RM default), route_opt will enable power recovery,
#    if there is a dynamic power scenario enabled in the design. 
#    Set ROUTE_OPT_CLOCK_POWER_RECOVERY to none if you want this behavior disabled. Set it to area to do area recovery instead.
#    Set it to power to enable power recovery if there are only leakage power scenarios enabled.
#  - If CCD is not enabled, with auto (tool and RM default), route_opt will not enable the feature.
#    Set ROUTE_OPT_CLOCK_POWER_RECOVERY to power or area if you want to enable the feature. 
puts "RM-info: Setting route_opt.flow.enable_clock_power_recovery to $ROUTE_OPT_CLOCK_POWER_RECOVERY (tool default auto)"
set_app_option -name route_opt.flow.enable_clock_power_recovery -value $ROUTE_OPT_CLOCK_POWER_RECOVERY ;# tool default auto

## CTS : Clock DRC fixing during route_opt
#  Note: this feature affects both CCD and non-CCD route_opt
#  - If CCD is enabled (route_opt.flow.enable_ccd = true), with auto (tool and RM default), route_opt will enable the feature.
#    Set ROUTE_OPT_CTO to always_off if you want it disabled. 
#  - If CCD is not enabled, with auto (tool and RM default), route_opt will not enable the feature.
#    Set ROUTE_OPT_CTO to always_on if you want to enable the feature.
puts "RM-info: Setting route_opt.flow.enable_ccd_clock_drc_fixing to $ROUTE_OPT_CTO (tool default auto)"
set_app_options -name route_opt.flow.enable_ccd_clock_drc_fixing -value $ROUTE_OPT_CTO ;# tool default auto

## ECO route : spreading
## To disable soft-rule-based timing optimization during ECO routing, uncomment the following.
#  This is to limit spreading which can impact convergence by touching multiple routes.
#	set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false


## Incremental reshielding 
if {$ROUTE_AUTO_CREATE_SHIELDS != "none" && $ROUTE_OPT_RESHIELD == "incremental"} {
	puts "RM-info: Setting route.common.reshield_modified_nets to reshield (tool default off)"
	set_app_options -name route.common.reshield_modified_nets -value reshield
}

## Instance name prefix 
if {$ROUTE_OPT_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name opt.common.user_instance_name_prefix -value $ROUTE_OPT_USER_INSTANCE_NAME_PREFIX
}
if {$ROUTE_OPT_CTO_USER_INSTANCE_NAME_PREFIX != ""} {
	set_app_options -name cts.common.user_instance_name_prefix -value $ROUTE_OPT_CTO_USER_INSTANCE_NAME_PREFIX
}

puts "RM-info: Completed script [info script]\n"
