
IVERILOG=iverilog -DSIMULATION -Wall -Wno-sensitivity-entire-vector -Wno-sensitivity-entire-array -g2012 -Y.sv -I ./hdl -I ./tests 
VVP=vvp
VVP_POST=-fst
VIVADO=vivado -mode batch -source
SRCS=hdl/*.sv

.PHONY: clean submission remove_solutions

clean:
	rm -f *.bin *.vcd *.fst vivado*.log *.jou vivado*.str *.log *.checkpoint *.bit *.html *.xml *.out
	rm -rf .Xil

test_sync_pulse_generator : testbenches/sync_pulse_generator_tb.sv hdl/*
	${IVERILOG} $^ -o sync_pulse_generator_tb.bin && ${VVP} sync_pulse_generator_tb.bin ${VVP_POST} && gtkwave sync_pulse_generator.fst -a testbenches/sy

test_falling_sand_game_top : testbenches/falling_sand_game_top_tb.sv hdl/*
	${IVERILOG} $^ -o falling_sand_game_top_tb.bin && ${VVP} falling_sand_game_top_tb.bin ${VVP_POST} && gtkwave falling_sand_game_top.fst -a testbenches/sy

test_vram_sync : testbenches/vram_sync_tb.sv hdl/*
	${IVERILOG} $^ -o vram_sync_tb.bin && ${VVP} vram_sync_tb.bin ${VVP_POST} && gtkwave vram_sync.fst -a testbenches/sy

test_sync_pulse_generator_fsm : testbenches/sync_pulse_generator_fsm_tb.sv hdl/*
	${IVERILOG} $^ -o sync_pulse_generator_fsm_tb.bin && ${VVP} sync_pulse_generator_fsm_tb.bin ${VVP_POST} && gtkwave sync_pulse_generator_fsm.fst -a testbenches/sy

