`timescale 1ns/1ps
`default_nettype none

module mouse_pixel_drawer
    #(
        parameter COLUMNS = 640,
        parameter ROWS = 480
    ) (
        input wire clk_i, reset_i,
        input wire draw_en_i,
        input wire [$clog2(COLUMNS)-1:0] mouse_x_position_i,
        input wire [$clog2(ROWS)-1:0] mouse_y_position_i,
        output logic [$clog2(COLUMNS*ROWS)-1:0] ram_wr_address_o,
        output logic ram_wr_data_o,
        output logic ram_wr_en_o
    );

    logic [$clog2(COLUMNS)-1:0] pixel_x_count_reg, pixel_x_count_next;
    logic [$clog2(ROWS)-1:0] pixel_y_count_reg, pixel_y_count_next;
    logic [$clog2(COLUMNS*ROWS)-1:0] ram_wr_address_reg, ram_wr_address_next;

    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            pixel_x_count_reg <= 0;
            pixel_y_count_reg <= 0;
            ram_wr_address_reg <= 0;
        end else begin
            pixel_x_count_reg <= pixel_x_count_next;
            pixel_y_count_reg <= pixel_y_count_next;
            ram_wr_address_reg <= ram_wr_address_next;
        end
    end

    always_comb begin
        pixel_x_count_next = pixel_x_count_reg;
        pixel_y_count_next = pixel_y_count_reg;
        ram_wr_address_next = ram_wr_address_reg;
        ram_wr_en_o = 0;
        ram_wr_data_o = 0;
        if (draw_en_i) begin
            if (((pixel_x_count_reg == mouse_x_position_i) && (pixel_y_count_reg == mouse_y_position_i)) ||
                (((pixel_x_count_reg + 1) == mouse_x_position_i) && (pixel_y_count_reg == mouse_y_position_i)) ||
                ((pixel_x_count_reg == mouse_x_position_i) && ((pixel_y_count_reg + 1) == mouse_y_position_i)) ||
                (((pixel_x_count_reg + 1) == mouse_x_position_i) && ((pixel_y_count_reg + 1) == mouse_y_position_i))) begin
                ram_wr_en_o = 1;
                ram_wr_data_o = 1;
                if (pixel_x_count_reg == (COLUMNS - 1)) begin
                    pixel_x_count_next = 0;
                    pixel_y_count_next = pixel_y_count_reg + 1;
                end else begin
                    pixel_x_count_next = pixel_x_count_reg + 1;
                end
                ram_wr_address_next = ram_wr_address_reg + 1;
            end else if (pixel_y_count_reg == (ROWS - 1)) begin
                pixel_x_count_next = 0;
                pixel_y_count_next = 0;
                ram_wr_address_next = 0;
            end else begin
                if (pixel_x_count_reg == (COLUMNS - 1)) begin
                    pixel_x_count_next = 0;
                    pixel_y_count_next = pixel_y_count_reg + 1;
                end else begin
                    pixel_x_count_next = pixel_x_count_reg + 1;
                end
                ram_wr_address_next = ram_wr_address_reg + 1;
            end
        end     
    end

    assign ram_wr_address_o = ram_wr_address_reg;

endmodule
