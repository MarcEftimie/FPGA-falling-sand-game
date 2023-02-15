
`timescale 1ns/1ps
`default_nettype none

module register_file_tb;

    parameter CLK_PERIOD_NS = 10;
    
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 8;
    parameter ROM_FILE = "zeros.mem";
    logic clk_i;
    logic _en;
    logic [ADDR_WIDTH-1:0] write_address_i, read_address_i;
    logic [DATA_WIDTH-1:0] write_data_i;
    wire [DATA_WIDTH-1:0] read_data_o;

    register_file #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ROM_FILE(ROM_FILE)
    ) UUT(
        .*
    );

    always #(CLK_PERIOD_NS/2) clk_i = ~clk_i;

    initial begin
        $dumpfile("register_file.fst");
        $dumpvars(0, UUT);
        clk_i = 0;
        reset_i = 1;
        repeat(1) @(negedge clk_i);
        reset_i = 0;
        $finish;
    end

endmodule