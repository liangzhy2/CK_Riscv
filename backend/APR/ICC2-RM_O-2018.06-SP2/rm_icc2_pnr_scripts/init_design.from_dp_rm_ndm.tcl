puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.from_dp_rm_ndm.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

########################################################################
## Copy designs from ICC2-DP-RM release area
########################################################################
	puts "RM-info: Sourcing [which import_from_dp.tcl]"
	source -echo import_from_dp.tcl

########################################################################
## Open the library and block
########################################################################
        if {$DESIGN_STYLE == "flat"} {

                ## For totally flat designs, open the design copied from ICC2 DP RM release area
                open_lib ${DESIGN_NAME}${LIBRARY_SUFFIX}
                open_block ${DESIGN_NAME}/${RELEASE_LABEL_NAME_DP}
        
        } elseif {$DESIGN_STYLE == "hier"} {

		puts "RM-info: Sourcing [which init_design.from_dp_rm_ndm.hier.tcl]"
		source -echo init_design.from_dp_rm_ndm.hier.tcl

        }

puts "RM-info: Completed script [info script]\n"
