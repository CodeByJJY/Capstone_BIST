`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 18:31:41
// Design Name: 
// Module Name: Systolic_Array_STRAIT
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

//======================================================
//  N x N Systolic Array for STRAIT-style BIST
//  - Uses PE_Top_STRAIT as the PE
//  - A : left  → right
//  - W : top   → bottom
//  - P : left  → right (used both as partial sum & scan chain)
//======================================================
module Systolic_Array_STRAIT #(
    parameter N           = 16,
    parameter DATA_WIDTH  = 32
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      scan_en,       // 1: shift, 0: capture(MAC)

    // 각 row의 가장 왼쪽으로 들어가는 A (N개)
    input  wire [N*DATA_WIDTH-1:0]   in_A,         

    // 각 column의 가장 위로 들어가는 W (N개)
    input  wire [N*DATA_WIDTH-1:0]   in_W,         

    // 각 row의 P 체인 시작점 (예: STRAIT test pattern 또는 0)
    input  wire [N*DATA_WIDTH-1:0]   scan_in_p,    

    // 각 row의 마지막 PE (col = N-1)의 P_out
    output wire [N*DATA_WIDTH-1:0]   scan_out_p    
);

    // -------------------------------------------------
    // 내부 연결선: A, W, P (각각 N x N 개)
    // -------------------------------------------------
    // A_wire[m][n] : (m행, n열) PE의 A_out (→ 오른쪽 PE의 A 입력으로 사용)
    // W_wire[m][n] : (m행, n열) PE의 W_out (→ 아래쪽 PE의 W 입력으로 사용)
    // P_wire[m][n] : (m행, n열) PE의 P_out (→ 오른쪽 PE의 P_in으로 사용)
    // -------------------------------------------------
    wire [DATA_WIDTH-1:0] A_wire [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] W_wire [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] P_wire [0:N-1][0:N-1];

    genvar m, n;
    generate
        for (m = 0; m < N; m = m + 1) begin : ROW
            for (n = 0; n < N; n = n + 1) begin : COL

                // ------------------------------
                // 이 PE에 들어갈 A / W / P_in 계산
                // ------------------------------
                wire [DATA_WIDTH-1:0] A_in_this;
                wire [DATA_WIDTH-1:0] W_in_this;
                wire [DATA_WIDTH-1:0] P_in_this;

                // A: 왼쪽에서 오거나 (n==0이면 외부 in_A에서)
                assign A_in_this = (n == 0) 
                                   ? in_A[m*DATA_WIDTH +: DATA_WIDTH]
                                   : A_wire[m][n-1];

                // W: 위에서 오거나 (m==0이면 외부 in_W에서)
                assign W_in_this = (m == 0)
                                   ? in_W[n*DATA_WIDTH +: DATA_WIDTH]
                                   : W_wire[m-1][n];

                // P: 왼쪽에서 오거나 (n==0이면 scan_in_p에서 시작)
                assign P_in_this = (n == 0)
                                   ? scan_in_p[m*DATA_WIDTH +: DATA_WIDTH]
                                   : P_wire[m][n-1];

                // ------------------------------
                // 실제 PE 인스턴스
                // ------------------------------
                PE_Top_STRAIT u_pe (
                    .clk    (clk),
                    .rst    (rst),
                    .scan_en(scan_en),

                    .A      (A_in_this),
                    .W      (W_in_this),
                    .P_in   (P_in_this),

                    .P_out  (P_wire[m][n]),
                    .A_out  (A_wire[m][n]),
                    .W_out  (W_wire[m][n])
                );

                // ------------------------------
                // 각 row의 마지막 P_out을 scan_out_p로 전달
                // (row m, col N-1)
                // ------------------------------
                if (n == N-1) begin : LAST_COL
                    assign scan_out_p[m*DATA_WIDTH +: DATA_WIDTH] = P_wire[m][n];
                end

            end
        end
    endgenerate

endmodule