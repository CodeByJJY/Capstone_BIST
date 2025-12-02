`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: BIST_Controller_FSM_BICS
* 설명:
* BICS-BIST의 메인 FSM(Finite State Machine) 컨트롤러입니다.
* 'start' 신호를 받으면, 'LOAD -> CAPTURE -> SHIFT' 사이클을
* 'NUM_PATTERNS' 횟수만큼 반복하여 BICS-BIST 테스트를 수행합니다.
*
* 파라미터:
* ARRAY_SIZE:   Systolic Array의 크기 (N) (N클럭 SHIFT용)
* NUM_PATTERNS: 총 테스트 패턴의 수 (P) (P회 반복용)
*******************************************************************/

module BIST_Controller_FSM_BICS #(
    parameter ARRAY_SIZE   = 16, // N
    parameter NUM_PATTERNS = 16  // P
) (
    // --- 1. 기본 입출력 ---
    input  wire clk,
    input  wire rst,
    input  wire start,            // BIST 테스트 시작 신호
    output wire bist_done,        // BIST 테스트 완료 신호
    
    // --- 2. PE 제어 출력 ---
    output wire parallel_load_en, // (BICS) A/W 병렬 로드
    output wire bist_capture_en,  // (BICS) P 레지스터에 fail_flag 캡처
    output wire scan_en,          // (공통) P-path 직렬 스캔
    
    // --- 3. 주변장치 제어 출력 ---
    output wire rom_addr_en,      // Test_Pattern_ROM 주소 증가
    output wire rom_addr_rst,     // Test_Pattern_ROM 주소 리셋
    output wire ram_addr_en,      // Accumulator_RAM 주소 증가
    output wire ram_addr_rst,     // Accumulator_RAM 주소 리셋
    output wire ram_wr_en         // Accumulator_RAM 쓰기 인에이블
);

    // --- FSM 상태 정의 ---
    localparam [2:0] 
        S_IDLE        = 3'b000, // 대기
        S_LOAD        = 3'b001, // 1-clk: 병렬 로드
        S_CAPTURE     = 3'b010, // 1-clk: 플래그 캡처
        S_SHIFT       = 3'b011, // N-clk: 스캔 아웃 및 RAM 저장
        S_PATTERN_INC = 3'b100, // 1-clk: 다음 패턴으로
        S_DONE        = 3'b101; // 완료

    // --- FSM 상태 레지스터 ---
    reg [2:0] current_state, next_state;

    // --- 내부 카운터 (SHIFT용, PATTERN용) ---
    reg [$clog2(ARRAY_SIZE)-1:0]   shift_count_reg,   shift_count_next;
    reg [$clog2(NUM_PATTERNS)-1:0] pattern_count_reg, pattern_count_next;

    // --- 조합논리: 카운터 완료 신호 ---
    wire shift_done   = (shift_count_reg   == ARRAY_SIZE - 1);
    wire pattern_done = (pattern_count_reg == NUM_PATTERNS - 1);


    // --- 1. 순차 논리 (레지스터) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state     <= S_IDLE;
            shift_count_reg   <= 0;
            pattern_count_reg <= 0;
        end else begin
            current_state     <= next_state;
            shift_count_reg   <= shift_count_next;
            pattern_count_reg <= pattern_count_next;
        end
    end

    // --- 2. 조합 논리 (다음 상태 결정) ---
    always @* begin
        // 기본값: 현재 상태 유지, 카운터 값 유지
        next_state         = current_state;
        shift_count_next   = shift_count_reg;
        pattern_count_next = pattern_count_reg;

        case (current_state)
            S_IDLE: begin
                if (start) begin
                    next_state = S_LOAD;
                    pattern_count_next = 0; // 패턴 카운터 리셋
                end
            end
            
            S_LOAD: begin
                next_state = S_CAPTURE;
                shift_count_next = 0; // 시프트 카운터 리셋
            end
            
            S_CAPTURE: begin
                next_state = S_SHIFT;
            end

            S_SHIFT: begin // N 클럭 동안 S_SHIFT 상태 유지
                if (shift_done) begin
                    next_state = S_PATTERN_INC; // N클럭 완료
                end else begin
                    shift_count_next = shift_count_reg + 1; // 0, 1, ... N-1
                end
            end
            
            S_PATTERN_INC: begin
                if (pattern_done) begin
                    next_state = S_DONE; // 모든 패턴 완료
                end else begin
                    next_state = S_LOAD; // 다음 패턴 로드
                    pattern_count_next = pattern_count_reg + 1;
                end
            end
            
            S_DONE: begin
                if (!start) begin // start가 0이 되면 IDLE로 복귀
                    next_state = S_IDLE;
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // --- 3. 조합 논리 (FSM 출력 결정) ---
    // (Moore FSM: 출력이 오직 'current_state'에만 의존)
    assign parallel_load_en = (current_state == S_LOAD);
    assign bist_capture_en  = (current_state == S_CAPTURE);
    assign scan_en          = (current_state == S_SHIFT);
    
    assign rom_addr_en      = (current_state == S_PATTERN_INC);
    assign rom_addr_rst     = (current_state == S_IDLE); // IDLE일 때 ROM 주소 0
    
    assign ram_addr_en      = (current_state == S_SHIFT); // S_SHIFT 상태에서 N클럭 동안 카운트
    assign ram_addr_rst     = (current_state == S_CAPTURE); // S_CAPTURE일 때 0으로 리셋
    assign ram_wr_en        = (current_state == S_SHIFT); // S_SHIFT 상태에서 N클럭 동안 RAM에 쓰기
    
    assign bist_done        = (current_state == S_DONE);

endmodule