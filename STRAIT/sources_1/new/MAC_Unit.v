`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 15:31:35
// Design Name: 
// Module Name: MAC_Unit
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