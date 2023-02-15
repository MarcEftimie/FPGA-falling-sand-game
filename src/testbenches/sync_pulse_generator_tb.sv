
`timescale 1ns/1ps
`default_nettype none

module sync_pulse_generator_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter TOTAL_COLUMNS = 800;
    parameter TOTAL_ROWS = 525;
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 480;
    parameter FRONT_PORCH_HORIZONTAL = 16;
    parameter FRONT_PORCH_VERTICAL = 10;
    parameter BACK_PORCH_HORIZONTAL = 48;
    parameter BACK_PORCH_VERTICAL = 33;
    logic clk_i, reset_i;
    wire hsync_o, vsync_o, video_en_o;
    wire [$clog2(ACTIVE_COLUMNS)-1:0] x_o;
    wire [$clog2(ACTIVE_ROWS)-1:0] y_o;
    wire [$clog2(ACTIVE_COLUMNS*ACTIVE_ROWS)-1:0] pixel_o;

    sync_pulse_generator #(
        .TOTAL_COLUMNS(TOTAL_COLUMNS),
        .TOTAL_ROWS(TOTAL_ROWS),
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .FRONT_PORCH_HORIZONTAL(FRONT_PORCH_HORIZONTAL),
        .FRONT_PORCH_VERTICAL(FRONT_PORCH_VERTICAL),
        .BACK_PORCH_HORIZONTAL(BACK_PORCH_HORIZONTAL),
        .BACK_PORCH_VERTICAL(BACK_PORCH_VERTICAL)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("sync_pulse_generator.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        repeat(100000) @(negedge clk_i);

        $finish;
    end

endmodule
