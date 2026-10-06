module uart_rx #(
    parameter integer CLKS_PER_BIT = 10417
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,

    output reg [7:0]  rx_data,
    output reg        rx_valid,
    output reg        framing_error
);

    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0] state;

    reg [13:0] clk_count;
    reg [2:0]  bit_index;

    reg rx_sync1;
    reg rx_sync2;


    // =========================================================
    // Two-flop synchronizer
    // =========================================================

    always @(posedge clk) begin

        if (reset) begin

            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;

        end
        else begin

            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;

        end

    end


    // =========================================================
    // UART Receiver
    // 8 Data Bits
    // No Parity
    // 1 Stop Bit
    // LSB First
    // =========================================================

    always @(posedge clk) begin

        if (reset) begin

            state         <= IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            rx_data       <= 8'h00;
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

        end

        else begin

            // Default: pulses remain LOW
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;


            case (state)


                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    clk_count <= 0;
                    bit_index <= 0;

                    // Detect falling edge / start bit
                    if (rx_sync2 == 1'b0) begin

                        state <= START;

                    end

                end


                // =================================================
                // START BIT
                // Check middle of start bit
                // =================================================

                START: begin

                    if (clk_count == (CLKS_PER_BIT/2)) begin

                        if (rx_sync2 == 1'b0) begin

                            // Valid start bit
                            clk_count <= 0;
                            state <= DATA;

                        end

                        else begin

                            // False start
                            state <= IDLE;
                            clk_count <= 0;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                // =================================================
                // DATA BITS
                // Sample every full bit period
                // =================================================

                DATA: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        // LSB first
                        rx_data[bit_index] <= rx_sync2;

                        if (bit_index == 3'd7) begin

                            bit_index <= 0;
                            state <= STOP;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                // =================================================
                // STOP BIT
                // Check MIDDLE of stop bit
                // =================================================

                STOP: begin

                    if (clk_count == (CLKS_PER_BIT/2)) begin

                        clk_count <= 0;
                        state <= IDLE;

                        if (rx_sync2 == 1'b1) begin

                            // Valid stop bit
                            rx_valid <= 1'b1;

                        end

                        else begin

                            // Invalid stop bit
                            framing_error <= 1'b1;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state     <= IDLE;
                    clk_count <= 0;
                    bit_index <= 0;

                end

            endcase

        end

    end

endmodule