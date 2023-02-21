
`timescale 1ns/1ps
`default_nettype none

module falling_sand_game_top_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter VRAM_ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS);
    parameter VRAM_DATA_WIDTH = 2;
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 400;
    logic clk_i, reset_i;
    logic [3:0] sw_i;
    wire ps2d_io, ps2c_io;
    wire hsync_o, vsync_o;
    wire [3:0] vga_red_o, vga_blue_o, vga_green_o;
    wire [15:0] led_o;

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
        sw_i = 4'b0111;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        repeat(2700000) @(negedge clk_i);
        $finish;
    end

endmodule
