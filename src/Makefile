
IVERILOG=iverilog -DSIMULATION -Wall -Wno-sensitivity-entire-vector -Wno-sensitivity-entire-array -g2012 -Y.sv -I ./hdl -I ./tests 
VVP=vvp
VVP_POST=-fst
VIVADO=vivado -mode batch -source
SRCS=hdl/*.sv
MEMS=mem/*.mem

.PHONY: clean submission remove_solutions

clean:
	rm -f *.bin *.vcd *.fst vivado*.log *.jou vivado*.str *.log *.checkpoint *.bit *.html *.xml *.out
	rm -rf .Xil

program_fpga_vivado: $(SRCS) $(MAIN_MEMSMEMORIES) build.tcl program.tcl Basys-3-Master.xdc
	@echo "########################################"
	@echo "#### Building FPGA bitstream        ####"
	@echo "########################################"
	${VIVADO} build.tcl
	@echo "########################################"
	@echo "#### Programming FPGA (Vivado)      ####"
	@echo "########################################"
	${VIVADO} program.tcl

test_sync_pulse_generator : testbenches/sync_pulse_generator_tb.sv hdl/*
	${IVERILOG} $^ -o sync_pulse_generator_tb.bin && ${VVP} sync_pulse_generator_tb.bin ${VVP_POST} && gtkwave sync_pulse_generator.fst -a testbenches/sy

test_ps2_verification : testbenches/ps2_verification_tb.sv hdl/*
	${IVERILOG} $^ -o ps2_verification_tb.bin && ${VVP} ps2_verification_tb.bin ${VVP_POST} && gtkwave ps2_verification.fst -a testbenches/sy

test_mouse_led : testbenches/mouse_led_tb.sv hdl/*
	${IVERILOG} $^ -o mouse_led_tb.bin && ${VVP} mouse_led_tb.bin ${VVP_POST} && gtkwave mouse_led.fst -a testbenches/sy

test_tick_speed_controller : testbenches/tick_speed_controller_tb.sv hdl/*
	${IVERILOG} $^ -o tick_speed_controller_tb.bin && ${VVP} tick_speed_controller_tb.bin ${VVP_POST} && gtkwave tick_speed_controller.fst -a testbenches/sy

test_register_file_dual_port_read : testbenches/register_file_dual_port_read_tb.sv hdl/*
	${IVERILOG} $^ -o register_file_dual_port_read_tb.bin && ${VVP} register_file_dual_port_read_tb.bin ${VVP_POST} && gtkwave register_file_dual_port_read.fst -a testbenches/sy

test_falling_sand_game_top : testbenches/falling_sand_game_top_tb.sv hdl/*
	${IVERILOG} $^ -o falling_sand_game_top_tb.bin && ${VVP} falling_sand_game_top_tb.bin ${VVP_POST} && gtkwave falling_sand_game_top.fst -a testbenches/sy

test_clk_25MHz : testbenches/clk_25MHz_tb.sv hdl/*
	${IVERILOG} $^ -o clk_25MHz_tb.bin && ${VVP} clk_25MHz_tb.bin ${VVP_POST} && gtkwave clk_25MHz.fst -a testbenches/sy

test_ps2_rxtx : testbenches/ps2_rxtx_tb.sv hdl/*
	${IVERILOG} $^ -o ps2_rxtx_tb.bin && ${VVP} ps2_rxtx_tb.bin ${VVP_POST} && gtkwave ps2_rxtx.fst -a testbenches/sy

test_ps2_rx : testbenches/ps2_rx_tb.sv hdl/*
	${IVERILOG} $^ -o ps2_rx_tb.bin && ${VVP} ps2_rx_tb.bin ${VVP_POST} && gtkwave ps2_rx.fst -a testbenches/sy

test_register_file : testbenches/register_file_tb.sv hdl/*
	${IVERILOG} $^ -o register_file_tb.bin && ${VVP} register_file_tb.bin ${VVP_POST} && gtkwave register_file.fst -a testbenches/sy

test_mouse : testbenches/mouse_tb.sv hdl/*
	${IVERILOG} $^ -o mouse_tb.bin && ${VVP} mouse_tb.bin ${VVP_POST} && gtkwave mouse.fst -a testbenches/sy

test_cells_next_state : testbenches/cells_next_state_tb.sv hdl/*
	${IVERILOG} $^ -o cells_next_state_tb.bin && ${VVP} cells_next_state_tb.bin ${VVP_POST} && gtkwave cells_next_state.fst -a testbenches/sy

test_game_state_controller : testbenches/game_state_controller_tb.sv hdl/*
	${IVERILOG} $^ -o game_state_controller_tb.bin && ${VVP} game_state_controller_tb.bin ${VVP_POST} && gtkwave game_state_controller.fst -a testbenches/sy

test_ps2_tx : testbenches/ps2_tx_tb.sv hdl/ps2_tx.sv hdl/debouncer.sv
	${IVERILOG} $^ -o ps2_tx_tb.bin && ${VVP} ps2_tx_tb.bin ${VVP_POST} && gtkwave ps2_tx.fst -a testbenches/sy

test_UART_TX : testbenches/UART_TX_tb.sv hdl/*
	${IVERILOG} $^ -o UART_TX_tb.bin && ${VVP} UART_TX_tb.bin ${VVP_POST} && gtkwave UART_TX.fst -a testbenches/sy

