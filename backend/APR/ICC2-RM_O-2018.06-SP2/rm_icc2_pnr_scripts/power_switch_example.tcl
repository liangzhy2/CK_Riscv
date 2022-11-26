puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: power_switch_example.tcl
# This is a sample script to insert, assign, and connect power switches.
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## Insert power switches for UPF strategy PSW_1 in array format
create_power_switch_array -power_switch psw1_va \
   -voltage_area psw1_va \
   -x_pitch  45.5  -y_pitch  3.5 \
   -prefix psw_1

## Insert power switches for UPF strategy PSW_2 in ring format
create_power_switch_ring -power_switch PSW_2 \
   -voltage_area psw2_va \
   -prefix psw_2 \
   -snap_to_site_row true

## Assigne power switch control signals to variables
set psw_1_source "top/mod1/psw_shutdown"
set psw_2_source "top/mod2/psw_shutdown"

## Connect power switch sleep signals in high fanout mode
connect_power_switch \
   -mode hfn \
   -source $psw_1_source \
   -port_name  SLEEP \
   -object_list [get_cells -physical *psw_1*]

## Connect power switch sleep signals in daisy chain mode
connect_power_switch \
   -mode daisy \
   -source $psw_2_source \
   -port_name SLEEP \
   -direction vertical \
   -object_list [get_cells -physical *psw_2*]

## Ensure all power switch cells have been associated with UPF strategies
associate_mv_cells -power_switches

## Connect the PG pin of newly inserter power switch cells
connect_pg_net -automatic

puts "RM-info: Completed script [info script]\n"

