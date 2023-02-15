`timescale 1ns/1ps
`default_nettype none

module cells_next_state
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 1
    )(
        input wire clk_i, reset_i,
        input wire ready_i,
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
        DELETE_PIXEL,
        DRAW
    } state_d;

    state_d state_reg, state_next;

    logic [ADDR_WIDTH-1:0] base_address_reg, base_address_next;
    logic [ADDR_WIDTH-1:0] read_address, write_address;
    logic [DATA_WIDTH-1:0] write_data;
    logic wr_ena, done;

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            base_address_reg <= 0;
        end else begin
            state_reg <= state_next;
            base_address_reg <= base_address_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        base_address_next = base_address_reg;
        write_address = 0;
        write_data = 0;
        wr_ena = 0;
        done = 0;
        case (state_reg)
            IDLE : begin
                if (ready_i) begin
                    base_address_next = 0;
                    read_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end
            end
            PIXEL_EMPTY : begin
                if (base_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    state_next = DRAW;
                end else if (pixel_state_i == 0) begin
                    base_address_next = base_address_reg + 1;
                    read_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else begin
                    read_address = base_address_next + ACTIVE_COLUMNS;
                    state_next = PIXEL_DOWN;
                end
            end
            PIXEL_DOWN : begin
                if ((base_address_reg + ACTIVE_COLUMNS) > (ACTIVE_COLUMNS*ACTIVE_ROWS)) begin
                    base_address_next = base_address_reg + 1;
                    read_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else if (pixel_state_i == 1) begin
                    read_address = base_address_next + ACTIVE_COLUMNS - 1;
                    state_next = PIXEL_DOWN_LEFT;
                end else begin
                    write_address = base_address_reg + ACTIVE_COLUMNS;
                    write_data = 1;
                    wr_ena = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            PIXEL_DOWN_LEFT : begin
                if (pixel_state_i == 1) begin
                    read_address = base_address_next + ACTIVE_COLUMNS + 1;
                    state_next = PIXEL_DOWN_RIGHT;
                end else begin
                    write_address = base_address_reg + ACTIVE_COLUMNS - 1;
                    write_data = 1;
                    wr_ena = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            PIXEL_DOWN_RIGHT : begin
                if (pixel_state_i == 1) begin
                    base_address_next = base_address_reg + 1;
                    read_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else begin
                    write_address = base_address_reg + ACTIVE_COLUMNS + 1;
                    write_data = 1;
                    wr_ena = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            DELETE_PIXEL : begin
                base_address_next = base_address_reg + 1;
                read_address = base_address_next;
                write_address = base_address_reg;
                write_data = 0;
                wr_ena = 1;
                state_next = PIXEL_EMPTY;
            end
            DRAW : begin
                write_address = 320;
                write_data = 1;
                wr_ena = 1;
                done = 1;
                state_next = IDLE;
            end
            default : state_next = IDLE;
        endcase
    end

    assign read_address_o = read_address;
    assign write_address_o = write_address;
    assign write_data_o = write_data;
    assign wr_ena_o = wr_ena;
    assign done_o = done;

endmodule
