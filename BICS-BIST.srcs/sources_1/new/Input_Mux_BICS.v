`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Input_Mux_BICS
* 설명:
* BICS-BIST의 'Broadcast-Input'을 위한 2-to-1 MUX입니다.
* 'sel_parallel_load' 신호에 따라 'in_functional' (일반 경로) 또는
* 'in_test' (TPG 브로드캐스트 패턴) 중 하나를 선택합니다.
*
* PE_Top_BICS 모듈에서 A 레지스터와 W 레지스터 입력단에
* 각각 인스턴스화되어 재사용됩니다.
*
* 파라미터:
* DATA_WIDTH: A 또는 W 레지스터의 비트 폭 (예: 8)
*
* 포트:
* in_functional:     (입력) 일반 기능 경로의 데이터 (예: scan_in_a)
* in_test:           (입력) TPG 브로드캐스트 테스트 패턴 (예: TP_A)
* sel_parallel_load: (입력) BIST 컨트롤러의 'parallel_load_en' 신호
* mux_out:           (출력) 선택된 데이터 (A 또는 W 레지스터의 D 입력)
*******************************************************************/

module Input_Mux_BICS #(
    parameter DATA_WIDTH = 8
) (
    // --- 입력 포트 ---
    input wire [DATA_WIDTH-1:0] in_functional,
    input wire [DATA_WIDTH-1:0] in_test,
    input wire                  sel_parallel_load,
    
    // --- 출력 포트 ---
    output wire [DATA_WIDTH-1:0] mux_out
);

    // --- 조합 논리 (Combinational Logic) ---
    
    // sel_parallel_load가 1이면 TPG 패턴을, 0이면 일반 경로를 선택
    assign mux_out = (sel_parallel_load == 1'b1) ? in_test : in_functional;

endmodule