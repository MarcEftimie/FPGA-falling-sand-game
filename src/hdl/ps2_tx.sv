`timescale 1ns/1ps
`default_nettype none

module ps2_tx
    (
        input wire clk_i, reset_i,
        input wire tx_en_i,
        inout wire ps2d_io, ps2c_io,
        input wire [7:0] tx_data_i,
        output logic idle_o, done_o
    );

    // Declarations
    typedef enum logic [2:0] {
        IDLE,
        REQUEST_TO_SEND,
        START,
        DATA,
        STOP
    } state_d;

    state_d state_reg, state_next;

    logic [7:0] filter_reg, filter_next;
    logic filter_ps2c_reg, filter_ps2c_next;
    logic falling_edge;

    logic [7:0] tx_data_reg, tx_data_next;
    logic ps2d_tri, ps2c_tri;
    logic ps2d, ps2c;

    logic [12:0] delay_count_reg, delay_count_next;
    logic [3:0] bit_count_reg, bit_count_next;

    // Registers
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= IDLE;
            filter_reg <= 0;
            delay_count_reg <= 0;
            bit_count_reg <= 0;
            filter_ps2c_reg <= 0;
            tx_data_reg <= 0;
        end else begin
            state_reg <= state_next;
            delay_count_reg <= delay_count_next;
            bit_count_reg <= bit_count_next;
            filter_reg <= filter_next;
            filter_ps2c_reg <= filter_ps2c_next;
            tx_data_reg <= tx_data_next;
        end
    end

    // Next State Logic
    always_comb begin
        state_next = state_reg;
        delay_count_next = delay_count_reg;
        bit_count_next = bit_count_reg;
        tx_data_next = tx_data_reg;
        delay_count_next = delay_count_reg;
        ps2d = 1;
        ps2c = 1;
        ps2d_tri = 0;
        ps2c_tri = 0;
        idle_o = 0;
        done_o = 0;
        case (state_reg)
            IDLE : begin
                if (tx_en_i) begin
                    delay_count_next = 13'h1FFF;
                    bit_count_next = 8;
                    tx_data_next = tx_data_i;
                    state_next = REQUEST_TO_SEND;
                end else begin
                    idle_o = 1;
                end
            end
            REQUEST_TO_SEND : begin
                ps2c_tri = 1;
                ps2c = 0;
                delay_count_next = delay_count_reg - 1;
                if (delay_count_next == 0) begin
                    state_next = START;
                end
            end
            START : begin
                ps2d_tri = 1;
                ps2d = 0;
                if (falling_edge) begin
                    state_next = DATA;
                end
            end
            DATA : begin
                ps2d_tri = 1;
                ps2d = tx_data_reg[0];
                if (falling_edge) begin
                    tx_data_next = tx_data_reg >> 1;
                    if (bit_count_reg == 0) begin
                        state_next = STOP;
                    end else begin
                        bit_count_next = bit_count_reg - 1;
                    end
                end
            end
            STOP : begin
                if (falling_edge) begin
                    done_o = 1;
                    state_next = IDLE;
                end
            end
            default : begin
                state_next = IDLE;
            end
        endcase
    end

    assign filter_next = {ps2c, filter_reg[7:1]};
    assign filter_ps2c_next = &filter_reg ? 1'b1 :
                              |filter_reg ? 1'b0 : filter_ps2c_reg;
    assign falling_edge = filter_ps2c_next & ~filter_ps2c_reg;

    // Outputs
    assign ps2d_io = ps2d_tri ? ps2d : 1'bz;
    assign ps2c_io = ps2c_tri ? ps2c : 1'bz;

endmodule
