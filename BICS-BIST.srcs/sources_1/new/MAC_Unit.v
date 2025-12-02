`timescale 1ns / 1ps
/*******************************************************************
* 모듈명: MAC_Unit
* 설명:
* A (Activation), W (Weight), P_in (Partial Sum)을 입력받아
* A * W + P_in 연산을 수행하는 조합 논리(Combinational) 모듈입니다.
* 모든 연산은 'signed' (부호 있는 정수)로 처리됩니다.
*
* 파라미터:
* A_WIDTH: 'in_a' (Activation)의 비트 폭 (기본값: 8)
* W_WIDTH: 'in_w' (Weight)의 비트 폭 (기본값: 8)
* P_WIDTH: 'in_p' (Partial Sum) 및 'actual_result'의 비트 폭 (기본값: 32)
*
* 포트:
* in_a:  Activation 입력 [A_WIDTH-1:0]
* in_w:  Weight 입력 [W_WIDTH-1:0]
* in_p:  상위 PE의 Partial Sum 입력 [P_WIDTH-1:0]
* actual_result: (A * W) + P_in 연산 결과 [P_WIDTH-1:0]
*******************************************************************/

module MAC_Unit #(
    parameter A_WIDTH = 8,
    parameter W_WIDTH = 8,
    parameter P_WIDTH = 32
) (
    // --- 입력 포트 ---
    input  wire signed [A_WIDTH-1:0] in_a,
    input  wire signed [W_WIDTH-1:0] in_w,
    input  wire signed [P_WIDTH-1:0] in_p,
    
    // --- 출력 포트 ---
    output wire signed [P_WIDTH-1:0] actual_result
);

    // --- 내부 와이어 선언 ---
    
    // 곱셈 결과는 두 입력의 비트 폭을 더한 크기를 가집니다.
    // (예: 8-bit * 8-bit = 16-bit)
    wire signed [A_WIDTH + W_WIDTH - 1:0] mult_result;
    
    
    // --- 조합 논리 (Combinational Logic) ---
    
    // 1. 곱셈 (Multiply)
    assign mult_result = in_a * in_w;
    
    // 2. 덧셈 (Accumulate)
    // (A * W) + P_in
    // 'mult_result' (예: 16-bit)는 'actual_result' (예: 32-bit)의
    // 비트 폭에 맞게 자동으로 '부호 확장(Sign-Extension)'되어 덧셈됩니다.
    assign actual_result = $signed(mult_result) + in_p;

endmodule