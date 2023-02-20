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
        output logic [ADDR_WIDTH-1:0] rd_address_o,
        output logic [ADDR_WIDTH-1:0] wr_address_o,
        output logic [DATA_WIDTH-1:0] wr_data_o,
        output logic wr_en_o,
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
    logic [ADDR_WIDTH-1:0] rd_address, wr_address;
    logic [DATA_WIDTH-1:0] wr_data;
    logic wr_en, done;

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
        wr_address = 0;
        wr_data = 0;
        wr_en = 0;
        done = 0;
        case (state_reg)
            IDLE : begin
                if (ready_i) begin
                    base_address_next = 0;
                    rd_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end
            end
            PIXEL_EMPTY : begin
                if (base_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    state_next = DRAW;
                end else if (pixel_state_i == 0) begin
                    base_address_next = base_address_reg + 1;
                    rd_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else begin
                    rd_address = base_address_next + ACTIVE_COLUMNS;
                    state_next = PIXEL_DOWN;
                end
            end
            PIXEL_DOWN : begin
                if ((base_address_reg + ACTIVE_COLUMNS) >= ((ACTIVE_COLUMNS*ACTIVE_ROWS) - 1)) begin
                    base_address_next = base_address_reg + 1;
                    rd_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else if (pixel_state_i == 1) begin
                    rd_address = base_address_next + ACTIVE_COLUMNS - 1;
                    state_next = PIXEL_DOWN_LEFT;
                end else begin
                    wr_address = base_address_reg + ACTIVE_COLUMNS;
                    wr_data = 1;
                    wr_en = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            PIXEL_DOWN_LEFT : begin
                if (pixel_state_i == 1) begin
                    rd_address = base_address_next + ACTIVE_COLUMNS + 1;
                    state_next = PIXEL_DOWN_RIGHT;
                end else begin
                    wr_address = base_address_reg + ACTIVE_COLUMNS - 1;
                    wr_data = 1;
                    wr_en = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            PIXEL_DOWN_RIGHT : begin
                if (pixel_state_i == 1) begin
                    base_address_next = base_address_reg + 1;
                    rd_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end else begin
                    wr_address = base_address_reg + ACTIVE_COLUMNS + 1;
                    wr_data = 1;
                    wr_en = 1;
                    state_next = DELETE_PIXEL;
                end
            end
            DELETE_PIXEL : begin
                base_address_next = base_address_reg + 1;
                rd_address = base_address_next;
                wr_address = base_address_reg;
                wr_data = 0;
                wr_en = 1;
                state_next = PIXEL_EMPTY;
            end
            DRAW : begin
                wr_address = 320;
                wr_data = 1;
                wr_en = 1;
                done = 1;
                state_next = IDLE;
            end
            default : state_next = IDLE;
        endcase
    end

    assign rd_address_o = rd_address;
    assign wr_address_o = wr_address;
    assign wr_data_o = wr_data;
    assign wr_en_o = wr_en;
    assign done_o = done;

endmodule
