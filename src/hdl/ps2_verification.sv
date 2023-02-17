`timescale 1ns/1ps
`default_nettype none

module mouse_led
    (
        input wire clk_i, reset_i,
        input wire [7:0] sw_i,
        input wire btn_i,
        inout wire ps2d_io, ps2c_io,
        output logic TX_serial
    );

    // Declarations
    typedef enum logic [1:0] {
        IDLE,
        SEND1,
        SEND0,
        SENDB
    } state_d;

    state_d state_reg, state_next;
    logic [7:0] rx_data;
    logic [7:0] w_data;
    logic psrx_done, wr_ps2;
    logic [3:0] hex_in;
    logic [7:0] ascii_code;
    logic wr_uart;

    assign wr_ps2 = btn_i;

    UART_TX UART_TX(
        .clk(clk_i),
        .rst(reset_i),
        .TX_byte(w_data),
        .TX_DV(wr_uart),
        .TX_serial(TX_serial)
    );

    ps2_rxtx PS2RXTX(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tx_en_i(wr_ps2),
        .tx_data_i(8'hf4),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .rx_data_o(rx_data),
        .rx_done_o(),
        .tx_done_o(psrx_done)
    );

    logic [8:0] x_mouse_pos_reg, x_mouse_pos_next;
    logic [8:0] y_mouse_pos_reg, y_mouse_pos_next;
    logic [2:0] btn_mouse_reg, btn_mouse_next;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    // Next State Logic
    always_comb begin
        wr_uart = 0;
        w_data = 8'h20;
        state_next = state_reg;
        case (state_reg)
            IDLE : begin
                if (psrx_done) begin
                    state_next = SEND1;
                end
            end
            SEND1 : begin
                w_data = ascii_code;
                wr_uart = 1;
                state_next = SEND0;
            end
            SEND0 : begin
                w_data = ascii_code;
                wr_uart = 1;
                state_next = SENDB;
            end
            SENDB : begin
                w_data = 8'h20;
                wr_uart = 1;
                state_next = IDLE;
            end
        endcase
    end

    assign hex_in = (state_reg==SEND1) ? rx_data[7:4] : rx_data[3:0];

    always_comb begin
        case (hex_in)
            4'h0: ascii_code = 8'h30;
            4'h1: ascii_code = 8'h31;
            4'h2: ascii_code = 8'h32;
            4'h3: ascii_code = 8'h33;
            4'h4: ascii_code = 8'h34;
            4'h5: ascii_code = 8'h35;
            4'h6: ascii_code = 8'h36;
            4'h7: ascii_code = 8'h37;
            4'h8: ascii_code = 8'h38;
            4'h9: ascii_code = 8'h39;
            4'ha: ascii_code = 8'h41;
            4'hb: ascii_code = 8'h42;
            4'hc: ascii_code = 8'h43;
            4'hd: ascii_code = 8'h44;
            4'he: ascii_code = 8'h45;
            default : ascii_code = 8'h46;
        endcase
    end

endmodule
