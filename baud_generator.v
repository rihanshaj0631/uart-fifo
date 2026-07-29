// ============================================================
// baud_generator.v
// Turns a 50 MHz input clock into a single-cycle "tick" pulse
// that happens once every 9600 baud bit period.
//
// 50,000,000 / 9600 = 5208.33 -> we use 5208 clock cycles per bit
// ============================================================
module baud_generator (
    input  wire clk,
    input  wire rst,

    // Pulse this high for 1 cycle to restart the counter, so that
    // a brand new UART frame always lines up with a fresh tick.
    input  wire sync_reset,

    output reg  tick
);

    // Number of 50 MHz clock cycles in one 9600 baud bit period
    parameter CLKS_PER_BIT = 5208;

    reg [15:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 16'd0;
            tick    <= 1'b0;
        end else if (sync_reset) begin
            // Restart the counter so timing lines up with the new frame
            counter <= 16'd0;
            tick    <= 1'b0;
        end else begin
            if (counter == CLKS_PER_BIT - 1) begin
                counter <= 16'd0;
                tick    <= 1'b1;   // one cycle pulse
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end
    end

endmodule