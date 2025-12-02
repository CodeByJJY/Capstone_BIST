`timescale 1ns / 1ps

module tb_System_Top;

    // =========================================================
    // 1. 시뮬레이션 파라미터 정의
    // =========================================================
    parameter CLK_PERIOD   = 10; // 100MHz
    parameter ARRAY_SIZE   = 16; 
    parameter NUM_PATTERNS = 16; 
    
    parameter A_WIDTH = 8;
    parameter W_WIDTH = 8;
    parameter P_WIDTH = 32;

    // =========================================================
    // 2. 공통 제어 신호
    // =========================================================
    reg clk;
    reg rst;
    reg start;

    // =========================================================
    // 3. DUT 1: BICS-BIST (본인) 신호
    // =========================================================
    wire bics_done;
    wire bics_final_error;
    
    reg  [(ARRAY_SIZE*ARRAY_SIZE)-1:0] bics_pe_disable_bus;
    reg  [(A_WIDTH*ARRAY_SIZE)-1:0]    bics_flat_in_a;
    reg  [(W_WIDTH*ARRAY_SIZE)-1:0]    bics_flat_in_w;
    reg  [(P_WIDTH*ARRAY_SIZE)-1:0]    bics_flat_in_p;
    wire [(A_WIDTH*ARRAY_SIZE)-1:0]    bics_flat_out_a;
    wire [(W_WIDTH*ARRAY_SIZE)-1:0]    bics_flat_out_w;

    // =========================================================
    // 4. DUT 2: STRAIT (팀원) 신호
    // =========================================================
    wire strait_done;
    // [수정] error_count 포트 제거 (팀원 모듈에 없으므로)
    reg  [1:0] strait_bist_mode;

    // =========================================================
    // 5. 성능 측정 변수
    // =========================================================
    integer start_time;
    integer bics_end_time;
    integer strait_end_time;
    
    integer bics_cycles;
    integer strait_cycles;

    // =========================================================
    // 6. 클럭 생성
    // =========================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =========================================================
    // 7. DUT 인스턴스화
    // =========================================================

    // --- [DUT 1] BICS-BIST System ---
    BIST_System_Top_BICS #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .NUM_PATTERNS(NUM_PATTERNS),
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) dut_bics (
        .clk(clk),
        .rst(rst),
        .start(start),
        .bist_done(bics_done),
        .final_error(bics_final_error),
        .pe_disable_bus(bics_pe_disable_bus),
        .flat_array_in_a(bics_flat_in_a),
        .flat_array_in_w(bics_flat_in_w),
        .flat_array_in_p(bics_flat_in_p),
        .flat_array_out_a(bics_flat_out_a),
        .flat_array_out_w(bics_flat_out_w)
    );

    // --- [DUT 2] STRAIT System ---
    System_Top_STRAIT dut_strait (
        .clk(clk),
        .reset(rst),           
        .bist_en(start),       
        .bist_mode(strait_bist_mode),
        // [수정] error_count 연결 삭제 (이 부분이 에러 원인이었음)
        .done(strait_done)
    );

    // =========================================================
    // 8. Watchdog (타임아웃)
    // =========================================================
    initial begin
        #(CLK_PERIOD * 5000);
        $display("\n[Time %0t] Simulation Timeout!", $time);
        $finish;
    end

    // =========================================================
    // 9. 메인 테스트 시나리오
    // =========================================================
    initial begin
        // --- 초기화 ---
        $display("============================================================");
        $display("   BICS vs STRAIT Fairness Benchmark Simulation Start");
        $display("============================================================");

        rst = 1;
        start = 0;
        
        bics_pe_disable_bus = 0;
        bics_flat_in_a = 0;
        bics_flat_in_w = 0;
        bics_flat_in_p = 0;
        strait_bist_mode = 2'b01;

        // --- 리셋 해제 ---
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 5);

        // --- 테스트 시작 ---
        start = 1;
        start_time = $time;
        $display("[Time %0t] Test START!", $time);

        // --- 완료 대기 ---
        fork
            // Thread 1: BICS
            begin
                wait(bics_done);
                bics_end_time = $time;
                bics_cycles = (bics_end_time - start_time) / CLK_PERIOD;
                $display("[Time %0t] BICS-BIST Completed! (Cycles: %0d)", $time, bics_cycles);
            end

            // Thread 2: STRAIT
            begin
                wait(strait_done);
                strait_end_time = $time;
                strait_cycles = (strait_end_time - start_time) / CLK_PERIOD;
                $display("[Time %0t] STRAIT Completed! (Cycles: %0d)", $time, strait_cycles);
            end
        join

        #(CLK_PERIOD * 10);

        // =========================================================
        // 10. 최종 결과 리포트
        // =========================================================
        $display("\n============================================================");
        $display("                  FINAL BENCHMARK REPORT                    ");
        $display("============================================================");
        
        // 1. 속도 비교
        $display("1. Test Speed (Latency):");
        $display("   - BICS-BIST : %5d Cycles", bics_cycles);
        $display("   - STRAIT    : %5d Cycles", strait_cycles);
        
        if (bics_cycles < strait_cycles)
            $display("   >> RESULT: BICS is FASTER!");
        else
            $display("   >> RESULT: STRAIT is FASTER (Unexpected?)");

        // 2. 기능(에러) 비교
        $display("\n2. Error Status:");
        
        // BICS 결과 확인
        if (bics_final_error == 0)
            $display("   - BICS Status   : PASS");
        else
            $display("   - BICS Status   : FAIL");

        // STRAIT 결과 확인 (수정됨: 내부 신호 직접 참조)
        // dut_strait 내부의 'err_flag' 와이어를 직접 읽어옴 (Hierarchical Reference)
        if (dut_strait.err_flag == 0) 
            $display("   - STRAIT Status : PASS (Internal signal checked)");
        else 
            $display("   - STRAIT Status : FAIL (Internal signal checked)");

        $display("============================================================\n");
        $finish;
    end

endmodule