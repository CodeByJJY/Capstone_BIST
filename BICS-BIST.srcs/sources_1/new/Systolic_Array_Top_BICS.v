`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Systolic_Array_Top_BICS
* 설명:
* BICS-BIST 아키텍처가 적용된 N x N Systolic Array입니다.
*
* [수정]: Vivado [VRFC 10-3642] 에러 해결
* 2D 배열 포트(Unpacked Array)를 Verilog-2001 호환을 위해
* 1D 벡터 포트(Packed Array)로 "Flatten(평탄화)"함.
*
* [수정 2]: 'in_tp_p' 포트를 추가하여 PE로 브로드캐스트합니다.
*******************************************************************/

module Systolic_Array_Top_BICS #(
    parameter ARRAY_SIZE = 16,
    parameter A_WIDTH    = 8,
    parameter W_WIDTH    = 8,
    parameter P_WIDTH    = 32
) (
    // --- 1. 글로벌 신호 (BIST Controller) ---
    input wire clk,
    input wire rst,

    // --- 2. BIST 제어 신호 (브로드캐스트) ---
    input wire parallel_load_en,
    input wire bist_capture_en,
    input wire scan_en,
    
    // --- 3. BIST 데이터 신호 (브로드캐스트) ---
    input wire signed [A_WIDTH-1:0] in_tp_a,
    input wire signed [W_WIDTH-1:0] in_tp_w,
    input wire signed [P_WIDTH-1:0] in_expected_p,
    input wire signed [P_WIDTH-1:0] in_tp_p, // [수정] P-패턴 입력 포트

    // --- 4. BISR 신호 (브로드캐스트 버스) ---
    input wire [(ARRAY_SIZE*ARRAY_SIZE)-1:0] pe_disable_bus,

    // --- 5. [수정] 배열 경계 입력 (Flattened 1D Vectors) ---
    input wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_a, // (8*16) = 128-bit
    input wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_w, // (8*16) = 128-bit
    input wire signed [(P_WIDTH*ARRAY_SIZE)-1:0] flat_array_in_p, // (32*16) = 512-bit
    
    // --- 6. [수정] 배열 경계 출력 (Flattened 1D Vectors) ---
    output wire signed [(A_WIDTH*ARRAY_SIZE)-1:0] flat_array_out_a,
    output wire signed [(W_WIDTH*ARRAY_SIZE)-1:0] flat_array_out_w,
    
    // --- 7. BICS-BIST 최종 출력 (Main Comparator로 연결) ---
    output wire signed [P_WIDTH-1:0] final_scan_out_p
);

    // --- 내부 와이어 선언 (PE 연결망) ---
    
    // 2D 와이어 (Generate Loop에서 사용)
    wire signed [A_WIDTH-1:0] a_data [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
    wire signed [W_WIDTH-1:0] w_data [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
    wire signed [P_WIDTH-1:0] p_data [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
    
    // 1D 포트를 2D 와이어로 "Un-flatten" 하기 위한 임시 2D 와이어
    wire signed [A_WIDTH-1:0] array_in_a_unpacked [0:ARRAY_SIZE-1];
    wire signed [W_WIDTH-1:0] array_in_w_unpacked [0:ARRAY_SIZE-1];
    wire signed [P_WIDTH-1:0] array_in_p_unpacked [0:ARRAY_SIZE-1];
    
    wire signed [A_WIDTH-1:0] array_out_a_unpacked [0:ARRAY_SIZE-1];
    wire signed [W_WIDTH-1:0] array_out_w_unpacked [0:ARRAY_SIZE-1];


    // --- [신규] 1D Port -> 2D Wire (Un-flattening) ---
    genvar i_unpack;
    generate
        for (i_unpack = 0; i_unpack < ARRAY_SIZE; i_unpack = i_unpack + 1) begin : unflatten_wires
            // A-path
            assign array_in_a_unpacked[i_unpack] = flat_array_in_a[(i_unpack+1)*A_WIDTH-1 : i_unpack*A_WIDTH];
            // W-path
            assign array_in_w_unpacked[i_unpack] = flat_array_in_w[(i_unpack+1)*W_WIDTH-1 : i_unpack*W_WIDTH];
            // P-path
            assign array_in_p_unpacked[i_unpack] = flat_array_in_p[(i_unpack+1)*P_WIDTH-1 : i_unpack*P_WIDTH];
        end
    endgenerate


    // --- 1. 경계(Boundary) 입력 연결 ---
    genvar i_bound;
    generate
        for (i_bound = 0; i_bound < ARRAY_SIZE; i_bound = i_bound + 1) begin : boundary_wires
            // [수정] Un-flatten된 2D 와이어를 사용
            assign a_data[i_bound][0] = array_in_a_unpacked[i_bound];
            assign w_data[0][i_bound] = array_in_w_unpacked[i_bound];
            assign p_data[0][i_bound] = array_in_p_unpacked[i_bound];
        end
    endgenerate

    // --- 2. N x N PE 배열 생성 (Generate Loop) ---
    genvar i_row, j_col;
    generate
        for (i_row = 0; i_row < ARRAY_SIZE; i_row = i_row + 1) begin : row_gen
            for (j_col = 0; j_col < ARRAY_SIZE; j_col = j_col + 1) begin : col_gen
                
                PE_Top_BICS #(
                    .A_WIDTH(A_WIDTH),
                    .W_WIDTH(W_WIDTH),
                    .P_WIDTH(P_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .parallel_load_en(parallel_load_en),
                    .bist_capture_en(bist_capture_en),
                    .scan_en(scan_en),
                    .in_tp_a(in_tp_a),
                    .in_tp_w(in_tp_w),
                    .in_tp_p(in_tp_p), // [수정] P-패턴 포트 연결
                    .in_expected_p(in_expected_p),
                    .pe_disable(pe_disable_bus[i_row * ARRAY_SIZE + j_col]),
                    .scan_in_a(a_data[i_row][j_col]),
                    .scan_in_w(w_data[i_row][j_col]),
                    .scan_in_p(p_data[i_row][j_col]),
                    .scan_out_a(a_data[i_row][j_col+1]),
                    .scan_out_w(w_data[i_row+1][j_col]),
                    .scan_out_p(p_data[i_row+1][j_col])
                );
            end
        end
    endgenerate

    // --- 3. 경계(Boundary) 출력 연결 ---
    genvar i_out;
    generate
        for (i_out = 0; i_out < ARRAY_SIZE; i_out = i_out + 1) begin : output_wires
            // [수정] 2D 와이어를 임시 Unpacked 와이어에 연결
            assign array_out_a_unpacked[i_out] = a_data[i_out][ARRAY_SIZE];
            assign array_out_w_unpacked[i_out] = w_data[ARRAY_SIZE][i_out];
        end
    endgenerate
    
    // --- [신규] 2D Wire -> 1D Port (Flattening) ---
    genvar i_pack;
    generate
         for (i_pack = 0; i_pack < ARRAY_SIZE; i_pack = i_pack + 1) begin : flatten_wires
            // A-path
            assign flat_array_out_a[(i_pack+1)*A_WIDTH-1 : i_pack*A_WIDTH] = array_out_a_unpacked[i_pack];
            // W-path
            assign flat_array_out_w[(i_pack+1)*W_WIDTH-1 : i_pack*W_WIDTH] = array_out_w_unpacked[i_pack];
        end
    endgenerate


    // --- 4. BICS-BIST 최종 P-출력 (Bitwise-OR) ---
    reg signed [P_WIDTH-1:0] temp_final_p;
    integer k;
    
    always @* begin
        temp_final_p = {P_WIDTH{1'b0}}; // 0으로 초기화
        for (k = 0; k < ARRAY_SIZE; k = k + 1) begin
            temp_final_p = temp_final_p | p_data[ARRAY_SIZE][k];
        end
    end
    
    assign final_scan_out_p = temp_final_p;

endmodule