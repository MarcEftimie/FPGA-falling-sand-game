
`timescale 1ns/1ps
`default_nettype none

module game_state_controller_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 480;
    parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS);
    parameter DATA_WIDTH = 1;
    logic clk_i, reset_i;
    logic [26:0] tick_10_ns;
    logic [DATA_WIDTH-1:0] ram_rd_data_i, vram_rd_data_i;
    wire [ADDR_WIDTH-1:0] ram_rd_address_o, vram_rd_address_o;
    wire [ADDR_WIDTH-1:0] ram_wr_address_o, vram_wr_address_o;
    wire [DATA_WIDTH-1:0] ram_wr_data_o, vram_wr_data_o;
    wire ram_wr_en_o, vram_wr_en_o;

    game_state_controller #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("game_state_controller.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule