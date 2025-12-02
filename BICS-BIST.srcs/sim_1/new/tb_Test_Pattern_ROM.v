/*******************************************************************
* 모듈명: tb_Test_Pattern_ROM
* 설명: Test_Pattern_ROM.v 모듈의 비동기식 읽기 기능을 검증합니다.
* 'addr' 입력에 따라 올바른 4개의 'signed' 출력
* (tp_a, tp_w, tp_p, expected_p)이 나오는지 확인합니다.
*******************************************************************/

`timescale 1ns / 1ps

module tb_Test_Pattern_ROM;

    // --- 파라미터 선언 (DUT와 동일하게) ---
    parameter DELAY        = 10; // 입력 변경 후 대기 시간 (10ns)
    parameter NUM_PATTERNS = 16;
    parameter ADDR_WIDTH   = $clog2(NUM_PATTERNS); // 4-bit
    parameter A_WIDTH      = 8;
    parameter W_WIDTH      = 8;
    parameter P_WIDTH      = 32;

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  [ADDR_WIDTH-1:0] tb_addr;
    
    wire signed [A_WIDTH-1:0] tb_out_tp_a;
    wire signed [W_WIDTH-1:0] tb_out_tp_w;
    wire signed [P_WIDTH-1:0] tb_out_tp_p;
    wire signed [P_WIDTH-1:0] tb_out_expected_p;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Test_Pattern_ROM #(
        .NUM_PATTERNS(NUM_PATTERNS),
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .addr(tb_addr),
        .out_tp_a(tb_out_tp_a),
        .out_tp_w(tb_out_tp_w),
        .out_tp_p(tb_out_tp_p),
        .out_expected_p(tb_out_expected_p)
    );

    // --- 모니터링 ---
    initial begin
        $monitor("Time=%0t | addr=%d | a=%d, w=%d, p=%d | expected=%d",
                 $time, tb_addr, tb_out_tp_a, tb_out_tp_w, tb_out_tp_p, tb_out_expected_p);
    end

    // --- 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Test_Pattern_ROM 테스트 시작 ---");
        
        // --- 테스트 0: 'default' (addr=0) ---
        $display("--- 테스트 0: 'default' (addr=0) ---");
        tb_addr = 0;
        #DELAY;
        if (tb_out_tp_a !== 0 || tb_out_tp_w !== 0 || tb_out_tp_p !== 0 || tb_out_expected_p !== 0) begin
            $error("Default (addr=0) 케이스 실패!"); $finish;
        end

        // --- 테스트 1: (5 * 10) + 100 = 150 ---
        $display("--- 테스트 1: (5 * 10) + 100 = 150 ---");
        tb_addr = 1;
        #DELAY;
        if (tb_out_tp_a !== 5 || tb_out_tp_w !== 10 || tb_out_tp_p !== 100 || tb_out_expected_p !== 150) begin
            $error("테스트 1 실패!"); $finish;
        end

        // --- 테스트 2: (-5 * 10) + 100 = 50 ---
        $display("--- 테스트 2: (-5 * 10) + 100 = 50 ---");
        tb_addr = 2;
        #DELAY;
        if (tb_out_tp_a !== -5 || tb_out_tp_w !== 10 || tb_out_tp_p !== 100 || tb_out_expected_p !== 50) begin
            $error("테스트 2 실패!"); $finish;
        end

        // --- 테스트 3: (-5 * -10) + 100 = 150 ---
        $display("--- 테스트 3: (-5 * -10) + 100 = 150 ---");
        tb_addr = 3;
        #DELAY;
        if (tb_out_tp_a !== -5 || tb_out_tp_w !== -10 || tb_out_tp_p !== 100 || tb_out_expected_p !== 150) begin
            $error("테스트 3 실패!"); $finish;
        end

        // --- 테스트 4: (5 * 10) + (-200) = -150 ---
        $display("--- 테스트 4: (5 * 10) + (-200) = -150 ---");
        tb_addr = 4;
        #DELAY;
        if (tb_out_tp_a !== 5 || tb_out_tp_w !== 10 || tb_out_tp_p !== -200 || tb_out_expected_p !== -150) begin
            $error("테스트 4 실패!"); $finish;
        end

        // --- 테스트 5: (120 * 0) + (-50) = -50 ---
        $display("--- 테스트 5: (120 * 0) + (-50) = -50 ---");
        tb_addr = 5;
        #DELAY;
        if (tb_out_tp_a !== 120 || tb_out_tp_w !== 0 || tb_out_tp_p !== -50 || tb_out_expected_p !== -50) begin
            $error("테스트 5 실패!"); $finish;
        end

        // --- 테스트 6: 'default' (out-of-bounds, addr=10) ---
        $display("--- 테스트 6: 'default' (addr=10) ---");
        tb_addr = 10; // case 문에 없는 주소
        #DELAY;
        if (tb_out_tp_a !== 0 || tb_out_tp_w !== 0 || tb_out_tp_p !== 0 || tb_out_expected_p !== 0) begin
            $error("Default (addr=10) 케이스 실패!"); $finish;
        end

        $display("--- 모든 Test_Pattern_ROM 테스트 통과 ---");
        $finish;
    end

endmodule