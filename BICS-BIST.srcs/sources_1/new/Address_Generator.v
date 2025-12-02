`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Address_Generator
* 설명:
* BIST 컨트롤러의 제어 하에 0부터 N-1까지 카운트하는
* 동기식 카운터입니다. 'Accumulator_RAM'의 주소 버스로 사용됩니다.
*
* 파라미터:
* ARRAY_SIZE: Systolic Array의 크기 (예: 16). 카운터의 최대값 (N)
* ADDR_WIDTH: 주소 버스의 비트 폭. $clog2(ARRAY_SIZE)로 자동 계산
*
* 포트:
* clk:       (입력) 시스템 클럭
* rst:       (입력) 동기식 리셋. 1이면 카운터를 0으로 초기화
* en:        (입력) 카운트 인에이블. 1이면 카운트 증가
* addr_out:  (출력) 현재 카운트 값 (RAM 주소) [ADDR_WIDTH-1:0]
*******************************************************************/

module Address_Generator #(
    parameter ARRAY_SIZE = 16,
    // $clog2(N)은 N개의 값을 표현하는데 필요한 비트 수를 계산합니다.
    // 예: $clog2(16) = 4, $clog2(15) = 4
    parameter ADDR_WIDTH = $clog2(ARRAY_SIZE)
) (
    // --- 입력 포트 ---
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    
    // --- 출력 포트 ---
    // reg 타입: always 블록 안에서 값을 할당(저장)하기 위함
    output reg  [ADDR_WIDTH-1:0] addr_out
);

    // --- 동기식 카운터 로직 ---
    always @(posedge clk) begin
        if (rst) begin
            // 리셋 신호가 1이면, 카운터를 0으로 초기화
            addr_out <= 0;
        end 
        else if (en) begin
            // 리셋이 아니고 인에이블이 1이면, 카운트 1 증가
            addr_out <= addr_out + 1;
            
            // 참고:
            // BIST 컨트롤러가 정확히 N번만 'en'을 1로 만들고
            // 카운터가 N-1을 넘어 N이 되더라도(예: 4'b1111 -> 5'b10000),
            // ADDR_WIDTH (4비트)에 의해 상위 비트는 자동으로 잘려서
            // 4'b0000으로 랩어라운드(wrap-around)됩니다.
            // 따라서 FSM이 제어만 잘 해주면 별도의 max 값 비교 로직이
            // 필요 없이 이 간단한 코드로 충분합니다.
        end
        // en=0이면, 'else' 구문이 없으므로 'addr_out'은
        // Verilog 특성에 따라 이전 값을 그대로 유지(Hold)합니다.
    end

endmodule