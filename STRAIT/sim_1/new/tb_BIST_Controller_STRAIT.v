`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/16 17:40:53
// Design Name: 
// Module Name: tb_BIST_Controller_STRAIT
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

module tb_BIST_Controller_STRAIT;

    // -------------------------
    // Parameters
    // -------------------------
    localparam ADDR_WIDTH  = 4;
    localparam SCAN_LENGTH = 4;   // 테스트 빠르게 하기 위해 4로 설정

    // -------------------------
    // DUT Inputs
    // -------------------------
    reg clk, rst, start;
    reg compare_fail, last_pattern;

    // -------------------------
    // DUT Outputs
    // -------------------------
    wire scan_en, addr_en, done, error;

    // -------------------------
    // DUT Instance
    // -------------------------
    BIST_Controller_STRAIT #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SCAN_LENGTH(SCAN_LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .compare_fail(compare_fail),
        .last_pattern(last_pattern),
        .scan_en(scan_en),
        .addr_en(addr_en),
        .done(done),
        .error(error)
    );

    // -------------------------
    // Clock Generator
    // -------------------------
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns Clock

    // -------------------------
    // 상태 모니터링 (Debug)
    // -------------------------
    // FSM 내부 state를 보기 위해, DUT 내부 상태를 Hierarchical reference로 참조
    wire [2:0] state = dut.state;

    // 상태 이름을 String으로 출력
    task print_state;
        begin
            case(state)
                3'd0: $write("IDLE      ");
                3'd1: $write("SHIFT_IN  ");
                3'd2: $write("CAPTURE   ");
                3'd3: $write("SHIFT_OUT ");
                3'd4: $write("COMPARE   ");
                3'd5: $write("NEXT      ");
                3'd6: $write("DONE      ");
                default: $write("UNKNOWN   ");
            endcase
        end
    endtask

    // -------------------------
    // Test Procedure
    // -------------------------
    initial begin
        $display("=========== STRAIT BIST Controller Testbench Start ===========");

        // 초기화
        rst = 1;
        start = 0;
        compare_fail = 0;
        last_pattern = 0;
        #25;

        rst = 0;
        #10;

        // ------------------------------
        // TEST 1: 정상 실행 (compare_fail=0, 마지막 패턴에서 종료)
        // ------------------------------
        $display("\n===== TEST 1: NORMAL OPERATION =====");

        start = 1;
        @(posedge clk);
        start = 0;

        // 첫 번째 패턴 실행
        // SHIFT_IN → CAPTURE → SHIFT_OUT → COMPARE → NEXT
        repeat(1 + SCAN_LENGTH + 1 + SCAN_LENGTH + 1 + 1) begin
            @(posedge clk);
            print_state();
            $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);
        end

        // 다음 패턴에서 last_pattern=1 설정
        last_pattern = 1;

        // 두 번째 패턴 실행
        repeat(1 + SCAN_LENGTH + 1 + SCAN_LENGTH + 1 + 1) begin
            @(posedge clk);
            print_state();
            $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);
        end

        if (done == 1 && error == 0)
            $display("[TEST 1 PASSED]");
        else
            $display("[TEST 1 FAILED]");


        // ------------------------------
        // TEST 2: 중간 compare_fail 발생
        // ------------------------------
        $display("\n===== TEST 2: COMPARE FAIL TEST =====");

        // Reset
        rst = 1; #20; rst = 0; #10;

        last_pattern = 0;
        compare_fail = 0;

        start = 1;
        @(posedge clk);
        start = 0;

        // 1) SHIFT_IN
        repeat (SCAN_LENGTH) begin
            @(posedge clk);
            print_state();
            $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);
        end

        // 2) CAPTURE (1clk)
        @(posedge clk);
        print_state();
        $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);

        // 3) SHIFT_OUT
        repeat (SCAN_LENGTH) begin
            @(posedge clk);
            print_state();
            $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);
        end

        // 4) SHIFT_OUT 마지막 클럭 → compare_fail 설정
        compare_fail = 1;
        @(posedge clk);  // COMPARE 상태
        print_state();
        $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);

        // 5) NEXT
        @(posedge clk);
        print_state();
        $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);
        
        // 6) DONE
        @(posedge clk);
        print_state();
        $display(" scan_en=%0d addr_en=%0d done=%0d error=%0d", scan_en, addr_en, done, error);

        if (done == 1 && error == 1)
            $display("[TEST 2 PASSED]");
        else
            $display("[TEST 2 FAILED]");


        $display("\n=========== STRAIT BIST Controller Testbench FINISHED ===========");
        $finish;
    end

endmodule