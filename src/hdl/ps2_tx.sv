module p2s_tx
    (
        input wire clk_i, reset_i,
        input wire ready_i,
        input wire [7:0] tx_data,
        inout wire ps2d_o, ps2c_o,
        output logic tx_idle, tx_done
    );

    typedef enum logic [2:0] {
        IDLE,
        REQUEST_TO_SEND,
        START,
        DATA,
        STOP
    } state_d;

    state_d state_reg, state_next;

    logic [7:0] filter_reg, filter_next;
    logic filter_ps2c_reg, filter_ps2c_next;
    logic [7:0] wr_data_reg, wr_data_next;
    logic falling_edge;
    logic ps2d_tri, ps2c_tri;
    logic ps2d, ps2c;
    logic [12:0] count_reg, count_next;

    always_ff @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            state_reg <= IDLE;
            filter_reg <= 0;
            count_reg <= 0;
            filter_ps2c_reg <= 0;
            wr_data_reg <= 0;
        end else begin
            state_reg <= state_next;
            count_reg <= count_next;
            filter_reg <= filter_next;
            filter_ps2c_reg <= filter_ps2c_next;
            wr_data_reg <= wr_data_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        count_next = count_reg;
        wr_data_next = wr_data_reg;
        count_next = count_reg;
        ps2d = 1;
        ps2c = 1;
        ps2d_tri = 0;
        ps2c_tri = 0;
        case (state_reg)
            IDLE : begin
                if (ready_i) begin
                    count_next = 13'h1FFF;
                    state_next = REQUEST_TO_SEND;
                end
            end
            REQUEST_TO_SEND : begin
                ps2c_tri = 1;
                ps2c = 0;
                count_next = count_reg - 1;
                if (count_next == 0) begin
                    state_next = START;
                end
            end
            START : begin
                ps2d_tri = 1;
                ps2d = 0;
                if (falling_edge) begin
                    
                end
            end
            default : begin
                state_next = IDLE;
            end
        endcase
    end

    assign filter_next = {ps2c, filter_reg[7:1]};
    assign filter_ps2c_next = &filter_reg ? 1'b1 :
                              |filter_reg ? 1'b0 : filter_ps2c_reg;
    assign falling_edge = filter_ps2c_next & ~filter_ps2c_reg;

    assign ps2d_o = ps2d_tri ? ps2d : 1'bz;
    assign ps2c_o = ps2c_tri ? ps2c : 1'bz;

endmodule
