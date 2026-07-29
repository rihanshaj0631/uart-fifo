// ============================================================
// uart_controller.v
// Simple controller that connects the FIFO to the UART transmitter.
//
// Behavior:
//   If UART is not busy AND FIFO is not empty
//     -> read one byte from FIFO, load it into the UART TX, start sending
//   Otherwise
//     -> do nothing, just wait
// ============================================================
module uart_controller (
    input  wire       clk,
    input  wire       rst,

    // FIFO side
    input  wire        fifo_empty,
    input  wire [7:0]  fifo_rd_data,
    output reg          fifo_rd_en,

    // UART TX side
    input  wire        uart_busy,
    output reg          uart_tx_start,
    output reg  [7:0]   uart_tx_data
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_rd_en    <= 1'b0;
            uart_tx_start <= 1'b0;
            uart_tx_data  <= 8'd0;
        end else begin
            // Default: no read, no start, unless we decide otherwise below
            fifo_rd_en    <= 1'b0;
            uart_tx_start <= 1'b0;

            if (!uart_busy && !fifo_empty) begin
                uart_tx_data  <= fifo_rd_data; // grab the next byte
                fifo_rd_en    <= 1'b1;         // pop it out of the FIFO
                uart_tx_start <= 1'b1;         // tell the UART to send it
            end
        end
    end

endmodule