##########################################################################################
# Tool: IC Compiler II
# Script: init_dp.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_dp_setup.tcl 

####################################
# Create and read the design	
####################################
if {[file exists ${WORK_DIR}/$DESIGN_LIBRARY]} {
   file delete -force ${WORK_DIR}/${DESIGN_LIBRARY}
}

# NOTE: The library will not appear on disk until you save
set create_lib_cmd "create_lib ${WORK_DIR}/$DESIGN_LIBRARY"
if {[file exists [which $TECH_FILE]]} {
   lappend create_lib_cmd -tech $TECH_FILE ;# recommended
} elseif {$TECH_LIB != ""} {
   lappend create_lib_cmd -use_technology_lib $TECH_LIB ;# optional
}
lappend create_lib_cmd -ref_libs $REFERENCE_LIBRARY
puts "RM-info : $create_lib_cmd"
eval $create_lib_cmd

if {$DP_FLOW == "hier" && $BOTTOM_BLOCK_VIEW == "abstract"} {
   # Read in the DESIGN_NAME outline.  This will create the outline 
   puts "RM-info : Reading verilog outline (${VERILOG_NETLIST_FILES})"
   read_verilog_outline -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
} else {
   # Read in the full DESIGN_NAME.  This will create the DESIGN_NAME view in the database
   puts "RM-info : Reading full chip verilog (${VERILOG_NETLIST_FILES})"
   read_verilog -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} -top ${DESIGN_NAME} ${VERILOG_NETLIST_FILES}
}

####################################################
# Here we use add ICC2 only tech information.
# ICC2 needs to have the routing direction specified, 
# track offset, and default site defs.
####################################################

## Technology setup for routing layer direction, offset, site default, and site symmetry.
#  If TECH_FILE is specified, they should be properly set.
#  If TECH_LIB is used and it does not contain such information, then they should be set here as well.
if {$TECH_FILE != "" || ($TECH_LIB != "" && !$TECH_LIB_INCLUDES_TECH_SETUP_INFO)} {
   if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
      puts "RM-info : Sourcing [which $TCL_TECH_SETUP_FILE]"
      source -echo $TCL_TECH_SETUP_FILE
   } elseif {$TCL_TECH_SETUP_FILE != ""} {
      puts "RM-error : TCL_TECH_SETUP_FILE($TCL_TECH_SETUP_FILE) is invalid. Please correct it."
   }
}

# Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command
if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_PARASITIC_SETUP_FILE]"
   source -echo $TCL_PARASITIC_SETUP_FILE
} elseif {$TCL_PARASITIC_SETUP_FILE != ""} {
   puts "RM-error : TCL_PARASITIC_SETUP_FILE($TCL_PARASITIC_SETUP_FILE) is invalid. Please correct it."
} else {
   puts "RM-info : No TLU plus files sourced, Parastic library containing TLU+ must be included in library reference list"
}

if {[file exists [which $TCL_TIMING_RULER_SETUP_FILE]]} {
   puts "RM-info : Sourcing [which $TCL_TIMING_RULER_SETUP_FILE]"
   source -echo $TCL_TIMING_RULER_SETUP_FILE
} else {
   puts "RM-warning : TCL_TIMING_RULER_SETUP_FILE not found or not specified. Timing ruler will not work accurately if it is not defined"
}

# Define the ignored layers (if specified)
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER} 
if {$MAX_ROUTING_LAYER != ""} {
   set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER
}

####################################
# Check Design: Pre-Floorplanning
####################################
if {$CHECK_DESIGN} { 
   redirect -file ${REPORTS_DIR_INIT_DP}/check_design.pre_floorplan \
    {check_design -ems_database check_design.pre_floorplan.ems -checks dp_pre_floorplan}
}

####################################
# Floorplanning
####################################

if {[file exists [which $TCL_PHYSICAL_CONSTRAINTS_FILE]]} {
   puts "RM-info : Creating floorplan from TCL file TCL_PHYSICAL_CONSTRAINTS_FILE ($TCL_PHYSICAL_CONSTRAINTS_FILE)"
   source -echo -verbose $TCL_PHYSICAL_CONSTRAINTS_FILE
} elseif {[file exists [which $DEF_FLOORPLAN_FILES]]} {
   puts "RM-info : Creating floorplan from DEF file DEF_FLOORPLAN_FILES ($DEF_FLOORPLAN_FILES)"
   read_def $DEF_FLOORPLAN_FILES
} else {
   puts "RM-info : No floorplan setup provided, creating fallback initialization"
   initialize_floorplan
}

if {[file exists [which $TCL_PHYSICAL_CONSTRAINTS_FILE]] && [file exists [which $DEF_FLOORPLAN_FILES]]} {
   puts "RM-warning : Updating floorplan from DEF file DEF_FLOORPLAN_FILES ($DEF_FLOORPLAN_FILES)"
   read_def $DEF_FLOORPLAN_FILES
}

if {[file exists [which $TCL_PRE_COMMIT_FILE]]} {
   puts "RM-info : Loading TCL_PRE_COMMIT_FILE file ($TCL_PRE_COMMIT_FILE)"
   source -echo $TCL_PRE_COMMIT_FILE
} elseif {$TCL_PRE_COMMIT_FILE != ""} {
   puts "RM-error: TCL_PRE_COMMIT_FILE file ($TCL_PRE_COMMIT_FILE) is invalid. Please correct it."
}


############################################################################
# Commit each block to its own library and add the block library as 
# a reference library
############################################################################
if {$DP_FLOW == "hier"} {
   set cd [current_design]

   # Derive block instances from block references if not already defined.
   set DP_BLOCK_INSTS ""
   foreach ref "$DP_BLOCK_REFS" {
      set DP_BLOCK_INSTS "$DP_BLOCK_INSTS [get_object_name [get_cells -hier -filter ref_name==$ref]]"
   }

   # copy_lib -from_lib -to_lib does not support paths to the libraries
   set pwd [pwd]
   cd ${WORK_DIR}
   foreach ref ${DP_BLOCK_REFS} {
      puts "RM-info : Creating ${ref}${LIBRARY_SUFFIX}"
      file delete -force -- ${ref}${LIBRARY_SUFFIX}
      copy_lib -to_lib ${ref}${LIBRARY_SUFFIX} -no_designs
      set_attribute -object ${ref}${LIBRARY_SUFFIX} -name use_hier_ref_libs -value true
   }
   cd $pwd

   save_lib -all

   # Create blackboxes
   foreach ref ${DP_BB_BLOCK_REFS} {
      # Create the black boxes, and set the area if defined, otherwise
      set inst [index_collection [filter_collection [get_cells $DP_BLOCK_INSTS] ref_name==$ref] 0]
      puts "RM-info : Creating blackbox $ref into library ${ref}${LIBRARY_SUFFIX}"
      if {[info exists DP_BB_BLOCKS($ref,area)]} {
        create_blackbox -library ${ref}${LIBRARY_SUFFIX} -target_boundary_area $DP_BB_BLOCKS($ref,area) $inst
      } elseif {[info exists DP_BB_BLOCKS($ref,boundary)]} {
        create_blackbox -library ${ref}${LIBRARY_SUFFIX} -boundary $DP_BB_BLOCKS($ref,boundary) $inst
      } else {
        puts "RM-error : Black boxes are defined as $DP_BB_BLOCK_REFS, but have no area or boundary, assign an area in setup.tcl"
        error 
      }
   }

   # Commit all non-black box blocks
   foreach ref ${DP_BLOCK_REFS} {
     if {[lsearch $DP_BB_BLOCK_REFS $ref] < 0} {
       puts "RM-info : Committing block $ref into library ${ref}${LIBRARY_SUFFIX}"
       commit_block -library ${ref}${LIBRARY_SUFFIX} $ref
     }
   }

   # Add child block reference to parent block
   foreach inst ${DP_BLOCK_INSTS} {
      # Add a reference to any child blocks
      set ref_lib_name [get_attribute [get_cells $inst] ref_lib_name]
      set parent_ref_lib_name [get_attribute [get_cells $inst] parent_block.lib_name]
      # Check to see if ref lib already exists in the case of MIB
      if {[lsearch [get_attribute [get_libs $parent_ref_lib_name] ref_libs] "./${ref_lib_name}"] < 0} {
         puts "RM-info : Adding ./${ref_lib_name} as a reference of ${parent_ref_lib_name}"
         set_ref_libs -library ${parent_ref_lib_name} -add ./${ref_lib_name}
      }
   }
}

# Setup distributed host options for blocks
if {[file exist $BLOCK_DIST_JOB_FILE]} {
   source -echo $BLOCK_DIST_JOB_FILE
}

################################
## Post-init_dp customizations
################################
if {[file exists [which $TCL_USER_INIT_DP_POST_SCRIPT]]} {
   puts "RM-info: Sourcing [which $TCL_USER_INIT_DP_POST_SCRIPT]"
   source $TCL_USER_INIT_DP_POST_SCRIPT
} elseif {$TCL_USER_INIT_DP_POST_SCRIPT != ""} {
   puts "RM-error:TCL_USER_INIT_DP_POST_SCRIPT($TCL_USER_INIT_DP_POST_SCRIPT) is invalid. Please correct it."
}

if {$COMPRESS_LIBS} {
  save_lib -all -compress
} else {
  save_lib -all
}


print_message_info -ids * -summary
echo [date] > init_dp

exit 
