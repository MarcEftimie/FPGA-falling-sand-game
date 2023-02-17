
`timescale 1ns/1ps
`default_nettype none

module ps2_rxtx_tb;

    parameter CLK_PERIOD_NS = 10;
    
    logic clk_i, reset_i;
    logic tx_en_i;
    logic [7:0] tx_data_i;
    wire ps2d_io, ps2c_io;
    wire [7:0] rx_data_o;
    wire rx_done_o, tx_done_o;

    ps2_rxtx #(
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("ps2_rxtx.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        tx_data_i = 8'b01010100;
        repeat(1) @(negedge clk_i);
        tx_en_i = 0;
        reset_i = 0;
        repeat(1) @(negedge clk_i);
        tx_en_i = 1;
        repeat(1) @(negedge clk_i);
        tx_en_i = 0;
        ps2c_io = 1;
        repeat(50) @(negedge clk_i);
        ps2c_io = 0;
        repeat(10) @(negedge clk_i);
        ps2c_io = 1;
        repeat(10) @(negedge clk_i);
        $finish;
    end

endmodule
