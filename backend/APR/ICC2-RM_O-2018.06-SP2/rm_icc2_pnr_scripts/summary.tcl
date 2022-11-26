##########################################################################################
# Tool: IC Compiler II
# Script: summary.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

####################################
## Summary Report
####################################			 
if {$REPORT_QOR} {
	set REPORT_PREFIX summary
	puts "RM-info: Sourcing [which print_icc2_results.tcl]"
	source print_icc2_results.tcl
        print_icc2_results -tns_sig_digits 2 -outfile ${REPORTS_DIR}/${REPORT_PREFIX}.rpt
	## Specify -tns_sig_digits N to display N digits for the TNS results in the report. Default is 0
}

print_message_info -ids * -summary
echo [date] > summary

exit 

