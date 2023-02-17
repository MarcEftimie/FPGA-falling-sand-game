`timescale 1ns/1ps
`default_nettype none

module ps2_rx
    (
        input wire clk_i, reset_i,
        input wire rx_en_i,
        input wire ps2d_i, ps2c_i,
        output logic [7:0] rx_data_o,
        output logic done_o
    );

    // Declarations
    typedef enum logic [1:0] {
        IDLE,
        DATA,
        DONE
    } state_d;

    state_d state_reg, state_next;

    logic [7:0] filter_reg, filter_next;
    logic filter_ps2c_reg, filter_ps2c_next;
    logic falling_edge;
    
    logic [10:0] rx_data_reg, rx_data_next;

    logic [3:0] bit_count_reg, bit_count_next;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= IDLE;
            filter_reg <= 0;
            bit_count_reg <= 0;
            filter_ps2c_reg <= 0;
            rx_data_reg <= 0;
        end else begin
            state_reg <= state_next;
            bit_count_reg <= bit_count_next;
            filter_reg <= filter_next;
            filter_ps2c_reg <= filter_ps2c_next;
            rx_data_reg <= rx_data_next;
        end
    end

    // Next State Logic
    always_comb begin
        state_next = state_reg;
        bit_count_next = bit_count_reg;
        rx_data_next = rx_data_reg;
        done_o = 0;
        case (state_reg)
            IDLE : begin
                if (rx_en_i & falling_edge) begin
                    bit_count_next = 8;
                    rx_data_next = 0;
                    state_next = DATA;
                end
            end
            DATA : begin
                if (falling_edge) begin
                    rx_data_next = {ps2d_i, rx_data_reg[10:1]};
                    if (bit_count_reg == 0) begin
                        state_next = DONE;
                    end else begin
                        bit_count_next = bit_count_reg - 1;
                    end
                end
            end
            DONE : begin
                done_o = 1;
                state_next = IDLE;
            end
            default : begin
                state_next = IDLE;
            end
        endcase
    end

    assign filter_next = {ps2c_i, filter_reg[7:1]};
    assign filter_ps2c_next = &filter_reg ? 1'b1 :
                              |filter_reg ? 1'b0 : filter_ps2c_reg;
    assign falling_edge = filter_ps2c_next & ~filter_ps2c_reg;

    // Outputs
    assign rx_data_o = rx_data_reg[8:1];

endmodule
