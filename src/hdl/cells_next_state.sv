`timescale 1ns/1ps
`default_nettype none

module cells_next_state
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
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
        PIXEL_DOWN_LEFT,
        PIXEL_DOWN_RIGHT,
        PIXEL_LEFT,
        PIXEL_RIGHT,
        DELETE_PIXEL,
        DRAW
    } state_d;

    state_d state_reg, state_next;

    logic [ADDR_WIDTH-1:0] base_address_reg, base_address_next;
    logic [ADDR_WIDTH-1:0] vram_rd_address, ram_rd_address;
    logic [ADDR_WIDTH-1:0] vram_wr_address, ram_wr_address;
    logic [DATA_WIDTH-1:0] vram_wr_data, ram_wr_data;
    logic vram_wr_en, ram_wr_en;
    logic done;
    
    logic [DATA_WIDTH-1:0] base_pixel_state_reg, base_pixel_state_next;

    logic [4:0] pixel_surrounding_state_reg, pixel_surrounding_state_next;

    logic [3:0] random_counter_reg, random_counter_next;
    logic down_random, left_down_random, right_down_random;
    
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

    // INCLUDE THE RAM CHECK IN THE ACTUAL CHECKS WITH PIXEL_STATE_I

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

        // Check empty
        // Check down
        // Check down right
        // Check down left
        // Down gets 1/2
        // Bottom right gets 1/4
        // Bottom left gets 1/4
        // [BL 0 BR 0 DOWN 0]

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
                if (base_address_reg == ACTIVE_COLUMNS*ACTIVE_ROWS) begin
                    // All pixels redrawn
                    done = 1;
                    state_next = IDLE;
                end else if (vram_rd_data == 2'b00) begin
                    // Empty pixel
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_rd_address = vram_rd_address;
                    state_next = PIXEL_EMPTY;
                end else begin
                    // Check pixel down
                    vram_rd_address = base_address_reg + ACTIVE_COLUMNS;
                    ram_rd_address = base_address_reg + ACTIVE_COLUMNS;
                    state_next = PIXEL_DOWN;
                end
            end
            PIXEL_DOWN : begin
                pixel_surrounding_state_next[0] = (|vram_rd_data) | (|ram_rd_data);
                if ((base_address_reg + ACTIVE_COLUMNS) >= ((ACTIVE_COLUMNS*ACTIVE_ROWS) - 1)) begin
                    // Pixel on bottom layer
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = PIXEL_EMPTY;
                end else begin
                    // Check pixel down left
                    vram_rd_address = base_address_reg + ACTIVE_COLUMNS - 1;
                    ram_rd_address = base_address_reg + ACTIVE_COLUMNS - 1;
                    state_next = PIXEL_DOWN_LEFT;
                end
            end
            PIXEL_DOWN_LEFT : begin
                pixel_surrounding_state_next[1] = (|vram_rd_data) | (|ram_rd_data);
                // Check pixel down right
                vram_rd_address = base_address_reg + ACTIVE_COLUMNS + 1;
                ram_rd_address = base_address_reg + ACTIVE_COLUMNS + 1;
                state_next = PIXEL_DOWN_RIGHT;
            end
            PIXEL_DOWN_RIGHT : begin
                pixel_surrounding_state_next[2] = (|vram_rd_data) | (|ram_rd_data);
                down_random = 0;
                left_down_random = 0;
                right_down_random = 0;
                case (pixel_surrounding_state_next)
                    5'b00000 : begin
                        down_random = (random_counter_reg == 0) || (random_counter_reg == 1);
                        left_down_random = (random_counter_reg == 2);
                        right_down_random = (random_counter_reg == 3);
                    end
                    // Down
                    5'b00001 : begin
                        left_down_random = (random_counter_reg == 0) || (random_counter_reg == 1);
                        right_down_random = (random_counter_reg == 2) || (random_counter_reg == 3);
                    end
                    // Down Left
                    5'b00010 : begin
                        down_random = (random_counter_reg == 0) || (random_counter_reg == 1) || (random_counter_reg == 2);
                        right_down_random = (random_counter_reg == 3);
                    end
                    // Down, Down Left
                    5'b00011 : begin
                        right_down_random = 1;
                    end
                    // Down Right
                    5'b00100 : begin
                        down_random = (random_counter_reg == 0) || (random_counter_reg == 1) || (random_counter_reg == 2);
                        left_down_random = (random_counter_reg == 3);
                    end
                    // Down, Down Right
                    5'b00101 : begin
                        left_down_random = 1;
                    end
                    // Down Left, Down Right
                    5'b00110 : begin
                        down_random = 1;
                    end
                    default : ;
                endcase

                if (down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + ACTIVE_COLUMNS;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (left_down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + ACTIVE_COLUMNS - 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else if (right_down_random) begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + ACTIVE_COLUMNS + 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
                end else begin
                    if (base_pixel_state_reg == 2'b10) begin
                        
                    end else begin
                        base_address_next = base_address_reg + 1;
                        vram_rd_address = base_address_next;
                        ram_wr_address = base_address_reg;
                        ram_wr_data = base_pixel_state_reg;
                        ram_wr_en = 1;
                        state_next = PIXEL_EMPTY;
                    end
                end
                // if ((|vram_rd_data) | (|ram_rd_data)) begin
                //     if (base_pixel_state_reg == 2'b10) begin
                //         vram_rd_address = base_address_reg - 1;
                //         ram_rd_address = base_address_reg - 1;
                //         state_next = PIXEL_LEFT;
                //     end else begin
                //         base_address_next = base_address_reg + 1;
                //         vram_rd_address = base_address_next;
                //         ram_wr_address = base_address_reg;
                //         ram_wr_data = base_pixel_state_reg;
                //         ram_wr_en = 1;
                //         state_next = PIXEL_EMPTY;
                //     end
                // end else begin 
                //     vram_wr_address = base_address_reg;
                //     vram_wr_data = 0;
                //     vram_wr_en = 1;
                //     ram_wr_address = base_address_reg + ACTIVE_COLUMNS + 1;
                //     ram_wr_data = base_pixel_state_reg;
                //     ram_wr_en = 1;
                //     state_next = DELETE_PIXEL;
                // end
            end
            PIXEL_LEFT : begin
                pixel_surrounding_state_next[3] = ((|vram_rd_data) | (|ram_rd_data));
                vram_rd_address = base_address_reg + 1;
                ram_rd_address = base_address_reg + 1;
                state_next = PIXEL_RIGHT;
            end
            PIXEL_RIGHT : begin
                pixel_surrounding_state_next[4] = ((|vram_rd_data) | (|ram_rd_data));
                if ((|vram_rd_data) | (|ram_rd_data)) begin
                    base_address_next = base_address_reg + 1;
                    vram_rd_address = base_address_next;
                    ram_wr_address = base_address_reg;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = PIXEL_EMPTY;
                end else begin
                    vram_wr_address = base_address_reg;
                    vram_wr_data = 0;
                    vram_wr_en = 1;
                    ram_wr_address = base_address_reg + 1;
                    ram_wr_data = base_pixel_state_reg;
                    ram_wr_en = 1;
                    state_next = DELETE_PIXEL;
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
