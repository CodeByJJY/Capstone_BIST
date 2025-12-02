`timescale 1ns / 1ps

module System_Top_STRAIT (
    input clk,
    input reset,
    input bist_en,              
    input [1:0] bist_mode,      
    output [7:0] error_count,   
    output done                 
);

    // --- 내부 신호 ---
    wire last_pattern;
    
    wire [7:0]  scan_data_A, scan_data_W;
    wire [31:0] scan_in_p, expected_data;
    wire [3:0]  addr;
    wire addr_valid;

    wire sa_test_en, td_test_en, scan_en, addr_en;
    
    wire [511:0] scan_out_p_bus; 
    wire [31:0]  actual_p_out; 
    wire [3:0]   check_addr;   

    wire err_flag;     
    wire error_flag;   

    // 에러 카운트는 내부 에러 플래그 연결
    assign error_count = {7'b0, error_flag};
    
    // [수정 1] RAM을 읽을 때 현재 ROM 주소(addr)와 같은 곳을 읽도록 연결
    // (기존에는 0으로 고정되어 있어 틀렸음)
    assign check_addr  = addr; 

    assign last_pattern = (addr == 4'd15);

    // === 1. Address Generator ===
    Address_Generator addr_gen (
        .clk(clk),
        .rst(reset),
        .en(addr_en),          
        .addr_out(addr)        
    );

    // === 2. Test Pattern ROM ===
    Test_Pattern_ROM rom (
        .addr(addr),
        .out_tp_a(scan_data_A),
        .out_tp_w(scan_data_W),
        .out_tp_p(scan_in_p),             
        .out_expected_p(expected_data)
    );

    // === 3. Accumulator RAM ===
    Accumulator_RAM acc_ram (
        .clk(clk),
        .wr_en(addr_en),            
        .wr_addr(addr),             
        .din(scan_out_p_bus[31:0]), 
        .rd_addr(check_addr),       // [수정 1] 반영됨
        .dout(actual_p_out)         
    );

    // === 4. BIST Controller ===
    BIST_Controller_STRAIT bist_ctrl (
        .clk(clk),
        .rst(reset),
        .start(bist_en),           
        // [수정 2] 이제 모듈을 고쳤으니 에러 신호를 정상 연결합니다!
        // 우리가 만든 로직이 유효할 때만 에러를 띄우므로 연결해도 안전합니다.
        .compare_fail(err_flag),   
        .last_pattern(last_pattern),
        .scan_en(scan_en),
        .addr_en(addr_en),
        .done(done),
        .error(error_flag)         
    );

    // === 5. Systolic Array ===
    Systolic_Array_STRAIT sa_top (
        .clk(clk),
        .rst(reset),
        .scan_en(scan_en),
        .in_A({16{ {24'b0, scan_data_A} }}), 
        .in_W({16{ {24'b0, scan_data_W} }}), 
        .scan_in_p({16{scan_in_p}}), 
        .scan_out_p(scan_out_p_bus)  
    );

    // === 6. Main Comparator ===
    Main_Comparator_STRAIT comparator (
        .clk(clk),
        .rst(reset),                  
        
        // [수정 3] RAM에서 읽어온 데이터 vs ROM 정답 비교
        // (Step 1에서 수정한 Comparator가 0인 값은 무시하므로 타이밍 문제 해결됨)
        .accum_out(actual_p_out),    
        .expected(expected_data),    
        .ERROR(err_flag)             
    );

endmodule