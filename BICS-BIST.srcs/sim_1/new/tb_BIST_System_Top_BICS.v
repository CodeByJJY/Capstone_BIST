`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: tb_BIST_System_Top_BICS
* 설명:
* BIST_System_Top_BICS (최상위 DUT)를 검증하는 테스트벤치.
*
* N=4, P=6 (ROM 패턴 5개 + default 1개)로 설정하여 테스트합니다.
* 1. 'All Pass' BIST 실행 (모든 PE 활성화)
* 2. 'BISR' BIST 실행 (PE(0,0) 비활성화)
*
* [수정]: "cannot access memory" 오류를 해결하기 위해
* 2D Unpacked Array (`reg [7:0] tb_array_a [0:3]`) 대신
* 1D Packed Vector (`reg [31:0] tb_flat_array_a`)를 사용하도록
* 테스트벤치 선언 및 로직을 수정합니다.
*******************************************************************/

module tb_BIST_System_Top_BICS;

    // --- 파라미터 ---
    parameter ARRAY_SIZE   = 4;
    parameter NUM_PATTERNS = 6; // ROM (Default 0 + 1~5)
    parameter A_WIDTH      = 8;
    parameter W_WIDTH      = 8;
    parameter P_WIDTH      = 32;
    parameter CLK_PERIOD   = 10;
    
    localparam PE_BUS_SIZE = ARRAY_SIZE * ARRAY_SIZE; // 16

    // --- DUT 입력 (reg) ---
    reg tb_clk;
    reg tb_rst;
    reg tb_start;
    reg [PE_BUS_SIZE-1:0] tb_pe_disable_bus;
    
    // [수정] 기능 경로 입력 (Packed 1D Vector)
    reg signed [(A_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_a;
    reg signed [(W_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_w;
    reg signed [(P_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_in_p;

    // --- DUT 출력 (wire) ---
    wire tb_bist_done;
    wire tb_final_error;
    
    // [수정] 기능 경로 출력 (Packed 1D Vector)
    wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_out_a;
    wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] tb_flat_array_out_w;
    
    integer i;

    // --- DUT 인스턴스화 ---
    BIST_System_Top_BICS #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .NUM_PATTERNS(NUM_PATTERNS),
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) DUT (
        .clk(tb_clk),
        .rst(tb_rst),
        .start(tb_start),
        .bist_done(tb_bist_done),
        .final_error(tb_final_error),
        
        .pe_disable_bus(tb_pe_disable_bus),
        
        // [수정] 1D Packed 포트 연결
        .flat_array_in_a(tb_flat_array_in_a),
        .flat_array_in_w(tb_flat_array_in_w),
        .flat_array_in_p(tb_flat_array_in_p),
        .flat_array_out_a(tb_flat_array_out_a),
        .flat_array_out_w(tb_flat_array_out_w)
    );

    // --- 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 모니터링 ---
    initial begin
        $monitor("Time=%0t | rst=%b | start=%b | done=%b | error=%b",
                 $time, tb_rst, tb_start, tb_bist_done, tb_final_error);
    end

    // --- 테스트 태스크 ---
    
    // 1. 리셋 태스크
    task reset_system;
    begin
        $display("--- 1. 시스템 리셋 시작 ---");
        tb_rst = 1'b1;
        tb_start = 1'b0;
        tb_pe_disable_bus = 0;
        
        // [수정] 기능 포트 초기화 (1D Packed)
        tb_flat_array_in_a = 0;
        tb_flat_array_in_w = 0;
        tb_flat_array_in_p = 0;
        
        repeat(5) @(posedge tb_clk); // 5 클럭 동안 리셋 유지
        tb_rst = 1'b0;
        @(posedge tb_clk);
        
        if (tb_bist_done !== 0 || tb_final_error !== 0) begin
            $error("리셋 실패! done=%b, error=%b", tb_bist_done, tb_final_error);
            $finish;
        end
        $display("--- 1. 시스템 리셋 완료 ---");
    end
    endtask

    // 2. BIST 실행 태스크
    task run_bist;
        input [PE_BUS_SIZE-1:0] disable_bus;
    begin
        tb_start = 1'b0;
        tb_pe_disable_bus = disable_bus;
        
        // [수정] 기능 포트 0으로 설정 (BIST 테스트 중이므로)
        tb_flat_array_in_a = 0;
        tb_flat_array_in_w = 0;
        tb_flat_array_in_p = 0;
        
        @(posedge tb_clk);
        
        // BIST 시작 (1 클럭 펄스)
        tb_start = 1'b1;
        @(posedge tb_clk);
        tb_start = 1'b0;
        
        // BIST 완료(bist_done=1) 신호를 기다림
        // FSM 사이클: P * (LOAD(1) + CAPTURE(1) + SHIFT(N)) + IDLE/DONE
        // (6 * (1 + 1 + 4)) = 36 클럭 + @
        wait (tb_bist_done == 1'b1);
        
        $display("... BIST 사이클 완료 (done=1) at Time=%0t", $time);
        
        // FSM이 IDLE로 돌아갈 때까지 대기
        wait (tb_bist_done == 1'b0);
        @(posedge tb_clk);
        $display("... FSM이 IDLE로 복귀 (done=0)");
    end
    endtask


    // --- 6. 테스트 시나리오 ---
    initial begin
        $display("--- BIST_System_Top_BICS (N=%d, P=%d) 테스트 시작 ---", ARRAY_SIZE, NUM_PATTERNS);
        
        // --- 1. 리셋 ---
        reset_system();
        
        // --- 2. BIST 'All Pass' 테스트 ---
        $display("--- 2. BIST 'All Pass' 테스트 시작 ---");
        run_bist(0); // 모든 PE 활성화 (disable_bus = 0)
        
        if (tb_final_error !== 1'b0) begin
            $error("테스트 2 (All Pass) 실패! final_error=1 (예상 0)");
            $finish;
        end
        $display("--- 2. BIST 'All Pass' 테스트 통과 ---");
        
        @(posedge tb_clk);

        // --- 3. BIST 'BISR' 테스트 ---
        $display("--- 3. BIST 'BISR' (PE(0,0) Disable) 테스트 시작 ---");
        run_bist(1); // PE(0,0) 비활성화 (disable_bus[0] = 1)
        
        if (tb_final_error !== 1'b0) begin
            $error("테스트 3 (BISR) 실패! final_error=1 (예상 0)");
            $finish;
        end
        $display("--- 3. BIST 'BISR' 테스트 통과 ---");


        $display("--- 모든 BIST_System_Top_BICS 테스트 통과 ---");
        $finish;
    end

endmodule