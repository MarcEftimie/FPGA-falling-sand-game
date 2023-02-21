`timescale 1ns/1ps
`default_nettype none

module tick_speed_controller
    (
        input wire [2:0] controller_i,
        output logic [26:0] tick_delay_o 
    );

    always_comb begin
        case (controller_i)
            0 : tick_delay_o = 400000;
            1 : tick_delay_o = 100000000/2;
            2 : tick_delay_o = 100000000/4;
            3 : tick_delay_o = 100000000/8;
            4 : tick_delay_o = 100000000/16;
            5 : tick_delay_o = 100000000/32;
            6 : tick_delay_o = 100000000/64;
            7 : tick_delay_o = 100000000/128;
        endcase
    end

endmodule
