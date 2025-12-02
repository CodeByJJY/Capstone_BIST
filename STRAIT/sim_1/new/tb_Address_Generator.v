`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 16:00:37
// Design Name: 
// Module Name: tb_Address_Generator
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

module tb_Address_Generator;

    // --- 파라미터 선언 ---
    parameter ARRAY_SIZE = 16;
    parameter ADDR_WIDTH = $clog2(ARRAY_SIZE); // 4-bit
    parameter CLK_PERIOD = 10;                 // 클럭 주기 (10ns)

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  tb_clk;
    reg  tb_rst;
    reg  tb_en;
    wire [ADDR_WIDTH-1:0] tb_addr_out;
    
    // 검증용 내부 변수
    integer i;
    reg  [ADDR_WIDTH-1:0] expected_addr;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Address_Generator #(
        .ARRAY_SIZE(ARRAY_SIZE)
        // .ADDR_WIDTH(ADDR_WIDTH) // 파라미터가 자동으로 계산되므로 생략 가능
    ) DUT (
        .clk(tb_clk),
        .rst(tb_rst),
        .en(tb_en),
        .addr_out(tb_addr_out)
    );

    // --- 1. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 2. 모니터링 ---
    // 클럭 상승 엣지마다 신호 값들을 10진수로 출력
    always @(posedge tb_clk) begin
        $display("Time=%0t | rst: %b | en: %b | addr_out: %d",
                 $time, tb_rst, tb_en, tb_addr_out);
    end

    // --- 3. 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Address_Generator Test Start ---");
        
        // --- 테스트 1: 동기식 리셋 (Synchronous Reset) ---
        $display("--- Test 1: Synchronizd Reset ---");
        tb_rst = 1; // 리셋 활성화
        tb_en  = 0; // 인에이블 비활성화
        @(posedge tb_clk); // 클럭 1
        @(posedge tb_clk); // 클럭 2
        
        if (tb_addr_out !== 0) begin
            $error("Reset failed! addr_out = %d (Expected: 0)", tb_addr_out); $finish;
        end
        
        // --- 테스트 2: 리셋 해제 (Hold 상태) ---
        $display("--- Test 2: Reset Release (en=0) ---");
        tb_rst = 0; // 리셋 비활성화
        tb_en  = 0; // 인에이블 비활성화
        @(posedge tb_clk); // 클럭 3
        
        if (tb_addr_out !== 0) begin
            $error("Hold failed after Reset released! addr_out = %d (Expected: 0)", tb_addr_out); $finish;
        end

        // --- 테스트 3: 카운트 증가 및 랩어라운드 (Wrap-around) ---
        $display("--- Test 3: Count increase (0 -> 15 -> 0) ---");
        tb_en = 1; // 인에이블 활성화
        
        // 0부터 16까지 총 17번 카운트 (0~15, 그리고 0으로 랩어라운드)
        for (i = 0; i < ARRAY_SIZE + 1; i = i + 1) begin
            // 예상 값 계산 (0, 1, ... 15, 0)
            expected_addr = (i + 1) % ARRAY_SIZE;
            
            @(posedge tb_clk);
            
            if (tb_addr_out !== expected_addr) begin
                $error("Count failed! addr_out = %d (Expected: %d)", tb_addr_out, expected_addr);
                $finish;
            end
        end
        // 현재 tb_addr_out = 1 (17번째 카운트 결과)

        // --- 테스트 4: 카운트 홀드 (Hold) ---
        $display("--- Test 4: Count Hold (en=0) ---");
        tb_en = 0; // 인에이블 비활성화
        expected_addr = tb_addr_out; // 현재 값 (1)을 저장
        
        @(posedge tb_clk);
        @(posedge tb_clk);
        
        if (tb_addr_out !== expected_addr) begin
            $error("Hold failed! addr_out = %d (Expected: %d)", tb_addr_out, expected_addr);
            $finish;
        end

        // --- 테스트 5: 카운트 중 리셋 ---
        $display("--- Test 5: Reset during Count ---");
        tb_en = 1; // 인에이블 활성화
        @(posedge tb_clk); // addr_out = 2
        @(posedge tb_clk); // addr_out = 3
        
        tb_rst = 1; // 리셋 활성화
        @(posedge tb_clk); // 리셋 신호가 인가됨 (동기식)
        
        if (tb_addr_out !== 0) begin
            $error("Reset during Count failed! addr_out = %d (Expected: 0)", tb_addr_out);
            $finish;
        end

        $display("--- Every Address_Generator Test Succeed! ---");
        $finish;
    end

endmodule