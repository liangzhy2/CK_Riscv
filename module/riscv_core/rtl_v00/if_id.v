// *********************************************************************************
// Project Name : CK_riscv
// Author       : Core_kingdom
// Website      : https://blog.csdn.net/weixin_40377195
// Create Time  : 2022-03-12
// File Name    : if_id.v
// Module Name  : if_id
// Called By    :
// Abstract     :
//
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2022-03-12    Macro           1.0                     Original
//  
// *********************************************************************************
module if_id(
    //clk & rst
    input               clk                     ,
    input               rstn                    ,
    input               if_flush                ,
    //data input
    input       [31:0]  PC_line_in              ,
    input       [31:0]  instruct_data_line_in   ,
    //data output
    output  reg [31:0]  PC_line_out             ,
    output      [31:0]  instruct_data_line_out      
);

//=================================================================================
// Parameter declaration
//=================================================================================





//=================================================================================
// Signal declaration
//=================================================================================




//=================================================================================
// Body
//=================================================================================


always @(posedge clk or negedge rstn) begin
    if(!rstn)
        PC_line_out <= 32'd0;
    else if(if_flush == 1'b1)
        PC_line_out <= 32'd0;
    else
        PC_line_out <= PC_line_in;
end

assign  instruct_data_line_out = instruct_data_line_in;

endmodule
