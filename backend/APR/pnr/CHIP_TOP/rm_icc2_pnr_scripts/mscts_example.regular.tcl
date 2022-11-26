puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: mscts_example.regular.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
## The following is a sample script for regular MSCTS construction.
#  The script is intended for the following clock structure :
#  clock root -> global clock tree (HTree) -> clock mesh drivers -> clock mesh 
#  -> tap drivers -> subtrees
##########################################################################################

# Build global clock distribution structure and define tap assignment constraints 
	
#############################
## MSCTS specific settings
#############################
set MSCTS_CLOCK	""				;# Clock name
set MSCTS_SOURCE "" 				;# Multisource Clock root
set MSCTS_NDR_MAX_ROUTING_LAYER ""		;# Clock NDR max routing layer for MSCTS in general

## Variables for the global clock tree (Htree) 
set MSCTS_HTREE_NDR_RULE_NAME ""		;# Htree NDR rule name
set MSCTS_HTREE_MIN_ROUTING_LAYER ""		;# Htree min routing layer
set MSCTS_HTREE_MAX_ROUTING_LAYER ""		;# Htree max routing layer
set MSCTS_HTREE_DRIVER_LIB_CELLS ""		;# Htree driver lib cells

## Variables for the clock mesh creation and mesh driver insertion
set MSCTS_CLOCK_MESH_NAME ""			;# Mesh net name
set MSCTS_CLOCK_MESH_DRIVER_LIB_CELLS ""	;# Mesh driver lib cells	
set MSCTS_CLOCK_MESH_DRIVER_MAX_DISPLACEMENT ""	;# Mesh driver max displacement
set MSCTS_CLOCK_MESH_STRAP_HORIZONTAL_LAYER ""	;# Mesh strap horizontal layer	
set MSCTS_CLOCK_MESH_STRAP_VERTICAL_LAYER ""	;# Mesh strap vertical layer
set MSCTS_CLOCK_MESH_ROUTE_NDR_RULE_NAME "" 	;# Mesh routing to clock straps NDR rule name (comb/fishbone)
set MSCTS_CLOCK_MESH_ROUTE_MIN_ROUTING_LAYER "" ;# Mesh routing to clock straps min routing layer
set MSCTS_CLOCK_MESH_ROUTE_MAX_ROUTING_LAYER "" ;# Mesh routing to clock straps max routing layer

## Variables for the tap driver insertion
set MSCTS_TAP_DRIVER_LIB_CELLS ""		;# Tap driver lib cells
set MSCTS_TAP_DRIVER_MAX_DISPLACEMENT ""	;# Tap driver max displacement

## Variables for the analyze_subcircuit command
#  Note: Specify full paths to the driver and spice header files
set MSCTS_ANALYZE_DRIVER_FILES ""		;# Driver files for analyze_subcircuit
set MSCTS_ANALYZE_SPICE_HEADER_FILES ""		;# SPICE header files for analyze_subcircuit
set MSCTS_ANALYZE_SCENARIO ""			;# Specify the scenario name for analyze_subcircuit
set MSCTS_ANALYZE_SCENARIO_MAX_SPICE_HEADER_FILES "" ;# Scenario max SPICE header files
set MSCTS_ANALYZE_SCENARIO_MIN_SPICE_HEADER_FILES "" ;# Scenario min SPICE header files

## MSCTS specific application option settings
set_app_options -name cts.multisource.subtree_merge_cell_name_suffix -value mscts_merge
set_app_options -name cts.multisource.subtree_split_cell_name_suffix -value mscts_split

## Application option to enable MSCTS support for MV designs
#  This punches port on power domain boundaries and merges/clones power management cells (isolation and level shifters)
#  set_app_options -name cts.multisource.enable_full_mv_support -value true
#  Enable below application option for physical feedthrough nets and power domain on instances support
#  set_app_options -name opt.common.allow_physical_feedthrough -value true
 
#  For more detailed log file output, set the following application option
#	set_app_options -name cts.multisource.verbose -value 8 

set_ignored_layers -max_routing_layer $MSCTS_NDR_MAX_ROUTING_LAYER
set mscts_root_net [get_nets -of $MSCTS_SOURCE]

## Remove constraints like dont_touch, fixed, locked and user_size_only on nets/cells to allow merging/splitting of clock cells for tap assignment
mark_clock_trees -clear -dont_touch
set_size_only $cell_list false

##########################################################################################
## STEP 1 : Insert multisource tap drivers
##########################################################################################
## Temporarily disabled pin accessibility check since tap drivers are not directly driven by 
#  Htree in the aforementioned clock structure
set RM_current_value_pin_accessibility \
[get_app_option_value -name cts.multisource.enable_pin_accessibility_for_global_clock_trees]
set_app_options -name cts.multisource.enable_pin_accessibility_for_global_clock_trees -value false

## Use -max_displacement to control maximum cell displacement allowed from preferred location
#  Specify desired values for the -boxes option  
create_clock_drivers -loads $mscts_root_net -lib_cells $MSCTS_TAP_DRIVER_LIB_CELLS -prefix mscts_tap_driver \
-boxes {columns rows} -max_displacement $MSCTS_TAP_DRIVER_MAX_DISPLACEMENT

set_app_options -name cts.multisource.enable_pin_accessibility_for_global_clock_trees -value ${RM_current_value_pin_accessibility}
legalize_placement

##########################################################################################
## STEP 2: Insert Clock Mesh structure 
##########################################################################################
## Specify desired values for the -widths, -margins, and -grids options
create_clock_straps -nets $mscts_root_net \
-layers "$MSCTS_CLOCK_MESH_STRAP_HORIZONTAL_LAYER $MSCTS_CLOCK_MESH_STRAP_VERTICAL_LAYER" \
-widths {widthH widthV} -margins {marginH marginV} \
-types {stripe stripe} -grids {{startH endH stepH} {startV endV stepV}}  

##########################################################################################
## STEP 3: Insert Clock Mesh drivers, create multi-driven net and transfer clock mesh 
#          structure to multi-driven net  
##########################################################################################
## Define a NDR rule with "set_routing_rule" to prevent NDR propagation to output net. 
#  NDR and layer assignment is required to ensure pin accessibility of Htree loads.
set_routing_rule -rule $MSCTS_HTREE_NDR_RULE_NAME -min_routing_layer $MSCTS_HTREE_MIN_ROUTING_LAYER \
-max_routing_layer $MSCTS_HTREE_MAX_ROUTING_LAYER [get_nets $mscts_root_net]

## Specify desired values of num_columns and num_rows for the -boxes option.
#  Each of num_columns and num_rows should be an integer that is power of 2, such as 4 columns and 4 rows.  
#  The mesh drivers are loads of Htree in the structure, hence loads are inserted such that 
#  they are in {num_columns X num_rows} and distributed uniformly. 
#  Use -max_displacement of min{0.3 times x_pitch, 0.3 times y_pitch} for uniform clock driver insertion,
#  where pitch is associated with clock driver columns and rows.
#  This helps in achieving structurally symmetric Htree with low skew across the corners
create_clock_drivers -loads $mscts_root_net -boxes {num_columns num_rows} -lib_cells $MSCTS_CLOCK_MESH_DRIVER_LIB_CELLS \
-prefix mscts_mesh_driver -short_outputs -transfer_wires_from $mscts_root_net -output_net_name $MSCTS_CLOCK_MESH_NAME \
-max_displacement $MSCTS_CLOCK_MESH_DRIVER_MAX_DISPLACEMENT

legalize_placement

##########################################################################################
## STEP 4: Build Global Clock Tree (Htree) to drive the mesh drivers
##########################################################################################
## Remove NDR specified in STEP 3 and re-apply NDR with "set_clock_routing_rules" to ensure 
#  NDR propagation to newly created Htree nets
set_routing_rule -clear [get_nets $mscts_root_net]
set_clock_routing_rules -rule $MSCTS_HTREE_NDR_RULE_NAME -nets $mscts_root_net \
-min_routing_layer $MSCTS_HTREE_MIN_ROUTING_LAYER -max_routing_layer $MSCTS_HTREE_MAX_ROUTING_LAYER

synthesize_multisource_global_clock_trees -nets $mscts_root_net -lib_cells $MSCTS_HTREE_DRIVER_LIB_CELLS \
-use_zroute_for_pin_connections -prefix mscts_htree

##########################################################################################
## STEP 5: Route to clock straps and freeze the mesh net
##########################################################################################
###Define NDR and layer list for routing to clock straps

##Control comb distance using below app option
# set_app_options -name route.common.comb_distance -value 2; default is 2 gCells. Max value that can be specified is 10

##Specify layers to be used for routing pins to clock straps during comb/fishbone routing
set_routing_rule -rule $MSCTS_CLOCK_MESH_ROUTE_NDR_RULE_NAME -min_routing_layer $MSCTS_CLOCK_MESH_ROUTE_MIN_ROUTING_LAYER \
-max_routing_layer $MSCTS_CLOCK_MESH_ROUTE_MIN_ROUTING_LAYER [get_nets $MSCTS_CLOCK_MESH_NAME]

##Specify appropriate value to indicate number of via layers that can be traversed to access a pin above net-max layer if layers used for routing are lower than the clock strap layers
#set_app_options -name route.common.number_of_vias_over_net_max_layer -value 1; default is 1

route_clock_straps -nets $MSCTS_CLOCK_MESH_NAME 
set_dont_touch [get_nets $MSCTS_CLOCK_MESH_NAME]
set_attribute [get_nets $MSCTS_CLOCK_MESH_NAME] physical_status locked

## check that the clock mesh net is connected
check_routes -check_from_user_shapes  true -check_from_frozen_shapes  true -nets $MSCTS_CLOCK_MESH_NAME

##########################################################################################
## STEP 6: Simulate clock mesh and annotate timing information on it
##########################################################################################

if {!$PLACE_OPT_MSCTS} {
   ## Propagate clock for timer to see actual transitions on the Htree before CTS
   synthesize_clock_trees -propagate_only
}

update_timing -full

analyze_subcircuit -net $MSCTS_CLOCK_MESH_NAME -from [get_pins -filter "direction==in&&port_type!=power&&port_type!=ground" -of [get_cells -physical *mscts_mesh_driver*]]  \
-MSCTS_ANALYZE_DRIVER_FILES $MSCTS_ANALYZE_DRIVER_FILES \
-MSCTS_ANALYZE_SPICE_HEADER_FILES $MSCTS_ANALYZE_SPICE_HEADER_FILES \
-clock $MSCTS_CLOCK \
-configuration { \
	-scenario_name $MSCTS_ANALYZE_SCENARIO \
	-max_spice_header_files $MSCTS_ANALYZE_SCENARIO_MAX_SPICE_HEADER_FILES \
	-min_spice_header_files $MSCTS_ANALYZE_SCENARIO_MIN_SPICE_HEADER_FILES \
} \
-simulator hspice \
-name clk_mesh_analysis

########################################################################################## 
## STEP 7: Tap assignment settings
##########################################################################################
set tap_drivers [get_pins -filter "direction==out" -of [get_cells *mscts_tap_driver* -physical] ]
## Define tap assignment settings 
set_multisource_clock_tap_options -clock $MSCTS_CLOCK \
	-driver_objects  $tap_drivers -num_taps [sizeof [get_pins $tap_drivers]]
# Use -dont_merge_cells to provide list of cells which should not get merged with other cells during tap assignment merge stage

##########################################################################################
## STEP 8: Restore original settings (if any)
##########################################################################################
## Min-max routing layer constraint
set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER

#Reset app options to previous values
#set_app_options -name route.common.comb_distance -value $previous_value
#set_app_options -name route.common.number_of_vias_over_net_max_layer  -value $previous_value

puts "RM-info: Completed script [info script]\n"
