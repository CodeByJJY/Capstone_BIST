`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 23:48:43
// Design Name: 
// Module Name: tb_System_Top_STRAIT
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

module tb_System_Top_STRAIT;

    reg clk = 0;
    reg rst = 1;
    reg bist_en = 0;
    reg [1:0] bist_mode = 2'b00;

    wire done;

    always #5 clk = ~clk;

    System_Top_STRAIT dut (
        .clk(clk),
        .reset(rst),
        .bist_en(bist_en),
        .bist_mode(bist_mode),
        .done(done)
    );

    initial begin
        $display("=== STRAIT BIST Testbench Start ===");

        // 초기화
        #20; rst = 0;

        // BIST 시작
        #10;
        bist_mode = 2'b01;   // SA 테스트
        bist_en = 1;         // FSM 시작 트리거
        #10;
        bist_en = 0;         // 한 클럭만 줌

        // done 될 때까지 기다림
        wait (done == 1);
        #20;

        $display("=== STRAIT BIST Testbench Complete ===");
        $finish;
    end

endmodule