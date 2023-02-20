`timescale 1ns/1ps
`default_nettype none

module mouse_position_tracker #(
        parameter COLUMNS = 640,
        parameter ROWS = 480
    )
    (
        input wire clk_i, reset_i,
        input wire [8:0] x_velocity_i, y_velocity_i,
        input wire en_i,
        output logic [$clog2(COLUMNS)-1:0] x_position_o,
        output logic [$clog2(ROWS)-1:0] y_position_o
    );

    // Declarations
    logic [$clog2(COLUMNS)-1:0] x_position_reg, x_position_next;
    logic [$clog2(ROWS)-1:0] y_position_reg, y_position_next;
    logic [7:0] twos_complement_x;
    logic [7:0] twos_complement_y;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
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
        if (en_i) begin
            if (x_velocity_i[8]) begin
                twos_complement_x = ~(x_velocity_i[7:0]) + 1;
                if ({2'b0, twos_complement_x} > x_position_reg) begin
                    x_position_next = 0;
                end else begin
                    x_position_next = x_position_reg - {2'b0, twos_complement_x};
                end
            end else begin
                if (({1'b0, x_velocity_i} + x_position_reg) > (COLUMNS - 1)) begin
                    x_position_next = COLUMNS - 1;
                end else begin
                    x_position_next = x_position_reg + x_velocity_i;
                end
            end
            if (y_velocity_i[8]) begin
                twos_complement_y = ~(y_velocity_i[7:0]) + 1;
                if ((twos_complement_y + y_position_reg) > (ROWS - 1)) begin
                    y_position_next = ROWS - 1;
                end else begin
                    y_position_next = y_position_reg + twos_complement_y;
                end
            end else begin
                if (y_velocity_i > y_position_reg) begin
                    y_position_next = 0;
                end else begin
                    y_position_next = y_position_reg - y_velocity_i;
                end
            end
        end
    end

    // Outputs
    assign x_position_o = x_position_reg;
    assign y_position_o = y_position_reg;

endmodule
