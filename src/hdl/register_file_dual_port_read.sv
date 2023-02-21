`timescale 1ns/1ps
`default_nettype none

module register_file_dual_port_read
    # (
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8,
        parameter RAM_LENGTH = 0,
        parameter ROM_FILE = "zeros.mem"
    ) (
        input wire clk_i,
        input wire wr_en,
        input wire [ADDR_WIDTH-1:0] wr_address_i, rd_address_1_i, rd_address_2_i,
        input wire [DATA_WIDTH-1:0] wr_data_i,
        output logic [DATA_WIDTH-1:0] rd_data_1_o, rd_data_2_o
    );


    // Declarations
    logic [DATA_WIDTH-1:0] ram [0:RAM_LENGTH-1];
    logic [DATA_WIDTH-1:0] rd_data_1_reg, rd_data_2_reg;

    initial begin
        $readmemb({"./mem/", ROM_FILE}, ram);
    end

    // Registers
    always_ff @(posedge clk_i) begin
        if (wr_en) begin
            ram[wr_address_i] <= wr_data_i;
        end
        rd_data_1_reg <= ram[rd_address_1_i];
        rd_data_2_reg <= ram[rd_address_2_i];
    end

    // Output Logic
    assign rd_data_1_o = rd_data_1_reg;
    assign rd_data_2_o = rd_data_2_reg;

endmodule
