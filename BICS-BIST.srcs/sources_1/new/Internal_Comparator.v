`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Internal_Comparator
* 설명:
* PE 내부에서 MAC 유닛의 실제 결과(actual_result)와
* TPG가 브로드캐스트한 예상 결과(expected_result)를 비교합니다.
* 'signed' (부호 있는) 값으로 비교하며, 불일치 시 'fail_flag'를 1로
* 출력하는 순수 조합 논리(Combinational) 회로입니다.
*
* 파라미터:
* P_WIDTH: 비교할 데이터의 비트 폭 (Partial Sum 비트 폭)
*
* 포트:
* actual_result:   (입력) MAC 유닛의 실제 연산 결과
* expected_result: (입력) Test_Pattern_ROM이 제공한 예상 결과
* fail_flag:       (출력) 비교 결과 (1: Fail / 0: Pass)
*******************************************************************/

module Internal_Comparator #(
    parameter P_WIDTH = 32
) (
    // --- 입력 포트 ---
    // 'signed'로 선언하여 부호 있는 값으로 비교
    input wire signed [P_WIDTH-1:0] actual_result,
    input wire signed [P_WIDTH-1:0] expected_result,
    
    // --- 출력 포트 ---
    output wire                 fail_flag
);

    // --- 조합 논리 (Combinational Logic) ---
    
    // 두 'signed' 입력이 다르면 1 (Fail)을, 같으면 0 (Pass)을 출력
    assign fail_flag = (actual_result != expected_result);

endmodule
