##########################################################################################
# Synopsys(R) IC Compiler II(TM) Hierarchical Design Planning Reference Methodology
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

Overview
========
A reference methodology provides a set of reference scripts that serve as a good
starting point for running a tool. These scripts are not designed to run in their
current form. You should use them as a reference and adapt them for use in your
design environment.

Features
========
* Advanced abstraction management for processing large designs

* Fast placement of macros and standard cells

* Multiple Physical Hierarchy (MPH) support

* Pattern-based power planning

* Power network description using UPF

* Clock Trunk Planning support

* Virtual in-place timing optimization

* Pin placement and bus bundling

* Timing budgeting

* Easy export to the P&R flow

Instructions for Using the IC Compiler II Hierarchical Design Planning RM
=========================================================================
The IC Compiler II Hierarchical Design Planning Reference Methodology
consists of two major sections:

(1) Split constraints: To execute this RM step, use the following command

	% make -f rm_setup/Makefile_dp_hier split_constraints

	This RM step reads the full chip Verilog netlist, full
	chip timing constraints, full chip UPF (if specified) and
	creates the block and top constraints in the ./split directory.

(2) Design Planning: To execute the design planning flow, use the
    following command:

	% make -f rm_setup/Makefile_dp_hier all

	Replace "all" with any other desired step in the
	Makefile_dp_hier, such as shaping, placement, etc.

        Note: Makefile_dp_hier variables PLACE_IO and/or CTP can be
              set to true or false to run or skip these flow steps.

Flow Steps
==========
The IC Compiler II Hierarchical Design Planning Reference Methodology
flow includes the following steps:
(Refer to the makefile : rm_setup/Makefile_dp_hier)

* split_constraints
	- Top Chip-level SDC and UPF files are partitioned into
          top-level and block-level files.

* init_dp
	- Data preparation. Read design inputs and create the design.

* pre_shaping
	- Creates placement abstracts for each block. 
          Commits UPF and checks multi-voltage related electrical rules.

* place_io
	- Place I/O drivers in the design.

* shaping
	- Shapes and places physical blocks (including power domains
          and voltage areas).

* placement
	- Performs global macro and standard cell placement.

* create_power
	- Inserts the power and ground structures for the design and
          pushes these structures into the blocks.

* clock_trunk_planning (optional)
	- Performs block and top-level clock trunk synthesis.

* place_pins
	- Performs global routing of the interface nets and block pin
          assignment.

* pre_timing
	- Performs estimated timing on the blocks and create 
	  optimized abstracts used for top level optimization.

* timing_estimation
	- Performs virtual optimization of the block and top paths.

* budgeting
	- Creates timing budgets for blocks.

* write_data (optional)
	- Writes hierarchical design data including netlist,
          power/ground netlist, SDC, and UPF.

* all (optional)
	- Performs all of the above steps including write_data.

* export (optional)
	- Copies the hierarchical design data to a release directory that 
          can be imported to place & route (pnr flow).

* view_copy (optional)
	- Copies the design from the specified stage and opens it up
          for viewing.

* view_in_place (optional)
	- Opens the design for viewing at the specified stage.

Files Included With the IC Compiler II Hierarchical Design Planning RM
======================================================================
* rm_setup/Makefile_dp_hier
  Makefile for the IC Compiler II Hierarchical Reference Methodology
  scripts

* rm_setup/icc2_common_setup.tcl
  Design-specific variables that are shared by both Flat and
  Hierarchical Reference Methodology scripts, such as, TECH_FILE,
  REFERENCE_LIBRARY, and VERILOG_NETLIST_FILE, etc

* rm_setup/icc2_dp_setup.tcl
  This file includes IC Compiler II design planning Reference
  Methodology-specific design setup variables.  Use the
  variables to specify various design planning constraints that are
  used through the design planning RM.  The variables listed in this
  file specify block list, full module names from which physical
  hierarchy will be created, physical constraints for I/O placement,
  shaping constraints, hierarchical placement constraints, PNA/PNS
  related constraints, pin placement related constraints, estimate
  timing related constraints and budgeting related setup constraints.
  This also includes the system variables that specify the path for
  work, report directory for each RM step.  See the
  rm_setup/icc2_dp_setup.tcl file for complete list of variable
  names and their usage.

* Flow Setup
  The default design planning reference methodology flow is set in 
  rm_setup/icc2_dp_setup.tcl
  set DP_FLOW "hier"

  In rm_setup/icc2_dp_setup.tcl, distributed modes are enabled in
  pre_shaping, placement, pre_timing, and timing_estimation DP steps
  set DISTRIBUTED 1
  You must include the set_host_options command to enable distributed
  mode tasks. See rm_setup/icc2_dp_setup.tcl for example

* rm_icc2_dp_scripts/split_constraints.tcl

  This script is used in the split_constraints RM step. In the ICC II
  flow, you must have top and block constraints.  This RM step reads
  the full chip verilog netlist, full chip timing constraints, full
  chip UPF (if specified) and creates top and block constraints under
  the split directory.

* rm_icc2_dp_scripts/init_dp.tcl

  This script is used in the init_dp RM step. The RM variables which
  specify the constraints for die area creation and I/O placement are
  listed under the "TOP LEVEL FLOORPLAN CREATION (die, pad, RDL) /
  PLACE IO" section of the rm_setup/icc2_dp_setup.tcl file. This RM
  step creates the top level die area, I/O cell planning and placement
  and commits blocks as specified by the user in the
  rm_setup/icc2_dp_setup.tcl file.

* rm_icc2_dp_scripts/tech_setup.tcl
  
  This script is used in the init_dp RM step. By default,
  rm_icc2_dp_scripts/init_dp.tcl sources tech_setup.tcl or you can
  specify your own file using the TCL_TECH_SETUP_FILE variable in the
  icc2_common_setup.tcl script. The routing layer directions, offsets,
  site default, and site symmetry list are now set through the
  following TCL variables:
        
  ROUTING_LAYER_DIRECTION_OFFSET_LIST (replaces VERTICAL_ROUTING_LAYER_LIST / 
                                       HORIZONTAL_ROUTING_LAYER_LIST; 
                                       formerly in icc2_common_setup.tcl)
  SITE_DEFAULT (replaces SITE_DEF; formerly in icc2_hier_setup.tcl)
  SITE_SYMMETRY_LIST (replaces SITE_DEF_SYMMETRY; formerly in icc2_hier_setup.tcl)

* rm_icc2_dp_scripts/pre_shaping.tcl

  This script is used in the pre_shaping RM step. This RM step creates
  placement abstracts and runs in distributed mode. Since the default 
  hierarchical design planning RM uses outline views, abstract creation 
  is necessary before proceeding with block shaping and placement.
  This RM step also commits UPF, connects pg nets, and checks 
  multi-voltage related electrical rules for the design.

* rm_icc2_dp_scripts/place_io.tcl

  This script is used in the place_io RM step. This RM step places I/O
  driver cell instances in I/O guides.

* rm_icc2_dp_scripts/shaping.tcl

  This script is used in the shaping RM step. RM Variables to
  specify shaping constraints are listed under the "SHAPING"
  section of the rm_setup/icc2_dp_setup.tcl file. This RM step
  creates shapes for the blocks and voltage areas in the design.

* rm_icc2_dp_scripts/placement.tcl

  This script is used in the placement RM step. RM variables to specify
  hierarchical placement constraints are listed under the "PLACEMENT"
  section of the rm_setup/icc2_dp_setup.tcl file. This RM step performs
  the global macro and standard cell placement. This step is run in 
  distributed mode.

* rm_icc2_dp_scripts/create_power.tcl

  This script is used in the create_power RM step. The RM variables
  that specify PNS-related constraints are listed under the "PNS"
  section of the rm_setup/icc2_dp_setup.tcl file. An example file
  rm_icc2_dp_scripts/pns_example.tcl is provided for reference. This
  RM step inserts the power and ground structures for the design and
  pushes these structures into the blocks.

* rm_icc2_dp_scripts/clock_trunk_planning.tcl (Optional)

  This script is used in the clock_trunk_planning (optional) RM step.
  The RM variables that specify clock trunk planning constraints are 
  listed under the "CLOCK TRUNK PLANNING" section of the 
  rm_setup/icc2_dp_setup.tcl file. This RM step performs block and 
  top-level clock trunk synthesis. The CTP variable in the 
  rm_setup/Makefile_dp_hier file must be set to true to run this step.

* rm_icc2_dp_scripts/block_create_frame.tcl

  This script is used within rm_icc2_dp_scripts/clock_trunk_planning.tcl
  to create frame views for all blocks to control top level routing
  behavior.

* rm_icc2_dp_scripts/place_pins.tcl

  This script is used in the place_pins RM step. The RM variables that
  specify pin constraints are listed under the "PLACE PINS" section of
  the rm_setup/icc2_dp_setup.tcl file. By default, feedthroughs are
  disabled in IC Compiler II. You can enable the feedthroughs using
  the pin constraint Tcl commands and pin constraints file. This RM
  step performs global routing of the interface nets and block pin
  assignment.

* rm_icc2_dp_scripts/pre_timing.tcl

  This script is used in the pre_timing RM step. The RM variables that
  specify timing abstracts are listed under the "PRE-TIMING" section 
  of the rm_setup/icc2_dp_setup.tcl file. This RM step performs 
  estimated timing on the blocks and create optimized abstracts used 
  for top level optimization. This step is run in distributed mode.

* rm_icc2_dp_scripts/timing_estimation.tcl

  This script is used in the timing_estimation RM step. The RM variables that
  specify estimated timing constraints are listed under the "TIMING ESTIMATION"
  section of rm_setup/icc2_dp_setup.tcl file. This RM step performs
  virtual optimization of the block and top paths before the budgeting
  step. This step is run in distributed mode.

* rm_icc2_dp_scripts/budgeting.tcl

  This script is used in the budgeting RM step. The RM variables that
  specify the budgeting setup files are listed under the "BUDGETING"
  section of rm_setup/icc2_dp_setup.tcl file. This RM step creates
  block budgets and these budgets are used during block
  implementation.


* rm_icc2_dp_scripts/budgeting_estimated.tcl (Optional)

  This script is used in the budgeting RM step. The RM variables that
  specify the budgeting setup files are listed under the "BUDGETING"
  section of rm_setup/icc2_dp_setup.tcl file. This RM step creates
  block budgets which estimated by clock trunk planning step and these budgets are 
  used during block implementation. The CTP variable in the 
  rm_setup/Makefile_dp_hier file must be set to true to run this step.


* rm_icc2_dp_scripts/load_block_budgets.tcl

  This script is used within rm_icc2_dp_scripts/budgeting.tcl to 
  load block related budgets.

* rm_icc2_dp_scripts/write_data.tcl (Optional)

  This script is used in the write_data RM step, an optional RM step.
  This RM step writes hierarchical design data, including netlist,
  power/ground netlist, SDC, and UPF.

* rm_icc2_dp_scripts/write_block_data.tcl

  This script is sourced within rm_icc2_dp_scripts/write_data.tcl and
  writes out Top and block UPF, Verilog, floorplan information, and
  other data to the specified files.

* rm_icc2_dp_scripts/export.tcl (Optional)

  This script is used in the export RM step, an optional RM step.
  This RM step copies the design data to a release directory. 
  The release directory can then be imported into the pnr flow via the 
  rm_icc2_pnr_scripts/import_from_dp.tcl script.

* rm_icc2_dp_scripts/view_copy.tcl (Optional)

  This script is used in the view_copy RM step, an optional RM step. 
  The view_copy RM step enables viewing the design data in a copied mode. 
  Select the flow stage that you wish to copy the design data from.
  The library from that stage will be copied with "_copy" appended to it 
  to form the copied library name. The block will then be opened for 
  viewing.

* rm_icc2_dp_scripts/view_in_place.tcl (Optional)

  This script is used in the view_in_place RM step, an optional RM step. 
  The view_in_place RM step enables viewing the design data for the 
  specified flow stage.
