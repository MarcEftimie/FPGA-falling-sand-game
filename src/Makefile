
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

test_falling_sand_game_top : testbenches/falling_sand_game_top_tb.sv hdl/*
	${IVERILOG} $^ -o falling_sand_game_top_tb.bin && ${VVP} falling_sand_game_top_tb.bin ${VVP_POST} && gtkwave falling_sand_game_top.fst -a testbenches/sy

test_clk_25MHz : testbenches/clk_25MHz_tb.sv hdl/*
	${IVERILOG} $^ -o clk_25MHz_tb.bin && ${VVP} clk_25MHz_tb.bin ${VVP_POST} && gtkwave clk_25MHz.fst -a testbenches/sy

test_register_file : testbenches/register_file_tb.sv hdl/*
	${IVERILOG} $^ -o register_file_tb.bin && ${VVP} register_file_tb.bin ${VVP_POST} && gtkwave register_file.fst -a testbenches/sy

