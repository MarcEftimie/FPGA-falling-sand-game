`timescale 1ns/1ps
`default_nettype none

module falling_sand_game_top
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 480,
        parameter VRAM_DATA_WIDTH = 1,
        parameter VRAM_ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS)
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

    logic vram_write_en;
    logic [VRAM_ADDR_WIDTH-1:0] vram_write_address, vram_read_address;
    logic [VRAM_DATA_WIDTH-1:0] vram_write_data, vram_read_data;

    register_file #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .ROM_FILE("vram.mem")
    ) VRAM_RAM (
        .clk_i(clk_i),
        .write_en(vram_write_en),
        .write_address_i(vram_write_address),
        .read_address_i(pixel_count),
        .write_data_i(vram_write_data),
        .read_data_o(vram_read_data)
    );

    // logic game_write_en;
    // logic [$clog2(ACTIVE_COLUMNS*ACTIVE_ROWS):0] game_write_address, game_read_address;
    // logic [VRAM_DATA_WIDTH-1:0] game_write_data, game_read_data;

    // register_file #(
    //     .ADDR_WIDTH(VRAM_ADDR_WIDTH),
    //     .DATA_WIDTH(VRAM_DATA_WIDTH),
    //     .ROM_FILE("game.txt")
    // ) GAME_RAM (
    //     .clk_i(clk_i),
    //     .write_en(game_write_en),
    //     .write_address_i(game_write_address),
    //     .read_address_i(game_read_address),
    //     .write_data_i(game_write_data),
    //     .read_data_o(game_read_data)
    // );

    assign vram_write_en = 0;
    
    assign hsync_o = hsync;
    assign vsync_o = vsync;

    assign vga_red_o = video_en ? {4{vram_read_data}} : 4'h0;
    assign vga_blue_o = video_en ? {4{vram_read_data}} : 4'h0;
    assign vga_green_o = video_en ? {4{vram_read_data}} : 4'h0;
    
    // assign vram_address = pixel_count;

endmodule
