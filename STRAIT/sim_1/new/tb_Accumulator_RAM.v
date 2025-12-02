`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 15:39:36
// Design Name: 
// Module Name: tb_Accumulator_RAM
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
        $display("--- Accumulator_RAM Test Start ---");
        
        // --- 테스트 1: 0~15번지에 데이터 쓰기 (동기식) ---
        $display("--- Test 1: Sequential Writing in Address 0~15 ---");
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
        $display("--- Test 2: Sequential Read from Address 0~15 ---");
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            tb_rd_addr = i;
            expected_data = i + 32'hCAFE0000;
            
            #1; // 비동기식 읽기 딜레이 (조합 논리 전파 시간)
            
            if (tb_dout !== expected_data) begin
                $error("Read failed! Address %d: dout=0x%h (Expected: 0x%h)",
                       i, tb_dout, expected_data);
                $finish;
            end
        end
        
        // --- 테스트 3: 쓰기 비활성화(wr_en=0) 검증 ---
        $display("--- Test 3: Write Not Enable (wr_en=0) ---");
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
            $error("Write Not Enable Failed! The value of Address 5 is overwritten: dout=0x%h (Expected: 0x%h)",
                   tb_dout, expected_data);
            $finish;
        end
        $display("... Value in Address 5(0x%h) is not overwritten (Correct!)", tb_dout);

        $display("--- Every Accumulator_RAM Test Success! ---");
        $finish;
    end

endmodule