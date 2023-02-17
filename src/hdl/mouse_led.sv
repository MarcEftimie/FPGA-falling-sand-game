`timescale 1ns/1ps
`default_nettype none

module mouse_led
    (
        input wire clk_i, reset_i,
        inout wire ps2d_io, ps2c_io,
        output logic [7:0] led_o
    );

    // Declarations
    logic [9:0] led_reg, led_next;
    logic [8:0] x_pos;
    logic [2:0] btn;
    logic mouse_done;

    mouse MOUSE(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .x_o(x_pos),
        .y_o(),
        .btn_o(btn),
        .done_o(mouse_done)
    );

    logic [8:0] x_mouse_pos_reg, x_mouse_pos_next;
    logic [8:0] y_mouse_pos_reg, y_mouse_pos_next;
    logic [2:0] btn_mouse_reg, btn_mouse_next;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            led_reg <= 0;
        end else begin
            led_reg <= led_next;
        end
    end

    // Next State Logic
    assign led_next = (~mouse_done) ? led_reg :
                      (btn[0])      ? 10'b0 :
                      (btn[1])      ? 10'h3ff :
                      led_reg + {x_pos[8], x_pos};

    always_comb begin
        case (led_reg[9:7])
            3'b000: led_o = 8'b10000000;
            3'b001: led_o = 8'b01000000;
            3'b010: led_o = 8'b00100000;
            3'b011: led_o = 8'b00010000;
            3'b100: led_o = 8'b00001000;
            3'b101: led_o = 8'b00000100;
            3'b110: led_o = 8'b00000010;
            default : led_o = 8'b00000001;
        endcase
    end

endmodule
