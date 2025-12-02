`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 18:16:16
// Design Name: 
// Module Name: PE_Top_STRAIT
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

module PE_Top_STRAIT (
    input  wire        clk,
    input  wire        rst,
    input  wire        scan_en,      // 1: shift, 0: capture(MAC)

    input  wire [31:0] A,            // from left PE (or external)
    input  wire [31:0] W,            // from top  PE (or external)
    input  wire [31:0] P_in,         // from left PE

    output reg  [31:0] P_out,        // to right PE
    output reg  [31:0] A_out,        // to right PE
    output reg  [31:0] W_out         // to bottom PE
);

    // 내부 레지스터: 현재 PE에 저장된 A/W
    reg [31:0] A_reg;
    reg [31:0] W_reg;

    // MAC 결과 (조합 논리)
    wire [31:0] mac_result;

    // 아래 MAC_Unit은 반드시 "조합논리"로 구현되어 있어야 한다.
    // (in_a, in_w, in_p가 바뀌면 mac_result가 바로 바뀌는 형태)
    MAC_Unit mac_unit (
        .in_a         (A_reg[7:0]),  // 예: 하위 8비트만 사용
        .in_w         (W_reg[7:0]),
        .in_p         (P_in),
        .actual_result(mac_result)
    );

    //==================================================
    // A/W shift & P 레지스터 (STRAIT: shift vs capture)
    //==================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A_reg <= 32'd0;
            W_reg <= 32'd0;

            A_out <= 32'd0;
            W_out <= 32'd0;

            P_out <= 32'd0;
        end else begin
            //-----------------------------
            // 1) P 레지스터 (scan_en 제어)
            //-----------------------------
            if (scan_en)
                P_out <= P_in;        // shift (pass-through)
            else
                P_out <= mac_result;  // capture (MAC 결과 저장)

            //-----------------------------
            // 2) A/W shift 파이프라인
            //-----------------------------
            // 현재 클럭에서 들어온 A/W를 레지스터에 저장하고,
            // 다음 클럭에 오른쪽/아래쪽 PE로 전달
            A_reg <= A;
            W_reg <= W;

            A_out <= A_reg;          // 한 클럭 지연된 A값 전달
            W_out <= W_reg;          // 한 클럭 지연된 W값 전달
        end
    end

endmodule