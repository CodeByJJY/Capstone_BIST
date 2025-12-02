`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Main_Comparator_BICS
* 설명:
* BICS-BIST의 최종 에러를 판별하는 "Sticky Bit" 비교기입니다.
* BIST 컨트롤러의 'scan_en'이 활성화된 동안,
* 'scan_out_data' 스트림에서 0이 아닌 값(Fail Flag)이
* 단 한 번이라도 감지되면, 'final_error'를 1로 래치(Latch)합니다.
*
* 이 모듈은 Accumulator_RAM이 필요 없습니다.
*
* 파라미터:
* DATA_WIDTH: scan_out 데이터의 비트 폭 (P_WIDTH)
*
* 포트:
* clk:           (입력) 시스템 클럭
* rst:           (입력) 동기식 리셋 (Active High)
* scan_en:       (입력) BIST 컨트롤러의 'scan_en' 신호 (S_SHIFT 상태)
* scan_out_data: (입력) Systolic Array의 'scan_out_p' 포트에서
* 직접 오는 1비트 fail_flag 스트림
* final_error:   (출력) 최종 에러 신호 (1 = Fail, 0 = Pass)
*******************************************************************/

module Main_Comparator_BICS #(
    parameter DATA_WIDTH = 32
) (
    // --- 입력 포트 ---
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  scan_en,
    input  wire [DATA_WIDTH-1:0] scan_out_data,
    
    // --- 출력 포트 ---
    output reg                   final_error
);

    // --- "Sticky Bit Latch" 로직 ---
    // final_error는 한 번 1이 되면, rst가 1이 되기 전까지 0으로
    // 돌아가지 않습니다.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 1. 리셋: 에러 플래그를 0으로 초기화
            final_error <= 1'b0;
            
        end else if (scan_en && (scan_out_data != 0)) begin
            // 2. 에러 감지:
            // S_SHIFT 상태(scan_en=1)이고,
            // PE에서 0이 아닌 값(fail_flag=1)이 감지되면,
            // final_error를 1로 세움.
            final_error <= 1'b1;
            
        end
        // 3. 유지:
        // (else 절이 없으므로)
        // 위 두 조건이 아니면, 'final_error'는 기존 값을 유지합니다.
        // (즉, final_error <= final_error;)
    end

endmodule