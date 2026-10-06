`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 15:32:25
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(
    parameter integer CLKS_PER_BIT = 10417
)(
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] tx_data,
    input  wire       tx_start,

    output reg        tx,
    output reg        tx_busy
);

    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0] state;

    reg [13:0] clk_count;
    reg [2:0]  bit_index;

    reg [7:0] data_reg;

    always @(posedge clk) begin

        if (reset) begin

            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_reg  <= 8'h00;

            tx        <= 1'b1;
            tx_busy   <= 1'b0;

        end
        else begin

            case (state)

                IDLE: begin

                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin

                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START;

                    end

                end

                START: begin

                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;
                        state <= DATA;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                DATA: begin

                    tx <= data_reg[bit_index];

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

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

                STOP: begin

                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;
                        tx_busy <= 1'b0;
                        state <= IDLE;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule

