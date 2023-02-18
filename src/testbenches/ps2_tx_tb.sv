
`timescale 1ns/1ps
`default_nettype none

module ps2_tx_tb;

    parameter CLK_PERIOD_NS = 10;
    
    logic clk_i, reset_i;
    logic tx_en_i;
    logic [7:0] tx_data_i;
    wire idle_o, done_o;
    wire [2:0] state_o;
    wire [3:0] bit_count_o;

    ps2_tx #(
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("ps2_tx.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule
