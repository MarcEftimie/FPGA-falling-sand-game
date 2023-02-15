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
        .TICK_10_NS(100000000)
    ) GAME_STATE_CONTROLLER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ram_read_data_i(ram_read_data),
        .vram_read_data_i(vram_read_data_2),
        .ram_read_address_o(ram_read_address),
        .vram_read_address_o(vram_read_address),
        .ram_write_address_o(ram_write_address),
        .vram_write_address_o(vram_write_address),
        .ram_write_data_o(ram_write_data),
        .vram_write_data_o(vram_write_data),
        .ram_write_ena_o(ram_write_en),
        .vram_write_ena_o(vram_write_en)
    );

    logic vram_write_en;
    logic [VRAM_ADDR_WIDTH-1:0] vram_write_address, vram_read_address;
    logic [VRAM_DATA_WIDTH-1:0] vram_write_data, vram_read_data_1, vram_read_data_2;

    register_file_dual_port_read #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .ROM_FILE("vram.mem")
    ) VRAM_RAM (
        .clk_i(clk_i),
        .write_en(vram_write_en),
        .write_address_i(vram_write_address),
        .read_address_1_i(pixel_count),
        .read_address_2_i(vram_read_address),
        .write_data_i(vram_write_data),
        .read_data_1_o(vram_read_data_1),
        .read_data_2_o(vram_read_data_2)
    );

    logic ram_write_en;
    logic [VRAM_ADDR_WIDTH-1:0] ram_write_address, ram_read_address;
    logic [VRAM_DATA_WIDTH-1:0] ram_write_data, ram_read_data;

    register_file #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .ROM_FILE("vram.mem")
    ) GAME_STATE_RAM (
        .clk_i(clk_i),
        .write_en(ram_write_en),
        .write_address_i(ram_write_address),
        .read_address_i(ram_read_address),
        .write_data_i(ram_write_data),
        .read_data_o(ram_read_data)
    );

    assign hsync_o = hsync;
    assign vsync_o = vsync;

    assign vga_red_o = video_en ? {4{vram_read_data_1}} : 4'h0;
    assign vga_blue_o = video_en ? {4{vram_read_data_1}} : 4'h0;
    assign vga_green_o = video_en ? {4{vram_read_data_1}} : 4'h0;
    
    // assign vram_address = pixel_count;

endmodule
