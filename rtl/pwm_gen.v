`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 15:33:29
// Design Name: 
// Module Name: pwm_gen
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

module pwm_gen #(
    parameter integer PWM_PERIOD = 100000
)(
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] duty,

    output wire       pwm
);

    //=========================================================
    // PWM COUNTER
    //=========================================================

    reg [16:0] counter;


    //=========================================================
    // DUTY THRESHOLD
    //=========================================================

    wire [16:0] duty_count;


    //=========================================================
    // DUTY CALCULATION
    //
    // Real hardware:
    // PWM_PERIOD = 100000
    //
    // duty_count = 1000 * duty
    //
    // 1000 = 1024 - 16 - 8
    //
    //=========================================================

    generate

        if (PWM_PERIOD == 100000) begin : GEN_PWM_100000

            wire [16:0] duty_ext;
            wire [16:0] duty_x1024;
            wire [16:0] duty_x16;
            wire [16:0] duty_x8;

            assign duty_ext   = {9'b0, duty};

            assign duty_x1024 = duty_ext << 10;
            assign duty_x16   = duty_ext << 4;
            assign duty_x8    = duty_ext << 3;

            assign duty_count =
                    duty_x1024
                  - duty_x16
                  - duty_x8;

        end

        else if (PWM_PERIOD == 100) begin : GEN_PWM_100

            // For simulation:
            //
            // PWM_PERIOD = 100
            //
            // duty_count = duty

            assign duty_count = {9'b0, duty};

        end

        else begin : GEN_PWM_GENERIC

            assign duty_count =
                    (PWM_PERIOD * duty) / 100;

        end

    endgenerate


    //=========================================================
    // PWM OUTPUT
    //=========================================================

    assign pwm = (counter < duty_count);


    //=========================================================
    // PWM COUNTER
    //=========================================================

    always @(posedge clk) begin

        if (reset) begin

            counter <= 17'd0;

        end

        else begin

            if (counter == PWM_PERIOD - 1) begin

                counter <= 17'd0;

            end

            else begin

                counter <= counter + 17'd1;

            end

        end

    end

endmodule