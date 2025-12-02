`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 17:58:55
// Design Name: 
// Module Name: tb_P_Input_Mux_STRAIT
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

module tb_P_Input_Mux_STRAIT;
    reg  [31:0] from_top;
    reg  [31:0] from_left;
    reg         select;
    wire [31:0] out_p;

    P_Input_Mux_STRAIT uut (
        .from_top(from_top),
        .from_left(from_left),
        .select(select),
        .out_p(out_p)
    );

    initial begin
        from_top  = 32'hAAAA_AAAA;
        from_left = 32'h5555_5555;

        select = 0; #10;
        $display("Select 0: out_p = %h", out_p);

        select = 1; #10;
        $display("Select 1: out_p = %h", out_p);

        $finish;
    end
endmodule