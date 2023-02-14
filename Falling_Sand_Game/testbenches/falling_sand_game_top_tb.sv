
`timescale 1ns/1ps
`default_nettype none

module falling_sand_game_top_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter VRAM_ADDR_WIDTH = 19;
    parameter VRAM_DATA_WIDTH = 1;
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 480;
    logic clk_i, reset_i;
    wire hsync_o, vsync_o;
    wire vga_red_o, vga_blue_o, vga_green_o;

    falling_sand_game_top #(
        .VRAM_ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .VRAM_DATA_WIDTH(VRAM_DATA_WIDTH),
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("falling_sand_game_top.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        repeat(2500000) @(negedge clk_i);
        $finish;
    end

endmodule
