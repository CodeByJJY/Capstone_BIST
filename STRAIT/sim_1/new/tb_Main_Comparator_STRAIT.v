`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 18:04:22
// Design Name: 
// Module Name: tb_Main_Comparator_STRAIT
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

module tb_Main_Comparator_STRAIT;
    reg clk = 0, rst = 0;
    reg [31:0] accum_out, expected;
    wire ERROR;

    Main_Comparator_STRAIT uut (
        .clk(clk), .rst(rst),
        .accum_out(accum_out),
        .expected(expected),
        .ERROR(ERROR)
    );

    always #5 clk = ~clk;

    initial begin
        $display("--- Main_Comparator_STRAIT Test Start ---");
        rst = 1; #10;
        rst = 0;

        // 일치하는 경우
        accum_out = 32'hDEADBEEF; expected = 32'hDEADBEEF; #10;
        $display("Match Test: ERROR = %b", ERROR);  // 0이어야 함

        // 불일치하는 경우
        accum_out = 32'hABCD1234; expected = 32'h1234ABCD; #10;
        $display("Mismatch Test: ERROR = %b", ERROR);  // 1이어야 함

        // 이후에도 유지되는지 확인
        accum_out = 32'h00000000; expected = 32'h00000000; #10;
        $display("Persistent ERROR: ERROR = %b", ERROR);  // 여전히 1

        $display("--- Main_Comparator_STRAIT Test Done ---");
        $finish;
    end
endmodule