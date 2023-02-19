`timescale 1ns/1ps
`default_nettype none

module mouse_position_tracker
    (
        input wire clk_i, reset_i,
        input wire [8:0] x_velocity_i, y_velocity_i,
        input wire update_position_i,
        output logic [9:0] x_position_o,
        output logic [8:0] y_position_o
    );

    // Declarations
    logic [9:0] x_position_reg, x_position_next;
    logic [8:0] y_position_reg, y_position_next;

    // Registers
    always_ff @(posedge clk_i, reset_i) begin
        if (reset_i) begin
            x_position_reg <= 0;
            y_position_reg <= 0;
        end else begin
            x_position_reg <= x_position_next;
            y_position_reg <= y_position_next;
        end
    end

    // Next State Logic
    always_comb begin
        x_position_next = x_position_reg;
        y_position_next = y_position_reg;
        if (update_position_i) begin
            if (x_velocity_i[8]) begin
                if ((~({1'b1, x_velocity_i}) + 1) > x_position_reg) begin
                    x_position_next = 0;
                end else if ((x_position_reg + {1'b1, x_velocity_i}) > 639) begin
                    x_position_next = 639;
                end else begin
                    x_position_next = x_position_reg + x_velocity_i;
                end
            end
            if (y_velocity_i[8]) begin
                if ((~y_velocity_i + 1) > y_position_reg) begin
                    y_position_next = 0;
                end else if ((y_position_reg + y_velocity_i) > 479) begin
                    y_position_next = 479;
                end else begin
                    y_position_next = y_position_reg + y_velocity_i;
                end
            end
        end
    end

    // Outputs
    assign x_position_o = x_position_reg;
    assign y_position_o = y_position_reg;

endmodule
