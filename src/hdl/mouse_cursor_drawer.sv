`timescale 1ns/1ps
`default_nettype none

module mouse_cursor_drawer #(
        parameter COLUMNS = 640,
        parameter ROWS = 480
    )
    (
        input wire clk_i, reset_i,
        input wire [$clog2(COLUMNS)-1:0] mouse_x_position_i, pixel_x_i,
        input wire [$clog2(ROWS)-1:0] mouse_y_position_i, pixel_y_i,
        output logic cursor_draw_o
    );

    assign cursor_draw_o = ((mouse_x_position_i == pixel_x_i) && (mouse_y_position_i == pixel_y_i)) ? 1'b1 :
                           ((mouse_x_position_i - 1 == pixel_x_i) && (mouse_y_position_i == pixel_y_i)) ? 1'b1 :
                           ((mouse_x_position_i + 1 == pixel_x_i) && (mouse_y_position_i == pixel_y_i)) ? 1'b1 :
                           ((mouse_x_position_i == pixel_x_i) && (mouse_y_position_i + 1 == pixel_y_i)) ? 1'b1 :
                           ((mouse_x_position_i == pixel_x_i) && (mouse_y_position_i - 1 == pixel_y_i)) ? 1'b1 : 1'b0;

endmodule
