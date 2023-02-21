`timescale 1ns/1ps
`default_nettype none

module falling_sand_game_top
    #(
        parameter ACTIVE_COLUMNS = 640,
        parameter ACTIVE_ROWS = 400,
        parameter VRAM_DATA_WIDTH = 2,
        parameter VRAM_ADDR_WIDTH = $clog2(ACTIVE_COLUMNS*ACTIVE_ROWS)
    )(
        input wire clk_i, reset_i,
        input wire [3:0] sw_i,
        inout wire ps2d_io, ps2c_io,
        output logic hsync_o, vsync_o,
        output logic [3:0] vga_red_o, vga_blue_o, vga_green_o,
        output logic [15:0] led_o
    );

    logic [26:0] tick_10_ns;

    tick_speed_controller TICK_SPEED_CONTROLLER (
        .controller_i(sw_i[2:0]),
        .tick_delay_o(tick_10_ns)
    );

    logic video_en;
    logic [$clog2(ACTIVE_COLUMNS)-1:0] pixel_x;
    logic [$clog2(ACTIVE_ROWS)-1:0] pixel_y;
    logic [VRAM_ADDR_WIDTH-1:0] pixel_count;
    
    sync_pulse_generator SYNC_PULSE_GENERATOR (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o),
        .video_en_o(video_en),
        .x_o(pixel_x),
        .y_o(pixel_y),
        .pixel_o(pixel_count)
    );

    logic [VRAM_ADDR_WIDTH-1:0] gst_vram_wr_address;
    logic [VRAM_DATA_WIDTH-1:0] gst_vram_wr_data;
    logic gst_vram_wr_en;

    game_state_controller #(
        .ACTIVE_COLUMNS(ACTIVE_COLUMNS),
        .ACTIVE_ROWS(ACTIVE_ROWS),
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH)
    ) GAME_STATE_CONTROLLER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .tick_10_ns(tick_10_ns),
        .draw_en_i(mouse_btn[0]),
        .ram_rd_data_i(ram_rd_data),
        .vram_rd_data_i(vram_rd_data_2),
        .ram_rd_address_o(ram_rd_address),
        .vram_rd_address_o(vram_rd_address),
        .ram_wr_address_o(ram_wr_address),
        .vram_wr_address_o(gst_vram_wr_address),
        .ram_wr_data_o(ram_wr_data),
        .vram_wr_data_o(gst_vram_wr_data),
        .ram_wr_en_o(ram_wr_en),
        .vram_wr_en_o(gst_vram_wr_en),
        .draw_en_o(cursor_draw_en)
    );

    logic vram_wr_en;
    logic [VRAM_ADDR_WIDTH-1:0] vram_wr_address, vram_rd_address;
    logic [VRAM_DATA_WIDTH-1:0] vram_wr_data, vram_rd_data_1, vram_rd_data_2;

    register_file_dual_port_read #(
        .ADDR_WIDTH(VRAM_ADDR_WIDTH),
        .DATA_WIDTH(VRAM_DATA_WIDTH),
        .RAM_LENGTH(ACTIVE_COLUMNS*ACTIVE_ROWS),
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
        .RAM_LENGTH(ACTIVE_COLUMNS*ACTIVE_ROWS),
        .ROM_FILE("zeros.mem")
    ) GAME_STATE_RAM (
        .clk_i(clk_i),
        .wr_en(ram_wr_en),
        .wr_address_i(ram_wr_address),
        .rd_address_i(ram_rd_address),
        .wr_data_i(ram_wr_data),
        .rd_data_o(ram_rd_data)
    );

    logic [8:0] mouse_x_velocity, mouse_y_velocity;
    logic [2:0] mouse_btn;
    logic mouse_done;

    mouse_controller MOUSE(
        .clk_i(clk_i),
        .reset_i(reset_i),
        .ps2d_io(ps2d_io),
        .ps2c_io(ps2c_io),
        .x_velocity_o(mouse_x_velocity),
        .y_velocity_o(mouse_y_velocity),
        .btn_o(mouse_btn),
        .done_o(mouse_done)
    );

    logic [$clog2(ACTIVE_COLUMNS)-1:0] mouse_x_position;
    logic [$clog2(ACTIVE_ROWS)-1:0] mouse_y_position;

    mouse_position_tracker #(
        .COLUMNS(ACTIVE_COLUMNS),
        .ROWS(ACTIVE_ROWS)
    ) MOUSE_POSITION_TRACKER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .x_velocity_i(mouse_x_velocity),
        .y_velocity_i(mouse_y_velocity),
        .en_i(mouse_done),
        .x_position_o(mouse_x_position),
        .y_position_o(mouse_y_position)
    );

    logic cursor_draw;

    mouse_cursor_drawer #(
        .COLUMNS(ACTIVE_COLUMNS),
        .ROWS(ACTIVE_ROWS)
    ) MOUSE_CURSOR_DRAWER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .mouse_x_position_i(mouse_x_position),
        .mouse_y_position_i(mouse_y_position),
        .pixel_x_i(pixel_x),
        .pixel_y_i(pixel_y),
        .cursor_draw_o(cursor_draw)
    );

    logic cursor_draw_en;
    logic [11:0] draw_vga;
    logic [11:0] game_vga;

    always_comb begin
        if (sw_i[3]) begin
            mpd_vram_wr_data = 2'b10;
            draw_vga = 12'b000011110000;
        end else begin
            mpd_vram_wr_data = 2'b01;
            draw_vga = 12'b111100001111;
        end

        case (vram_rd_data_1)
            2'b00 : game_vga = 12'b0;
            2'b01 : game_vga = 12'b111100001111;
            2'b10 : game_vga = 12'b000011110000;
            default : game_vga = 12'b0;
        endcase
    end

    logic [VRAM_ADDR_WIDTH-1:0] mpd_vram_wr_address;
    logic [VRAM_DATA_WIDTH-1:0] mpd_vram_wr_data;
    logic mpd_vram_wr_en;

    mouse_pixel_drawer #(
        .COLUMNS(ACTIVE_COLUMNS),
        .ROWS(ACTIVE_ROWS)
    ) MOUSE_PIXEL_DRAWER (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .draw_en_i(cursor_draw_en),
        .mouse_x_position_i(mouse_x_position),
        .mouse_y_position_i(mouse_y_position),
        .wr_address_o(mpd_vram_wr_address),
        .wr_en_o(mpd_vram_wr_en)
    );

    assign vram_wr_address = cursor_draw_en ? mpd_vram_wr_address : gst_vram_wr_address;
    assign vram_wr_data = cursor_draw_en ? mpd_vram_wr_data : gst_vram_wr_data;
    assign vram_wr_en = cursor_draw_en ? mpd_vram_wr_en : gst_vram_wr_en;

    assign vga_red_o = video_en ? (cursor_draw ? draw_vga[11:8] : game_vga[11:8]) : 4'h0;
    assign vga_blue_o = video_en ? (cursor_draw ? draw_vga[7:4] : game_vga[7:4]) : 4'h0;
    assign vga_green_o = video_en ? (cursor_draw ? draw_vga[3:0] : game_vga[3:0]) : 4'h0;

    assign led_o = {mouse_x_position[6:0], mouse_y_position};

endmodule
