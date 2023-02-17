
`timescale 1ns/1ps
`default_nettype none

module mouse_tb;

    parameter CLK_PERIOD_NS = 10;
    
    logic clk_i, reset_i;
    wire [8:0] x_o, y_o;
    wire [2:0] btn_o;
    wire done_o;

    mouse #(
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("mouse.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule