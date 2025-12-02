`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: PE_Top_BICS
* 설명:
* BICS-BIST 아키텍처가 적용된 Processing Element (PE)의
* 최상위 모듈입니다.
*
* [수정 1]: 176라인 P_Reg_inst의 파라미터 이름을 .P_WIDTH에서
* .DATA_WIDTH로 수정 (Vivado VRFC 10-2861 오류 수정)
*
* [수정 2]: A-Path Bypass MUX 로직 수정 (BISR 버그)
* 'e_reg_q' (disable)가 'parallel_load_en' (S_LOAD)보다
* 높은 우선순위를 가져 A-reg에 0이 로드되는 버그를 수정합니다.
*******************************************************************/

module PE_Top_BICS #(
    // --- 데이터 비트 폭 파라미터 ---
    parameter A_WIDTH = 8,
    parameter W_WIDTH = 8,
    parameter P_WIDTH = 32
) (
    // (포트 선언은 이전과 동일...)
    // --- 1. 글로벌 신호 (BIST 컨트롤러 및 시스템) ---
    input wire clk,
    input wire rst,

    // --- 2. BIST 제어 신호 (BIST Controller -> PE) ---
    input wire parallel_load_en,  // (신규) BICS 병렬 로드 신호
    input wire bist_capture_en,  // (신규) BICS 캡처 신호
    input wire scan_en,          // (공통) 직렬 스캔 인에이블
    
    // --- 3. BIST 데이터 신호 (Test_Pattern_ROM -> PE) ---
    input wire signed [A_WIDTH-1:0] in_tp_a,
    input wire signed [W_WIDTH-1:0] in_tp_w,
    input wire signed [P_WIDTH-1:0] in_tp_p,       // [버그 수정] 포트 추가
    input wire signed [P_WIDTH-1:0] in_expected_p,

    // --- 4. BISR (고장 수리) 신호 (eNVM -> PE) ---
    input wire pe_disable,       // (공통) E 레지스터에 저장될 신호

    // --- 5. 이웃 PE 입력 (기능/스캔 경로) ---
    input wire signed [A_WIDTH-1:0] scan_in_a, // From Left PE
    input wire signed [W_WIDTH-1:0] scan_in_w, // From Top PE
    input wire signed [P_WIDTH-1:0] scan_in_p, // From Top PE
    
    // --- 6. 이웃 PE 출력 (기능/스캔 경로) ---
    output wire signed [A_WIDTH-1:0] scan_out_a, // To Right PE
    output wire signed [W_WIDTH-1:0] scan_out_w, // To Bottom PE
    output wire signed [P_WIDTH-1:0] scan_out_p  // To Bottom PE
);

    // --- 내부 와이어 (모듈 간 연결선) ---
    
    // MUX -> REG 경로
    wire [A_WIDTH-1:0] a_mux_out;
    wire [A_WIDTH-1:0] a_bypass_mux_out;
    wire [W_WIDTH-1:0] w_mux_out;
    wire [P_WIDTH-1:0] p_mux_out;

    // REG -> MAC/Mux 경로
    wire signed [A_WIDTH-1:0] a_reg_q;
    wire signed [W_WIDTH-1:0] w_reg_q;
    wire signed [P_WIDTH-1:0] p_reg_q;
    wire                      e_reg_q; // 1-bit

    // MAC -> Comp/Mux 경로
    wire signed [P_WIDTH-1:0] actual_result;
    
    // Comp -> Mux 경로
    wire                      fail_flag; // 1-bit


    // --- 1. A-Path (Activation) ---
    // 1a. BICS 입력 MUX (Normal vs BICS-Load)
    Input_Mux_BICS #(
        .DATA_WIDTH(A_WIDTH)
    ) A_BICS_Mux_inst (
        .in_functional(scan_in_a),         // 일반 경로
        .in_test(in_tp_a),                 // BICS 테스트 패턴
        .sel_parallel_load(parallel_load_en),
        .mux_out(a_mux_out)
    );
    
    // 1b. [수정 2] A-Path Bypass MUX
    // BIST S_LOAD 상태(!parallel_load_en)가 아닐 때만
    // 'e_reg_q' (disable) 바이패스가 동작하도록 수정
    assign a_bypass_mux_out = (e_reg_q && !parallel_load_en) ? scan_in_a : a_mux_out;

    // 1c. A 레지스터
    Basic_Register #(
        .DATA_WIDTH(A_WIDTH)
    ) A_Reg_inst (
        .clk(clk),
        .rst(rst),
        .en(1'b1), 
        .d(a_bypass_mux_out),
        .q(a_reg_q)
    );
    assign scan_out_a = a_reg_q; // A 레지스터 출력이 오른쪽 PE로

    
    // --- 2. W-Path (Weight) ---
    // 2a. BICS 입력 MUX (Normal vs BICS-Load)
    Input_Mux_BICS #(
        .DATA_WIDTH(W_WIDTH)
    ) W_BICS_Mux_inst (
        .in_functional(scan_in_w),         // 일반 경로
        .in_test(in_tp_w),                 // BICS 테스트 패턴
        .sel_parallel_load(parallel_load_en),
        .mux_out(w_mux_out)
    );

    // 2b. W 레지스터
    // (W-Path는 BISR 바이패스 로직이 없음.
    // 어차피 TPG가 브로드캐스트하므로 불필요)
    Basic_Register #(
        .DATA_WIDTH(W_WIDTH)
    ) W_Reg_inst (
        .clk(clk),
        .rst(rst),
        .en(1'b1), 
        .d(w_mux_out),
        .q(w_reg_q)
    );
    assign scan_out_w = w_reg_q; // W 레지스터 출력이 아래쪽 PE로


    // --- 3. E-Path (PE Disable) ---
    // 3a. E 레지스터 (1-bit)
    Basic_Register #(
        .DATA_WIDTH(1)
    ) E_Reg_inst (
        .clk(clk),
        .rst(rst),
        .en(1'b1), 
        .d(pe_disable),
        .q(e_reg_q)
    );

    // --- 4. P-Path (Partial Sum & BICS Logic) ---
    
    // [버그 수정] BIST 테스트 중 P 입력을 선택하기 위한 MUX
    wire signed [P_WIDTH-1:0] mac_in_p;
    assign mac_in_p = (parallel_load_en | bist_capture_en) ? 
                      in_tp_p : scan_in_p;

    // 4a. MAC 유닛
    MAC_Unit #(
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) MAC_Unit_inst (
        .in_a(a_reg_q),    // A 레지스터 출력
        .in_w(w_reg_q),    // W 레지스터 출력
        .in_p(mac_in_p),   // [버그 수정] MUX 출력 사용
        .actual_result(actual_result)
    );

    // 4b. BICS 내부 비교기
    Internal_Comparator #(
        .P_WIDTH(P_WIDTH)
    ) Internal_Comp_inst (
        .actual_result(actual_result),
        .expected_result(in_expected_p), // TPG의 황금 정답
        .fail_flag(fail_flag)
    );

    // 4c. BICS P-입력 우선순위 MUX
    P_Input_Mux_BICS #(
        .P_WIDTH(P_WIDTH)
    ) P_Input_Mux_inst (
        .actual_result(actual_result),
        .scan_in_p(scan_in_p),
        .fail_flag(fail_flag),
        .scan_en(scan_en),
        .bist_capture_en(bist_capture_en),
        .pe_disable(e_reg_q), 
        .p_reg_in(p_mux_out)
    );

    // 4d. P 레지스터
    // [버그 수정] .P_WIDTH -> .DATA_WIDTH
    Basic_Register #(
        .DATA_WIDTH(P_WIDTH)
    ) P_Reg_inst (
        .clk(clk),
        .rst(rst),
        .en(1'b1), 
        .d(p_mux_out),
        .q(p_reg_q)
    );
    assign scan_out_p = p_reg_q; // P 레지스터 출력이 아래쪽 PE로

endmodule