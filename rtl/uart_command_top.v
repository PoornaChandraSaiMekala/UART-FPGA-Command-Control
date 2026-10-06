`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 15:34:55
// Design Name: 
// Module Name: uart_command_top
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


module uart_command_top #(
    parameter integer CLKS_PER_BIT = 10417,
    parameter integer PWM_PERIOD   = 100000
)(
    input  wire       clk,
    input  wire       reset,

    input  wire       uart_rx_i,
    output wire       uart_tx_o,

    output reg [7:0]  led,
    output wire       pwm_o
);

    //=========================================================
    // UART RX SIGNALS
    //=========================================================

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       framing_error;


    //=========================================================
    // UART TX SIGNALS
    //=========================================================

    reg  [7:0] tx_data;
    reg        tx_start;

    wire       tx_busy;


    //=========================================================
    // PWM SIGNAL
    //=========================================================

    reg [7:0] pwm_duty;


    //=========================================================
    // UART RECEIVER
    //=========================================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (

        .clk(clk),
        .reset(reset),
        .rx(uart_rx_i),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)

    );


    //=========================================================
    // UART TRANSMITTER
    //=========================================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (

        .clk(clk),
        .reset(reset),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx(uart_tx_o),
        .tx_busy(tx_busy)

    );


    //=========================================================
    // PWM GENERATOR
    //=========================================================

    pwm_gen #(
        .PWM_PERIOD(PWM_PERIOD)
    ) u_pwm (

        .clk(clk),
        .reset(reset),

        .duty(pwm_duty),

        .pwm(pwm_o)

    );


    //=========================================================
    // FSM STATES
    //=========================================================

    localparam [3:0]

        IDLE          = 4'd0,

        LED_ARG       = 4'd1,

        PWM_ARG       = 4'd2,

        TX_LOAD1      = 4'd3,

        TX_START1     = 4'd4,

        TX_WAIT1_BUSY = 4'd5,

        TX_WAIT1_DONE = 4'd6,

        TX_LOAD2      = 4'd7,

        TX_START2     = 4'd8,

        TX_WAIT2_BUSY = 4'd9,

        TX_WAIT2_DONE = 4'd10;


    reg [3:0] state;


    //=========================================================
    // RESPONSE REGISTERS
    //=========================================================

    reg [7:0] response1;
    reg [7:0] response2;


    //=========================================================
    // COMMAND CONTROLLER
    //=========================================================

    always @(posedge clk) begin

        //=====================================================
        // RESET
        //=====================================================

        if (reset) begin

            state      <= IDLE;

            led        <= 8'h00;

            pwm_duty   <= 8'd0;

            tx_data    <= 8'h00;

            tx_start   <= 1'b0;

            response1  <= 8'h00;

            response2  <= 8'h00;

        end


        //=====================================================
        // NORMAL OPERATION
        //=====================================================

        else begin

            // tx_start is a one-clock pulse
            tx_start <= 1'b0;


            case (state)


                //=================================================
                // IDLE
                //=================================================

                IDLE: begin

                    //=============================================
                    // UART FRAMING ERROR
                    //=============================================

                    if (framing_error) begin

                        response1 <= 8'hE1;
                        response2 <= 8'h00;

                        state <= TX_LOAD1;

                    end


                    //=============================================
                    // VALID RECEIVED BYTE
                    //=============================================

                    else if (rx_valid) begin

                        case (rx_data)


                            //=====================================
                            // COMMAND 01
                            // SET LED
                            //
                            // Host:
                            // 01 <LED_VALUE>
                            //
                            // Response:
                            // A1 <LED_VALUE>
                            //=====================================

                            8'h01: begin

                                state <= LED_ARG;

                            end


                            //=====================================
                            // COMMAND 02
                            // CLEAR LED
                            //
                            // Host:
                            // 02
                            //
                            // Response:
                            // A2 00
                            //=====================================

                            8'h02: begin

                                led <= 8'h00;

                                response1 <= 8'hA2;
                                response2 <= 8'h00;

                                state <= TX_LOAD1;

                            end


                            //=====================================
                            // COMMAND 03
                            // READ LED STATUS
                            //
                            // Host:
                            // 03
                            //
                            // Response:
                            // A3 <LED_VALUE>
                            //=====================================

                            8'h03: begin

                                response1 <= 8'hA3;
                                response2 <= led;

                                state <= TX_LOAD1;

                            end


                            //=====================================
                            // COMMAND 04
                            // SET PWM
                            //
                            // Host:
                            // 04 <DUTY>
                            //
                            // Valid:
                            // 0 to 100
                            //
                            // Response:
                            // A4 <DUTY>
                            //=====================================

                            8'h04: begin

                                state <= PWM_ARG;

                            end


                            //=====================================
                            // INVALID COMMAND
                            //
                            // Response:
                            // E2 <COMMAND>
                            //=====================================

                            default: begin

                                response1 <= 8'hE2;
                                response2 <= rx_data;

                                state <= TX_LOAD1;

                            end

                        endcase

                    end

                end


                //=================================================
                // LED ARGUMENT
                //=================================================

                LED_ARG: begin

                    //=============================================
                    // FRAMING ERROR
                    //=============================================

                    if (framing_error) begin

                        response1 <= 8'hE1;
                        response2 <= 8'h00;

                        state <= TX_LOAD1;

                    end


                    //=============================================
                    // RECEIVE LED VALUE
                    //=============================================

                    else if (rx_valid) begin
    
                        // Update LED register
                        led <= rx_data;

                        // Prepare response
                        response1 <= 8'hA1;
                        response2 <= rx_data;

                        state <= TX_LOAD1;

                    end

                end


                //=================================================
                // PWM ARGUMENT
                //=================================================

                PWM_ARG: begin

                    //=============================================
                    // FRAMING ERROR
                    //=============================================

                    if (framing_error) begin

                        response1 <= 8'hE1;
                        response2 <= 8'h00;

                        state <= TX_LOAD1;

                    end


                    //=============================================
                    // RECEIVE PWM DUTY
                    //=============================================

                    else if (rx_valid) begin

                        // Valid duty cycle
                        if (rx_data <= 8'd100) begin

                            pwm_duty <= rx_data;

                            response1 <= 8'hA4;
                            response2 <= rx_data;

                        end


                        // Invalid duty cycle
                        else begin

                            response1 <= 8'hE2;
                            response2 <= rx_data;

                        end

                        state <= TX_LOAD1;

                    end

                end


                //=================================================
                // LOAD RESPONSE BYTE 1
                //=================================================

                TX_LOAD1: begin
                                   
                    // Load response byte into UART TX input
                    tx_data <= response1;

                    // Go to separate start state
                    state <= TX_START1;

                end


                //=================================================
                // START RESPONSE BYTE 1
                //=================================================

                TX_START1: begin

                    // Generate one-clock start pulse
                    tx_start <= 1'b1;

                    // Wait until UART TX becomes busy
                    state <= TX_WAIT1_BUSY;

                end


                //=================================================
                // WAIT UNTIL TX BECOMES BUSY
                //=================================================

                TX_WAIT1_BUSY: begin

                    if (tx_busy) begin

                        state <= TX_WAIT1_DONE;

                    end

                end


                //=================================================
                // WAIT UNTIL RESPONSE BYTE 1 FINISHES
                //=================================================

                TX_WAIT1_DONE: begin

                    if (!tx_busy) begin

                        state <= TX_LOAD2;

                    end

                end


                //=================================================
                // LOAD RESPONSE BYTE 2
                //=================================================

                TX_LOAD2: begin

                    // Load second response byte
                    tx_data <= response2;

                    // Go to separate start state
                    state <= TX_START2;

                end


                //=================================================
                // START RESPONSE BYTE 2
                //=================================================

                TX_START2: begin

                    // Generate one-clock start pulse
                    tx_start <= 1'b1;

                    // Wait until UART TX becomes busy
                    state <= TX_WAIT2_BUSY;

                end


                //=================================================
                // WAIT UNTIL TX BECOMES BUSY
                //=================================================

                TX_WAIT2_BUSY: begin

                    if (tx_busy) begin

                        state <= TX_WAIT2_DONE;

                    end

                end


                //=================================================
                // WAIT UNTIL RESPONSE BYTE 2 FINISHES
                //=================================================

                TX_WAIT2_DONE: begin

                    if (!tx_busy) begin

                        state <= IDLE;

                    end

                end


                //=================================================
                // DEFAULT
                //=================================================

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule