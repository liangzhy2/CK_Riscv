#################################################
# vivado FPGA environment configuration
#################################################

set PRJ_NAME        CK_Riscv
set SCRIPT_DIR      ../script
set CONST_DIR       ../constraint
set DEVICE_NAME     xc7a100tfgg676-2
set XDC_FILE        $CONST_DIR/pin.xdc
set CODE_FILE       module_file_list
set FPGA_TOP        ../rtl/fpga_top.v
################################################
#Step1: Create project and overwrite old files
################################################
create_project -force $PRJ_NAME ./ -part $DEVICE_NAME
read_xdc $XDC_FILE
add_file $FPGA_TOP
source $CODE_FILE
#add_files ../libs/sysclk_wiz/sysclk_wiz.xci
#set_property ip_repo_paths ../libs/sysclk_wiz [current_project]
set_property verilog_define {FPGA_SYN=1} [get_filesets sources_1]
#set max threads
set_param general.maxThreads 8

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz
set_property -dict [list \
            CONFIG.PRIM_IN_FREQ {50.000} \
            CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
            CONFIG.RESET_TYPE {ACTIVE_LOW} \
            CONFIG.CLKIN1_JITTER_PS {200.0} \
            CONFIG.MMCM_DIVCLK_DIVIDE {1} \
            CONFIG.MMCM_CLKFBOUT_MULT_F {20.000} \
            CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
            CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
            CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} \
            CONFIG.RESET_PORT {resetn} \
            CONFIG.CLKOUT1_JITTER {192.113} \
            CONFIG.CLKOUT1_PHASE_ERROR {164.985}] [get_ips clk_wiz]


# Launch Synthesis
launch_runs synth_1
wait_on_run synth_1
# Launch Implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
write_cfgmem  -format mcs -size 16 -interface SPIx4 -loadbit {up 0x00000000 "./CK_Riscv.runs/impl_1/fpga_top.bit" } -checksum -force -disablebitswap -file "./CK_Riscv.runs/impl_1/fpga_top.mcs"
