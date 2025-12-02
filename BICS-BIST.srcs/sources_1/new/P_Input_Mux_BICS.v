`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: P_Input_Mux_BICS
* 설명:
* BICS-BIST 아키텍처의 P (Partial Sum) 레지스터 입력단을 제어하는
* 4-to-1 우선순위 MUX입니다.
* 4가지 모드(Scan, Capture, Bypass, Normal)를 제어합니다.
*
* 파라미터:
* P_WIDTH: P (Partial Sum) 레지스터의 비트 폭
*
* 포트:
* (데이터 입력)
* actual_result:   (입력) MAC 유닛의 실제 연산 결과 (Normal 모드용)
* scan_in_p:       (입력) 위쪽 PE의 P 레지스터 출력 (Scan/Bypass 모드용)
* fail_flag:       (입력) 1비트 Fail Flag (Capture 모드용)
*
* (제어 신호 입력)
* scan_en:         (입력) 1순위: Scan Mode 활성화
* bist_capture_en: (입력) 2순위: Flag Capture Mode 활성화
* pe_disable:      (입력) 3순위: PE Bypass Mode 활성화
*
* (데이터 출력)
* p_reg_in:        (출력) P 레지스터의 D 입력으로 연결될 최종 신호
*******************************************************************/

module P_Input_Mux_BICS #(
    parameter P_WIDTH = 32
) (
    // --- 데이터 입력 ---
    input wire [P_WIDTH-1:0] actual_result,
    input wire [P_WIDTH-1:0] scan_in_p,
    input wire                 fail_flag,
    
    // --- 제어 신호 입력 ---
    input wire                 scan_en,
    input wire                 bist_capture_en,
    input wire                 pe_disable,
    
    // --- 데이터 출력 ---
    output reg [P_WIDTH-1:0] p_reg_in
);

    // --- 1비트 'fail_flag'를 P_WIDTH 비트로 변환 ---
    // 1 (Fail) -> 32'h0000_0001
    // 0 (Pass) -> 32'h0000_0000
    // LSB에 플래그를 위치시키고 나머지는 0으로 채웁니다.
    wire [P_WIDTH-1:0] flag_capture_data;
    assign flag_capture_data = { {(P_WIDTH-1){1'b0}}, fail_flag };

    
    // --- 4-to-1 우선순위 MUX 로직 (조합 논리) ---
    // if-else if-else 구문이 우선순위를 결정합니다.
    always @* begin
        if (scan_en) begin
            // --- 1순위: Scan Mode ---
            // BIST 컨트롤러가 직렬 스캔을 할 때 사용합니다.
            // (STRAIT 원본 기능, BICS 플래그 시프트아웃)
            p_reg_in = scan_in_p;

        end else if (bist_capture_en) begin
            // --- 2순위: BICS Flag Capture Mode ---
            // BIST 캡처 시점에 1비트 Fail Flag를 P 레지스터 LSB에 저장합니다.
            // (BICS 신규 기능)
            p_reg_in = flag_capture_data;

        end else if (pe_disable) begin
            // --- 3순위: PE Bypass Mode ---
            // 고장 진단 후 PE를 영구적으로 Bypass 시킬 때 사용합니다.
            // (STRAIT 고장 수리 기능)
            p_reg_in = scan_in_p;

        end else begin
            // --- 4순위 (기본값): Normal Mode ---
            // 모든 제어 신호가 0일 때, 일반적인 Systolic Array 연산을 수행합니다.
            p_reg_in = actual_result;
        end
    end

endmodule