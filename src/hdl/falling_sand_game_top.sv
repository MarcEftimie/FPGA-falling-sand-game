`timescale 1ns/1ps
`default_nettype none

module falling_sand_game_top
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter VRAM_DATA_WIDTH = 1,
        parameter VRAM_ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS),
        parameter TICK_10_NS = 100000000
    )(
        input wire clk_i, reset_i,
        output logic hsync_o, vsync_o,
        output logic [3:0] vga_red_o, vga_blue_o, vga_green_o
    );

    logic hsync, vsync;
    logic video_en;
    logic [$clog2(ACTIVE_COLUMNS)-1:0] pixel_x;
    logic [$clog2(ACTIVE_ROWS)-1:0] pixel_y;
    logic [VRAM_ADDR_WIDTH-1:0] pixel_count;
    
    sync_pulse_generator SYNC_PULSE_GENERATOR (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .hsync_o(hsync),
        .vsync_o(vsync),
        .video_en_o(video_en),
        .x_o(pixel_x),
        .y_o(pixel_y),
        .pixel_o(pixel_count)
    );

    game_state_controller #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .TICK_10_NS(TICK_10_NS)
    ) GAME_STATE_CONTROLLER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ram_rd_data_i(ram_rd_data),
        .vram_rd_data_i(vram_rd_data_2),
        .ram_rd_address_o(ram_rd_address),
        .vram_rd_address_o(vram_rd_address),
        .ram_wr_address_o(ram_wr_address),
        .vram_wr_address_o(vram_wr_address),
        .ram_wr_data_o(ram_wr_data),
        .vram_wr_data_o(vram_wr_data),
        .ram_wr_en_o(ram_wr_en),
        .vram_wr_en_o(vram_wr_en)
    );

    logic vram_wr_en;
    logic [VRAM_ADDR_WIDTH-1:0] vram_wr_address, vram_rd_address;
    logic [VRAM_DATA_WIDTH-1:0] vram_wr_data, vram_rd_data_1, vram_rd_data_2;

    register_file_dual_port_read #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .ROM_FILE("vram.mem")
    ) VRAM_RAM (
        .clk_i(clk_i),
        .wr_en(vram_wr_en),
        .wr_address_i(vram_wr_address),
        .rd_address_1_i(pixel_count),
        .rd_address_2_i(vram_rd_address),
        .wr_data_i(vram_wr_data),
        .rd_data_1_o(vram_rd_data_1),
        .rd_data_2_o(vram_rd_data_2)
    );

    logic ram_wr_en;
    logic [VRAM_ADDR_WIDTH-1:0] ram_wr_address, ram_rd_address;
    logic [VRAM_DATA_WIDTH-1:0] ram_wr_data, ram_rd_data;

    register_file #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .ROM_FILE("vram.mem")
    ) GAME_STATE_RAM (
        .clk_i(clk_i),
        .wr_en(ram_wr_en),
        .wr_address_i(ram_wr_address),
        .rd_address_i(ram_rd_address),
        .wr_data_i(ram_wr_data),
        .rd_data_o(ram_rd_data)
    );

    assign hsync_o = hsync;
    assign vsync_o = vsync;

    assign vga_red_o = video_en ? {4{vram_rd_data_1}} : 4'h0;
    assign vga_blue_o = video_en ? {4{vram_rd_data_1}} : 4'h0;
    assign vga_green_o = video_en ? {4{vram_rd_data_1}} : 4'h0;
    
    // assign vram_address = pixel_count;

endmodule
