`timescale 1ns / 1ps

module tb_Systolic_Array_STRAIT;

    parameter N = 4;                     // 테스트는 4×4로 축소 (시뮬레이션 속도 위해)
    parameter DATA_WIDTH = 32;

    reg clk, rst, scan_en;

    reg  [N*DATA_WIDTH-1:0] in_A;
    reg  [N*DATA_WIDTH-1:0] in_W;
    reg  [N*DATA_WIDTH-1:0] scan_in_p;
    wire [N*DATA_WIDTH-1:0] scan_out_p;

    // -------------------------------
    // DUT 인스턴스
    // -------------------------------
    Systolic_Array_STRAIT #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .scan_en(scan_en),

        .in_A(in_A),
        .in_W(in_W),
        .scan_in_p(scan_in_p),

        .scan_out_p(scan_out_p)
    );

    // -------------------------------
    // Clock
    // -------------------------------
    always #5 clk = ~clk;

    // -------------------------------
    // Test Sequence
    // -------------------------------
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        scan_en = 1;
        in_A = 0;
        in_W = 0;
        scan_in_p = 0;

        #20;
        rst = 0;

        // ============================================================
        // 1) Scan Shift Test (scan_en = 1)
        // ============================================================
        $display("===== SCAN SHIFT TEST (scan_en = 1) =====");

        // 각 row의 P-chain 시작점에 값 넣기
        scan_in_p = {
            32'hAAAA0003,  // row 3
            32'hAAAA0002,  // row 2
            32'hAAAA0001,  // row 1
            32'hAAAA0000   // row 0
        };

        for (i = 0; i < N+2; i = i + 1) begin
            #10;
            $display("[SCAN] cycle=%0d  scan_out_p=%h", i, scan_out_p);
        end


        // ============================================================
        // 2) Systolic Array Normal MAC Test (scan_en = 0)
        // ============================================================
        $display("\n===== NORMAL MAC TEST (scan_en = 0) =====");

        scan_en = 0;
        scan_in_p = 0;   // partial sum 초기화

        // A = [1 2 3 4]^T (row input)
        in_A = {
            32'd4,
            32'd3,
            32'd2,
            32'd1
        };

        // W = [5 6 7 8] (column input)
        in_W = {
            32'd8,
            32'd7,
            32'd6,
            32'd5
        };

        for (i = 0; i < 10; i = i + 1) begin
            #10;
            $display("[MAC] cycle=%0d  scan_out_p=%h", i, scan_out_p);
        end


        $display("\n===== TEST FINISHED =====");
        $finish;
    end

endmodule