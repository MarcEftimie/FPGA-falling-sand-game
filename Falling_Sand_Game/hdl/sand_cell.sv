`timescale 1ns/1ps
`default_nettype none

module sand_cell 
    # (
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8
    ) (
        input logic clk_i,
        input logic write_en,
        input logic [DATA_WIDTH-1:0] cell_status,
        input logic [ADDR_WIDTH-1:0] current_address_i,
        output logic [ADDR_WIDTH-1:0] write_address_o,
        output logic [DATA_WIDTH-1:0] write_data_o
    );

    always_comb begin
        if (cell_status) begin
        end
    end

endmodule
