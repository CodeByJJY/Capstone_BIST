`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 23:18:54
// Design Name: 
// Module Name: System_Top_STRAIT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module System_Top_STRAIT (
    input clk,
    input reset,
    input bist_en,              // 전체 BIST 시작 제어
    input [1:0] bist_mode,      // 00: Idle, 01: SA Test, 10: TD Test
//    output [7:0] error_count,   // 총 에러 개수
    output done                 // BIST 종료 여부
);

    // 내부 연결 신호들
    reg last_pattern;
    wire [7:0]  scan_data_A, scan_data_W;
    wire [31:0] scan_in_p, expected_data;
    wire [3:0] addr;
    wire addr_valid;

    wire sa_test_en, td_test_en, scan_en, addr_en, capture_en, compare_en;
    wire [15:0] scan_out;

    wire [15:0] systolic_out;

    wire err_flag;
    wire err_valid;

    // === Address Generator ===
    Address_Generator addr_gen (
        .clk(clk),
        .rst(reset),           // 포트명 정확히 일치
        .en(scan_en),          // STRAIT에서는 scan_en이 address 증가 타이밍
        .addr_out(addr)        // addr_out → addr이라는 wire로 연결
    );

    // === Test Pattern ROM ===
    Test_Pattern_ROM rom (
        .addr(addr),
        .out_tp_a(scan_data_A),
        .out_tp_w(scan_data_W),
        .out_tp_p(scan_in_p),             // STRAIT 구조에서 P 입력으로 씀
        .out_expected_p(expected_data)
    );

    // Write 연결
    Accumulator_RAM acc_ram (
        .clk(clk),
        .wr_en(compare_en),         // FSM이 compare 단계일 때만 write
        .wr_addr(addr),             // 현재 패턴 번호
        .din(scan_out_p),           // SA 결과
        .rd_addr(check_addr),       // 테스트 벤치에서 분석용 read
        .dout(actual_p_out)         // 비교용 출력
    );

    // === BIST Controller (STRAIT FSM) ===
    BIST_Controller_STRAIT bist_ctrl (
        .clk(clk),
        .rst(reset),
        .start(bist_en),           // bist_en이 start 역할
        .compare_fail(err_flag),   // Main_Comparator에서 나오는 mismatch 신호
        .last_pattern(last_pattern), // 마지막 패턴인지 여부
        .scan_en(scan_en),
        .addr_en(addr_en),
        .done(done),
        .error(error_flag)         // sticky error flag
    );

    // === STRAIT 기반 Systolic Array Top ===
    Systolic_Array_STRAIT sa_top (
        .clk(clk),
        .rst(reset),
        .scan_en(scan_en),
        .in_A(scan_data_A),
        .in_W(scan_data_W),
        .scan_in_p(scan_in_p),
        .scan_out_p(scan_out_p)
    );

    // === Main Comparator ===
    Main_Comparator_STRAIT comparator (
        .clk(clk),
        .rst(reset),                  // reset → rst
        .accum_out(scan_out),        // scan_out → accum_out
        .expected(expected_data),    // OK
        .ERROR(err_flag)             // error → ERROR
    );

//    // === Error Counter ===
//    Error_Counter err_cnt (
//        .clk(clk),
//        .reset(reset),
//        .error(err_flag),
//        .valid(err_valid),
//        .count(error_count)
//    );

endmodule