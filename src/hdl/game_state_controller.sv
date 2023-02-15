`timescale 1ns/1ps
`default_nettype none

module game_state_controller
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 1,
        parameter TICK_10_NS = 100000000 //100000000
    )(
        input wire clk_i, reset_i,
        input wire [DATA_WIDTH-1:0] ram_read_data_i, vram_read_data_i,
        output logic [ADDR_WIDTH-1:0] ram_read_address_o, vram_read_address_o,
        output logic [ADDR_WIDTH-1:0] ram_write_address_o, vram_write_address_o,
        output logic [DATA_WIDTH-1:0] ram_write_data_o, vram_write_data_o,
        output logic ram_write_ena_o, vram_write_ena_o
    );

    typedef enum logic [2:0] {
        IDLE,
        DELAY,
        REDRAW_FRAME,
        WAIT,
        WRITE_VRAM
    } state_d;

    state_d state_reg, state_next;

    logic [$clog2(TICK_10_NS)-1:0] tick_count_reg, tick_count_next;

    logic [ADDR_WIDTH-1:0] write_vram_address_reg, write_vram_address_next;
    logic [ADDR_WIDTH-1:0] read_ram_address;
    logic [DATA_WIDTH-1:0] vram_write_data;
    logic vram_write_ena;

    logic cell_redraw_ready, cell_redraw_done;

    sand_cell #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) SAND_CELL (
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
            write_vram_address_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state_reg <= state_next;
            write_vram_address_reg <= write_vram_address_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        write_vram_address_next = write_vram_address_reg;
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
                if (tick_count_reg == ((TICK_10_NS))) begin // 100000000 - (ACTIVE_COLUMNS*ACTIVE_ROWS)
                    tick_count_next = 0;
                    write_vram_address_next = 0;
                    read_ram_address = write_vram_address_next;
                    state_next = WRITE_VRAM;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                end
            end
            WRITE_VRAM : begin
                if (write_vram_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    write_vram_address_next = 0;
                    read_ram_address = write_vram_address_next;
                    state_next = IDLE;
                end else begin
                    write_vram_address_next = write_vram_address_reg + 1;
                    read_ram_address = write_vram_address_next;
                    vram_write_data = ram_read_data_i;
                    vram_write_ena = 1;
                end
            end
            default : state_next = IDLE;
        endcase
    end

    assign ram_read_address_o = read_ram_address;
    assign vram_write_address_o = write_vram_address_reg;
    assign vram_write_data_o = vram_write_data;
    assign vram_write_ena_o = vram_write_ena;

endmodule
