/*******************************************************************
* 모듈명: tb_Input_Mux_BICS
* 설명: Input_Mux_BICS.v 모듈의 2-to-1 MUX 기능을 검증합니다.
*
* 1. sel_parallel_load = 0 일 때: mux_out == in_functional
* 2. sel_parallel_load = 1 일 때: mux_out == in_test
*******************************************************************/

`timescale 1ns / 1ps

module tb_Input_Mux_BICS;

    // --- 파라미터 선언 ---
    parameter DATA_WIDTH = 8;
    parameter DELAY      = 10; // 입력 변경 후 대기 시간 (10ns)

    // --- 신호 선언 ---
    // DUT의 입력은 reg, 출력은 wire
    reg  [DATA_WIDTH-1:0] tb_in_functional;
    reg  [DATA_WIDTH-1:0] tb_in_test;
    reg                   tb_sel_parallel_load;
    
    wire [DATA_WIDTH-1:0] tb_mux_out;

    // --- DUT (Design Under Test) 인스턴스화 ---
    Input_Mux_BICS #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .in_functional(tb_in_functional),
        .in_test(tb_in_test),
        .sel_parallel_load(tb_sel_parallel_load),
        .mux_out(tb_mux_out)
    );

    // --- 모니터링 ---
    initial begin
        $monitor("Time=%0t | sel=%b | in_func=0x%h | in_test=0x%h | mux_out=0x%h",
                 $time, tb_sel_parallel_load, tb_in_functional, tb_in_test, tb_mux_out);
    end

    // --- 테스트 시나리오 (Stimulus) ---
    initial begin
        $display("--- Input_Mux_BICS 테스트 시작 ---");

        // 초기값 설정
        tb_in_functional     = 8'hAA; // (10101010)
        tb_in_test           = 8'h55; // (01010101)
        tb_sel_parallel_load = 0;
        
        #DELAY;

        // --- 테스트 1: sel = 0 (Functional Mode) ---
        $display("--- 테스트 1: sel=0 (Functional Mode) ---");
        tb_sel_parallel_load = 0;
        #DELAY;

        if (tb_mux_out !== tb_in_functional) begin
            $error("테스트 1 실패! sel=0일 때 mux_out(0x%h) != in_functional(0x%h)",
                   tb_mux_out, tb_in_functional);
            $finish;
        end
        $display("... PASS: mux_out (0x%h) == in_functional (0x%h)", tb_mux_out, tb_in_functional);

        // --- 테스트 2: sel = 1 (Test Mode) ---
        $display("--- 테스트 2: sel=1 (Test Mode) ---");
        tb_sel_parallel_load = 1;
        #DELAY;
        
        if (tb_mux_out !== tb_in_test) begin
            $error("테스트 2 실패! sel=1일 때 mux_out(0x%h) != in_test(0x%h)",
                   tb_mux_out, tb_in_test);
            $finish;
        end
        $display("... PASS: mux_out (0x%h) == in_test (0x%h)", tb_mux_out, tb_in_test);
        
        // --- 테스트 3: sel=1 상태에서 in_test 값 변경 ---
        $display("--- 테스트 3: sel=1 상태에서 in_test 값 변경 ---");
        tb_in_test = 8'hFF;
        #DELAY;
        
        if (tb_mux_out !== tb_in_test) begin
             $error("테스트 3 실패! sel=1일 때 mux_out(0x%h) != in_test(0x%h)",
                   tb_mux_out, tb_in_test);
            $finish;
        end
        $display("... PASS: mux_out (0x%h) == in_test (0x%h)", tb_mux_out, tb_in_test);


        $display("--- 모든 Input_Mux_BICS 테스트 통과 ---");
        $finish;
    end

endmodule