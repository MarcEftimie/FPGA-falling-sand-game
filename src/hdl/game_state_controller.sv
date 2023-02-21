`timescale 1ns/1ps
`default_nettype none

module game_state_controller
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter DATA_WIDTH = 2
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
        WRITE_VRAM,
        CLEAR_RAM,
        WAIT
    } state_d;

    state_d state_reg, state_next;

    logic [26:0] tick_count_reg, tick_count_next;

    logic [ADDR_WIDTH-1:0] vram_wr_address_reg, vram_wr_address_next;
    logic [ADDR_WIDTH-1:0] ram_wr_address_reg, ram_wr_address_next;
    logic [ADDR_WIDTH-1:0] ram_wr_address;
    logic [ADDR_WIDTH-1:0] ram_rd_address;
    logic [DATA_WIDTH-1:0] vram_wr_data;
    logic [DATA_WIDTH-1:0] ram_wr_data;
    logic vram_wr_en, ram_wr_en;

    logic cell_redraw_ready, cell_redraw_done;

    logic [ADDR_WIDTH-1:0] cns_vram_rd_address;
    logic [ADDR_WIDTH-1:0] cns_ram_rd_address;
    logic [ADDR_WIDTH-1:0] cns_vram_wr_address;
    logic [ADDR_WIDTH-1:0] cns_ram_wr_address;
    logic [DATA_WIDTH-1:0] cns_vram_wr_data;
    logic [DATA_WIDTH-1:0] cns_ram_wr_data;
    logic cns_vram_wr_en;
    logic cns_ram_wr_en;
    
    

    cells_next_state #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) CELLS_NEXT_STATE (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ready_i(cell_redraw_ready),
        .vram_rd_data(vram_rd_data_i),
        .ram_rd_data(ram_rd_data_i),
        .vram_rd_address_o(cns_vram_rd_address),
        .ram_rd_address_o(cns_ram_rd_address),
        .vram_wr_address_o(cns_vram_wr_address),
        .ram_wr_address_o(cns_ram_wr_address),
        .vram_wr_data_o(cns_vram_wr_data),
        .ram_wr_data_o(cns_ram_wr_data),
        .vram_wr_en_o(cns_vram_wr_en),
        .ram_wr_en_o(cns_ram_wr_en),
        .done_o(cell_redraw_done)
    );

    always_ff @(posedge clk_i, posedge reset_i ) begin
        if (reset_i) begin
            state_reg <= IDLE;
            vram_wr_address_reg <= 0;
            ram_wr_address_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state_reg <= state_next;
            vram_wr_address_reg <= vram_wr_address_next;
            ram_wr_address_reg <= ram_wr_address_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        vram_wr_address_next = vram_wr_address_reg;
        ram_wr_address_next = ram_wr_address_reg;
        tick_count_next = tick_count_reg;
        ram_wr_address = 0;
        ram_rd_address = 0;
        cell_redraw_ready = 0;
        vram_wr_data = 0;
        vram_wr_en = 0;
        ram_wr_en = 0;
        draw_en_o = 0;
        case (state_reg)
            IDLE : begin
                tick_count_next = 0;
                cell_redraw_ready = 1;
                state_next = REDRAW_FRAME;
            end
            REDRAW_FRAME : begin
                // tick_count_next = tick_count_reg + 1;
                if (cell_redraw_done) begin
                    vram_wr_address_next = 0;
                    state_next = WRITE_VRAM;
                end
            end
            WRITE_VRAM : begin
                if (vram_wr_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    ram_wr_address_next = 0;
                    state_next = WAIT;
                end else begin
                    vram_wr_address_next = vram_wr_address_reg + 1;
                    ram_rd_address = vram_wr_address_next;
                    ram_wr_address_next = ram_rd_address;
                end
                vram_wr_data = ram_rd_data_i;
                vram_wr_en = 1;
                ram_wr_data = 0;
                ram_wr_en = 1;
            end
            CLEAR_RAM : begin
                if (ram_wr_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    ram_wr_address_next = 0;
                    state_next = WAIT;
                end else begin
                    ram_wr_address_next = ram_wr_address_reg + 1;
                end
                ram_wr_data = 0;
                ram_wr_en = 1;
            end
            WAIT : begin
                if (tick_count_reg == tick_10_ns) begin // 100000000 - (ACTIVE_COLUMNS*ACTIVE_ROWS)
                    state_next = IDLE;
                end else begin
                    tick_count_next = tick_count_reg + 1;
                    if (draw_en_i) begin
                        draw_en_o = 1;
                    end
                end
            end
            default : state_next = IDLE;
        endcase
    end

    assign vram_rd_address_o = cns_vram_rd_address;
    assign ram_rd_address_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? ram_rd_address : cns_ram_rd_address;
    assign vram_wr_address_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? vram_wr_address_reg : cns_vram_wr_address;
    assign ram_wr_address_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? ram_wr_address_reg : cns_ram_wr_address;
    assign vram_wr_data_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? vram_wr_data : cns_vram_wr_data;
    assign ram_wr_data_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? ram_wr_data : cns_ram_wr_data;
    assign vram_wr_en_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? vram_wr_en : cns_vram_wr_en;
    assign ram_wr_en_o = ((state_reg == CLEAR_RAM) || (state_reg == WRITE_VRAM)) ? ram_wr_en : cns_ram_wr_en;

endmodule
