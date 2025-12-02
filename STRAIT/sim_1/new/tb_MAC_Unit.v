`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 15:32:34
// Design Name: 
// Module Name: tb_MAC_Unit
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

module tb_MAC_Unit;

    // --- 파라미터 선언 (DUT와 동일하게) ---
    parameter A_WIDTH = 8;
    parameter W_WIDTH = 8;
    parameter P_WIDTH = 32;
    parameter DELAY   = 10; // 입력 변경 후 대기 시간 (10ns)

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  signed [A_WIDTH-1:0] tb_in_a;
    reg  signed [W_WIDTH-1:0] tb_in_w;
    reg  signed [P_WIDTH-1:0] tb_in_p;
    wire signed [P_WIDTH-1:0] tb_actual_result;
    
    // 검증을 위한 예상 결과값 (부호 있는 정수)
    reg  signed [P_WIDTH-1:0] tb_expected_result;

    // --- DUT (Design Under Test) 인스턴스화 ---
    MAC_Unit #(
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .in_a(tb_in_a),
        .in_w(tb_in_w),
        .in_p(tb_in_p),
        .actual_result(tb_actual_result)
    );

    // --- 모니터링 ---
    // 신호가 바뀔 때마다 값들을 10진수(d)와 16진수(h)로 출력
    initial begin
        $monitor("Time=%0t | in_a: %d(0x%h) | in_w: %d(0x%h) | in_p: %d(0x%h) | Result: %d(0x%h) | Expected: %d(0x%h)",
                 $time, tb_in_a, tb_in_a, tb_in_w, tb_in_w, tb_in_p, tb_in_p, 
                 tb_actual_result, tb_actual_result, tb_expected_result, tb_expected_result);
    end

    // --- 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- MAC_Unit Test Start (A*W + P_in) ---");

        // 1. 테스트: 모두 양수
        // (5 * 10) + 100 = 150
        $display("--- Test 1: (5 * 10) + 100 ---");
        tb_in_a = 5;
        tb_in_w = 10;
        tb_in_p = 100;
        tb_expected_result = 150;
        #DELAY; // 조합 논리가 안정화될 때까지 대기
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 1 failed!"); $finish;
        end
        
        // 2. 테스트: 곱셈 결과가 음수
        // (-5 * 10) + 100 = -50 + 100 = 50
        $display("--- Test 2: (-5 * 10) + 100 ---");
        tb_in_a = -5; // 8'hFB
        tb_in_w = 10;
        tb_in_p = 100;
        tb_expected_result = 50;
        #DELAY;
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 2 failed!"); $finish;
        end

        // 3. 테스트: 음수 x 음수 = 양수
        // (-5 * -10) + 100 = 50 + 100 = 150
        $display("--- Test 3: (-5 * -10) + 100 ---");
        tb_in_a = -5;
        tb_in_w = -10; // 8'hF6
        tb_in_p = 100;
        tb_expected_result = 150;
        #DELAY;
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 3 failed!"); $finish;
        end

        // 4. 테스트: 누적 결과가 음수
        // (5 * 10) + (-200) = 50 - 200 = -150
        $display("--- Test 4: (5 * 10) + (-200) ---");
        tb_in_a = 5;
        tb_in_w = 10;
        tb_in_p = -200; // 32'hFFFFFF38
        tb_expected_result = -150;
        #DELAY;
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 4 failed!"); $finish;
        end

        // 5. 테스트: 모두 음수
        // (-5 * -10) + (-100) = 50 - 100 = -50
        $display("--- Test 5: (-5 * -10) + (-100) ---");
        tb_in_a = -5;
        tb_in_w = -10;
        tb_in_p = -100;
        tb_expected_result = -50;
        #DELAY;
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 5 failed!"); $finish;
        end
        
        // 6. 테스트: 0 포함
        // (120 * 0) + (-50) = 0 - 50 = -50
        $display("--- Test 6: (120 * 0) + (-50) ---");
        tb_in_a = 120; // 8'h78
        tb_in_w = 0;
        tb_in_p = -50;
        tb_expected_result = -50;
        #DELAY;
        if (tb_actual_result !== tb_expected_result) begin
            $error("Test 6 failed!"); $finish;
        end

        $display("--- Every MAC_Unit Test Success! ---");
        $finish;
    end

endmodule