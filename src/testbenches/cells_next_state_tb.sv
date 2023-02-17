
`timescale 1ns/1ps
`default_nettype none

module cells_next_state_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter ACTIVE_COLUMNS = 640;
    parameter ACTIVE_ROWS = 480;
    parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS);
    parameter DATA_WIDTH = 1;
    logic clk_i, reset_i;
    logic ady_i;
    logic [DATA_WIDTH-1:0] pixel_state_i;
    wire [ADDR_WIDTH-1:0] rd_address_o;
    wire [ADDR_WIDTH-1:0] wr_address_o;
    wire [DATA_WIDTH-1:0] wr_data_o;
    wire wr_en_o;
    wire done_o;

    cells_next_state #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("cells_next_state.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule