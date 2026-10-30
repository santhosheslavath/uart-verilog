module uart_rx #(
    parameter CLKS_PER_BIT = 16
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg        rx_sync1, rx_sync2;   // 2-flop synchronizer for the async input
    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
            state    <= IDLE;
            clk_cnt  <= 16'd0;
            bit_idx  <= 3'd0;
            shift    <= 8'd0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            rx_valid <= 1'b0;

            case (state)
                IDLE: begin
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    if (rx_sync2 == 1'b0)
                        state <= START;
                end

                START: begin
                    if (clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        if (rx_sync2 == 1'b0) begin
                            clk_cnt <= 16'd0;
                            state   <= DATA;
                        end else
                            state <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt        <= 16'd0;
                        shift[bit_idx] <= rx_sync2;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= STOP;
                        end else
                            bit_idx <= bit_idx + 1'b1;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 16'd0;
                        if (rx_sync2 == 1'b1) begin
                            rx_data  <= shift;
                            rx_valid <= 1'b1;
                        end
                        state <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end
            endcase
        end
    end
endmodule