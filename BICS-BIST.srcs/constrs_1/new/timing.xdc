# 10ns 주기 (100MHz)로 동작하는 클럭 정의
# 만약 100MHz에서도 Timing Violation(WNS가 음수)이 나면 -period 값을 늘려야 합니다.
create_clock -period 10.000 -name sys_clk [get_ports clk]

# (선택사항) 입력/출력 지연 시간 설정 (OOC 모드에서는 생략 가능하나 경고 방지용)
# set_input_delay -clock sys_clk 0.0 [all_inputs]
# set_output_delay -clock sys_clk 0.0 [all_outputs]