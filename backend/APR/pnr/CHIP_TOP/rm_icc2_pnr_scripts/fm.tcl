puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: Formality Verification for IC Compiler II Chip-Level
# Script: fm.tcl
# Purpose: run formal verification on the netlist before and after ICC II implementation
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

#################################################################################
# Sections of this script may be uncommented to perform various types of verifications.
#
# The default verification flow assumes the gate vs gate (G2G) verification 
# of the files going into IC Compiler II and the resulting Verilog netlist from IC Compiler II.
#
# This script may be manually modified to perform other types of verifications as needed.
# 
# This script will use variables set in the ICC2 RM scripts icc_pnr_setup.tcl and icc2_common_setup.tcl
#
#################################################################################

#################################################################################
## Synopsys Auto Setup Mode
#################################################################################

## This mode applies to RTL vs gate verifications which are not the default for this script.
## 
## set_app_var synopsys_auto_setup true

## Note: The Synopsys Auto Setup mode is less conservative than the Formality default mode, 
## and is more likely to result in a successful verification out-of-the-box.
## 
## Setting this variable will change the default values of the variables listed here below
## You may change any of these variables back to their default settings to be more conservative.
## Uncomment the appropriate lines below to revert back to their default settings:

	## set_app_var hdlin_ignore_embedded_configuration false
	## set_app_var hdlin_ignore_full_case true
	## set_app_var hdlin_ignore_parallel_case true
	## set_app_var signature_analysis_allow_subset_match true
	## set_app_var svf_ignore_unqualified_fsm_information true
	## set_app_var upf_assume_related_supply_default_primary false
	## set_app_var upf_use_additional_db_attributes false
	## set_app_var verification_set_undriven_signals BINARY:X
	## set_app_var verification_verify_directly_undriven_output true

## Other variables with changed default values are described in the next section.

#################################################################################
## Setup for handling undriven signals in the design
#################################################################################
## The Synopsys Auto Setup mode sets undriven signals in the reference design to
## "0" or "BINARY" (as done by DC), and the undriven signals in the impl design are
## forced to "BINARY".  This is done with the following setting:
	## set_app_var verification_set_undriven_signals synthesis
## Uncomment the next line to revert back to the more conservative default setting:

	## set_app_var verification_set_undriven_signals BINARY:X

#################################################################################
## Setup for Clock-gating
#################################################################################
## The Synopsys Auto Setup mode, along with the SVF file, will appropriately set the clock-gating variable.
## Otherwise, the user will need to notify Formality of clock-gating by uncommenting the next line:

	## set_app_var verification_clock_gate_hold_mode any

#################################################################################
## Setup for instantiated DesignWare or function-inferred DesignWare components
#################################################################################
## Set this variable ONLY if your design contains instantiated DW or function-inferred DW

	## set_app_var hdlin_dwroot "" ;# Enter the pathname to the top-level of the DC tree

#################################################################################
## Setup for handling missing design modules
#################################################################################
## If the design has missing blocks or missing components in both the reference and implementation designs,
## uncomment the following variable so that Formality can complete linking each design:

	## set_app_var hdlin_unresolved_modules black_box

#################################################################################
## Read in the SVF file(s)
#################################################################################
## Set this variable to point to individual SVF file(s) or to a directory containing SVF files.

## set_svf ${SOURCE_DIR}/${DESIGN_NAME}.mapped.svf

#################################################################################
# Read in the libraries
#################################################################################
foreach tech_lib ${LINK_LIBRARY} {
  read_db -technology_library $tech_lib
}

#################################################################################
# Read in the Reference Design
#
# This sections uses ICC2 RM variables to determine the type of reference design
#################################################################################
if {$INIT_DESIGN_INPUT == "ASCII" } {
	read_verilog -r $VERILOG_NETLIST_FILES
	# Setting the top of design for these input formats
	set_top r:/WORK/${DESIGN_NAME}
}

	#################################################################################
	# For a UPF MV flow, read in the UPF file for the Reference Design
	#################################################################################
	# load_upf -r ${SOURCE_DIR}/${DESIGN_NAME}.mapped.upf
	if {[file exists [which $UPF_FILE]]} {
		load_upf -r $UPF_FILE 
	} else {
	  	puts "RM-error: UPF_FILE $UPF_FILE is not found or not defined."
	  	puts "RM-info: For UPF designs, fm.tcl requires one single UPF file. Exiting"
		exit 
	}

#################################################################################
# Read in the Implementation Design from ICC2-RM result
#
# Note: In ICC2, when writing out a Verilog netlist for Formality, 
# use the following options, as in write_data.tcl:
# 	write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations \ 
#    	end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells \
#    	cover_cells supply_statements} -hierarchy all ${OUTPUTS_DIR}/${WRITE_DATA_BLOCK_NAME}.fm.v
#################################################################################

read_verilog -i ${OUTPUTS_DIR}/${WRITE_DATA_BLOCK_NAME}.fm.v

set_top i:/WORK/${DESIGN_NAME}

#################################################################################
# Setup for scan re-ordering
#
# If IC Compiler II has performed scan re-ordering, the user will need to manually
# set constants on the scan enable and test mode signals to disable scan path
# verification.
# 
# Example command format:
#
#   set_constant -type port r:/WORK/${DESIGN_NAME}/<port_name> <constant_value> 
#   set_constant -type port i:/WORK/${DESIGN_NAME}/<port_name> <constant_value> 
#
#
# Also, the user will need to manually perform set_dont_verify on dedicated scanout
# ports to avoid verification failures on those ports.
#
# Example command format:
#
#   set_dont_verify_point -type port r:/WORK/${DESIGN_NAME}/<port_name>
#   ...
#
#################################################################################

#################################################################################
# Note in using the UPF MV flow with Formality:
#
# By default Formality verifies low power designs with all UPF supplies 
# constrained to their ON state.  For the IC Compiler reference methodology flow,
# is it recommended to set this variable to false instead.
#
      set_app_var verification_force_upf_supplies_on false
#
#################################################################################

#################################################################################
# Match compare points and report unmatched points 
#################################################################################
match

report_unmatched_points > ${REPORTS_DIR}/${DESIGN_NAME}.fmv_unmatched_points.rpt

#################################################################################
# Verify and Report
#
# If the verification is not successful, the session will be saved and reports
# will be generated to help debug the failed or inconclusive verification.
#################################################################################
if { ![verify] }  {  
  save_session -replace ${REPORTS_DIR}/${DESIGN_NAME}
  report_failing_points > ${REPORTS_DIR}/${DESIGN_NAME}.fmv_failing_points.rpt
  report_aborted > ${REPORTS_DIR}/${DESIGN_NAME}.fmv_aborted_points.rpt
  # Use analyze_points to help determine the next step in resolving verification
  # issues. It runs heuristic analysis to determine if there are potential causes
  # other than logical differences for failing or hard verification points. 
  analyze_points -all > ${REPORTS_DIR}/${DESIGN_NAME}.fmv_analyze_points.rpt
  set fm_passed FALSE
} else {
  set fm_passed TRUE
}


echo [date] > fm

exit 

