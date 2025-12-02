/*******************************************************************
* 모듈명: tb_P_Input_Mux_BICS
* 설명: P_Input_Mux_BICS.v 모듈의 4-to-1 우선순위 MUX 기능을 검증합니다.
*
* 우선순위: scan_en (P1) > bist_capture_en (P2) > pe_disable (P3) > Normal (Default)
*******************************************************************/

`timescale 1ns / 1ps

module tb_P_Input_Mux_BICS;

    // --- 파라미터 선언 ---
    parameter P_WIDTH = 32;
    parameter DELAY   = 10; // 입력 변경 후 대기 시간 (10ns)

    // --- 테스트용 데이터 정의 ---
    localparam DATA_NORMAL   = 32'hAAAA_AAAA; // 4순위 (Normal)
    localparam DATA_SCAN     = 32'hBBBB_BBBB; // 1순위 & 3순위 (Scan/Bypass)
    localparam DATA_CAPTURE  = 32'h0000_0001; // 2순위 (Fail Flag Capture)
    localparam DATA_CAPTURE_FLAG = 1'b1;      // DATA_CAPTURE를 만들기 위한 1비트 fail_flag

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  [P_WIDTH-1:0] tb_actual_result;
    reg  [P_WIDTH-1:0] tb_scan_in_p;
    reg                tb_fail_flag;
    
    reg                tb_scan_en;
    reg                tb_bist_capture_en;
    reg                tb_pe_disable;
    
    wire [P_WIDTH-1:0] tb_p_reg_in;

    // --- DUT (Design Under Test) 인스턴스화 ---
    P_Input_Mux_BICS #(
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .actual_result(tb_actual_result),
        .scan_in_p(tb_scan_in_p),
        .fail_flag(tb_fail_flag),
        .scan_en(tb_scan_en),
        .bist_capture_en(tb_bist_capture_en),
        .pe_disable(tb_pe_disable),
        .p_reg_in(tb_p_reg_in)
    );

    // --- 모니터링 ---
    initial begin
        $monitor("Time=%0t | P1(scan_en)=%b P2(capture)=%b P3(disable)=%b | OUT = 0x%h",
                 $time, tb_scan_en, tb_bist_capture_en, tb_pe_disable, tb_p_reg_in);
    end

    // --- 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- P_Input_Mux_BICS 우선순위 테스트 시작 ---");
        
        // --- 0. 초기값 설정 ---
        // 4개의 데이터 입력을 고유한 값으로 고정
        tb_actual_result   = DATA_NORMAL;
        tb_scan_in_p       = DATA_SCAN;
        tb_fail_flag       = DATA_CAPTURE_FLAG;
        // 모든 제어 신호 0으로 시작
        tb_scan_en         = 0;
        tb_bist_capture_en = 0;
        tb_pe_disable      = 0;
        #DELAY;

        // --- 테스트 1: 4순위 (Default/Normal) ---
        $display("--- 테스트 1: 모든 제어=0 (Normal Mode) ---");
        // (이미 설정됨)
        #DELAY;
        if (tb_p_reg_in !== DATA_NORMAL) begin
            $error("테스트 1 실패! (Normal) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_NORMAL); $finish;
        end

        // --- 테스트 2: 3순위 (PE Disable) ---
        $display("--- 테스트 2: P3(disable)=1 (Bypass Mode) ---");
        tb_pe_disable = 1;
        #DELAY;
        if (tb_p_reg_in !== DATA_SCAN) begin
            $error("테스트 2 실패! (Bypass) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_SCAN); $finish;
        end

        // --- 테스트 3: 2순위 (BIST Capture) - 3순위를 덮어쓰는지 확인 ---
        $display("--- 테스트 3: P2(capture)=1 (Capture Mode) - P3(disable)보다 우선 ---");
        tb_bist_capture_en = 1; // P3(disable)은 여전히 1인 상태
        #DELAY;
        if (tb_p_reg_in !== DATA_CAPTURE) begin
            $error("테스트 3 실패! (Capture) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_CAPTURE); $finish;
        end

        // --- 테스트 4: 1순위 (Scan Enable) - 2/3순위를 덮어쓰는지 확인 ---
        $display("--- 테스트 4: P1(scan_en)=1 (Scan Mode) - P2/P3보다 우선 ---");
        tb_scan_en = 1; // P2(capture)와 P3(disable)은 여전히 1인 상태
        #DELAY;
        if (tb_p_reg_in !== DATA_SCAN) begin
            $error("테스트 4 실패! (Scan) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_SCAN); $finish;
        end

        // --- 테스트 5: 1순위 -> 2순위 (우선순위 복귀) ---
        $display("--- 테스트 5: P1(scan_en)=0 (P2가 다시 우선) ---");
        tb_scan_en = 0; // P2(capture)와 P3(disable)은 여전히 1인 상태
        #DELAY;
        if (tb_p_reg_in !== DATA_CAPTURE) begin
            $error("테스트 5 실패! (Capture) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_CAPTURE); $finish;
        end
        
        // --- 테스트 6: 2순위 -> 3순위 (우선순위 복귀) ---
        $display("--- 테스트 6: P2(capture)=0 (P3가 다시 우선) ---");
        tb_bist_capture_en = 0; // P3(disable)은 여전히 1인 상태
        #DELAY;
        if (tb_p_reg_in !== DATA_SCAN) begin
            $error("테스트 6 실패! (Bypass) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_SCAN); $finish;
        end
        
        // --- 테스트 7: 3순위 -> 4순위 (우선순위 복귀) ---
        $display("--- 테스트 7: P3(disable)=0 (Default가 다시 우선) ---");
        tb_pe_disable = 0; // 모든 제어 신호 0
        #DELAY;
        if (tb_p_reg_in !== DATA_NORMAL) begin
            $error("테스트 7 실패! (Normal) OUT=0x%h (예상=0x%h)", tb_p_reg_in, DATA_NORMAL); $finish;
        end

        $display("--- 모든 P_Input_Mux_BICS 테스트 통과 ---");
        $finish;
    end

endmodule