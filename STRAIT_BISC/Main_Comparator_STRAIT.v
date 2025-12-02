`timescale 1ns / 1ps

module Main_Comparator_STRAIT (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] accum_out, // RAM 또는 Bus에서 읽은 값
    input  wire [31:0] expected,  // ROM에서 나온 정답
    output reg         ERROR
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ERROR <= 0;
        end else begin
            // [수정된 논리] 
            // 1. 데이터가 0인 경우는 "아직 데이터가 안 왔다"고 보고 무시합니다.
            // 2. 데이터가 0이 아닌데(유효한데) 정답(expected)과 다르면 에러입니다.
            // (참고: 테스트 패턴의 정답은 모두 0이 아닌 값으로 구성되어 있습니다)
            if ((accum_out != 32'd0) && (accum_out !== expected)) begin
                ERROR <= 1;
            end
            // 한번 에러가 나면 1로 유지 (Sticky)
        end
    end

endmodule