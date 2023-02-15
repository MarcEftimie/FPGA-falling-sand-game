`timescale 1ns/1ps
`default_nettype none

module game_state_controller
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 1,
        parameter FPS = 1
    )(
        input wire clk_i, reset_i,
        input wire [DATA_WIDTH-1:0] ram_read_data_i, vram_read_data_i,
        output logic [ADDR_WIDTH-1:0] ram_read_address_o, vram_read_address_o,
        output logic [ADDR_WIDTH-1:0] ram_write_address_o, vram_write_address_o,
        output logic [DATA_WIDTH-1:0] ram_write_data_o, vram_write_data_o,
        output logic wr_ram_ena_o, wr_vram_ena_o
    );

    typedef enum logic [1:0] {
        IDLE,
        REDRAW_FRAME,
        WAIT,
        WRITE_VRAM
    } state_d;

    state_d state_reg, state_next;

    logic [$clog2(FPS*100000000)-1:0] fps_count_reg, fps_count_next;

    logic [ADDR_WIDTH-1:0] base_address_reg, base_address_next;
    logic [ADDR_WIDTH-1:0] read_ram_address;

    logic cell_redraw_ready_reg, cell_redraw_ready_next;
    logic cell_redraw_done;

    sand_cell #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) SAND_CELL (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ready_i(cell_redraw_ready_reg),
        .base_address_i(base_address_reg),
        .pixel_state_i(vram_read_data_i),
        .read_address_o(vram_read_address_o),
        .write_address_o(ram_write_address_o),
        .write_data_o(ram_write_data_o),
        .wr_ena_o(wr_ram_ena_o),
        .done_o(cell_redraw_done)
    );

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            base_address_reg <= 0;
            fps_count_reg <= 0;
            cell_redraw_ready_reg <= 0;
        end else begin
            state_reg <= state_next;
            base_address_reg <= base_address_next;
            fps_count_reg <= fps_count_next;
            cell_redraw_ready_reg <= cell_redraw_ready_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        base_address_next = base_address_reg;
        fps_count_next = fps_count_reg;
        cell_redraw_ready_next = cell_redraw_ready_reg;
        vram_write_address_o = 0;
        vram_write_data_o = 0;
        wr_vram_ena_o = 0;
        case (state_reg)
            IDLE : begin
                fps_count_next = 0;
                base_address_next = 0;
                cell_redraw_ready_next = 1;
                state_next = REDRAW_FRAME;
            end
            REDRAW_FRAME : begin
                cell_redraw_ready_next = 0;
                fps_count_next = fps_count_reg + 1;
                if (base_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS - 1) begin
                    base_address_next = 0;
                    state_next = WAIT;
                end else if (cell_redraw_done) begin
                    cell_redraw_ready_next = 1;
                    base_address_next = base_address_reg + 1;
                end
            end
            WAIT : begin
                if (fps_count_reg == FPS*100000000) begin // 100000000
                    fps_count_next = 0;
                    // ram_read_address_o = base_address_reg;
                    base_address_next = base_address_reg + 1;
                    state_next = WRITE_VRAM;
                end else begin
                    fps_count_next = fps_count_reg + 1;
                end
            end
            WRITE_VRAM : begin
                if (base_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    base_address_next = 0;
                    state_next = IDLE;
                end else begin
                    base_address_next = base_address_reg + 1;
                    // ram_read_address_o = base_address_reg;
                    vram_write_address_o = base_address_reg;
                    vram_write_data_o = ram_read_data_i;
                    wr_vram_ena_o = 1;
                end
            end
            default : state_next = IDLE;
        endcase
    end

    assign ram_read_address_o = (state_reg == WRITE_VRAM || state_reg == WAIT) ? base_address_next : read_ram_address;

endmodule
