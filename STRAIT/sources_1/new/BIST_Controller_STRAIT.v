`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 17:36:01
// Design Name: 
// Module Name: BIST_Controller_STRAIT
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

module BIST_Controller_STRAIT #(
    parameter ADDR_WIDTH  = 4,   // 패턴 수에 따라 결정 (ROM address width)
    parameter SCAN_LENGTH = 16   // 1개의 scan chain 길이 (PE 개수 = N)
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire compare_fail,    // Comparator mismatch 신호 (COMPARE 상태에서 유효)
    input  wire last_pattern,    // 현재 ROM 주소가 마지막 패턴이면 1

    output reg  scan_en,         // 1 = shift, 0 = capture
    output reg  addr_en,         // Address Generator enable (NEXT에서 1)
    output reg  done,            // 모든 패턴 테스트 완료
    output reg  error            // 테스트 중 1번이라도 fail나면 1 (sticky)
);

    // -------------------------------
    // 상태 정의
    // -------------------------------
    localparam IDLE       = 3'd0;
    localparam SHIFT_IN   = 3'd1;
    localparam CAPTURE    = 3'd2;
    localparam SHIFT_OUT  = 3'd3;
    localparam COMPARE    = 3'd4;
    localparam NEXT       = 3'd5;
    localparam DONE_STATE = 3'd6;

    reg [2:0] state, next_state;

    // -------------------------------
    // Shift Counter (0 ~ SCAN_LENGTH-1)
    // -------------------------------
    localparam CNT_W = $clog2(SCAN_LENGTH);
    reg [CNT_W-1:0] shift_cnt;

    wire shift_done = (shift_cnt == SCAN_LENGTH-1);

    // -------------------------------
    // Error sticky flag
    // -------------------------------
    reg error_flag;

    // ===============================
    // 상태 레지스터
    // ===============================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            shift_cnt  <= {CNT_W{1'b0}};
            error_flag <= 1'b0;
        end else begin
            state <= next_state;

            // Shift counter 동작
            case (state)
                SHIFT_IN,
                SHIFT_OUT: shift_cnt <= shift_cnt + 1'b1;
                default:   shift_cnt <= {CNT_W{1'b0}};
            endcase

            // COMPARE 상태에서 compare_fail이 1이면 error_flag를 set
            if (state == COMPARE && compare_fail)
                error_flag <= 1'b1;
        end
    end

    // ===============================
    // FSM: 상태 전이
    // ===============================
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = SHIFT_IN;
            end

            // 테스트 패턴 scan-in (P 체인에 주입)
            SHIFT_IN: begin
                if (shift_done)
                    next_state = CAPTURE;
            end

            // 1클럭 동안 capture (scan_en=0, MAC 수행)
            CAPTURE: begin
                next_state = SHIFT_OUT;
            end

            // partial sum scan-out
            SHIFT_OUT: begin
                if (shift_done)
                    next_state = COMPARE;
            end

            // Comparator가 scan_out_p를 보고 compare_fail 생성
            COMPARE: begin
                next_state = NEXT;
            end

            // 다음 패턴으로 넘어갈지, 종료할지 결정
            NEXT: begin
                if (error_flag)         // 중간에 한 번이라도 fail 발생
                    next_state = DONE_STATE;
                else if (last_pattern)  // 마지막 패턴까지 성공적으로 검사 완료
                    next_state = DONE_STATE;
                else
                    next_state = SHIFT_IN; // 다음 패턴으로 반복
            end

            DONE_STATE: begin
                next_state = DONE_STATE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // ===============================
    // 출력 제어
    // ===============================
    always @(*) begin
        // 기본값
        scan_en = 1'b0;
        addr_en = 1'b0;
        done    = 1'b0;
        error   = 1'b0;

        case (state)
            // SHIFT_IN / SHIFT_OUT 동안 scan_en=1 (P 체인 shift)
            SHIFT_IN: begin
                scan_en = 1'b1;
            end

            CAPTURE: begin
                scan_en = 1'b0;  // MAC capture
            end

            SHIFT_OUT: begin
                scan_en = 1'b1;
            end

            // NEXT 상태에서 addr_en=1 → Address_Generator가 +1
            NEXT: begin
                addr_en = 1'b1;
            end

            DONE_STATE: begin
                done  = 1'b1;
            end
        endcase

        // error 출력은 sticky flag 반영
        error = error_flag;
    end

endmodule