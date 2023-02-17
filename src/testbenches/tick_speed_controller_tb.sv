
`timescale 1ns/1ps
`default_nettype none

module tick_speed_controller_tb;

    parameter CLK_PERIOD_NS = 10;
    
    logic [2:0] controller_i;
    wire [26:0] tick_delay_o ;

    tick_speed_controller #(
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("tick_speed_controller.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule