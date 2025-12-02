`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Test_Pattern_ROM
* 설명:
* BIST 컨트롤러에 'TP_A', 'TP_W', 'TP_P' (MAC 입력)와
* 'Expected_Result_P' (사전 계산된 정답)를 제공하는 ROM입니다.
* 비동기식 읽기(조합 논리)로 동작합니다.
*
* 파라미터:
* NUM_PATTERNS: 저장할 총 테스트 패턴의 수 (기본값: 16)
* ADDR_WIDTH:   패턴 주소 비트 폭 ($clog2(NUM_PATTERNS))
* A_WIDTH:      Activation 비트 폭
* W_WIDTH:      Weight 비트 폭
* P_WIDTH:      Partial Sum 비트 폭
*******************************************************************/

module Test_Pattern_ROM #(
    parameter NUM_PATTERNS = 16,
    parameter ADDR_WIDTH   = $clog2(NUM_PATTERNS), // 16 -> 4-bit
    parameter A_WIDTH      = 8,
    parameter W_WIDTH      = 8,
    parameter P_WIDTH      = 32
) (
    // --- 입력 포트 ---
    input  wire [ADDR_WIDTH-1:0] addr, // BIST 컨트롤러가 주는 패턴 주소
    
    // --- 출력 포트 (reg: always @* 블록에서 할당) ---
    // MAC 유닛의 3개 입력
    output reg signed [A_WIDTH-1:0] out_tp_a,
    output reg signed [W_WIDTH-1:0] out_tp_w,
    output reg signed [P_WIDTH-1:0] out_tp_p,
    
    // MAC 유닛의 1개 황금 정답
    output reg signed [P_WIDTH-1:0] out_expected_p 
);

    // --- 조합 논리 (Asynchronous Read ROM) ---
    always @* begin
        // addr 값에 따라 하드코딩된 패턴을 출력
        case (addr)
            
            // 패턴 1: (5 * 10) + 100 = 150
            4'd1: begin
                out_tp_a       = 8'sd5;   // 5
                out_tp_w       = 8'sd10;  // 10
                out_tp_p       = 32'sd100; // 100
                out_expected_p = 32'sd150; // (5*10)+100 = 150
            end

            // 패턴 2: (-5 * 10) + 100 = 50
            4'd2: begin
                out_tp_a       = -8'sd5;  // -5
                out_tp_w       = 8'sd10;  // 10
                out_tp_p       = 32'sd100; // 100
                out_expected_p = 32'sd50;  // (-5*10)+100 = 50
            end

            // 패턴 3: (-5 * -10) + 100 = 150
            4'd3: begin
                out_tp_a       = -8'sd5;  // -5
                out_tp_w       = -8'sd10; // -10
                out_tp_p       = 32'sd100; // 100
                out_expected_p = 32'sd150; // (-5*-10)+100 = 150
            end

            // 패턴 4: (5 * 10) + (-200) = -150
            4'd4: begin
                out_tp_a       = 8'sd5;   // 5
                out_tp_w       = 8'sd10;  // 10
                out_tp_p       = -32'sd200; // -200
                out_expected_p = -32'sd150; // (5*10)-200 = -150
            end
            
            // 패턴 5: (120 * 0) + (-50) = -50
            4'd5: begin
                out_tp_a       = 8'sd120; // 120
                out_tp_w       = 8'sd0;   // 0
                out_tp_p       = -32'sd50; // -50
                out_expected_p = -32'sd50; // (120*0)-50 = -50
            end

            // 기본값 (주소 0 및 기타)
            default: begin
                out_tp_a       = 8'sd0;
                out_tp_w       = 8'sd0;
                out_tp_p       = 32'sd0;
                out_expected_p = 32'sd0;
            end
            
        endcase
    end

endmodule