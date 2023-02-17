`timescale 1ns/1ps
`default_nettype none

module mouse
    (
        input wire clk_i, reset_i,
        inout wire ps2d_io, ps2c_io,
        output logic [8:0] x_o, y_o,
        output logic [2:0] btn_o,
        output logic done_o
    );

    // Declarations
    typedef enum logic [2:0] {
        SEND_INIT_PACKET,
        WAIT,
        RECEIVE_INIT_PACKET,
        RECEIVE_PACKET_1,
        RECEIVE_PACKET_2,
        RECEIVE_PACKET_3,
        DONE
    } state_d;

    state_d state_reg, state_next;

    logic tx_en;
    logic [7:0] rx_data, tx_data;
    logic rx_done, tx_done;

    ps2_rxtx PS2RXTX(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tx_en_i(tx_en),
        .tx_data_i(tx_data),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .rx_data_o(rx_data),
        .rx_done_o(rx_done),
        .tx_done_o(tx_done)
    );

    logic [8:0] x_mouse_pos_reg, x_mouse_pos_next;
    logic [8:0] y_mouse_pos_reg, y_mouse_pos_next;
    logic [2:0] btn_mouse_reg, btn_mouse_next;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= SEND_INIT_PACKET;
            x_mouse_pos_reg <= 0;
            y_mouse_pos_reg <= 0;
            btn_mouse_reg <= 0;
        end else begin
            state_reg <= state_next;
            x_mouse_pos_reg <= x_mouse_pos_next;
            y_mouse_pos_reg <= y_mouse_pos_next;
            btn_mouse_reg <= btn_mouse_next;
        end
    end

    // Next State Logic
    always_comb begin
        state_next = state_reg;
        tx_en = 0;
        done_o = 0;
        x_mouse_pos_next = x_mouse_pos_reg;
        y_mouse_pos_next = y_mouse_pos_reg;
        btn_mouse_next = btn_mouse_reg;
        case (state_reg)
            SEND_INIT_PACKET : begin
                tx_en = 1;
                state_next = WAIT;
            end
            WAIT : begin
                if (tx_done) begin
                    state_next = RECEIVE_INIT_PACKET;
                end
            end
            RECEIVE_INIT_PACKET : begin
                if (rx_done) begin
                    state_next = RECEIVE_PACKET_1;
                end
            end
            RECEIVE_PACKET_1 : begin
                if (rx_done) begin
                    x_mouse_pos_next[8] = rx_data[4];
                    y_mouse_pos_next[8] = rx_data[5];
                    btn_mouse_next = rx_data[2:0];
                    state_next = RECEIVE_PACKET_2;
                end
            end
            RECEIVE_PACKET_2 : begin
                if (rx_done) begin
                    x_mouse_pos_next[7:0] = rx_data;
                    state_next = RECEIVE_PACKET_3;
                end
            end
            RECEIVE_PACKET_3 : begin
                if (rx_done) begin
                    y_mouse_pos_next[7:0] = rx_data;
                    state_next = DONE;
                end
            end
            DONE : begin
                done_o = 1;
                state_next = RECEIVE_PACKET_1;
            end
            default : begin
                state_next = SEND_INIT_PACKET;
            end
        endcase
    end

    assign tx_data = 8'hF4;

    // Outputs
    assign x_o = x_mouse_pos_reg;
    assign y_o = y_mouse_pos_reg;
    assign btn_o = btn_mouse_reg;

endmodule
