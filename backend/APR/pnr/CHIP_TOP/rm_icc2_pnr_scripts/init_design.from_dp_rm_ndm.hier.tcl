puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.from_dp_rm_ndm.hier.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################
        
if {$PHYSICAL_HIERARCHY_LEVEL == "bottom"} {
	## For bottom level of hier designs, open the design copied from ICC2 DP RM release area
	open_lib ${DESIGN_NAME}${LIBRARY_SUFFIX}
	open_block ${DESIGN_NAME}/${RELEASE_LABEL_NAME_DP}
} elseif {$PHYSICAL_HIERARCHY_LEVEL == "top" || $PHYSICAL_HIERARCHY_LEVEL == "intermediate"} {
	## For top or intermediate level of hier designs, link to sub-blocks in PNR RM release area
	puts "RM-info: Sourcing [which create_softlinks_to_subblocks.tcl]"
	source -echo create_softlinks_to_subblocks.tcl

	## For top or intermediate level of hier designs, open the copied design and do change_abstract
	open_lib ${DESIGN_NAME}${LIBRARY_SUFFIX}
	open_block ${DESIGN_NAME}/${RELEASE_LABEL_NAME_DP}
	## Swap abstracts created after DesignPlanning to abstracts specified for place_opt
	if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
		puts "RM-info: Swap abstracts created after ICC2-DP-RM with $BLOCK_ABSTRACT_FOR_PLACE_OPT abstracts for all blocks."
	      	change_abstract -view abstract -references $USE_ABSTRACTS_FOR_BLOCKS -label $BLOCK_ABSTRACT_FOR_PLACE_OPT
	      	report_abstracts
	}

	## Set the editability of the sub-blocks to false
        set_editability -blocks [get_blocks -hierarchical] -value false
        report_editability -blocks [get_blocks -hierarchical]

        ## Ignore the sub-blocks internal timing paths
        if {$USE_ABSTRACTS_FOR_BLOCKS != ""} {
              	set_timing_paths_disabled_blocks -all_sub_blocks
        }
}

puts "RM-info: Completed script [info script]\n"
