/*******************************************************************
* 모듈명: tb_PE_Top_BICS
* 설명:
* PE_Top_BICS.v 모듈의 2단계 통합 테스트 벤치입니다.
*
* [수정]: 테스트 2 (Normal Mode)가 2-stage 파이프라인을
* (1클럭: A/W 래치, 2클럭: P 래치) 올바르게 검증하도록 수정.
* [수정]: 레이스 컨디션 방지를 위해 @(posedge tb_clk) 직후 #1 딜레이 추가.
* [수정 2]: 테스트 2의 1st 클럭 P_out 예상 값을 0 -> 10으로 수정
*******************************************************************/

`timescale 1ns / 1ps

module tb_PE_Top_BICS;

    // --- 파라미터 선언 ---
    parameter A_WIDTH = 8;
    parameter W_WIDTH = 8;
    parameter P_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    // --- 1. DUT 입력 (reg) ---
    reg tb_clk;
    reg tb_rst;

    // BIST 제어 신호
    reg tb_parallel_load_en;
    reg tb_bist_capture_en;
    reg tb_scan_en;
    
    // TPG 데이터 신호
    reg signed [A_WIDTH-1:0] tb_in_tp_a;
    reg signed [W_WIDTH-1:0] tb_in_tp_w;
    reg signed [P_WIDTH-1:0] tb_in_expected_p;

    // BISR 신호
    reg tb_pe_disable;

    // 이웃 PE 입력
    reg signed [A_WIDTH-1:0] tb_scan_in_a;
    reg signed [W_WIDTH-1:0] tb_scan_in_w;
    reg signed [P_WIDTH-1:0] tb_scan_in_p;
    
    // --- 2. DUT 출력 (wire) ---
    wire signed [A_WIDTH-1:0] tb_scan_out_a;
    wire signed [W_WIDTH-1:0] tb_scan_out_w;
    wire signed [P_WIDTH-1:0] tb_scan_out_p;

    // --- 3. DUT 인스턴스화 ---
    PE_Top_BICS #(
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .clk(tb_clk),
        .rst(tb_rst),
        .parallel_load_en(tb_parallel_load_en),
        .bist_capture_en(tb_bist_capture_en),
        .scan_en(tb_scan_en),
        .in_tp_a(tb_in_tp_a),
        .in_tp_w(tb_in_tp_w),
        .in_expected_p(tb_in_expected_p),
        .pe_disable(tb_pe_disable),
        .scan_in_a(tb_scan_in_a),
        .scan_in_w(tb_scan_in_w),
        .scan_in_p(tb_scan_in_p),
        .scan_out_a(tb_scan_out_a),
        .scan_out_w(tb_scan_out_w),
        .scan_out_p(tb_scan_out_p)
    );

    // --- 4. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 5. 모니터링 (디버깅용) ---
    initial begin
        $monitor("Time=%0t | rst=%b | load=%b cap=%b scan=%b dis=%b | A_in=%d W_in=%d P_in=%d | A_out=%d W_out=%d P_out=0x%h",
                 $time, tb_rst, tb_parallel_load_en, tb_bist_capture_en, tb_scan_en, tb_pe_disable,
                 tb_scan_in_a, tb_scan_in_w, tb_scan_in_p,
                 tb_scan_out_a, tb_scan_out_w, tb_scan_out_p);
    end

    // --- 6. 테스트 시나리오 ---
    initial begin
        $display("--- PE_Top_BICS 테스트 시작 ---");
        
        // --- 1. 리셋 ---
        tb_rst = 1;
        tb_parallel_load_en = 0; tb_bist_capture_en = 0; tb_scan_en = 0; tb_pe_disable = 0;
        tb_in_tp_a = 0; tb_in_tp_w = 0; tb_in_expected_p = 0;
        tb_scan_in_a = 0; tb_scan_in_w = 0; tb_scan_in_p = 0;
        @(posedge tb_clk); // 5ns
        @(posedge tb_clk); // 15ns
        tb_rst = 0;
        @(posedge tb_clk); // 25ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_a !== 0 || tb_scan_out_w !== 0 || tb_scan_out_p !== 0) begin
            $error("리셋 실패! A/W/P 출력이 0이 아님"); $finish;
        end
        $display("--- 테스트 1: 리셋 통과 ---");

        // --- 2. 일반 연산 (Normal Mode) - 2-stage Pipeline 검증 ---
        $display("--- 테스트 2: 일반 연산 (2-stage Pipeline) ---");
        // (A_in=2, W_in=3, P_in=10)
        // 1클럭 후 (35ns): A_out=2, W_out=3, P_out=(A_reg=0 * W_reg=0) + P_in=10 = 10
        // 2클럭 후 (45ns): A_out=2, W_out=3, P_out=(A_reg=2 * W_reg=3) + P_in=10 = 16
        
        // 1st 클럭: A/W 레지스터에 값 래치
        tb_scan_in_a = 2; tb_scan_in_w = 3; tb_scan_in_p = 10;
        @(posedge tb_clk); // 35ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_a !== 2 || tb_scan_out_w !== 3) begin
             $error("테스트 2 실패! (A/W Reg) A=%d W=%d (예상: 2, 3)", tb_scan_out_a, tb_scan_out_w); $finish;
        end
        
        // [버그 수정] P_out은 1클럭 전의 MAC 결과 (리셋값 A_reg=0 * W_reg=0) + *현재* P_in=10 = 10
        if (tb_scan_out_p !== 10) begin
             $error("테스트 2 실패! (P Reg Cycle 1) P=0x%h (예상: 10)", tb_scan_out_p); $finish;
        end
        $display("... 1st 클럭: A_out=2, W_out=3, P_out=10 (정상)");
        
        // 2nd 클럭: P 레지스터에 MAC 결과(A*W+P_in) 래치
        // 입력은 그대로 유지
        @(posedge tb_clk); // 45ns
        #1; // 레이스 컨디션 방지
        
        // P_out은 1클럭 전의 MAC 결과 (A_reg=2 * W_reg=3) + *현재* P_in=10 = 16
        if (tb_scan_out_p !== 16) begin
             $error("테스트 2 실패! (P Reg Cycle 2) P=0x%h (예상: 16)", tb_scan_out_p); $finish;
        end
        $display("--- 테스트 2: 일반 연산 통과 (A=2, W=3, P_out=16) ---");
        

        // --- 3. BICS 병렬 로드 (Parallel Load) ---
        $display("--- 테스트 3: BICS 병렬 로드 ---");
        tb_parallel_load_en = 1;
        tb_in_tp_a = 5; tb_in_tp_w = 10;
        tb_scan_in_a = 99; tb_scan_in_w = 99; // 이웃 PE 값은 무시되어야 함
        @(posedge tb_clk); // 55ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_a !== 5 || tb_scan_out_w !== 10) begin
            $error("테스트 3 실패! (Load) A=%d W=%d (예상: 5, 10)",
                   tb_scan_out_a, tb_scan_out_w); $finish;
        end
        tb_parallel_load_en = 0; // 로드 종료
        $display("--- 테스트 3: BICS 병렬 로드 통과 (A=5, W=10) ---");

        // --- 4a. BICS 플래그 캡처 (Pass) ---
        $display("--- 테스트 4a: BICS 캡처(Pass) ---");
        // A=5, W=10 (이전 상태), P_in=100, Expected=150
        // (5*10)+100 = 150. (150 == 150) -> fail_flag=0 -> P_out=0
        tb_bist_capture_en = 1;
        tb_scan_in_p = 100;       // P_in (MAC 입력)
        tb_in_expected_p = 150; // 황금 정답
        @(posedge tb_clk); // 65ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_p !== 0) begin
            $error("테스트 4a 실패! (Capture Pass) P_out=0x%h (예상: 0x0)", tb_scan_out_p); $finish;
        end
        tb_bist_capture_en = 0;
        $display("--- 테스트 4a: BICS 캡처(Pass) 통과 (P_out=0) ---");

        // --- 4b. BICS 플래그 캡처 (Fail) ---
        $display("--- 테스트 4b: BICS 캡처(Fail) ---");
        // A=5, W=10 (이전 상태), P_in=100, Expected=999
        // (5*10)+100 = 150. (150 != 999) -> fail_flag=1 -> P_out=1
        tb_bist_capture_en = 1;
        tb_scan_in_p = 100;       // P_in (MAC 입력)
        tb_in_expected_p = 999; // 틀린 황금 정답
        @(posedge tb_clk); // 75ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_p !== 1) begin
            $error("테스트 4b 실패! (Capture Fail) P_out=0x%h (예상: 0x1)", tb_scan_out_p); $finish;
        end
        tb_bist_capture_en = 0;
        $display("--- 테스트 4b: BICS 캡처(Fail) 통과 (P_out=1) ---");

        // --- 5. P-스캔 체인 (Scan Mode) ---
        $display("--- 테스트 5: P-스캔 체인 (Scan) ---");
        // (scan_in_p = 0xDEADBEEF) -> (P_out = 0xDEADBEEF)
        tb_scan_en = 1;
        tb_scan_in_p = 32'hDEADBEEF;
        @(posedge tb_clk); // 85ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_p !== 32'hDEADBEEF) begin
            $error("테스트 5 실패! (Scan) P_out=0x%h (예상: 0xDEADBEEF)", tb_scan_out_p); $finish;
        end
        tb_scan_en = 0;
        $display("--- 테스트 5: P-스캔 체인 통과 ---");
        
        // --- 6. PE 바이패스 (Disable Mode) ---
        $display("--- 테스트 6: PE 바이패스 (Disable) ---");
        tb_pe_disable = 1; // E 레지스터에 1을 래치
        @(posedge tb_clk); // 95ns (E=1 래치됨)
        #1; // 레이스 컨디션 방지
        
        // E 레지스터에 1이 래치된 상태에서 테스트
        tb_scan_in_a = 8'hAA;
        tb_scan_in_p = 32'hCAFECAFE;
        tb_scan_in_w = 8'hBB; 
        
        @(posedge tb_clk); // 105ns
        #1; // 레이스 컨디션 방지
        
        if (tb_scan_out_a !== 8'hAA || tb_scan_out_p !== 32'hCAFECAFE) begin
            $error("테스트 6 실패! (Disable) A=%h, P=%h (예상: AA, CAFECAFE)",
                   tb_scan_out_a, tb_scan_out_p); $finish;
        end
        $display("--- 테스트 6: PE 바이패스 통과 (A=AA, P=CAFECAFE) ---");


        $display("--- 모든 PE_Top_BICS 테스트 통과 ---");
        $finish;
    end

endmodule