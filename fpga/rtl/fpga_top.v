// *********************************************************************************
// Project Name : CK_riscv
// Author       : Core_kingdom
// Website      : https://blog.csdn.net/weixin_40377195
// Create Time  : 2022-06-11
// File Name    : fpga_top.v
// Module Name  : fpga_top
// Called By    :
// Abstract     :
//
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2022-06-11    Macro           1.0                     Original
//  
// *********************************************************************************



module fpga_top(
    input   sclk_in     ,
    input   rstn_in     ,

    output  led_test    

);
//=================================================================================
// Parameter declaration
//=================================================================================


//=================================================================================
// Signal declaration
//=================================================================================

wire    sys_clk     ;
wire    sys_rst_n   ;

//=================================================================================
// Body
//=================================================================================

clk_wiz u_clk_wiz(
    // Clock out ports
    .clk_out1       ( sys_clk       ),      // output clk_out1
    // Status and control signals
    .resetn         ( rstn_in       ),      // input resetn
    .locked         ( sys_rst_n     ),      // output locked
    // Clock in ports
    .clk_in1        ( sclk_in       )       // input clk_in1
);      



CHIP_TOP    U_CHIP_TOP(
    .sys_clk            ( sys_clk       ),
    .sys_rst_n          ( sys_rst_n     ),
    .led_test           ( led_test      )

);

endmodule
