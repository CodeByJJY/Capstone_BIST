`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 15:21:37
// Design Name: 
// Module Name: tb_Basic_Register
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

module tb_Basic_Register;

    // --- 파라미터 선언 ---
    parameter CLK_PERIOD = 10;          // 클럭 주기 (10ns = 100MHz)
    parameter TEST_WIDTH = 32;          // 테스트할 레지스터의 비트 폭

    // --- 신호 선언 (reg: TB -> DUT, wire: DUT -> TB) ---
    reg                         clk;
    reg                         rst;
    reg                         en;
    reg  [TEST_WIDTH-1:0]       d;
    wire [TEST_WIDTH-1:0]       q;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Basic_Register #(
        .DATA_WIDTH(TEST_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q)
    );


    // --- 1. 클럭 생성 ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end


    // --- 2. 모니터링 ---
    initial begin
        $monitor("Time=%0t | rst=%b | en=%b | d=0x%h | q=0x%h", 
                 $time, rst, en, d, q);
    end


    // --- 3. 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Test Begin ---");
        
        // 1. 초기화: 모든 신호를 0으로 설정
        rst = 0;
        en  = 0;
        d   = 0;
        #(CLK_PERIOD);

        // 2. 테스트: 동기식 리셋 (rst = 1)
        $display("--- Test 1: Synchronized Reset ---");
        rst = 1;
        en  = 1;
        d   = {TEST_WIDTH{1'hA}}; // 'd'에 임의의 값(A)을 주입
        #(CLK_PERIOD); // posedge clk
        
        // [수정] assert...else 문을 if...$error 문으로 변경 (Verilog-2001 호환)
        if (q !== 0) begin
            $error("Reset failed! q is not 0");
            $finish;
        end
        
        rst = 0; // 리셋 해제
        #(CLK_PERIOD); // 안정화 대기

        // 3. 테스트: 인에이블 (en = 1, 데이터 로드)
        $display("--- Test 2: enable (Data load) ---");
        en = 1;
        d  = 32'hDEADBEEF;
        #(CLK_PERIOD); // posedge clk
        
        // [수정] assert...else 문을 if...$error 문으로 변경
        if (q !== 32'hDEADBEEF) begin
            $error("Data load failed!");
            $finish;
        end

        d  = 32'hCAFECAFE;
        #(CLK_PERIOD); // posedge clk
        
        // [수정] assert...else 문을 if...$error 문으로 변경
        if (q !== 32'hCAFECAFE) begin
            $error("Second Data load failed!");
            $finish;
        end

        // 4. 테스트: 홀드 (en = 0, 데이터 유지)
        $display("--- Test 3: Hold (Data remain) ---");
        en = 0; // 인에이블 비활성화
        d  = 32'hFFFFFFFF; // 'd' 값을 바꿔도...
        #(CLK_PERIOD); // posedge clk
        
        // [수정] assert...else 문을 if...$error 문으로 변경
        if (q !== 32'hCAFECAFE) begin
            $error("Data hold failed!");
            $finish;
        end

        #(CLK_PERIOD); // 한 클럭 더 대기
        
        // [수정] assert...else 문을 if...$error 문으로 변경
        if (q !== 32'hCAFECAFE) begin
            $error("Data hold failed (2nd)!");
            $finish;
        end

        // 5. 테스트: 재-인에이블 (en = 1)
        $display("--- Test 4: Re-enable ---");
        en = 1; // 인에이블 다시 활성화
        // d는 여전히 0xFFFFFFFF
        #(CLK_PERIOD); // posedge clk
        
        // [수정] assert...else 문을 if...$error 문으로 변경
        if (q !== 32'hFFFFFFFF) begin
            $error("Re-enable failed!");
            $finish;
        end

        // 6. 시뮬레이션 종료
        $display("--- Every Test Success! ---");
        $finish;
    end

endmodule