`timescale 1ns/1ps
`default_nettype none

module sand_cell
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 1
    )(
        input wire clk_i, reset_i,
        input wire ready_i,
        input wire [ADDR_WIDTH-1:0] base_address_i,
        input wire [DATA_WIDTH-1:0] pixel_state_i,
        output logic [ADDR_WIDTH-1:0] read_address_o,
        output logic [ADDR_WIDTH-1:0] write_address_o,
        output logic [DATA_WIDTH-1:0] write_data_o,
        output logic wr_ena_o,
        output logic done_o
    );

    typedef enum logic [2:0] {
        IDLE,
        PIXEL_EMPTY,
        PIXEL_DOWN,
        PIXEL_DOWN_LEFT,
        PIXEL_DOWN_RIGHT,
        DELETE_PIXEL
    } state_d;

    state_d state_reg, state_next;

    logic [ADDR_WIDTH-1:0] read_address_reg, read_address_next;

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            read_address_reg <= 0;
        end else begin
            state_reg <= state_next;
            read_address_reg <= read_address_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        write_address_o = 0;
        write_data_o = 0;
        read_address_next = read_address_reg;
        wr_ena_o = 0;
        done_o = 0;
        case (state_reg)
            IDLE : begin
                if (ready_i) begin
                    read_address_next = base_address_i;
                    state_next = PIXEL_EMPTY;
                end
            end
            PIXEL_EMPTY : begin
                if (pixel_state_i == 0) begin
                    done_o = 1;
                    state_next = IDLE;
                end else begin
                    read_address_next = base_address_i + ACTIVE_COLUMNS;
                    state_next = PIXEL_DOWN;
                end
            end
            PIXEL_DOWN : begin
                if (pixel_state_i == 1) begin
                    state_next = IDLE;
                end else begin
                    write_address_o = base_address_i + ACTIVE_COLUMNS;
                    write_data_o = 1;
                    wr_ena_o = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            DELETE_PIXEL : begin
                write_address_o = base_address_i;
                write_data_o = 0;
                wr_ena_o = 1;
                done_o = 1;
                state_next = IDLE;
            end
            default : state_next = IDLE;
        endcase
    end

    assign read_address_o = read_address_next;

endmodule
