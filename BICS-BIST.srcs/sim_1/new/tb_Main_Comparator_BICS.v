/*******************************************************************
* 모듈명: tb_Main_Comparator_BICS
* 설명:
* Main_Comparator_BICS.v 모듈의 "Sticky Bit Latch" 기능을 검증합니다.
* 'scan_en'이 1일 때만 0이 아닌 입력을 감지하여 'final_error'를
* 1로 래치(latch)하는지 확인합니다.
*******************************************************************/

`timescale 1ns / 1ps

module tb_Main_Comparator_BICS;

    // --- 파라미터 선언 ---
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    // --- 1. DUT 입력 (reg) ---
    reg  tb_clk;
    reg  tb_rst;
    reg  tb_scan_en;
    reg  [DATA_WIDTH-1:0] tb_scan_out_data;
    
    // --- 2. DUT 출력 (wire) ---
    wire tb_final_error;

    // --- 3. DUT 인스턴스화 ---
    Main_Comparator_BICS #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(tb_clk),
        .rst(tb_rst),
        .scan_en(tb_scan_en),
        .scan_out_data(tb_scan_out_data),
        .final_error(tb_final_error)
    );

    // --- 4. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 5. 모니터링 ---
    initial begin
        $monitor("Time=%0t | rst=%b | scan_en=%b | scan_data=0x%h | FINAL_ERROR=%b",
                 $time, tb_rst, tb_scan_en, tb_scan_out_data, tb_final_error);
    end

    // --- 6. 테스트 시나리오 ---
    initial begin
        $display("--- Main_Comparator_BICS (Sticky Bit) 테스트 시작 ---");
        
        // --- 1. 리셋 ---
        tb_rst = 1;
        tb_scan_en = 0;
        tb_scan_out_data = 0;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 0;
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 0) begin
            $error("리셋 실패! final_error가 0이 아님"); $finish;
        end
        $display("--- 1. 리셋 통과 (final_error=0) ---");

        // --- 2. 스캔 중, 에러 없음 (Pass Stream) ---
        $display("--- 2. 스캔 중, 에러 없음 (scan_en=1, data=0) ---");
        tb_scan_en = 1;
        tb_scan_out_data = 0; // 0 = Pass
        @(posedge tb_clk);
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 0) begin
            $error("테스트 2 실패! (data=0인데 error=1)"); $finish;
        end
        $display("... PASS: final_error=0 유지");

        // --- 3. 스캔 중, 에러 1회 감지 (Fail Flag) ---
        $display("--- 3. 스캔 중, 에러 1회 감지 (scan_en=1, data=1) ---");
        tb_scan_out_data = 1; // 1 = Fail (P_WIDTH가 32라도 != 0)
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 1) begin
            $error("테스트 3 실패! (data=1인데 error=0)"); $finish;
        end
        $display("... PASS: final_error=1 래치됨");

        // --- 4. "Sticky" 기능 검증 (Error=1 유지) ---
        $display("--- 4. 'Sticky' 기능 검증 (data=0)");
        tb_scan_out_data = 0; // data가 0 (Pass)으로 돌아가도
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 1) begin
            $error("테스트 4 실패! (Sticky bit가 0이 됨)"); $finish;
        end
        $display("... PASS: final_error=1 유지됨 (Sticky!)");
        
        // --- 5. 리셋 후 Sticky 해제 ---
        $display("--- 5. 리셋으로 Sticky 해제 ---");
        tb_rst = 1;
        @(posedge tb_clk);
        tb_rst = 0;
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 0) begin
            $error("테스트 5 실패! (리셋 후 0이 안됨)"); $finish;
        end
        $display("... PASS: final_error=0 리셋됨");

        // --- 6. 스캔 비활성화 시, 에러 무시 검증 ---
        $display("--- 6. 스캔 비활성화 시, 에러 무시 (scan_en=0) ---");
        tb_scan_en = 0; // scan_en=0
        tb_scan_out_data = 1; // 에러가 발생해도
        @(posedge tb_clk);
        #1;
        if (tb_final_error !== 0) begin
            $error("테스트 6 실패! (scan_en=0인데 에러 래치됨)"); $finish;
        end
        $display("... PASS: final_error=0 유지 (에러 무시)");

        $display("--- 모든 Main_Comparator_BICS 테스트 통과 ---");
        $finish;
    end

endmodule