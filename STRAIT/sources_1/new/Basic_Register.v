`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 15:19:23
// Design Name: 
// Module Name: Basic_Register
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


module Basic_Register #(
    parameter DATA_WIDTH = 32   // 기본 비트 폭을 32로 설정
) (
    // --- 입력 포트 ---
    input wire clk,                 // 클럭
    input wire rst,                 // 동기식 리셋 (Active High)
    input wire en,                  // 인에이블 (Active High)
    input wire [DATA_WIDTH-1:0] d,  // 데이터 입력
    
    // --- 출력 포트 ---
    output reg [DATA_WIDTH-1:0] q   // 데이터 출력
);

    // 동기식 로직: 클럭의 Positive Edge에서만 동작
    always @(posedge clk) begin
        if (rst) begin
            // 우선순위 1: 리셋 신호가 1이면, 'q'를 0으로 초기화
            // {DATA_WIDTH{1'b0}}는 DATA_WIDTH 만큼 0을 반복 (예: 32'b00...0)
            q <= {DATA_WIDTH{1'b0}};
        end else if (en) begin
            // 우선순위 2: 리셋이 0이고 인에이블이 1이면, 'd' 값을 'q'에 저장
            q <= d;
        end
        // (rst=0 이고 en=0 이면, q는 기존 값을 유지 (암시적 Latch))
    end

endmodule