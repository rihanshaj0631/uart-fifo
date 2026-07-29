// ============================================================
// top_uart_fifo.v
// Top level module.
//
//   User Input -> FIFO -> UART TX -> UART_TX pin
//
// Whenever the UART is idle and the FIFO is not empty, the
// controller automatically loads the next byte and starts sending it.
// ============================================================
module top_uart_fifo (
    input  wire       clk,
    input  wire       rst,

    // Simple write port so outside logic (or a testbench) can push
    // bytes into the FIFO
    input  wire        wr_en,
    input  wire [7:0]  wr_data,
    output wire         fifo_full,

    output wire         uart_tx_pin
);

    // Wires between FIFO and controller
    wire        fifo_empty;
    wire [7:0]  fifo_rd_data;
    wire        fifo_rd_en;

    // Wires between controller and UART TX
    wire        uart_busy;
    wire        uart_tx_start;
    wire [7:0]  uart_tx_data;

    // Wires between baud generator and UART TX
    wire        baud_tick;
    wire        baud_sync_reset;

    // ---------------- FIFO ----------------
    fifo u_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (wr_en),
        .wr_data  (wr_data),
        .rd_en    (fifo_rd_en),
        .rd_data  (fifo_rd_data),
        .full     (fifo_full),
        .empty    (fifo_empty)
    );

    // ---------------- Baud rate generator ----------------
    baud_generator u_baud_gen (
        .clk        (clk),
        .rst        (rst),
        .sync_reset (baud_sync_reset),
        .tick       (baud_tick)
    );

    // ---------------- UART transmitter ----------------
    uart_tx u_uart_tx (
        .clk             (clk),
        .rst             (rst),
        .tx_start        (uart_tx_start),
        .tx_data         (uart_tx_data),
        .baud_tick       (baud_tick),
        .tx              (uart_tx_pin),
        .busy            (uart_busy),
        .baud_sync_reset (baud_sync_reset)
    );

    // ---------------- Controller: FIFO -> UART TX glue logic ----------------
    uart_controller u_controller (
        .clk           (clk),
        .rst           (rst),
        .fifo_empty    (fifo_empty),
        .fifo_rd_data  (fifo_rd_data),
        .fifo_rd_en    (fifo_rd_en),
        .uart_busy     (uart_busy),
        .uart_tx_start (uart_tx_start),
        .uart_tx_data  (uart_tx_data)
    );

endmodule