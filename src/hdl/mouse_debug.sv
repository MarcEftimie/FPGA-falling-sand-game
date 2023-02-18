`timescale 1ns/1ps
`default_nettype none

module mouse_debug
    (
        input wire clk_i, reset_i,
        inout wire ps2d_io, ps2c_io,
        output logic [11:0] led_o
    );

    // Declarations
    logic [8:0] x_pos;
    logic [8:0] y_pos;
    logic [2:0] btn;

    assign led_o = {btn, x_pos};

    mouse MOUSE(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .x_o(x_pos),
        .y_o(y_pos),
        .btn_o(btn),
        .done_o()
    );

endmodule
