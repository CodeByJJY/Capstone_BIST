`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: Accumulator_RAM
* 설명:
* 'scan_out' 결과를 임시 저장하기 위한 간단한 RAM (Register File)입니다.
* 1개의 동기식 쓰기 포트와 1개의 비동기식 읽기 포트를 가집니다.
*
* 파라미터:
* DATA_WIDTH: 저장할 데이터의 비트 폭 (P 레지스터와 동일해야 함)
* ARRAY_SIZE: Systolic Array의 크기 (N)
* ADDR_WIDTH: 주소 비트 폭 ($clog2(ARRAY_SIZE))
*
* 포트:
* clk:       (입력) 시스템 클럭
* * wr_en:     (입력) 쓰기 인에이블 (Active High)
* wr_addr:   (입력) 쓰기 주소 (Address_Generator에서 옴)
* din:       (입력) 쓰기 데이터 (Systolic Array의 'scan_out'에서 옴)
* * rd_addr:   (입력) 읽기 주소 (Address_Generator 또는 Comparator에서 옴)
* dout:      (출력) 읽기 데이터 (Main_Comparator로 감)
*******************************************************************/

module Accumulator_RAM #(
    parameter DATA_WIDTH = 32,
    parameter ARRAY_SIZE = 16,
    parameter ADDR_WIDTH = $clog2(ARRAY_SIZE)
) (
    // --- 공통 ---
    input  wire                  clk,
    
    // --- 쓰기 포트 (Synchronous) ---
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] din,
    
    // --- 읽기 포트 (Asynchronous) ---
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] dout
);

    // --- RAM을 모델링하기 위한 레지스터 배열 ---
    // 예: 32비트 x 16개 (0~15)
    reg [DATA_WIDTH-1:0] mem [0:ARRAY_SIZE-1];

    
    // --- 1. 쓰기 로직 (Synchronous Write) ---
    // 클럭의 상승 엣지에서만 쓰기 동작 수행
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= din;
        end
    end

    // --- 2. 읽기 로직 (Asynchronous Read) ---
    // 'rd_addr'가 바뀌면 'dout'이 즉시 바뀜 (조합 논리)
    assign dout = mem[rd_addr];
    
    // 참고: 시뮬레이션에서는 'mem'의 초기값이 'x' (unknown)이므로
    // BIST FSM이 쓰기 동작을 완료한 후에 읽기 동작을 시작해야
    // 정확한 값을 읽을 수 있습니다.

endmodule