`timescale 1ns/1ps
`default_nettype none

module mouse_debug
    (
        input wire clk_i, reset_i,
        inout wire ps2d_io, ps2c_io,
        output logic [7:0] led_o,
        output logic TX_serial,
        output logic [2:0] state_o
    );

    // Declarations
    logic [9:0] led_reg, led_next;
    logic [8:0] x_pos;
    logic [7:0] btn;
    logic mouse_done;
    logic [2:0] hex_in;
    logic [7:0] ascii_code;

    assign hex_in = 0;

    mouse MOUSE(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .x_o(x_pos),
        .y_o(),
        .btn_o(btn),
        .done_o(mouse_done),
        .state_o(state_o)
    );

    // logic [8:0] x_mouse_pos_reg, x_mouse_pos_next;
    // logic [8:0] y_mouse_pos_reg, y_mouse_pos_next;
    // logic [2:0] btn_mouse_reg, btn_mouse_next;

    UART_TX UART_TX(
        .clk(clk_i),
        .rst(reset_i),
        .TX_byte(ascii_code),
        .TX_DV(mouse_done),
        .TX_serial(TX_serial)
    );

    // Next State Logic
    assign led_o = btn;


    always_comb begin
        case (hex_in)
            3'b000: ascii_code = 8'h48;
            3'b001: ascii_code = 8'h49;
            3'b010: ascii_code = 8'h50;
            3'b100: ascii_code = 8'h51;
            // 4'h4: ascii_code = 8'h34;
            // 4'h5: ascii_code = 8'h35;
            // 4'h6: ascii_code = 8'h36;
            // 4'h7: ascii_code = 8'h37;
            // 4'h8: ascii_code = 8'h38;
            // 4'h9: ascii_code = 8'h39;
            // 4'ha: ascii_code = 8'h41;
            // 4'hb: ascii_code = 8'h42;
            // 4'hc: ascii_code = 8'h43;
            // 4'hd: ascii_code = 8'h44;
            // 4'he: ascii_code = 8'h45;
            default : ascii_code = 8'h48;
        endcase
    end

endmodule
