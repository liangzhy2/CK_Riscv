// *********************************************************************************
// Project Name : OSXXXX
// Author       : Core_kingdom
// Website      : https://blog.csdn.net/weixin_40377195
// Create Time  : 2022-05-16
// File Name    : wrap_iram.v
// Module Name  : wrap_iram
// Called By    :
// Abstract     :
//
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2022-05-16    Macro           1.0                     Original
//  
// *********************************************************************************

module wrap_iram(
    //system signals
    input                   sclk        ,
    //input                   rstn        ,
    //control signals
    input                   mem_wr      ,
    input                   mem_rd      ,
    input           [31:0]  addr        ,
    input           [31:0]  wdata       ,
    output          [31:0]  rdata       
);


//=================================================================================
// Parameter declaration
//=================================================================================





//=================================================================================
// Signal declaration
//=================================================================================
wire            ram_cs      ;
wire    [3:0]   ram_we      ;
wire    [11:0]   ram_addr   ;
wire    [31:0]  ram_wdata   ;
wire    [31:0]  ram_rdata   ;

//=================================================================================
// Body
//=================================================================================

assign  ram_cs  = mem_wr | mem_rd;
assign  ram_addr= addr[13:2];
assign  ram_we  = 4'b0000   ;
assign  rdata   = ram_rdata ;
assign ram_wdata = 32'd0;
//ram_bfm #(
//        .DATA_WHITH     ( 32            ),
//        .DATA_SIZE      ( 8             ),
//        .ADDR_WHITH     ( 10            ),
//        .RAM_DEPTH      ( 1024          )
//    )
//    u_ram_data(
//    //system signals
//    .clk                        ( sclk              ),
//    //RAM Control signals
//    .cs                         ( ram_cs            ),
//    .we                         ( ram_we            ),
//    .addr                       ( ram_addr          ),
//    .wdata                      ( ram_wdata         ),
//    .rdata                      ( ram_rdata         )
//);



`ifdef FPGA_SYN

ram_bfm #(
        .DATA_WHITH     ( 32            ),
        .DATA_SIZE      ( 8             ),
        .ADDR_WHITH     ( 12            ),
        .RAM_DEPTH      ( 4096          )
    )
    u_ram_data(
    //system signals
    .clk                        ( sclk              ),
    //RAM Control signals
    .cs                         ( ram_cs            ),
    .we                         ( ram_we            ),
    .addr                       ( ram_addr          ),
    .wdata                      ( ram_wdata         ),
    .rdata                      ( ram_rdata         )
);

`else

SRAM_4096_32 u_ram_data(
    .QA       ( ram_rdata       ),     //port-A data output
    .CLKA     ( sclk            ),     //port-A clock
    .CENA     ( ram_cs          ),     //port-A chip enable
    .WENA     ( ram_we          ),     //port-A write enable
    .AA       ( ram_addr        ),     //port-A address
    .DA       ( ram_wdata       ),     //port-A data input

    .QB       (                 ),     //port-B data output
    .CLKB     ( 1'b0            ),     //port-B clock
    .CENB     ( 1'b0            ),     //port-B chip enable
    .WENB     ( 4'd0            ),     //port-B write enable
    .AB       ( 12'd0           ),     //port-B address
    .DB       (                 ),     //port-B data input
    
    .EMAA     (     ),     
    .EMAB     (     )
);
`endif


endmodule
