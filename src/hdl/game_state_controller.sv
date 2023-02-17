`timescale 1ns/1ps
`default_nettype none

module game_state_controller
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 1
    )(
        input wire clk_i, reset_i,
        input wire [26:0] tick_10_ns,
        input wire [DATA_WIDTH-1:0] ram_read_data_i, vram_read_data_i,
        output logic [ADDR_WIDTH-1:0] ram_read_address_o, vram_read_address_o,
        output logic [ADDR_WIDTH-1:0] ram_write_address_o, vram_write_address_o,
        output logic [DATA_WIDTH-1:0] ram_write_data_o, vram_write_data_o,
        output logic ram_write_ena_o, vram_write_ena_o
    );

    typedef enum logic [2:0] {
        IDLE,
        REDRAW_FRAME,
        WAIT,
        WRITE_VRAM,
        DRAW
    } state_d;

    state_d state_reg, state_next;

    logic [26:0] tick_count_reg, tick_count_next;

    logic [ADDR_WIDTH-1:0] vram_write_address_reg, vram_write_address_next;
    logic [ADDR_WIDTH-1:0] ram_read_address;
    logic [DATA_WIDTH-1:0] vram_write_data;
    logic vram_write_ena;

    logic cell_redraw_ready, cell_redraw_done;

    cells_next_state #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) CELLS_NEXT_STATE (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ready_i(cell_redraw_ready),
        .pixel_state_i(vram_read_data_i),
        .read_address_o(vram_read_address_o),
        .write_address_o(ram_write_address_o),
        .write_data_o(ram_write_data_o),
        .wr_ena_o(ram_write_ena_o),
        .done_o(cell_redraw_done)
    );

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            vram_write_address_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state_reg <= state_next;
            vram_write_address_reg <= vram_write_address_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        vram_write_address_next = vram_write_address_reg;
        tick_count_next = tick_count_reg;
        cell_redraw_ready = 0;
        vram_write_data = 0;
        vram_write_ena = 0;
        case (state_reg)
            IDLE : begin
                tick_count_next = 0;
                cell_redraw_ready = 1;
                state_next = REDRAW_FRAME;
            end
            REDRAW_FRAME : begin
                tick_count_next = tick_count_reg + 1;
                if (cell_redraw_done) begin
                    state_next = WAIT;
                end
            end
            WAIT : begin
                if (tick_count_reg == tick_10_ns) begin // 100000000 - (ACTIVE_COLUMNS*ACTIVE_ROWS)
                    tick_count_next = 0;
                    vram_write_address_next = 0;
                    ram_read_address = vram_write_address_next;
                    state_next = WRITE_VRAM;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                end
            end
            WRITE_VRAM : begin
                if (vram_write_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    vram_write_address_next = 0;
                    ram_read_address = vram_write_address_next;
                    state_next = DRAW;
                end else begin
                    vram_write_address_next = vram_write_address_reg + 1;
                    ram_read_address = vram_write_address_next;
                    vram_write_data = ram_read_data_i;
                    vram_write_ena = 1;
                end
            end
            default : state_next = IDLE;
        endcase
    end

    assign ram_read_address_o = ram_read_address;
    assign vram_write_address_o = vram_write_address_reg;
    assign vram_write_data_o = vram_write_data;
    assign vram_write_ena_o = vram_write_ena;

endmodule
