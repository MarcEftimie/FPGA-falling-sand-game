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
        input wire draw_en_i,
        input wire [DATA_WIDTH-1:0] ram_rd_data_i, vram_rd_data_i,
        output logic [ADDR_WIDTH-1:0] ram_rd_address_o, vram_rd_address_o,
        output logic [ADDR_WIDTH-1:0] ram_wr_address_o, vram_wr_address_o,
        output logic [DATA_WIDTH-1:0] ram_wr_data_o, vram_wr_data_o,
        output logic ram_wr_en_o, vram_wr_en_o,
        output logic draw_en_o
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

    logic [ADDR_WIDTH-1:0] vram_wr_address_reg, vram_wr_address_next;
    logic [ADDR_WIDTH-1:0] ram_rd_address;
    logic [DATA_WIDTH-1:0] vram_wr_data;
    logic vram_wr_en;

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
        .pixel_state_i(vram_rd_data_i),
        .rd_address_o(vram_rd_address_o),
        .wr_address_o(ram_wr_address_o),
        .wr_data_o(ram_wr_data_o),
        .wr_en_o(ram_wr_en_o),
        .done_o(cell_redraw_done)
    );

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            vram_wr_address_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state_reg <= state_next;
            vram_wr_address_reg <= vram_wr_address_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        vram_wr_address_next = vram_wr_address_reg;
        tick_count_next = tick_count_reg;
        cell_redraw_ready = 0;
        vram_wr_data = 0;
        vram_wr_en = 0;
        draw_en_o = 0;
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
                    vram_wr_address_next = 0;
                    ram_rd_address = vram_wr_address_next;
                    state_next = WRITE_VRAM;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                    if (draw_en_i) begin
                        draw_en_o = 1;
                    end
                end
            end
            WRITE_VRAM : begin
                if (vram_wr_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    vram_wr_address_next = 0;
                    ram_rd_address = vram_wr_address_next;
                    state_next = DRAW;
                end else begin
                    vram_wr_address_next = vram_wr_address_reg + 1;
                    ram_rd_address = vram_wr_address_next;
                    vram_wr_data = ram_rd_data_i;
                    vram_wr_en = 1;
                end
            end
            default : state_next = IDLE;
        endcase
    end

    assign ram_rd_address_o = ram_rd_address;
    assign vram_wr_address_o = vram_wr_address_reg;
    assign vram_wr_data_o = vram_wr_data;
    assign vram_wr_en_o = vram_wr_en;

endmodule
