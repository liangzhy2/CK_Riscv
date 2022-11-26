puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.from_ascii.hier.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

if {$PHYSICAL_HIERARCHY_LEVEL == "bottom"} {
       	read_verilog -top $DESIGN_NAME $VERILOG_NETLIST_FILES
       	current_block $DESIGN_NAME
       	link_block
       	save_lib
} elseif {$PHYSICAL_HIERARCHY_LEVEL == "top" || $PHYSICAL_HIERARCHY_LEVEL == "intermediate"} {
	## For top or intermediate level of hier designs, add sub-block design libraries to the reference libraries list
        foreach BLOCK $SUB_BLOCK_REFS {
                if {[file exists ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX}]} {
                   	puts "RM-info: Adding ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX} to the reference library list"
                   	set_ref_libs -add ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX}
                } else {
                   	puts "RM-error: Adding ${RELEASE_DIR_PNR}/${BLOCK}${LIBRARY_SUFFIX} to the reference library list but it doesn't exist. Exiting"

			exit 
		}
	}

	## Specify the label to be used for the created design
	## Specifying the following application option will enable the tool to link to the sub-blocks of the same label
	set_app_options -name file.verilog.default_user_label -value $INIT_DESIGN_BLOCK_NAME
	
	read_verilog -top ${DESIGN_NAME} $VERILOG_NETLIST_FILES
	current_block ${DESIGN_NAME}/${INIT_DESIGN_BLOCK_NAME}
	link_block
	save_lib
	
	## In the link performed above, the tool tries to link to sub-blocks with ${INIT_DESIGN_BLOCK_NAME} label
	## In the following step, change_abstract is used to link to the sub-blocks specified for place_opt step
	if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
	 	puts "RM-info: Swap abstracts to $BLOCK_ABSTRACT_FOR_PLACE_OPT abstracts for all blocks."
	 	change_abstract -view abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_PLACE_OPT
	 	report_abstracts
	}

}

puts "RM-info: Completed script [info script]\n"
