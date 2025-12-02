`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 18:20:34
// Design Name: 
// Module Name: tb_PE_Top_STRAIT
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

module tb_PE_Top_STRAIT;

    // 입력
    reg clk;
    reg rst;
    reg scan_en;
    reg [31:0] A, W, P_in;

    // 출력
    wire [31:0] P_out;
    wire [31:0] A_out, W_out;

    // DUT 인스턴스
    PE_Top_STRAIT dut (
        .clk(clk),
        .rst(rst),
        .scan_en(scan_en),
        .A(A),
        .W(W),
        .P_in(P_in),
        .P_out(P_out),
        .A_out(A_out),
        .W_out(W_out)
    );

    // 클럭 생성
    always #5 clk = ~clk;

    initial begin
        $display("\n--- PE_Top_STRAIT Test Start ---");

        // 초기화
        clk = 0;
        rst = 1;
        scan_en = 0;
        A = 0;
        W = 0;
        P_in = 0;
        #10;

        // 리셋 해제
        rst = 0;

        // === 테스트 1: CAPTURE (scan_en = 0) ===
        // A = 2, W = 3, P_in = 4 → MAC = 2×3+4 = 10
        A = 32'd2;
        W = 32'd3;
        P_in = 32'd4;
        scan_en = 0;  // capture
        #10;  // 첫 클럭에서 내부 A_reg, W_reg에 저장됨 → 아직 MAC 안 됨
        #10;  // 두 번째 클럭에 capture → 결과 나옴

        $display("Capture: A=2, W=3, P_in=4 -> P_out = %d (Expected 10)", P_out);
        $display("         A_out = %d (Expected 2), W_out = %d (Expected 3)", A_out, W_out);

        // === 테스트 2: SHIFT 모드 (scan_en = 1) ===
        scan_en = 1;
        P_in = 32'hCAFEBABE;
        #10;

        $display("Shift: scan_en=1, P_in=CAFEBABE -> P_out = %h (Expected CAFEBABE)", P_out);

        $display("--- PE_Top_STRAIT Test Done ---\n");
        $finish;
    end

endmodule