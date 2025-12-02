/*******************************************************************
* 모듈명: tb_BIST_Controller_FSM_BICS
* 설명:
* BIST_Controller_FSM_BICS.v 모듈의 FSM 상태 전이와
* 제어 신호 출력 타이밍을 검증합니다.
*
* 검증 파라미터: ARRAY_SIZE=4, NUM_PATTERNS=2
* 예상 흐름 (1-Pattern):
* IDLE -> LOAD(1clk) -> CAPTURE(1clk) -> SHIFT(4clk) -> PAT_INC(1clk)
*
* 총 2개 패턴을 테스트하고 DONE 상태로 진입하는지 확인합니다.
*******************************************************************/

`timescale 1ns / 1ps

module tb_BIST_Controller_FSM_BICS;

    // --- 파라미터 선언 ---
    parameter CLK_PERIOD = 10;
    // 시뮬레이션 시간을 줄이기 위해 파라미터를 작게 설정
    parameter TEST_ARRAY_SIZE   = 4;  // N=4 (S_SHIFT 4클럭)
    parameter TEST_NUM_PATTERNS = 2;  // P=2 (총 2회 반복)

    // --- 1. DUT 입력 (reg) ---
    reg tb_clk;
    reg tb_rst;
    reg tb_start;

    // --- 2. DUT 출력 (wire) ---
    wire tb_bist_done;
    wire tb_parallel_load_en;
    wire tb_bist_capture_en;
    wire tb_scan_en;
    wire tb_rom_addr_en;
    wire tb_rom_addr_rst;
    wire tb_ram_addr_en;
    wire tb_ram_addr_rst;
    wire tb_ram_wr_en;
    
    // FSM 상태 디버깅을 위한 와이어 (DUT 내부 신호)
    // Verilog에서는 `tb_BIST_Controller_FSM_BICS.DUT.current_state` 처럼
    // 계층적 이름으로 접근하여 모니터링/검증에 사용합니다.
    wire [2:0] dut_current_state = DUT.current_state;


    // --- 3. DUT 인스턴스화 ---
    BIST_Controller_FSM_BICS #(
        .ARRAY_SIZE(TEST_ARRAY_SIZE),
        .NUM_PATTERNS(TEST_NUM_PATTERNS)
    ) DUT (
        .clk(tb_clk),
        .rst(tb_rst),
        .start(tb_start),
        .bist_done(tb_bist_done),
        .parallel_load_en(tb_parallel_load_en),
        .bist_capture_en(tb_bist_capture_en),
        .scan_en(tb_scan_en),
        .rom_addr_en(tb_rom_addr_en),
        .rom_addr_rst(tb_rom_addr_rst),
        .ram_addr_en(tb_ram_addr_en),
        .ram_addr_rst(tb_ram_addr_rst),
        .ram_wr_en(tb_ram_wr_en)
    );

    // --- 4. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 5. 모니터링 ---
    initial begin
        $monitor("Time=%0t | rst=%b | start=%b | state=%h | load=%b | capture=%b | scan=%b | rom_en=%b | ram_en=%b | done=%b",
                 $time, tb_rst, tb_start, dut_current_state,
                 tb_parallel_load_en, tb_bist_capture_en, tb_scan_en,
                 tb_rom_addr_en, tb_ram_addr_en, tb_bist_done);
    end

    // --- 6. 테스트 시나리오 ---
    initial begin
        $display("--- BIST_Controller_FSM_BICS 테스트 시작 (N=%d, P=%d) ---",
                 TEST_ARRAY_SIZE, TEST_NUM_PATTERNS);
        
        // --- 1. 리셋 ---
        tb_start = 0;
        tb_rst = 1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 0;
        @(posedge tb_clk);
        #1;
        if (dut_current_state !== DUT.S_IDLE) begin
            $error("리셋 실패! FSM이 S_IDLE이 아님 (state=%h)", dut_current_state); $finish;
        end
        $display("--- 테스트 1: 리셋 통과 (S_IDLE) ---");

        // --- 2. BIST 시작 ---
        tb_start = 1;
        @(posedge tb_clk);
        #1;
        if (dut_current_state !== DUT.S_LOAD) begin
            $error("BIST 시작 실패! S_IDLE -> S_LOAD 전이 실패"); $finish;
        end
        $display("--- BIST 시작 -> S_LOAD (Pattern 0) ---");

        // --- 3. 패턴 1 (P=0) 테스트 ---
        // S_LOAD (1 clk)
        if (tb_parallel_load_en !== 1) $error("S_LOAD: parallel_load_en이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_CAPTURE) $error("S_LOAD -> S_CAPTURE 전이 실패");

        // S_CAPTURE (1 clk)
        if (tb_bist_capture_en !== 1) $error("S_CAPTURE: bist_capture_en이 0임");
        if (tb_ram_addr_rst !== 1) $error("S_CAPTURE: ram_addr_rst가 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_SHIFT) $error("S_CAPTURE -> S_SHIFT 전이 실패");

        // S_SHIFT (N=4 clk)
        if (tb_scan_en !== 1 || tb_ram_addr_en !== 1 || tb_ram_wr_en !== 1) $error("S_SHIFT (0): 신호 오류");
        repeat (TEST_ARRAY_SIZE - 1) begin // N-1 클럭 (1, 2, 3)
            @(posedge tb_clk); #1;
            if (dut_current_state !== DUT.S_SHIFT) $error("S_SHIFT 루프 실패 (N=%d)", TEST_ARRAY_SIZE);
        end
        @(posedge tb_clk); #1; // N번째 클럭 (4)
        if (dut_current_state !== DUT.S_PATTERN_INC) $error("S_SHIFT -> S_PATTERN_INC 전이 실패");
        $display("--- Pattern 0: SHIFT (4 clks) 완료 ---");

        // S_PATTERN_INC (1 clk)
        if (tb_rom_addr_en !== 1) $error("S_PATTERN_INC: rom_addr_en이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_LOAD) $error("S_PATTERN_INC -> S_LOAD (다음 패턴) 전이 실패");
        $display("--- S_PATTERN_INC -> S_LOAD (Pattern 1) ---");


        // --- 4. 패턴 2 (P=1) 테스트 (마지막 패턴) ---
        // S_LOAD (1 clk)
        if (tb_parallel_load_en !== 1) $error("S_LOAD (2): parallel_load_en이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_CAPTURE) $error("S_LOAD -> S_CAPTURE 전이 실패 (2)");

        // S_CAPTURE (1 clk)
        if (tb_bist_capture_en !== 1) $error("S_CAPTURE (2): bist_capture_en이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_SHIFT) $error("S_CAPTURE -> S_SHIFT 전이 실패 (2)");

        // S_SHIFT (N=4 clk)
        repeat (TEST_ARRAY_SIZE) begin
            @(posedge tb_clk); #1;
        end
        if (dut_current_state !== DUT.S_PATTERN_INC) $error("S_SHIFT -> S_PATTERN_INC 전이 실패 (2)");
        $display("--- Pattern 1: SHIFT (4 clks) 완료 ---");

        // S_PATTERN_INC (1 clk) - 마지막 패턴이었으므로 S_DONE으로 가야 함
        if (tb_rom_addr_en !== 1) $error("S_PATTERN_INC (2): rom_addr_en이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_DONE) $error("S_PATTERN_INC -> S_DONE 전이 실패 (pattern_done)");
        $display("--- S_PATTERN_INC -> S_DONE (모든 패턴 완료) ---");

        
        // --- 5. BIST 완료 (S_DONE) ---
        if (tb_bist_done !== 1) $error("S_DONE: bist_done이 0임");
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_DONE) $error("S_DONE: start=1일 때 S_DONE 상태 유지 실패");
        
        // start=0으로 내려서 IDLE 복귀 검증
        tb_start = 0;
        @(posedge tb_clk); #1;
        if (dut_current_state !== DUT.S_IDLE) $error("S_DONE -> S_IDLE (start=0) 전이 실패");
        $display("--- S_DONE -> S_IDLE (BIST 종료) ---");

        $display("--- 모든 BIST_Controller_FSM_BICS 테스트 통과 ---");
        $finish;
    end

endmodule