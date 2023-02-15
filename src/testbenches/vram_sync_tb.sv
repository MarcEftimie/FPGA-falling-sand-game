
`timescale 1ns/1ps
`default_nettype none

module vram_sync_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter ADDR_WIDTH = 19;
    parameter DATA_WIDTH = 1;
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 480;
    logic clk_i;
    logic [$clog2(ACTIVE_COLUMNS*ACTIVE_ROWS):0] addr_i;
    wire [DATA_WIDTH-1:0] data_o;

    vram_sync #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("vram_sync.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        repeat(1) @(negedge clk_i);
        repeat(1) @(negedge clk_i);
        for (int i=0; i<ACTIVE_COLUMNS*ACTIVE_ROWS; i++) begin
            addr_i = i;
            repeat(1) @(negedge clk_i);
        end
        $finish;
    end

endmodule
