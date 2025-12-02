/*******************************************************************
* 모듈명: tb_Internal_Comparator
* 설명: Internal_Comparator.v 모듈의 'signed' 비교 기능을 검증합니다.
* 'actual'과 'expected' 값이 같을 때 fail_flag=0,
* 다를 때 fail_flag=1이 나오는지 확인합니다.
*******************************************************************/

`timescale 1ns / 1ps

module tb_Internal_Comparator;

    // --- 파라미터 선언 ---
    parameter P_WIDTH = 32;
    parameter DELAY   = 10; // 입력 변경 후 대기 시간 (10ns)

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  signed [P_WIDTH-1:0] tb_actual_result;
    reg  signed [P_WIDTH-1:0] tb_expected_result;
    
    wire                      tb_fail_flag;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Internal_Comparator #(
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .actual_result(tb_actual_result),
        .expected_result(tb_expected_result),
        .fail_flag(tb_fail_flag)
    );

    // --- 모니터링 ---
    initial begin
        $monitor("Time=%0t | actual=%d, expected=%d | fail_flag=%b",
                 $time, tb_actual_result, tb_expected_result, tb_fail_flag);
    end

    // --- 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Internal_Comparator 테스트 시작 ---");
        
        // --- 테스트 1: 양수 일치 (Pass) ---
        $display("--- 테스트 1: 양수 일치 (150 vs 150) -> Pass (fail_flag=0) ---");
        tb_actual_result   = 32'sd150;
        tb_expected_result = 32'sd150;
        #DELAY;
        if (tb_fail_flag !== 0) begin
            $error("테스트 1 실패! (값이 같음에도 fail_flag=1)"); $finish;
        end

        // --- 테스트 2: 양수 불일치 (Fail) ---
        $display("--- 테스트 2: 양수 불일치 (150 vs 149) -> Fail (fail_flag=1) ---");
        tb_actual_result   = 32'sd150;
        tb_expected_result = 32'sd149;
        #DELAY;
        if (tb_fail_flag !== 1) begin
            $error("테스트 2 실패! (값이 다름에도 fail_flag=0)"); $finish;
        end
        
        // --- 테스트 3: 음수 일치 (Pass) ---
        $display("--- 테스트 3: 음수 일치 (-150 vs -150) -> Pass (fail_flag=0) ---");
        tb_actual_result   = -32'sd150;
        tb_expected_result = -32'sd150;
        #DELAY;
        if (tb_fail_flag !== 0) begin
            $error("테스트 3 실패! (음수 값이 같음에도 fail_flag=1)"); $finish;
        end

        // --- 테스트 4: 음수 불일치 (Fail) ---
        $display("--- 테스트 4: 음수 불일치 (-150 vs -151) -> Fail (fail_flag=1) ---");
        tb_actual_result   = -32'sd150;
        tb_expected_result = -32'sd151;
        #DELAY;
        if (tb_fail_flag !== 1) begin
            $error("테스트 4 실패! (음수 값이 다름에도 fail_flag=0)"); $finish;
        end
        
        // --- 테스트 5: 0 일치 (Pass) ---
        $display("--- 테스트 5: 0 일치 (0 vs 0) -> Pass (fail_flag=0) ---");
        tb_actual_result   = 32'sd0;
        tb_expected_result = 32'sd0;
        #DELAY;
        if (tb_fail_flag !== 0) begin
            $error("테스트 5 실패! (0 값이 같음에도 fail_flag=1)"); $finish;
        end

        $display("--- 모든 Internal_Comparator 테스트 통과 ---");
        $finish;
    end

endmodule