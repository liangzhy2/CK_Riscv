puts "RM-info: Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: read_parasitic_tech_example.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

##############################################################################################
# The following is a sample script to read two TLU+ files, 
# which you can expand to accomodate your design.
##############################################################################################

########################################
## Variables
########################################
## Parasitic tech files for read_parasitic_tech command; expand the section as needed
set parasitic1				"" ;# name of parasitic tech model 1
set tluplus_file($parasitic1)           "" ;# TLU+ files to read for parasitic 1
set layer_map_file($parasitic1)         "" ;# layer mapping file between ITF and tech for parasitic 1

set parasitic2				"" ;# name of parasitic tech model 2
set tluplus_file($parasitic2)           "" ;# TLU+ files to read for parasitic 2
set layer_map_file($parasitic2)         "" ;# layer mapping file between ITF and tech for parasitic 2

########################################
## Read parasitic files
########################################
## Read in the TLUPlus files first.
#  Later on in the corner constraints, you can then refer to these parasitic models.
foreach p [array name tluplus_file] {  
	puts "RM-info: read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p"
	read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p
}

puts "RM-info: Completed script [info script]\n"

