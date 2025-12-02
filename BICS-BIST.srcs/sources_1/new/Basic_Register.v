`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Basic_Register
* 설명:
* A/W/P/E 레지스터로 사용될 파라미터화된 D-타입 플립플롭 (SDFF).
* Active-High 동기식 리셋(rst)과 Active-High 인에이블(en)을 지원합니다.
*
* 파라미터:
* DATA_WIDTH: 레지스터의 비트 폭 (기본값: 32)
*
* 포트:
* clk: 클럭
* rst: 동기식 리셋 (Active High)
* en:  인에이블 (Active High)
* d:   데이터 입력 [DATA_WIDTH-1:0]
* q:   데이터 출력 [DATA_WIDTH-1:0]
*******************************************************************/

module Basic_Register #(
    parameter DATA_WIDTH = 32   // 기본 비트 폭을 32로 설정
) (
    // --- 입력 포트 ---
    input wire clk,                 // 클럭
    input wire rst,                 // 동기식 리셋 (Active High)
    input wire en,                  // 인에이블 (Active High)
    input wire [DATA_WIDTH-1:0] d,  // 데이터 입력
    
    // --- 출력 포트 ---
    output reg [DATA_WIDTH-1:0] q   // 데이터 출력
);

    // 동기식 로직: 클럭의 Positive Edge에서만 동작
    always @(posedge clk) begin
        if (rst) begin
            // 우선순위 1: 리셋 신호가 1이면, 'q'를 0으로 초기화
            // {DATA_WIDTH{1'b0}}는 DATA_WIDTH 만큼 0을 반복 (예: 32'b00...0)
            q <= {DATA_WIDTH{1'b0}};
        end else if (en) begin
            // 우선순위 2: 리셋이 0이고 인에이블이 1이면, 'd' 값을 'q'에 저장
            q <= d;
        end
        // (rst=0 이고 en=0 이면, q는 기존 값을 유지 (암시적 Latch))
    end

endmodule
