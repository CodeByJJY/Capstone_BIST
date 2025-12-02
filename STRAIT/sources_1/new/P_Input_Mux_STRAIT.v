`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 17:57:59
// Design Name: 
// Module Name: P_Input_Mux_STRAIT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module P_Input_Mux_STRAIT (
    input  wire [31:0] from_top,
    input  wire [31:0] from_left,
    input  wire        select,     // 0이면 from_left, 1이면 from_top
    output wire [31:0] out_p
);

    // OR 연산과 MUX 조합
    assign out_p = select ? from_top : from_left;

endmodule
