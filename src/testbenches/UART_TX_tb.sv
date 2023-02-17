
`timescale 1ns/1ps
`default_nettype none

module UART_TX_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter CLKS_PER_BIT = 217;;
    parameter HALF_CLKS_PER_BIT = 108;;
    logic clk;
    logic st;
    logic [7:0] TX_byte;
    logic TX_DV;
    wire TX_serial;

    UART_TX #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .HALF_CLKS_PER_BIT(HALF_CLKS_PER_BIT)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("UART_TX.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule