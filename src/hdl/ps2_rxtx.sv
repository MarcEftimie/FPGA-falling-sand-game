`timescale 1ns/1ps
`default_nettype none

module p2s_rxtx
    (
        input wire clk_i, reset_i,
        input wire tx_en_i,
        input logic [7:0] tx_data_i,
        inout wire ps2d_io, ps2c_io,
        output logic [7:0] rx_data_o,
        output wire rx_done_o, tx_done_o
    );

    // Declarations
    logic tx_idle;

    ps2_rx PS2_RX (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .rx_en_i(tx_idle),
        .ps2d_i(ps2d_io),
        .ps2c_i(ps2c_io),
        .rx_data_o(rx_data_o),
        .done_o(rx_done_o)
    );

    ps2_tx PS2_TX (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tx_en_i(tx_en_i),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .tx_data_i(tx_data_i),
        .idle_o(tx_idle),
        .done_o(tx_done_o)
    );

endmodule
