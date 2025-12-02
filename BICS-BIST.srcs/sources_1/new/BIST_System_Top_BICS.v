`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: BIST_System_Top_BICS
* 설명:
* BICS-BIST 아키텍처의 최상위 모듈 (DUT: Design Under Test).
*
* [수정 1]: 'w_tp_p' 와이어를 추가하여 ROM의 P-패턴을
* Systolic Array로 연결합니다. (디자인 버그 수정)
*
* [수정 3]: Vivado [VRFC 10-3642] 에러를 해결하기 위해
* 2D Unpacked Array 포트 (`array_in_a[0:15]`)를
* 1D Packed Vector 포트 (`flat_array_in_a[127:0]`)로 변경합니다.
*******************************************************************/

module BIST_System_Top_BICS #(
    parameter ARRAY_SIZE   = 16,
    parameter NUM_PATTERNS = 16,
    parameter A_WIDTH      = 8,
    parameter W_WIDTH      = 8,
    parameter P_WIDTH      = 32
) (
    // --- 1. 글로벌 입출력 ---
    input  wire clk,
    input  wire rst,
    input  wire start,             // BIST 시작
    output wire bist_done,         // BIST 완료
    output wire final_error,       // BIST 최종 에러 (1=Fail)
    
    // --- 2. [수정 3] Systolic Array 기능 입출력 (Packed 1D Vectors) ---
    input  wire [(ARRAY_SIZE*ARRAY_SIZE)-1:0] pe_disable_bus,
    input  wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_a,
    input  wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_w,
    input  wire signed [(P_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_p,
    output wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] flat_array_out_a,
    output wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] flat_array_out_w
    
    // (BICS는 array_out_p가 final_scan_out_p로 내부 처리됨)
);

    // --- 파라미터 계산 ---
    localparam ROM_ADDR_WIDTH = $clog2(NUM_PATTERNS);

    // --- 내부 와이어 (모듈 간 연결선) ---
    
    // 1. FSM -> All (BIST 제어 신호)
    wire w_parallel_load_en;
    wire w_bist_capture_en;
    wire w_scan_en;
    
    // 2. FSM -> ROM Addr Gen (ROM 제어 신호)
    wire w_rom_addr_en;
    wire w_rom_addr_rst;
    
    // 3. ROM Addr Gen -> ROM (ROM 주소)
    wire [ROM_ADDR_WIDTH-1:0] w_rom_addr;
    
    // 4. ROM -> Array (BIST 테스트 데이터)
    wire signed [A_WIDTH-1:0] w_tp_a;
    wire signed [W_WIDTH-1:0] w_tp_w;
    wire signed [P_WIDTH-1:0] w_tp_p;         // [수정 1]
    wire signed [P_WIDTH-1:0] w_expected_p;
    
    // 5. Array -> Comparator (BIST 결과 스트림)
    wire signed [P_WIDTH-1:0] w_final_scan_out_p;

    // [수정 3] 어댑터 로직(w_flat_... 와이어 및 generate 루프) 제거


    // --- 1. BIST 컨트롤러 FSM (두뇌) ---
    BIST_Controller_FSM_BICS #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .NUM_PATTERNS(NUM_PATTERNS)
    ) FSM_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .bist_done(bist_done), // Top 출력
        
        // PE 제어
        .parallel_load_en(w_parallel_load_en),
        .bist_capture_en(w_bist_capture_en),
        .scan_en(w_scan_en),
        
        // ROM Addr Gen 제어
        .rom_addr_en(w_rom_addr_en),
        .rom_addr_rst(w_rom_addr_rst),
        
        // (RAM 제어 신호는 BICS FSM에서 생성하지만 연결하지 않음)
        .ram_addr_en(),
        .ram_addr_rst(),
        .ram_wr_en()
    );

    // --- 2. ROM 주소 생성기 (카운터) ---
    Address_Generator #(
        .ARRAY_SIZE(NUM_PATTERNS), // ROM 주소는 0~P-1
        .ADDR_WIDTH(ROM_ADDR_WIDTH)
    ) ROM_Addr_Gen_inst (
        .clk(clk),
        .rst(w_rom_addr_rst), // FSM이 리셋 제어
        .en(w_rom_addr_en),   // FSM이 카운트 제어
        .addr_out(w_rom_addr) // ROM의 주소 입력으로
    );

    // --- 3. 테스트 패턴 ROM (패턴/정답 제공) ---
    Test_Pattern_ROM #(
        .NUM_PATTERNS(NUM_PATTERNS),
        .ADDR_WIDTH(ROM_ADDR_WIDTH),
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) ROM_inst (
        .addr(w_rom_addr),
        
        .out_tp_a(w_tp_a),
        .out_tp_w(w_tp_w),
        .out_tp_p(w_tp_p), // [수정 1]
        .out_expected_p(w_expected_p)
    );

    // [수정 3] Flatten/Un-flatten 'generate' 루프 제거

    // --- 4. Systolic Array (N x N PE 배열) ---
    Systolic_Array_Top_BICS #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .A_WIDTH(A_WIDTH),
        .W_WIDTH(W_WIDTH),
        .P_WIDTH(P_WIDTH)
    ) Array_inst (
        .clk(clk),
        .rst(rst),
        
        // BIST 제어
        .parallel_load_en(w_parallel_load_en),
        .bist_capture_en(w_bist_capture_en),
        .scan_en(w_scan_en),
        
        // BIST 데이터
        .in_tp_a(w_tp_a),
        .in_tp_w(w_tp_w),
        .in_tp_p(w_tp_p), // [수정 1]
        .in_expected_p(w_expected_p),
        
        // BISR
        .pe_disable_bus(pe_disable_bus),
        
        // --- [수정 3] 기능 입출력 (Packed 1D 포트 직접 연결) ---
        .flat_array_in_a(flat_array_in_a),
        .flat_array_in_w(flat_array_in_w),
        .flat_array_in_p(flat_array_in_p),
        .flat_array_out_a(flat_array_out_a),
        .flat_array_out_w(flat_array_out_w),
        
        // BIST 결과 (Comparator로)
        .final_scan_out_p(w_final_scan_out_p)
    );

    // [수정 3] Un-flatten 'generate' 루프 제거

    // --- 5. BICS 메인 비교기 (스트리밍 검사) ---
    Main_Comparator_BICS #(
        .DATA_WIDTH(P_WIDTH)
    ) Comp_inst (
        .clk(clk),
        .rst(rst),
        .scan_en(w_scan_en), // FSM의 scan_en 신호와 동기화
        .scan_out_data(w_final_scan_out_p), // Array의 Bitwise-OR 결과
        
        .final_error(final_error) // Top 출력
    );

endmodule