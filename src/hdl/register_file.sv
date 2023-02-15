`timescale 1ns/1ps
`default_nettype none

module register_file
    # (
        parameter ADDR_WIDTH = 8,
        parameter DATA_WIDTH = 8,
        parameter ROM_FILE = "zeros.mem"
    ) (
        input wire clk_i,
        input wire write_en,
        input wire [ADDR_WIDTH-1:0] write_address_i, read_address_i,
        input wire [DATA_WIDTH-1:0] write_data_i,
        output logic [DATA_WIDTH-1:0] read_data_o
    );


    // Declarations
    logic [DATA_WIDTH-1:0] ram [0:307200-1];
    logic [DATA_WIDTH-1:0] read_data;

    initial begin
        $readmemb({"./mem/", ROM_FILE}, ram);
    end

    // Registers
    always_ff @(posedge clk_i) begin
        if (write_en) begin
            ram[write_address_i] <= write_data_i;
        end
        read_data <= ram[read_address_i];
    end

    // Output Logic
    assign read_data_o = read_data;

endmodule
