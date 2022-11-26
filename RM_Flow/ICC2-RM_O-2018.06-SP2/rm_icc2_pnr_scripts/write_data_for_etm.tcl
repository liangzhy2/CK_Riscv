##########################################################################################
# Tool: IC Compiler II
# Script: write_data_for_etm.tcl
# Version: O-2018.06-SP2 (October 8, 2018)
# Copyright (C) 2016 Synopsys, Inc. All rights reserved.
##########################################################################################

source -echo ./rm_setup/icc2_pnr_setup.tcl 

######################################################################
## Write out ASCII Data needed to Generate ETM in PT and Create Frame
######################################################################
if {$USE_ETM_FOR_BLOCKS != ""} {
	foreach blk $USE_ETM_FOR_BLOCKS {
        	puts "RM-info: Writing out ASCII data to generate ETM for block ${blk}"

        if {[file exists ./${blk}${LIBRARY_SUFFIX}]} {
             	open_lib ${blk}${LIBRARY_SUFFIX}
     
             	## Following set of lines open the block saved after icv_in_design step and dump out design data needed to generate ETM
             	## Modify WRITE_DATA_FOR_ETM_BLOCK_NAME in icc2_pnr_setup.tcl if you want to create ETM for some other stage of the block
             	open_block ${blk}/$WRITE_DATA_FOR_ETM_BLOCK_NAME
     
     	     	## write_verilog for PT (without physical only cells and with diodes and DCAP for leakage power analysis)
     	     	## To enable write_verilog to write out UPF compatible for other Synopsys tools as well as verilog
     	     	set_app_options -name mv.upf.write_crosstool_wrappers -value true
             	set write_verilog_pt_cmd "write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells flip_chip_pad_cells} -hierarchy all ${OUTPUTS_DIR}/${blk}.pt.v"
             	if {$CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST != ""} {lappend write_verilog_pt_cmd -force_reference $CHIP_FINISH_METAL_FILLER_LIB_CELL_LIST}
                puts "RM-info: $write_verilog_pt_cmd"
             	eval $write_verilog_pt_cmd
     
     	     	## write_parasitics
     	     	update_timing
     	     	write_parasitics -output ${OUTPUTS_DIR}/${blk}
     
             	## write out scenario creation script
                write_script -format pt -output ${OUTPUTS_DIR}/pt_write_script

             	save_lib
     	     	close_lib
        } else {
		puts "RM-error: {blk}${LIBRARY_SUFFIX} does not exist. Please correct it. Exiting"
		exit 
        }
   }
}

print_message_info -ids * -summary
echo [date] > write_data_for_etm

exit 

