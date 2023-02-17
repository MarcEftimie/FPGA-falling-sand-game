
`timescale 1ns/1ps
`default_nettype none

module mouse_led_tb;

    parameter CLK_PERIOD_NS = 10;
    
    logic clk_i, reset_i;
    wire [7:0] led_o;

    mouse_led #(
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("mouse_led.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule