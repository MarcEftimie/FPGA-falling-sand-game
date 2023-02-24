`timescale 1ns/1ps
`default_nettype none

module cells_next_state
    #(
        parameter COLUMNS = 640,
        parameter ROWS = 480,
        parameter ADDR_WIDTH = $clog2(COLUMNS*ROWS),
        parameter DATA_WIDTH = 2
    )(
        input wire clk_i, reset_i,
        input wire ready_i,
        input wire [DATA_WIDTH-1:0] vram_rd_data,
        input wire [DATA_WIDTH-1:0] ram_rd_data,
        output logic [ADDR_WIDTH-1:0] vram_rd_address_o,
        output logic [ADDR_WIDTH-1:0] ram_rd_address_o,
        output logic [ADDR_WIDTH-1:0] vram_wr_address_o,
        output logic [ADDR_WIDTH-1:0] ram_wr_address_o,
        output logic [DATA_WIDTH-1:0] vram_wr_data_o,
        output logic [DATA_WIDTH-1:0] ram_wr_data_o,
        output logic vram_wr_en_o,
        output logic ram_wr_en_o,
        output logic done_o
    );

    typedef enum logic [3:0] {
        IDLE,
        PIXEL_EMPTY,
        PIXEL_DOWN,
        PIXEL_UP,
        PIXEL_DOWN_LEFT,
        PIXEL_DOWN_RIGHT,
        PIXEL_UP_LEFT,
        PIXEL_UP_RIGHT,
        PIXEL_LEFT,
        PIXEL_RIGHT,
        DELETE_PIXEL,
        SWAP_PIXEL
    } state_d;

    state_d state_reg, state_next;

    logic [ADDR_WIDTH-1:0] base_address_reg, base_address_next;
    logic [ADDR_WIDTH-1:0] vram_rd_address, ram_rd_address;
    logic [ADDR_WIDTH-1:0] vram_wr_address, ram_wr_address;
    logic [DATA_WIDTH-1:0] vram_wr_data, ram_wr_data;
    logic vram_wr_en, ram_wr_en;
    logic done;
    
    logic [DATA_WIDTH-1:0] base_pixel_state_reg, base_pixel_state_next;

    logic [2:0] pixel_surrounding_state_reg, pixel_surrounding_state_next;

    logic [2:0] random_counter_reg, random_counter_next;
    logic down_random, up_random, left_down_random, left_up_random, right_down_random, right_up_random,
          left_random, right_random;
    
    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            random_counter_reg <= 0;
        end else begin
            random_counter_reg <= random_counter_next;
        end
    end

    assign random_counter_next = LFSR_reg[7] ? random_counter_reg + 1 : random_counter_reg;

    logic [7:0] LFSR_reg, LFSR_next;

    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            LFSR_reg <= 8'd1;
        end else begin
            LFSR_reg <= LFSR_next;
        end
    end

    assign LFSR_next = {LFSR_reg[6:0], LFSR_reg[7] ^ LFSR_reg[5] ^ LFSR_reg[4] ^ LFSR_reg[3]};

    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= IDLE;
            base_address_reg <= 0;
            base_pixel_state_reg <= 0;
            pixel_surrounding_state_reg <= 0;
        end else begin
            state_reg <= state_next;
            base_address_reg <= base_address_next;
            base_pixel_state_reg <= base_pixel_state_next;
            pixel_surrounding_state_reg <= pixel_surrounding_state_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        base_address_next = base_address_reg;
        base_pixel_state_next = base_pixel_state_reg;
        pixel_surrounding_state_next = pixel_surrounding_state_reg;
        vram_rd_address = 0;
        ram_rd_address = 0;
        vram_wr_address = 0;
        ram_wr_address = 0;
        vram_wr_data = 0;
        ram_wr_data = 0;
        vram_wr_en = 0;
        ram_wr_en = 0;
        done = 0;

        down_random = 0;
        up_random = 0;
        left_down_random = 0;
        right_down_random = 0;
        left_up_random = 0;
        right_up_random = 0;
        left_random = 0;
        right_random = 0;

        case (state_reg)
            IDLE : begin
                if (ready_i) begin
                    base_address_next = 0;
                    base_pixel_state_next = 0;
                    vram_rd_address = base_address_next;
                    state_next = PIXEL_EMPTY;
                end
            end
            PIXEL_EMPTY : begin
                base_pixel_state_next = vram_rd_data;
                pixel_surrounding_state_next = 0;
                if (base_address_reg == COLUMNS*ROWS) begin
                    // All pixels redrawn
                    done = 1;
                    state_next = IDLE;
                end else if (vram_rd_data == 2'b00) begin
                    // Empty pixel
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_rd_address = vram_rd_address;
                    state_next = PIXEL_EMPTY;
                end else if (vram_rd_data == 2'b11) begin
                    vram_rd_address = base_address_reg - COLUMNS;
                    ram_rd_address = base_address_reg - COLUMNS;
                    state_next = PIXEL_UP;
                end else begin
                    // Check pixel down
                    vram_rd_address = base_address_reg + COLUMNS;
                    ram_rd_address = base_address_reg + COLUMNS;
                    state_next = PIXEL_DOWN;
                end
            end
            PIXEL_DOWN : begin
                pixel_surrounding_state_next[0] = (|vram_rd_data) | (|ram_rd_data);
                if ((base_address_reg + COLUMNS) >= ((COLUMNS*ROWS) - 1)) begin
                    // Pixel on bottom layer
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = PIXEL_EMPTY;
                end if ((base_pixel_state_reg == 2'b01) && (vram_rd_data == 2'b10)) begin
                    // Sand above water
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = 2'b10;
                    ram_wr_en = 1;
                    state_next = SWAP_PIXEL;
                end else begin
                    // Check pixel down left
                    vram_rd_address = base_address_reg + COLUMNS - 1;
                    ram_rd_address = base_address_reg + COLUMNS - 1;
                    state_next = PIXEL_DOWN_LEFT;
                end
            end
            PIXEL_UP : begin
                pixel_surrounding_state_next[0] = (|vram_rd_data) | (|ram_rd_data);
                if ((base_address_reg - COLUMNS) > (COLUMNS*ROWS)) begin
                    // Pixel on top layer
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                end else begin
                    // Check pixel up
                    vram_rd_address = base_address_reg - COLUMNS - 1;
                    ram_rd_address = base_address_reg - COLUMNS - 1;
                    state_next = PIXEL_UP_LEFT;
                end
            end
            SWAP_PIXEL : begin
                vram_wr_address = base_address_reg + COLUMNS;
                vram_wr_data = 0;
                vram_wr_en = 1;
                ram_wr_address = base_address_reg + COLUMNS;
                ram_wr_data = 2'b01;
                ram_wr_en = 1;
                state_next = DELETE_PIXEL;
            end
            PIXEL_DOWN_LEFT : begin
                pixel_surrounding_state_next[1] = (|vram_rd_data) | (|ram_rd_data);
                // Check pixel down right
                vram_rd_address = base_address_reg + COLUMNS + 1;
                ram_rd_address = base_address_reg + COLUMNS + 1;
                state_next = PIXEL_DOWN_RIGHT;
            end
            PIXEL_DOWN_RIGHT : begin
                pixel_surrounding_state_next[2] = (|vram_rd_data) | (|ram_rd_data);
                case (pixel_surrounding_state_next)
                    3'b000 : begin
                        if ((random_counter_reg == 0) ||
                            (random_counter_reg == 1) || 
                            (random_counter_reg == 2) || 
                            (random_counter_reg == 3) || 
                            (random_counter_reg == 4) || 
                            (random_counter_reg == 5)) begin
                            down_random = 1;
                        end else if (random_counter_reg == 6) begin
                            left_down_random = 1;
                        end else begin
                            right_down_random = 1;
                        end
                    end
                    // Down
                    3'b001 : begin
                        if ((random_counter_reg == 0) ||
                            (random_counter_reg == 1) || 
                            (random_counter_reg == 2) || 
                            (random_counter_reg == 3)) begin
                            down_random = 1;
                        end else begin
                            right_down_random = 1;
                        end
                    end
                    // Down Left
                    3'b010 : begin
                        if ((random_counter_reg == 0) || 
                        (random_counter_reg == 1) || 
                        (random_counter_reg == 2) || 
                        (random_counter_reg == 3) || 
                        (random_counter_reg == 4) ||
                        (random_counter_reg == 5)) begin
                            down_random = 1;
                        end else begin
                            right_down_random = 1;
                        end
                    end
                    // Down, Down Left
                    3'b011 : begin
                        right_down_random = 1;
                    end
                    // Down Right
                    3'b100 : begin
                        if ((random_counter_reg == 0) || 
                        (random_counter_reg == 1) || 
                        (random_counter_reg == 2) || 
                        (random_counter_reg == 3) || 
                        (random_counter_reg == 4) ||
                        (random_counter_reg == 5)) begin
                            down_random = 1;
                        end else begin
                            left_down_random = 1;                        
                        end
                    end
                    // Down, Down Right
                    3'b101 : begin
                        left_down_random = 1;
                    end
                    // Down Left, Down Right
                    3'b110 : begin
                        down_random = 1;
                    end
                    default : ;
                endcase

                // Move pixel to next location
                if (down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + COLUMNS;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (left_down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + COLUMNS - 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (right_down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_en = 1;
                    ram_wr_address = base_address_reg + COLUMNS + 1;
                    ram_wr_data = base_pixel_state_reg;
                    state_next = DELETE_PIXEL;
                end else begin
                    if (base_pixel_state_reg == 2'b10) begin
                        // Move to water specific checks
                        vram_rd_address = base_address_reg - 1;
                        ram_rd_address = base_address_reg - 1;
                        state_next = PIXEL_LEFT;
                    end else begin
                        // Finish sand state update
                        base_address_next = base_address_reg + 1;
                        vram_rd_address = base_address_next;
                        ram_wr_address = base_address_reg;
                        ram_wr_data = base_pixel_state_reg;
                        ram_wr_en = 1;
                        state_next = PIXEL_EMPTY;
                    end
                end
            end
            PIXEL_UP_LEFT : begin
                pixel_surrounding_state_next[1] = ((|vram_rd_data) | (|ram_rd_data));
                vram_rd_address = base_address_reg - COLUMNS + 1;
                ram_rd_address = base_address_reg - COLUMNS + 1;
                state_next = PIXEL_UP_RIGHT;
            end
            PIXEL_UP_RIGHT : begin
                pixel_surrounding_state_next[2] = ((|vram_rd_data) | (|ram_rd_data));
                case (pixel_surrounding_state_next)
                    3'b000 : begin
                        if ((random_counter_reg == 0) ||
                            (random_counter_reg == 1) || 
                            (random_counter_reg == 2) || 
                            (random_counter_reg == 3) || 
                            (random_counter_reg == 4) || 
                            (random_counter_reg == 5)) begin
                            up_random = 1;
                        end else if (random_counter_reg == 6) begin
                            left_up_random = 1;
                        end else begin
                            right_up_random = 1;
                        end
                    end
                    // Up
                    3'b001 : begin
                        if ((random_counter_reg == 0) ||
                            (random_counter_reg == 1) || 
                            (random_counter_reg == 2) || 
                            (random_counter_reg == 3)) begin
                            up_random = 1;
                        end else begin
                            right_up_random = 1;
                        end
                    end
                    // Up Left
                    3'b010 : begin
                        if ((random_counter_reg == 0) || 
                        (random_counter_reg == 1) || 
                        (random_counter_reg == 2) || 
                        (random_counter_reg == 3) || 
                        (random_counter_reg == 4) ||
                        (random_counter_reg == 5)) begin
                            up_random = 1;
                        end else begin
                            right_up_random = 1;
                        end
                    end
                    // Up, Up Left
                    3'b011 : begin
                        right_up_random = 1;
                    end
                    // Up Right
                    3'b100 : begin
                        if ((random_counter_reg == 0) || 
                        (random_counter_reg == 1) || 
                        (random_counter_reg == 2) || 
                        (random_counter_reg == 3) || 
                        (random_counter_reg == 4) ||
                        (random_counter_reg == 5)) begin
                            up_random = 1;
                        end else begin
                            left_up_random = 1;                        
                        end
                    end
                    // Up, Up Right
                    3'b101 : begin
                        left_up_random = 1;
                    end
                    // Up Left, Up Right
                    3'b110 : begin
                        up_random = 1;
                    end
                    default : ;
                endcase

                // Move pixel to next location
                if (up_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg - COLUMNS;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (left_up_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg - COLUMNS - 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (right_up_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_en = 1;
                    ram_wr_address = base_address_reg - COLUMNS + 1;
                    ram_wr_data = base_pixel_state_reg;
                    state_next = DELETE_PIXEL;
                end else begin
                    vram_rd_address = base_address_reg - 1;
                    ram_rd_address = base_address_reg - 1;
                    state_next = PIXEL_LEFT;
                end
            end
            PIXEL_LEFT : begin
                pixel_surrounding_state_next[0] = ((|vram_rd_data) | (|ram_rd_data));
                vram_rd_address = base_address_reg + 1;
                ram_rd_address = base_address_reg + 1;
                state_next = PIXEL_RIGHT;
            end
            PIXEL_RIGHT : begin
                pixel_surrounding_state_next[1] = ((|vram_rd_data) | (|ram_rd_data));
                case (pixel_surrounding_state_next[1:0])
                    2'b00 : begin
                        if ((random_counter_reg == 0) ||
                            (random_counter_reg == 1) || 
                            (random_counter_reg == 2) || 
                            (random_counter_reg == 3)) begin
                            right_random = 1;
                        end else begin
                            left_random = 1;
                        end
                    end
                    // Left
                    2'b01 : begin
                        right_random = 1;
                    end
                    // Right
                    2'b10 : begin
                        left_random = 1;
                    end
                    default : ;
                endcase
                // Move pixel to next location
                if (right_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (left_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg - 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else begin
                    // Finish water state update
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = PIXEL_EMPTY;
                end
            end
            DELETE_PIXEL : begin
                base_address_next = base_address_reg + 1;
                vram_rd_address = base_address_next;
                state_next = PIXEL_EMPTY;
            end
            default : state_next = IDLE;
        endcase
    end

    assign vram_rd_address_o = vram_rd_address;
    assign ram_rd_address_o = ram_rd_address;
    assign vram_wr_address_o = vram_wr_address;
    assign ram_wr_address_o = ram_wr_address;
    assign vram_wr_data_o = vram_wr_data;
    assign ram_wr_data_o = ram_wr_data;
    assign vram_wr_en_o = vram_wr_en;
    assign ram_wr_en_o = ram_wr_en;
    assign done_o = done;

endmodule
