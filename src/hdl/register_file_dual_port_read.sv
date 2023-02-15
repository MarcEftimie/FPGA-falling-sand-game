`timescale 1ns/1ps
`default_nettype none

module register_file_dual_port_read
    # (
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8,
        parameter ROM_FILE = "zeros.mem"
    ) (
        input wire clk_i,
        input wire write_en,
        input wire [ADDR_WIDTH-1:0] write_address_i, read_address_1_i, read_address_2_i,
        input wire [DATA_WIDTH-1:0] write_data_i,
        output logic [DATA_WIDTH-1:0] read_data_1_o, read_data_2_o
    );


    // Declarations
    logic [DATA_WIDTH-1:0] ram [0:307200-1];
    logic [DATA_WIDTH-1:0] read_data_1_reg, read_data_2_reg;

    initial begin
        $readmemb({"./mem/", ROM_FILE}, ram);
    end

    // Registers
    always_ff @(posedge clk_i) begin
        if (write_en) begin
            ram[write_address_i] <= write_data_i;
        end
        read_data_1_reg <= ram[read_address_1_i];
        read_data_2_reg <= ram[read_address_2_i];
    end

    // Output Logic
    assign read_data_1_o = read_data_1_reg;
    assign read_data_2_o = read_data_2_reg;

endmodule
