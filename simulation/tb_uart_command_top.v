`timescale 1ns/1ps

module tb_uart_command_top;

    //=========================================================
    // PARAMETERS
    //=========================================================

    parameter integer CLK_PERIOD_NS = 10;
    parameter integer CLKS_PER_BIT  = 10417;

    parameter integer BIT_TIME_NS =
                      CLK_PERIOD_NS * CLKS_PER_BIT;


    //=========================================================
    // TESTBENCH SIGNALS
    //=========================================================

    reg clk;
    reg reset;

    reg uart_rx_i;

    wire uart_tx_o;

    wire [7:0] led;
    wire       pwm_o;


    //=========================================================
    // RESPONSE STORAGE
    //=========================================================

    reg [7:0] response1;
    reg [7:0] response2;

    reg [7:0] received_byte1;
    reg [7:0] received_byte2;

    integer response_count;


    //=========================================================
    // TEST COUNTERS
    //=========================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;


    //=========================================================
    // DUT
    //=========================================================

    uart_command_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .PWM_PERIOD(100)
    ) DUT (

        .clk(clk),
        .reset(reset),

        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),

        .led(led),
        .pwm_o(pwm_o)

    );


    //=========================================================
    // 100 MHz CLOCK
    //=========================================================

    initial begin

        clk = 1'b0;

        forever
            #(CLK_PERIOD_NS / 2) clk = ~clk;

    end


    //=========================================================
    // UART SEND BYTE
    //
    // 8-N-1
    // LSB FIRST
    //=========================================================

    task uart_send_byte;

        input [7:0] data;

        integer i;

        begin

            // UART idle
            uart_rx_i = 1'b1;

            #(BIT_TIME_NS);


            // Start bit
            uart_rx_i = 1'b0;

            #(BIT_TIME_NS);


            // Data bits
            for (i = 0; i < 8; i = i + 1) begin

                uart_rx_i = data[i];

                #(BIT_TIME_NS);

            end


            // Stop bit
            uart_rx_i = 1'b1;

            #(BIT_TIME_NS);


            // Idle
            #(BIT_TIME_NS);

        end

    endtask


    //=========================================================
    // UART RECEIVE BYTE
    //
    // IMPORTANT:
    // This task waits for the actual START transition.
    //=========================================================

    task uart_receive_byte;

        output [7:0] data;

        integer i;

        begin

            data = 8'h00;


            //=================================================
            // WAIT FOR START BIT
            //=================================================

            @(negedge uart_tx_o);


            //=================================================
            // MOVE TO CENTER OF FIRST DATA BIT
            //=================================================

            #(BIT_TIME_NS + BIT_TIME_NS / 2);


            //=================================================
            // SAMPLE 8 DATA BITS
            //=================================================

            for (i = 0; i < 8; i = i + 1) begin

                data[i] = uart_tx_o;

                #(BIT_TIME_NS);

            end


            //=================================================
            // CHECK STOP BIT
            //=================================================

            if (uart_tx_o !== 1'b1) begin

                $display(
                    "WARNING: UART TX stop bit is not HIGH"
                );

            end


            //=================================================
            // COMPLETE STOP BIT
            //=================================================

            #(BIT_TIME_NS / 2);

        end

    endtask


    //=========================================================
    // RESPONSE RECEIVER
    //
    // THIS PROCESS IS ALWAYS WAITING FOR UART RESPONSES.
    //
    // This is important because the DUT may start transmitting
    // before the main test process reaches its checking code.
    //=========================================================

    initial begin

        response_count = 0;

        received_byte1 = 8'h00;
        received_byte2 = 8'h00;


        // Wait for reset to finish

        wait (reset == 1'b0);


        forever begin

            //=================================================
            // WAIT FOR NEXT RESPONSE BYTE
            //=================================================

            uart_receive_byte(response1);


            //=================================================
            // STORE BYTE 1
            //=================================================

            if (response_count == 0) begin

                received_byte1 = response1;

                response_count = 1;

                $display(
                    "RECEIVER: response byte 1 = %02h",
                    response1
                );

            end

            //=================================================
            // STORE BYTE 2
            //=================================================

            else if (response_count == 1) begin

                received_byte2 = response1;

                response_count = 2;

                $display(
                    "RECEIVER: response byte 2 = %02h",
                    response1
                );

            end

        end

    end


    //=========================================================
    // WAIT FOR TWO RESPONSE BYTES
    //=========================================================

    task wait_for_response;

        begin

            // Wait until both response bytes arrive

            wait (response_count == 2);

            #(100);

        end

    endtask


    //=========================================================
    // CLEAR RESPONSE BUFFER
    //=========================================================

    task clear_response;

        begin

            response_count = 0;

            received_byte1 = 8'h00;
            received_byte2 = 8'h00;

        end

    endtask


    //=========================================================
    // CHECK RESPONSE
    //=========================================================

    task check_response;

        input [7:0] expected1;
        input [7:0] expected2;

        begin

            wait_for_response;


            $display(
                "Received response byte 1 = %02h",
                received_byte1
            );

            $display(
                "Received response byte 2 = %02h",
                received_byte2
            );


            if ((received_byte1 === expected1) &&
                (received_byte2 === expected2)) begin

                $display(
                    "PASS: Response = %02h %02h",
                    expected1,
                    expected2
                );

                passed_tests = passed_tests + 1;

            end

            else begin

                $display(
                    "FAIL: Expected = %02h %02h, Received = %02h %02h",
                    expected1,
                    expected2,
                    received_byte1,
                    received_byte2
                );

                failed_tests = failed_tests + 1;

            end

        end

    endtask


    //=========================================================
    // CHECK LED
    //=========================================================

    task check_led;

        input [7:0] expected_led;

        begin

            if (led === expected_led) begin

                $display(
                    "PASS: LED = %02h",
                    expected_led
                );

            end

            else begin

                $display(
                    "FAIL: Expected LED = %02h, Actual LED = %02h",
                    expected_led,
                    led
                );

                failed_tests = failed_tests + 1;

            end

        end

    endtask


    //=========================================================
    // CHECK PWM
    //
    // PWM_PERIOD = 100
    //=========================================================

    task check_pwm;

        input integer expected_duty;

        integer i;
        integer high_count;

        begin

            high_count = 0;


            // Wait for clock edge

            @(posedge clk);


            // Count 100 PWM clock cycles

            for (i = 0; i < 100; i = i + 1) begin

                @(posedge clk);

                if (pwm_o == 1'b1)
                    high_count = high_count + 1;

            end


            if (high_count == expected_duty) begin

                $display(
                    "PASS: PWM = %0d%%",
                    expected_duty
                );

            end

            else begin

                $display(
                    "FAIL: PWM expected %0d HIGH cycles, got %0d",
                    expected_duty,
                    high_count
                );

                failed_tests = failed_tests + 1;

            end

        end

    endtask


    //=========================================================
    // MAIN TEST PROCESS
    //=========================================================

    initial begin

        //=====================================================
        // INITIALIZATION
        //=====================================================

        reset     = 1'b1;
        uart_rx_i = 1'b1;

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;


        //=====================================================
        // RESET
        //=====================================================

        #(100);

        reset = 1'b0;

        #(200);


        //=====================================================
        // TEST 1
        //
        // 01 55
        // Expected A1 55
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 1: SET LED TO 55");
        $display("Command: 01 55");
        $display("Expected: A1 55");
        $display("========================================");

        uart_send_byte(8'h01);
        uart_send_byte(8'h55);

        check_response(8'hA1, 8'h55);

        check_led(8'h55);


        //=====================================================
        // TEST 2
        //
        // 01 AA
        // Expected A1 AA
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 2: SET LED TO AA");
        $display("Command: 01 AA");
        $display("Expected: A1 AA");
        $display("========================================");

        uart_send_byte(8'h01);
        uart_send_byte(8'hAA);

        check_response(8'hA1, 8'hAA);

        check_led(8'hAA);


        //=====================================================
        // TEST 3
        //
        // 02
        // Expected A2 00
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 3: CLEAR LED");
        $display("Command: 02");
        $display("Expected: A2 00");
        $display("========================================");

        uart_send_byte(8'h02);

        check_response(8'hA2, 8'h00);

        check_led(8'h00);


        //=====================================================
        // TEST 4
        //
        // 03
        // Expected A3 00
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 4: READ LED STATUS");
        $display("Command: 03");
        $display("Expected: A3 00");
        $display("========================================");

        uart_send_byte(8'h03);

        check_response(8'hA3, 8'h00);


        //=====================================================
        // TEST 5
        //
        // 01 F0
        // Expected A1 F0
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 5: SET LED TO F0");
        $display("Command: 01 F0");
        $display("Expected: A1 F0");
        $display("========================================");

        uart_send_byte(8'h01);
        uart_send_byte(8'hF0);

        check_response(8'hA1, 8'hF0);

        check_led(8'hF0);


        //=====================================================
        // TEST 6
        //
        // 03
        // Expected A3 F0
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 6: READ LED STATUS");
        $display("Command: 03");
        $display("Expected: A3 F0");
        $display("========================================");

        uart_send_byte(8'h03);

        check_response(8'hA3, 8'hF0);


        //=====================================================
        // TEST 7
        //
        // 04 00
        // Expected A4 00
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 7: PWM = 0%%");
        $display("Command: 04 00");
        $display("Expected: A4 00");
        $display("========================================");

        uart_send_byte(8'h04);
        uart_send_byte(8'h00);

        check_response(8'hA4, 8'h00);

        check_pwm(0);


        //=====================================================
        // TEST 8
        //
        // PWM = 50%
        //
        // 50 DECIMAL = 32 HEX
        //
        // COMMAND:
        // 04 32
        //
        // RESPONSE:
        // A4 32
        //=====================================================
        
        total_tests = total_tests + 1;
        
        clear_response;
        
        $display("");
        $display("========================================");
        $display("TEST 8: PWM = 50%%");
        $display("Command: 04 32");
        $display("32 HEX = 50 DECIMAL");
        $display("Expected: A4 32");
        $display("========================================");
        
        uart_send_byte(8'h04);
        uart_send_byte(8'h32);
        
        check_response(8'hA4, 8'h32);
        
        check_pwm(50);


        //=====================================================
        // TEST 9
        //
        // 04 64
        // Expected A4 64
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 9: PWM = 100%%");
        $display("Command: 04 64");
        $display("Expected: A4 64");
        $display("========================================");

        uart_send_byte(8'h04);
        uart_send_byte(8'h64);

        check_response(8'hA4, 8'h64);

        check_pwm(100);


        //=====================================================
        // TEST 10
        //
        // 04 65
        // 65 HEX = 101 DECIMAL
        //
        // Expected E2 65
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 10: INVALID PWM DUTY");
        $display("Command: 04 65");
        $display("65 HEX = 101 DECIMAL");
        $display("Expected: E2 65");
        $display("========================================");

        uart_send_byte(8'h04);
        uart_send_byte(8'h65);

        check_response(8'hE2, 8'h65);


        //=====================================================
        // TEST 11
        //
        // 99
        // Expected E2 99
        //=====================================================

        total_tests = total_tests + 1;

        clear_response;

        $display("");
        $display("========================================");
        $display("TEST 11: INVALID COMMAND");
        $display("Command: 99");
        $display("Expected: E2 99");
        $display("========================================");

        uart_send_byte(8'h99);

        check_response(8'hE2, 8'h99);


        //=====================================================
        // FINAL SUMMARY
        //=====================================================

        $display("");
        $display("========================================");
        $display("       UART COMMAND SYSTEM");
        $display("          FINAL SUMMARY");
        $display("========================================");

        $display(
            "Total tests  : %0d",
            total_tests
        );

        $display(
            "Passed       : %0d",
            passed_tests
        );

        $display(
            "Failed       : %0d",
            failed_tests
        );


        if (failed_tests == 0) begin

            $display("");
            $display("========================================");
            $display("        ALL TESTS PASSED");
            $display("        UART SYSTEM VERIFIED");
            $display("========================================");

        end

        else begin

            $display("");
            $display("========================================");
            $display("        TEST FAILURES FOUND");
            $display("        CHECK ABOVE OUTPUT");
            $display("========================================");

        end


        //=====================================================
        // END SIMULATION
        //=====================================================

        $finish;

    end

endmodule