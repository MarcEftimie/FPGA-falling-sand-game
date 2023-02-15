`timescale 1ns / 1ps
`default_nettype none

module clk_25MHz (
    input wire clk_i,
    output logic clk_o
);

    logic clk_count;
    initial begin
        clk_count = 0;
        clk_o = 0;
    end

    always_ff @(posedge clk_i) begin
        if (clk_count == 1) begin
            clk_o <= ~clk_o;
        end
        clk_count <= clk_count + 1;
    end

endmodule

