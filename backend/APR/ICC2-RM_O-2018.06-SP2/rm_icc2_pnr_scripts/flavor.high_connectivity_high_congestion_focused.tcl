puts "RM-info: Running script [info script]\n"

##########################################################################################
# Script: flavor.high_connectivity_high_congestion_focused.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

## A side file to override RM default flow settings for high connectivity and high congestion design styles.
#  Please source this file at the end of icc2_pnr_setup.tcl

set PREROUTE_PLACEMENT_CDR_EFFORT	"ultra" ;# low|medium|high|ultra; tool default is medium; RM default medium; 	
					;# sets place.coarse.cong_restruct_effort to control CDR (congestion-driven restructuring) effort level

set CTS_ENABLE_GLOBAL_ROUTE		true ;# false|true; tool default false; RM default false;	
					;# sets cts.compile.enable_global_route to true to enable global router in CTS to avoid congestion;  

set CLOCK_OPT_OPTO_PLACE_EFFORT		"high" ;# low|medium|high; RM default medium;
					;# sets clock_opt.place.effort to enable specified coarse placement effort during clock_opt's final_opto phase;

set CLOCK_OPT_OPTO_CONGESTION_EFFORT	"high" ;# low|medium|high; RM default medium;
					;# sets clock_opt.congestion.effort to enable specified congestion effort during clock_opt's final_opto phase

puts "RM-info: Completed script [info script]\n"
