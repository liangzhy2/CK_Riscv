##########################################################################################
# Tool: IC Compiler II
# Script: load_block_budgets.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2014-2018 Synopsys, Inc. All rights reserved.
##########################################################################################

#Send jobID back to parent for tracking purposes
if {[info exist env(JOB_ID)]} {
   puts "Block: $block_refname JobID: $env(JOB_ID) - START"
}

source -echo ../${block_refname_no_label}/rm_setup/icc2_pnr_setup.tcl

open_lib $block_libfilename
copy_block -from ${block_refname} -to ${block_refname_no_label}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}
current_block ${block_refname_no_label}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME}
link_block

## For non-persistent settings that need to be re-applied in a new ICC-II session 
puts "RM-info: Sourcing [which settings.non_persistent.tcl]"
source -echo ../${block_refname_no_label}/rm_icc2_pnr_scripts/settings.non_persistent.tcl

record_signoff_eco_changes -start -input ${block_refname_no_label}_eco_step_2.tcl ;# this is the ECO change file generated from pt_eco_incremental_0.tcl

        ########################################
        ## Legalize ECO cells (MPI mode)
        ########################################
        set place_eco_cells_cmd "place_eco_cells -eco_changed_cells -legalize_only -legalize_mode minimum_physical_impact -displacement_threshold $PT_ECO_DISPLACEMENT_THRESHOLD"
        if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != "" || $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST != ""} {
                lappend place_eco_cells_cmd -remove_filler_references "$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST"
        }
        puts "RM-info: $place_eco_cells_cmd"
        eval ${place_eco_cells_cmd}

        ########################################
        ## ECO routing
        ########################################
        #  Turn off timing-driven and crosstalk-driven for ECO routing 
        set_app_options -name route.global.timing_driven    -value false
        set_app_options -name route.track.timing_driven     -value false
        set_app_options -name route.detail.timing_driven    -value false
        set_app_options -name route.global.crosstalk_driven -value false
        set_app_options -name route.track.crosstalk_driven  -value false
        route_eco -utilize_dangling_wires true -reroute modified_nets_first_then_others -open_net_driven true

        ########################################
        ## Reinsert filler cells in changed area
        ########################################
        ## Metal filler (decap cells)
        if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != ""} {
                set create_stdcell_filler_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST] area]]
                set create_stdcell_filler_metal_cmd "create_stdcell_filler -lib_cell [list $create_stdcell_filler_metal_lib_cell_sorted]"
                if {$CHIP_FINISH_METAL_FILLER_PREFIX != ""} {
                        lappend create_stdcell_filler_metal_cmd -prefix $CHIP_FINISH_METAL_FILLER_PREFIX
                }
                puts "RM-info: $create_stdcell_filler_metal_cmd"
                eval ${create_stdcell_filler_metal_cmd}
                connect_pg_net
                remove_stdcell_fillers_with_violation -post_eco true ;# -post_eco true option is required in PT-ECO flow
        }

        ## Non-metal filler
        if {$CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST != ""} {
                set create_stdcell_filler_non_metal_lib_cell_sorted [get_object_name [sort_collection -descending [get_lib_cells $CHIP_FINISH_NON_METAL_FILLER_LIB_CELL_LIST] area]]
                set create_stdcell_filler_non_metal_cmd "create_stdcell_filler -lib_cell [list $create_stdcell_filler_non_metal_lib_cell_sorted]"
                if {$CHIP_FINISH_NON_METAL_FILLER_PREFIX != ""} {
                        lappend create_stdcell_filler_non_metal_cmd -prefix $CHIP_FINISH_NON_METAL_FILLER_PREFIX
                }
                puts "RM-info: $create_stdcell_filler_non_metal_cmd"
                eval ${create_stdcell_filler_non_metal_cmd}
                connect_pg_net
        }

        save_block

       ########################################################
        ## Incremental signoff_create_metal_fill in changed area
        ########################################################
        ## You can perform incremental signoff_create_metal_fill here.
        #  Please refer to chip_finish.tcl for details about signoff_create_metal_fill
        #  Ensure to append the option "-auto_eco true" to the signoff_create_metal_fill command to refill in the automatically detected changed area
        #       signoff_create_metal_fill -auto_eco true ...
        #       save_block 

if {$TCL_USER_CONNECT_PG_NET_SCRIPT != ""} {
        if {[file exists [which $TCL_USER_CONNECT_PG_NET_SCRIPT]]} {
                puts "RM-info: Sourcing [which $TCL_USER_CONNECT_PG_NET_SCRIPT]"
                source $TCL_USER_CONNECT_PG_NET_SCRIPT
        } else {
                puts "RM-error: TCL_USER_CONNECT_PG_NET_SCRIPT($TCL_USER_CONNECT_PG_NET_SCRIPT) is invalid. Please correct it."
        }
} else {
        connect_pg_net
        # For non-MV designs with more than one PG, you should use connect_pg_net in manual mode.
}

record_signoff_eco_changes -stop -def
save_block

create_frame -block_all true

write_lef -design ${block_refname_no_label}/${PT_ECO_INCREMENTAL_2_BLOCK_NAME} ${block_refname_no_label}_eco_step_2.lef

close_lib -save
puts "Block: $block_refname - FINISHED"
