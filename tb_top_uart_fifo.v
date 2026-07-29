// ============================================================
// tb_top_uart_fifo.v
// Testbench for top_uart_fifo.
//
// - Generates a 50 MHz clock
// - Generates a reset pulse
// - Pushes the bytes for "HELLO" into the FIFO
// - Waits until every byte has been transmitted
// - Includes a simple UART receiver model that reconstructs the
//   bytes coming out of uart_tx_pin, so we can print them and
//   check they match what we sent
// - Dumps a VCD waveform file for GTKWave
// ============================================================
`timescale 1ns/1ps

module tb_top_uart_fifo;

    reg        clk;
    reg        rst;
    reg        wr_en;
    reg  [7:0] wr_data;
    wire       fifo_full;
    wire       uart_tx_pin;

    // Device under test
    top_uart_fifo dut (
        .clk         (clk),
        .rst         (rst),
        .wr_en       (wr_en),
        .wr_data     (wr_data),
        .fifo_full   (fifo_full),
        .uart_tx_pin (uart_tx_pin)
    );

    // ---------------- Clock generation: 50 MHz -> 20 ns period ----------------
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // ---------------- Task to push one byte into the FIFO ----------------
    task push_byte;
        input [7:0] data;
        begin
            @(posedge clk);
            wr_en   = 1'b1;
            wr_data = data;
            @(posedge clk);
            wr_en   = 1'b0;
        end
    endtask

    // ---------------- Main stimulus ----------------
    initial begin
        // Set up waveform dumping
        $dumpfile("uart_fifo.vcd");
        $dumpvars(0, tb_top_uart_fifo);

        // Initialize inputs
        rst     = 1'b1;
        wr_en   = 1'b0;
        wr_data = 8'd0;

        // Hold reset for a few clock cycles
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        $display("T=%0t : Pushing HELLO into the FIFO", $time);

        // Push the word "HELLO" into the FIFO, one byte at a time
        push_byte(8'h48); // 'H'
        push_byte(8'h45); // 'E'
        push_byte(8'h4C); // 'L'
        push_byte(8'h4C); // 'L'
        push_byte(8'h4F); // 'O'

        $display("T=%0t : All bytes pushed into FIFO", $time);

        // Wait until the FIFO has been fully drained
        wait (dut.fifo_empty == 1'b1);
        // ...and until the UART transmitter has finished the last byte
        wait (dut.uart_busy == 1'b0);

        // A little extra margin so the last stop bit is fully visible
        repeat (200) @(posedge clk);

        $display("T=%0t : All bytes transmitted, simulation done", $time);
        $finish;
    end

    // ------------------------------------------------------------------
    // Simple UART receiver model, used only to check the transmitted
    // data. It samples uart_tx_pin at the middle of every bit period
    // and rebuilds the byte, then prints it.
    // ------------------------------------------------------------------
    parameter BIT_TIME = 20 * 5208; // ns per bit = clk period * clocks per bit

    reg [7:0] received_byte;
    integer   bit_num;

    initial begin
        forever begin
            // Wait for the falling edge that marks the start bit
            @(negedge uart_tx_pin);

            // Move to the middle of the start bit
            #(BIT_TIME/2);

            // Step forward one more full bit time to land in the
            // middle of data bit 0
            #(BIT_TIME);

            for (bit_num = 0; bit_num < 8; bit_num = bit_num + 1) begin
                received_byte[bit_num] = uart_tx_pin;
                #(BIT_TIME);
            end

            $display("T=%0t : Received byte = 0x%02h ('%c')",
                      $time, received_byte, received_byte);
        end
    end

endmodule