puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: place_opt.spare_cell.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

set PLACE_OPT_SPARE_CELL_PREFIX		"" ;# A string to specify the prefix for the spare cells used by add_spare_cells -cell_name option; 
set PLACE_OPT_SPARE_CELL_REF_NUM_LIST 	"" ;# Specify a list that consists of pairs of space cell library cell name and number of instances,
					   ;# which is used by "add_spare_cells -num_cells" and "place_eco_cells -cells";
					   ;# the valid format is "ref1 num1 ref2 num2 ..."; for example, "andx1 10 norx1 5"

if {$PLACE_OPT_SPARE_CELL_PREFIX != "" && $PLACE_OPT_SPARE_CELL_REF_NUM_LIST != ""} {
	add_spare_cells -cell_name $PLACE_OPT_SPARE_CELL_PREFIX -num_cells $PLACE_OPT_SPARE_CELL_REF_NUM_LIST
	place_eco_cells -legalize_only -cells [get_cells -physical_context *${PLACE_OPT_SPARE_CELL_PREFIX}*]
} else {
	puts "RM-warning: Either PLACE_OPT_SPARE_CELL_PREFIX or PLACE_OPT_SPARE_CELL_REF_NUM_LIST is not spcified."
	puts "RM-warning: Skipping add_spare_cells and place_eco_cells."
}

puts "RM-info: Completed script [info script]\n"
