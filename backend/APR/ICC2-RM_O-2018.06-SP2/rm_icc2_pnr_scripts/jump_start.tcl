##########################################################################################
# Tool: IC Compiler II
# Script: jump_start.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################
#############################################################################################
# Note
# - To keep the script short and simple, unlike the full version, this version 
#   does not contain any error checking or message printing. The script has limited use of  
#   Tcl variables and contains minimum number of optional ICC-II features compared to the full version.
# - This version is intended for designs starting with SPG inputs coming from DC with DC's 
#   write_icc2_files outputs. The technology is based on established nodes.
# - Refer to the full version of ICC2-RM for the complete features and usages. 
#############################################################################################
####################################
## Variables 
####################################
set DESIGN_NAME 		"" ;# Name of the design to be worked on
set DESIGN_LIBRARY 		"${DESIGN_NAME}" ;# Name of the design library; default is ${DESIGN_NAME}
set TECH_FILE 			"" ;# A technology file
set REFERENCE_LIBRARY 		[list ]	;# A list of reference libraries for the design library.
set DCRM_RESULTS_DIR		"./results" ;# specifies DC-RM output directory. Default is ./results.

set MAX_ROUTING_LAYER 		""
set MIN_ROUTING_LAYER 		""
set CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST "" ;# A list of metal filler (decap) lib cells, including the library name
set ICV_IN_DESIGN_DRC_CHECK_RUNSET "z_icvFill" ;# The working directory for signoff_create_metal_fill. Optional. Default is z_icvFill.
set ICV_IN_DESIGN_METAL_FILL_RUNSET "" ;# Specify the foundry runset for signoff_create_metal_fill command;
set REPORTS_DIR 		"./rpts_icc2" ;# Directory to write reports
set OUTPUTS_DIR			"./outputs_icc2" ;# Directory to write output data files

file mkdir $REPORTS_DIR $OUTPUTS_DIR

set search_path [list ./rm_icc2_pnr_scripts ./rm_setup $REDHAWK_SEARCH_PATH]
lappend search_path .
if {$synopsys_program_name == "icc2_shell"} {set_host_options -max_cores 8}
if {$synopsys_program_name == "icc2_shell"} {
	## Enable on-disk operation for copy_block to save block to disk right away
	set_app_option -name design.on_disk_operation -value true ;# default false and global-scoped
}

set sh_continue_on_error true

####################################
## init_design 
####################################
## Commonly used features not included here can be found in the full version (init_design.tcl), such as :
#	- Library assembly flow for design library creation
#	- ASCII flow (starting with verilog, UPF, DEF, etc) 
#	- Additional floorplanning related contents such as initialize_floorplan, boundary cell, tap cell, etc
#	- POCV and AOCV setup

## Create the design library
file delete -force $DESIGN_LIBRARY
set_app_options -name lib.setting.on_disk_operation -value true ;# default false and global-scoped
create_lib $DESIGN_LIBRARY -tech $TECH_FILE -ref_libs $REFERENCE_LIBRARY
redirect -file ${REPORTS_DIR}/init_design.report_ref_libs {report_ref_libs}

## Read in design output files from Design Compiler's write_icc2_files command
source ${DCRM_RESULTS_DIR}/ICC2_files/${DESIGN_NAME}.icc2_script.tcl
commit_upf
associate_mv_cells -all

save_block -as init_design

####################################
## place_opt 
####################################
## Commonly used features not included here can be found in the full version (place_opt.tcl and settings.place_opt.tcl), such as :
#	- Set scenario status, Read SAIF, Set instance name prefix
#	- CTS max tran/cap, target skew/latency, balance points, skew groups, ICDB, latency adjustments, cell restrictions, and spacing
#	- Create and associate clock NDR (clock NDR examples in settings.place_opt.tcl)
#	- Set lib cell purpose restrictions (set_lib_cell_purpose.tcl)

set_app_options -name opt.timing.effort -value high
set_app_options -name place.coarse.auto_timing_control -value true
set_app_options -name opt.power.mode -value total
set_app_options -name opt.power.effort -value high
set_app_options -name opt.area.effort -value high
set_app_options -name opt.common.buffer_area_effort -value ultra
set_app_options -name opt.common.use_route_aware_estimation -value true
set_app_options -name place.coarse.channel_detect_mode -value true
set_app_options -name place.coarse.detect_detours -value true
set_app_options -name opt.port.eliminate_verilog_assign -value true
set_app_options -name route.global.timing_driven -value true
set_app_options -name time.enable_clock_to_data_analysis -value true
set_app_options -name place_opt.final_place.effort -value high
set_app_options -name place_opt.congestion.effort -value high
set_app_options -name place_opt.initial_drc.global_route_based -value 1
reset_app_options place_opt.flow.do_spg
set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER
set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER

redirect -file ${REPORTS_DIR}/report_routing_rules.rpt {report_routing_rules -verbose}
redirect -file ${REPORTS_DIR}/report_clock_routing_rules.rpt {report_clock_routing_rules}
redirect -tee -file ${REPORTS_DIR}/report_app_options.start {report_app_options -non_default *}
redirect -file ${REPORTS_DIR}/report_lib_cell_purpose.rpt {report_lib_cell -objects [get_lib_cells] -column {full_name:20 valid_purposes}}

mark_clock_trees -routing_rules
create_placement -buffering_aware_timing_driven
place_opt -from initial_drc -to initial_drc
update_timing -full
create_placement -incremental -timing_driven -congestion
place_opt -from initial_drc -to initial_opto
place_opt -from final_place

connect_pg_net
save_block -as place_opt
set REPORT_PREFIX place_opt
source report_qor.nosplit.tcl
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}

####################################
## clock_opt_cts 
####################################
## Commonly used features not included here can be found in the full version (clock_opt_cts.tcl and settings.clock_opt_cts.tcl), such as :
#	- CTS lib cell restrictions, and clock_opt CCD
#	- Enable power or area recovery from clock cells and registers during clock_opt
#	- GR-based CTS, Coarse placement effort for clock_opt final_opto, and Congestion effort for clock_opt final_opto
#	- To set up MSCTS : refer to MSCTS section of clock_opt_cts.tcl
#	- Bus routing example

set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name clock_opt.flow.enable_ccd -value true

redirect -file ${REPORTS_DIR}/clock_opt.pre_cts.check_clock_tree {check_clock_tree}
redirect -file ${REPORTS_DIR}/clock_opt.pre_cts.report_clock_settings {report_clock_settings}

clock_opt -from build_clock -to build_clock
clock_opt -from route_clock -to route_clock

connect_pg_net
save_block -as clock_opt_cts
set REPORT_PREFIX clock_opt_cts
source report_qor.nosplit.tcl
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}

####################################
## clock_opt_opto 
####################################
## Commonly used features not included here can be found in the full version (clock_opt_opto), such as :
#	- Clock propagation and IO latency computation for modes or corners which are not active during clock_opt_cts
#	- Non-CCD CTO

clock_opt -from final_opto -to final_opto

connect_pg_net
save_block -as clock_opt_opto
set REPORT_PREFIX clock_opt_opto
source report_qor.nosplit.tcl
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}

####################################
## route_auto 
####################################
## Commonly used features not included here can be found in the full version (route_auto.tcl and settings.route_auto.tcl), such as :
#	- Redundant via insertion with via mapping file and via mapping reporting
#	- Shielding
#	- Recommendations to resolve short violated nets and remaining routing DRCs

set_app_options -name route.track.timing_driven -value true
set_app_options -name route.detail.timing_driven -value true
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.crosstalk_driven -value true
set_app_options -name time.si_enable_analysis -value true
remove_route_aware_estimation

## Global route optimization 
set_app_options -name clock_opt.flow.enable_global_route_opt -value true
set_app_options -name route_opt.flow.enable_power -value true
clock_opt -from global_route_opt
## Track asssignment
update_timing; route_track
## Detail route
update_timing; route_detail

connect_pg_net
save_block -as route_auto
set REPORT_PREFIX route_auto
source report_qor.nosplit.tcl
redirect -tee -file ${REPORTS_DIR}/${REPORT_PREFIX}.report_congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}

####################################
## route_opt 
####################################
## Commonly used features not included here can be found in the full version (route_opt.tcl and settings.route_opt.tcl), such as :
#	- AWP
#	- Clock power recovery and clock DRC fixing
#	- Reshielding
#	- PT delay calculation based route_opt, with PBA, or with StarRC in-design extraction
#	- Targeted endpoint optimization

set_app_options -name time.enable_ccs_rcv_cap -value true
set_app_options -name route_opt.flow.enable_power -value true
compute_clock_latency

## First route_opt
set_app_option -name route_opt.flow.enable_ccd -value true
set_app_option -name ccd.post_route_buffer_removal -value true
route_opt

## Second route_opt
set_app_option -name route_opt.flow.enable_ccd -value false
route_opt

## Third route_opt
reset_app_options route_opt.flow.enable_ccd
reset_app_options route_opt.flow.enable_clock_power_recovery
reset_app_options route_opt.flow.enable_ccd_clock_drc_fixing
set_app_options -name route_opt.flow.size_only_mode -value equal_or_smaller
route_opt

connect_pg_net
save_block -as route_opt
set REPORT_PREFIX route_opt
source report_qor.nosplit.tcl

####################################
## chip_finish 
####################################
## Commonly used features not included here can be found in the full version (chip_finish.tcl), such as :
#	- Filler cell insertion to prevent 1x and 2x gaps
#	- Filler cell insertion prefix
#	- Signal EM analysis and fixing 

set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

set create_stdcell_filler_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST] area]]
create_stdcell_filler -lib_cell [list $create_stdcell_filler_metal_lib_cell_sorted]
connect_pg_net
remove_stdcell_fillers_with_violation

set create_stdcell_filler_non_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST] area]]
create_stdcell_filler -lib_cell [list $create_stdcell_filler_non_metal_lib_cell_sorted]
connect_pg_net
save_block -as chip_finish
set REPORT_PREFIX chip_finish
source report_qor.nosplit.tcl

####################################
## icv_in_design 
####################################
## Commonly used features not included here can be found in the full version (icv_in_design.tcl), such as :
#	- sign_off_fix_drc for DPT rules
#	- signoff_create_metal_fill for track-based creation
#	- Timing-driven signoff_create_metal_fill

set_app_options -name signoff.check_drc.runset -value $ICV_IN_DESIGN_DRC_CHECK_RUNSET

## signoff_check_drc
save_block ;# Save to disk is required as ICV reads from disk file instead of memory
set_app_options -name signoff.check_drc.run_dir -value z_check_drc
signoff_check_drc -error_data z_check_drc

## signoff_fix_drc
set_app_options -name signoff.fix_drc.init_drc_error_db -value z_check_drc
set_app_options -name signoff.fix_drc.run_dir -value z_adr
set_app_options -name signoff.fix_drc.custom_guidance -value off
signoff_fix_drc
save_block

## signoff_check_drc after signoff_fix_drc
set_app_options -name signoff.check_drc.run_dir -value z_post_adr
signoff_check_drc -error_data z_post_adr

## signoff_create_metal_fill
set_app_options -name signoff.create_metal_fill.run_dir -value z_icvFill
set_app_options -name signoff.create_metal_fill.runset -value $ICV_IN_DESIGN_METAL_FILL_RUNSET
save_block
signoff_create_metal_fill

## signoff_check_drc after signoff_create_metal_fill
set_app_options -name signoff.check_drc.fill_view_data -value read_if_uptodate
set_app_options -name signoff.check_drc.run_dir -value z_MFILL_after
signoff_check_drc -error_data z_MFILL_after
set_extraction_options -real_metalfill_extraction floating

set REPORT_PREFIX chip_finish
source report_qor.nosplit.tcl

####################################
## write_data 
####################################
## Commonly used features not included here can be found in the full version (write_data.tcl), such as :
#	- Write verilog for comparison with other tools such as DC, PT, LVS, or VC LP
#	- Additional write_gds and write_oasis options	

change_names -rules verilog -hierarchy
save_block

## Write verilog and UPF for Formality
set_app_option -name mv.upf.write_crosstool_wrappers -value true
write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells supply_statements} -hierarchy all ${OUTPUTS_DIR}/write_data.fm.v

## Write DEF
write_def -compress gzip -version 5.8 ${OUTPUTS_DIR}/write_data.def

## Write script (PT compatible)
write_script -compress gzip -format pt -output ${OUTPUTS_DIR}/write_data_wscript_for_pt

## Write parasitics
update_timing; write_parasitics -compress -output ${OUTPUTS_DIR}/write_data

## Write GDS and OASIS
write_gds -compress -hierarchy all -long_names ${OUTPUTS_DIR}/write_data.gds
write_oasis -compress 6 -hierarchy all ${OUTPUTS_DIR}/write_data.oasis

exit

