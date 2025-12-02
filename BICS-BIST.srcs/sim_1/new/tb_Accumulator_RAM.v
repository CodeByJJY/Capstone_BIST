/*******************************************************************
* 모듈명: tb_Accumulator_RAM
* 설명: Accumulator_RAM.v 모듈의 동기식 쓰기, 비동기식 읽기,
* 데이터 보존 기능을 검증합니다. (레이스 컨디션 수정)
*******************************************************************/

`timescale 1ns / 1ps

module tb_Accumulator_RAM;

    // --- 파라미터 선언 ---
    parameter DATA_WIDTH = 32;
    parameter ARRAY_SIZE = 16;
    parameter ADDR_WIDTH = $clog2(ARRAY_SIZE); // 4-bit
    parameter CLK_PERIOD = 10;                 // 클럭 주기 (10ns)

    // --- 신호 선언 ---
    reg  tb_clk;
    
    // 쓰기 포트
    reg  tb_wr_en;
    reg  [ADDR_WIDTH-1:0] tb_wr_addr;
    reg  [DATA_WIDTH-1:0] tb_din;
    
    // 읽기 포트
    reg  [ADDR_WIDTH-1:0] tb_rd_addr;
    wire [DATA_WIDTH-1:0] tb_dout;

    // 검증용 내부 변수
    integer i;
    reg [DATA_WIDTH-1:0] expected_data;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Accumulator_RAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE)
    ) DUT (
        .clk(tb_clk),
        .wr_en(tb_wr_en),
        .wr_addr(tb_wr_addr),
        .din(tb_din),
        .rd_addr(tb_rd_addr),
        .dout(tb_dout)
    );

    // --- 1. 클럭 생성 ---
    initial begin
        tb_clk = 0;
        forever #(CLK_PERIOD / 2) tb_clk = ~tb_clk;
    end

    // --- 2. 모니터링 ---
    initial begin
        $monitor("Time=%0t | wr_en=%b, wr_addr=%d, din=0x%h | rd_addr=%d, dout=0x%h",
                 $time, tb_wr_en, tb_wr_addr, tb_din, tb_rd_addr, tb_dout);
    end

    // --- 3. 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Accumulator_RAM 테스트 시작 ---");
        
        // --- 테스트 1: 0~15번지에 데이터 쓰기 (동기식) ---
        $display("--- 테스트 1: 0~15번지에 순차 쓰기 ---");
        tb_wr_en = 1;
        tb_rd_addr = 0; // 읽기 주소는 일단 0으로 고정
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            // (i + 0xCAFE0000) 형태의 예측 가능한 데이터 주입
            tb_din = i + 32'hCAFE0000;
            tb_wr_addr = i;
            
            // [수정된 부분]
            // posedge에서 쓰기가 발생하므로, negedge에서 입력을 설정해야
            // 레이스 컨디션을 피할 수 있습니다.
            @(negedge tb_clk); 
        end
        
        // 마지막 쓰기(i=15)가 posedge에서 처리될 시간을 줌
        @(posedge tb_clk); 
        
        tb_wr_en = 0; // 쓰기 비활성화
        @(posedge tb_clk);

        // --- 테스트 2: 0~15번지 데이터 읽기 (비동기식) ---
        $display("--- 테스트 2: 0~15번지 순차 읽기 ---");
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            tb_rd_addr = i;
            expected_data = i + 32'hCAFE0000;
            
            #1; // 비동기식 읽기 딜레이 (조합 논리 전파 시간)
            
            if (tb_dout !== expected_data) begin
                $error("읽기 실패! 주소 %d: dout=0x%h (예상: 0x%h)",
                       i, tb_dout, expected_data);
                $finish;
            end
        end
        
        // --- 테스트 3: 쓰기 비활성화(wr_en=0) 검증 ---
        $display("--- 테스트 3: 쓰기 비활성화(wr_en=0) 검증 ---");
        tb_wr_en = 0;
        tb_wr_addr = 5; // 5번지
        tb_din = 32'hDEADBEEF; // 덮어쓸 데이터
        
        // [수정된 부분] negedge에서 입력 설정
        @(negedge tb_clk); 
        
        // posedge에서 쓰기 시도 (wr_en=0이므로 안되어야 함)
        @(posedge tb_clk); 
        
        tb_rd_addr = 5; // 5번지 읽기
        expected_data = 5 + 32'hCAFE0000; // 이전에 썼던 값
        
        #1; // 비동기식 읽기 딜레이
        
        if (tb_dout !== expected_data) begin
            $error("쓰기 비활성화 실패! 5번지 값이 덮어써짐: dout=0x%h (예상: 0x%h)",
                   tb_dout, expected_data);
            $finish;
        end
        $display("... 5번지 값(0x%h)이 0xDEADBEEF로 덮어써지지 않음 (정상)", tb_dout);

        $display("--- 모든 Accumulator_RAM 테스트 통과 ---");
        $finish;
    end

endmodule