###############################################################################
# Synopsys(R) IC Compiler(TM) II Hierarchical P&R Reference Methodology
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
###############################################################################

Overview
========
A reference methodology (RM) provides a set of reference scripts that serve
as a good starting point for running a tool. These scripts are not designed
to run in their current form. You should use them as a reference and adapt
them for use in your design environment.

Features
========
* Provides self-documenting reference methodology scripts for place and route
  of hierarchical designs using the IC Compiler II tool
  - Uses the same scripts and supports all the flows as Flat P&R Reference Methodology.
    Refer to README.ICC2-FLAT-PNR-RM.txt for more details

* Supports P&R using abstracts and extracted timing models (ETMs)

* Supports designs with multiple levels of physical hierarchy

* Includes the following tasks, in addition to the tasks performed in the Flat P&R RM:
  - Creation of abstracts
  - Specification of the abstracts to be used for each top-level implementation stage
  - Promotion of clock tree exceptions from abstracts
  - Writing out the data needed to generate ETMs in the PrimeTime tool for
    user-specified blocks

Instructions for Using the IC Compiler II Hierarchical P&R RM
==============================================================
Prerequisites
-------------
* (Optional) Use the Unpack utility to setup the run environment. Refer to the
  README.unpack_rm_dirs.txt file for details

* Complete design planning using the IC Compiler II Design Planning Reference Methodology.
  Export the designs libraries of top and sub-blocks to the release directory.
  Refer to the README.ICC2-DP-RM.txt file for details

To perform place and route of hierarchical designs
--------------------------------------------------
Perform place and route for each level in a bottom-up manner, starting with the lowest
level. For example, onsider a design with multiple levels of physical hierarchy

  TOP
    MID
      BOT

Step 1: Implement the lowest level
     % cd <path>/BOT
     % Initialize the flow related variables in the icc2_common_setup.tcl 
       (you can skip this step when using the unpack utility)
    		set DESIGN_STYLE		"hier"
    		set PHYSICAL_HIERARCHY_LEVEL	"bottom"
    		Initialize RELEASE_DIR_DP and RELEASE_DIR_PNR variables
     % make -f rm_setup/Makefile_pnr all
       You can replace "all" with any other desired step in the Makefile_pnr file,
       such as place_opt or  clock_opt_cts.
     % make -f rm_setup/Makefile_pnr export	
	
Step 2: Implement the middle level (If you have more than one intermediate level, 
repeat these steps for each intermediate level)
     % cd <path>/MID
     % Initialize the following flow related variables in the icc2_common_setup.tcl
       (You can skip this step when using the unpack utility)
                set DESIGN_STYLE                "hier"  
                set PHYSICAL_HIERARCHY_LEVEL    "intermediate"
                Initialize RELEASE_DIR_DP and RELEASE_DIR_PNR variables
     % Initialize the following flow related variables in the icc2_pnr_setup.tcl
       (You can skip this step when using unpack utility)
		SUB_BLOCK_REFS
		USE_ABSTRACTS_FOR_BLOCKS
       By default, abstracts created after the chip_finish step of the lower level are
       used to implement the current level. If you want to use abstracts created 
       after any other step, update BLOCK_ABSTRACT_FOR_* 
     % make -f rm_setup/Makefile_pnr all
       You can replace "all" with any other desired step in the Makefile_pnr file,
       such as place_opt or  clock_opt_cts.
     % make -f rm_setup/Makefile_pnr export

Step 3: Implement the top level   
     % cd <path>/TOP
     % Initialize the following flow related variables in the icc2_common_setup.tcl
       (You can skip this step when using the unpack utility)
                set DESIGN_STYLE                "hier"
                set PHYSICAL_HIERARCHY_LEVEL    "top"
                Initialize RELEASE_DIR_DP and RELEASE_DIR_PNR variables
     % Initialize the following flow related variabes in the icc2_pnr_setup.tcl
       (You can skip this step when using the unpack utility)
                SUB_BLOCK_REFS
                USE_ABSTRACTS_FOR_BLOCKS
       By default, abstracts created after the chip_finish step of the lower level are
       used to implement the current level. If you want to use abstracts created 
       after any other step, update BLOCK_ABSTRACT_FOR_* 
     % make -f rm_setup/Makefile_pnr all
       You can replace "all" with any other desired step in the Makefile_pnr file,
       such as place_opt or clock_opt_cts.

To use extracted timing models (ETMs) for some of the blocks in the design
---------------------------------------------------------------------------
* Include the ETM library in the REFERENCE_LIBRARY list

  If the ETM library does not exist and you want to create it,
  % Use the write_data_for_etm utility to write out the files needed to
    generate ETMs in the PrimeTime tool
  % Use the PT-RM to generate ETMs
  % Use the IC Compiler II Library Preparation RM to generate the ETM libraries
* Initialize the USE_ETM_FOR_BLOCKS and ETM_UPF_MAPPING_FILE variables in icc2_pnr_setup.tcl

Files Included With the IC Compiler II Hierarchical P&R Reference Methodology
=============================================================================
Hierarchical P&R RM uses the same scripts as Flat P&R RM

The following scripts are specific to Hierarchical P&R RM
* rm_icc2_pnr_scripts/create_softlinks_to_subblocks.tcl
  Creates soft-links to the sub-blocks’ design libraries present in P&R Release Directory ($RELEASE_DIR_PNR)

* rm_icc2_pnr_scripts/init_design.tcl
  Please refer to README.ICC2-FLAT-PNR-RM.txt for details of this script.
  For hierarchical designs, at top and intermediate level, invokes rm_icc2_pnr_scripts/create_softlinks_to_subblocks.tcl to create soft-links
  to the sub-blocks’ design libraries present in P&R Release Directory ($RELEASE_DIR_PNR)

* rm_icc2_pnr_scripts/export.tcl
  Copies the design libraries to the P&R release directory 

* rm_icc2_pnr_scripts/write_data_for_etm.tcl
  This is an optional script. Writes out the design data required to generate ETMs in the PrimeTime tool
