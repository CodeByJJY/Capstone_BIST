`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 18:02:59
// Design Name: 
// Module Name: Main_Comparator_STRAIT
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

module Main_Comparator_STRAIT (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] accum_out,
    input  wire [31:0] expected,
    output reg         ERROR
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            ERROR <= 0;
        else if (accum_out !== expected)
            ERROR <= 1;  // 한 번이라도 틀리면 계속 1 유지
    end

endmodule