// ============================================================
// uart_tx.v
// Simple UART transmitter FSM
// Frame format: 1 start bit (0), 8 data bits (LSB first), 1 stop bit (1)
// Line idles HIGH.
// States: IDLE, START, DATA, STOP
// ============================================================
module uart_tx (
    input  wire       clk,
    input  wire       rst,

    input  wire        tx_start,   // pulse high for 1 cycle to begin sending
    input  wire [7:0]  tx_data,    // byte to send

    input  wire        baud_tick,  // 1 cycle pulse, once per bit period

    output reg          tx,        // the serial output pin
    output wire         busy,      // high while a byte is being sent

    // Tells the baud generator to restart its counter right when a new
    // frame begins, so every bit period is exactly one baud period long.
    output wire         baud_sync_reset
);

    // FSM state encoding
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [7:0] shift_reg;   // holds the byte while it is shifted out
    reg [2:0] bit_index;   // counts which data bit we are on (0 to 7)

    // busy is driven combinationally (not registered) so that it goes
    // high on the very same clock cycle tx_start arrives. If busy were
    // registered, there would be a 1-cycle window where the controller
    // still sees busy = 0 right after issuing tx_start, and could
    // mistakenly issue a second tx_start for the next byte too early.
    assign busy = (state != IDLE) || tx_start;

    // Resync the baud generator the instant we leave IDLE to start a frame
    assign baud_sync_reset = (state == IDLE) && tx_start;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;      // idle line is high
            shift_reg <= 8'd0;
            bit_index <= 3'd0;
        end else begin
            case (state)

                // Wait here until the controller asks us to send a byte
                IDLE: begin
                    tx <= 1'b1;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        bit_index <= 3'd0;
                        tx        <= 1'b0;   // drive the start bit
                        state     <= START;
                    end
                end

                // Hold the start bit for exactly one baud period
                START: begin
                    if (baud_tick) begin
                        tx    <= shift_reg[0];  // first data bit, LSB first
                        state <= DATA;
                    end
                end

                // Send 8 data bits, one per baud period, LSB first
                DATA: begin
                    if (baud_tick) begin
                        if (bit_index == 3'd7) begin
                            // last data bit already on the line, move to stop bit
                            tx    <= 1'b1;
                            state <= STOP;
                        end else begin
                            shift_reg <= shift_reg >> 1;
                            bit_index <= bit_index + 1'b1;
                            tx        <= shift_reg[1]; // next bit to send
                        end
                    end
                end

                // Hold the stop bit for exactly one baud period
                STOP: begin
                    if (baud_tick) begin
                        tx    <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule