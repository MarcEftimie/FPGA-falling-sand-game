module UART_TX(
    input wire clk,
    input wire rst,
    input wire [7:0] TX_byte,
    input wire TX_DV,
    output logic TX_serial
);

    // Clocks per bit is equal to clock rate / baud rate

    parameter CLKS_PER_BIT = 217;
    parameter HALF_CLKS_PER_BIT = 108;

    enum logic [1:0] {IDLE, START, WRITE_SERIAL, STOP_BIT} state;

    logic [31:0] count;
    logic [3:0] serial_count;

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
            serial_count <= 0;
            TX_serial <= 1;
            state <= IDLE;
        end else begin
            case (state)
                IDLE : begin
                    if (TX_DV) begin
                        count <= 0;
                        serial_count <= 0;
                        state <= START;
                    end
                end
                START : begin
                    if (count < CLKS_PER_BIT) begin
                        TX_serial <= 0;
                        count <= count + 1;
                    end else begin
                        state <= WRITE_SERIAL;
                    end
                end
                WRITE_SERIAL : begin
                    if (count < CLKS_PER_BIT) begin
                        count <= count + 1;
                    end else if (serial_count < 8) begin
                        serial_count <= serial_count + 1;
                        TX_serial <= TX_byte[serial_count];
                        count <= 0;
                    end else begin
                        state <= STOP_BIT;
                        count <= 0;
                    end
                end
                STOP_BIT : begin
                    if (count < CLKS_PER_BIT) begin
                        TX_serial <= 1;
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end


endmodule
