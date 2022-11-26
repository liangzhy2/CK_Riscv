puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: settings.non_persistent.tcl
# Description : Settings that need to be re-applied in each new ICC-II session are incldued below.
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

####################################
## Timer 
####################################
## set_app_options -name time.enable_preset_clear_arcs -value true ;# tool default false, global-scoped

####################################
## Keepout margin (lib cell based) 
####################################
## Lib cell based keepout margin is not persistent in the current release and must be re-applied in new ICC-II seccions.
#  Example : create_keepout_margin -outer {5 5 5 5} [get_lib_cells */lib_cell_name]

####################################
## set_threshold_voltage_group_type 
####################################
## Set your threshold_voltage_group attributes. These are persistent and can be simply defined in settings.place_opt.tcl. 
#  Listed here for your reference. For example:
#  	define_user_attribute -type string -class lib_cell threshold_voltage_group
#  	set_attribute -quiet [get_lib_cells -quiet */*LVT] threshold_voltage_group LVt
#  	set_attribute -quiet [get_lib_cells -quiet */*RVT] threshold_voltage_group RVt
#  	set_attribute -quiet [get_lib_cells -quiet */*HVT] threshold_voltage_group HVt

## set_threshold_voltage_group_type is not persistent and should be defined here:
#  	set_threshold_voltage_group_type -type low_vt LVt
#  	set_threshold_voltage_group_type -type normal_vt RVt
#  	set_threshold_voltage_group_type -type high_vt HVt

puts "RM-info: Completed script [info script]\n"
