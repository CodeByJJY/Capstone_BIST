`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: tb_Systolic_Array_Top_BICS
* 설명:
* Systolic_Array_Top_BICS.v (N x N 배열) 모듈을 검증합니다.
* N=4 (4x4 = 16 PEs)로 설정하여 테스트합니다.
*
* [수정 3]: Vivado [VRFC 10-2951] 에러 해결 (Indexed Part-Select)
* [수정 4]: 2-stage 파이프라인 해저드(Hazard) 해결
* LOAD(1clk)와 CAPTURE(1clk) 사이에 1클럭의 "CALC" 상태를
* (모든 제어 신호=0) 삽입하여 FSM의 N+4 사이클을 모방합니다.
*
* [수정 5 (Gemini)]:
* 1. 'for' 루프 part-select를 Replication Operator로 변경 (Data 설정 오류 수정)
* 2. Test 2/3의 Latency 오류 수정 (T=56/86ns 체크 제거)
* 3. Test 2b (Pass Stream Scan-Out) 추가
*******************************************************************/

module tb_Systolic_Array_Top_BICS;

    // --- 파라미터 선언 ---
    parameter ARRAY_SIZE = 4; // 시뮬레이션을 위해 N=4로 설정
    parameter A_WIDTH    = 8;
    parameter W_WIDTH    = 8;
    parameter P_WIDTH    = 32;
    parameter CLK_PERIOD = 10;
    
    localparam PE_BUS_SIZE = ARRAY_SIZE * ARRAY_SIZE; // 16

    // --- 1. DUT 입력 (reg) ---
    reg tb_clk;
    reg tb_rst;

    reg tb_parallel_load_en;
    reg tb_bist_capture_en;
    reg tb_scan_en;
    
    reg signed [A_WIDTH-1:0] tb_in_tp_a;
    reg signed [W_WIDTH-1:0] tb_in_tp_w;
    reg signed [P_WIDTH-1:0] tb_in_expected_p;

    reg [PE_BUS_SIZE-1:0] tb_pe_disable_bus;

    reg signed [(A_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_a;
    reg signed [(W_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_w;
    reg signed [(P_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_p;
    
    // --- 2. DUT 출력 (wire) ---
    wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_out_a;
    wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_out_w;
    wire signed [P_WIDTH-1:0] tb_final_scan_out_p;

    integer i; // 루프용

    // --- 3. DUT 인스턴스화 ---
    Systolic_Array_Top_BICS #(
        .ARRAY_SIZE(ARRAY_SIZE),
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
        .pe_disable_bus(tb_pe_disable_bus),
        .flat_array_in_a(tb_flat_array_in_a),
        .flat_array_in_w(tb_flat_array_in_w),
        .flat_array_in_p(tb_flat_array_in_p),
        .flat_array_out_a(tb_flat_array_out_a),
        .flat_array_out_w(tb_flat_array_out_w),
        .final_scan_out_p(tb_final_scan_out_p)
    );

    // --- 4. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 5. 모니터링 ---
    initial begin
        $monitor("Time=%0t | rst=%b | load=%b cap=%b scan=%b | final_scan_out_p=0x%h",
                 $time, tb_rst, tb_parallel_load_en, tb_bist_capture_en, tb_scan_en,
                 tb_final_scan_out_p);
    end

    // --- 6. 테스트 시나리오 ---
    initial begin
        $display("--- Systolic_Array_Top_BICS (N=%d) 테스트 시작 ---", ARRAY_SIZE);
        
        // --- 1. 리셋 및 초기화 ---
        tb_rst = 1;
        tb_parallel_load_en = 0; tb_bist_capture_en = 0; tb_scan_en = 0;
        tb_in_tp_a = 0; tb_in_tp_w = 0; tb_in_expected_p = 0;
        tb_pe_disable_bus = 0;
        tb_flat_array_in_a = 0;
        tb_flat_array_in_w = 0;
        tb_flat_array_in_p = 0;
        
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 0;
        @(posedge tb_clk);
        #1;
        if (tb_final_scan_out_p !== 0) begin
            $error("리셋 실패! final_scan_out_p가 0이 아님"); $finish;
        end
        $display("--- 1. 리셋 통과 ---");

        // --- 2. BICS 로드 + 캡처 (Pass) ---
        // (A=5, W=10, P_in=100) -> 150. (Expected=150) -> Pass (fail_flag=0)
        $display("--- 2. BICS 캡처(Pass) 테스트 ---");
        // 1. S_LOAD
        tb_parallel_load_en = 1; 
        tb_bist_capture_en = 0;
        tb_in_tp_a = 5;
        tb_in_tp_w = 10;
        @(posedge tb_clk); // 35ns. A.d=5, W.d=10
        
        // 2. S_CALC (파이프라인 해저드 방지용 1클럭 대기)
        tb_parallel_load_en = 0;
        tb_bist_capture_en = 0;
        // P_in과 Expected_Result는 이 CALC 상태에서 안정화됨
        tb_in_expected_p = 150; // 올바른 정답
        
        // [수정 1] Replication Operator 사용
        tb_flat_array_in_p = {(ARRAY_SIZE){32'sd100}}; // P_in = 100
        
        @(posedge tb_clk); // 45ns. A.q=5, W.q=10. MAC/Comp 조합논리 계산.
        
        // 3. S_CAPTURE
        tb_parallel_load_en = 0;
        tb_bist_capture_en = 1; // 캡처
        @(posedge tb_clk); // 55ns. P.d <= fail_flag(0)
        #1; // 56ns

        // [수정 2] Latency 오류로 인해 T=56ns 에서의 체크 제거
        // P.q는 150이 되지만, final_scan_out_p는 아직 0임.
        // P.d는 0 (fail_flag=0)이 됨.
        tb_bist_capture_en = 0;
        $display("... Pass Test: Capture Cycle Done. (fail_flag=0 캡처됨)");

        // --- 2b. [신규] Scan-Out (Pass Stream) ---
        // 직전 S_CAPTURE에서 P.d <= 0 (Pass)이 됨.
        $display("--- 2b. Scan-Out (Pass Stream, N=4) 테스트 ---");
        tb_scan_en = 1;
        tb_flat_array_in_p = 0; // P-path 스캔 체인의 상단 입력은 0
        
        // N 클럭 동안 0이 나오는지 확인
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            @(posedge tb_clk); // 65ns, 75ns, 85ns, 95ns
            #1;
            // P.q(at S_CAPTURE) = 0. 이 0이 N 클럭에 걸쳐 전파됨.
            if (tb_final_scan_out_p !== 0) begin
                $error("테스트 2b 실패! (Shift %d) Pass Flag(0)가 스캔되지 않음. P_out=0x%h", i+1, tb_final_scan_out_p); $finish;
            end
        end
        $display("... Pass Stream: 0이 %d 클럭 동안 스캔됨 (정상)", ARRAY_SIZE);
        tb_scan_en = 0;


        // --- 3. BICS 로드 + 캡처 (Fail) ---
        $display("--- 3. BICS 캡처(Fail) 테스트 ---");
        // 1. S_LOAD
        tb_parallel_load_en = 1;
        tb_bist_capture_en = 0;
        tb_in_tp_a = 5;
        tb_in_tp_w = 10;
        @(posedge tb_clk); // 105ns
        
        // 2. S_CALC
        tb_parallel_load_en = 0;
        tb_bist_capture_en = 0;
        tb_in_expected_p = 999; // 틀린 정답
        
        // [수정 1] Replication Operator 사용
        tb_flat_array_in_p = {(ARRAY_SIZE){32'sd100}}; // P_in = 100
        
        @(posedge tb_clk); // 115ns
        
        // 3. S_CAPTURE
        tb_bist_capture_en = 1;
        @(posedge tb_clk); // 125ns. P.d <= fail_flag(1)
        #1; // 126ns
        
        // [수정 2] Latency 오류로 인해 T=86ns(126ns) 에서의 체크 제거
        // P.q는 150이 되지만, final_scan_out_p는 아직 0임.
        // P.d는 1 (fail_flag=1)이 됨.
        tb_bist_capture_en = 0;
        $display("... Fail Test: Capture Cycle Done. (fail_flag=1 캡처됨)");


        // --- 4. Scan-Out (Fail Stream) ---
        // 직전 S_CAPTURE에서 P.d <= 1 (Fail)이 됨.
        $display("--- 4. Scan-Out (Fail Stream, N=4) 테스트 ---");
        tb_scan_en = 1;
        tb_flat_array_in_p = 0; // P-path 스캔 체인의 상단 입력은 0
        
        // S_SHIFT 클럭 1
        @(posedge tb_clk); // 135ns
        #1; // 136ns
        // P.q (at 136ns) = P.d (at 125ns) = 1 (Fail Flag)
        // 이 값은 PE(0,0)에만 있음. N=4이므로 final_scan_out_p는 아직 0.
        if (tb_final_scan_out_p !== 0) begin
             $error("테스트 4 오류! (Shift 1) 값이 너무 일찍 나옴. P_out=0x%h (예상 0x0)", tb_final_scan_out_p); $finish;
        end

        // S_SHIFT 클럭 2
        @(posedge tb_clk); // 145ns
        #1; // 146ns
        if (tb_final_scan_out_p !== 0) begin
             $error("테스트 4 오류! (Shift 2) 값이 너무 일찍 나옴. P_out=0x%h (예상 0x0)", tb_final_scan_out_p); $finish;
        end
        
        // S_SHIFT 클럭 3
        @(posedge tb_clk); // 155ns
        #1; // 156ns
        if (tb_final_scan_out_p !== 0) begin
             $error("테스트 4 오류! (Shift 3) 값이 너무 일찍 나옴. P_out=0x%h (예상 0x0)", tb_final_scan_out_p); $finish;
        end

        // S_SHIFT 클럭 4 (N번째)
        // PE(0,0)의 '1'이 PE(3,0)을 거쳐 final_scan_out_p로 나옴
        @(posedge tb_clk); // 165ns
        #1; // 166ns
        if (tb_final_scan_out_p !== 1) begin
            $error("테스트 4 실패! (Shift %d) Fail Flag가 캡처되지 않음. P_out=0x%h (예상 0x1)", ARRAY_SIZE, tb_final_scan_out_p); $finish;
        end
        $display("... Shift %d: P_out=1 (Fail Flag 캡처 성공)", ARRAY_SIZE);

        // N=4 (ARRAY_SIZE)이므로, 1, 1, 1이 스캔 아웃되어야 합니다.
        // Bitwise-OR 이므로 1이 계속 유지됩니다.
        for (i = 1; i < ARRAY_SIZE; i = i + 1) begin
             @(posedge tb_clk); // 175ns, 185ns
             #1;
             if (tb_final_scan_out_p !== 1) begin
                $error("테스트 4 실패! (Shift %d) 1이 유지되지 않음.", ARRAY_SIZE+i); $finish;
             end
        end
        $display("... %d 클럭 동안 1 유지 (정상)", ARRAY_SIZE - 1);
        
        // (N*2-1) = 7번째 클럭
        // 마지막 '1'이 빠져나가고 0이 들어옴
        @(posedge tb_clk); // 195ns
        #1; // 196ns
        if (tb_final_scan_out_p !== 0) begin
             $error("테스트 4 실패! (Shift %d) 0으로 비워지지 않음", (ARRAY_SIZE*2)-1); $finish;
        end
        $display("... %d 클럭 째에 0으로 비워짐 (정상)", (ARRAY_SIZE*2)-1);
        
        tb_scan_en = 0;

        $display("--- 모든 Systolic_Array_Top_BICS 테스트 통과 ---");
        $finish;
    end

endmodule