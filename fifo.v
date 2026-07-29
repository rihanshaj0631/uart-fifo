
// ============================================================
// fifo.v
// Simple synchronous FIFO
// Depth  = 16 bytes
// Width  = 8 bits
// Single clock, single reset
// ============================================================
module fifo (
    input  wire       clk,
    input  wire       rst,

    input  wire        wr_en,     // write enable, pulse high for 1 cycle to write
    input  wire [7:0]  wr_data,   // byte to write

    input  wire        rd_en,     // read enable, pulse high for 1 cycle to pop
    output wire [7:0]  rd_data,   // byte currently at the read pointer

    output wire         full,     // high when FIFO cannot accept more data
    output wire         empty     // high when FIFO has no data to read
);

    // Memory array: 16 locations, each 8 bits wide
    reg [7:0] mem [0:15];

    // Write pointer and read pointer, 4 bits each (0 to 15)
    reg [3:0] wr_ptr;
    reg [3:0] rd_ptr;

    // Counts how many bytes are currently stored (0 to 16)
    reg [4:0] count;

    // Full when we are holding all 16 bytes, empty when we are holding 0
    assign full  = (count == 5'd16);
    assign empty = (count == 5'd0);

    // Read data is just whatever byte the read pointer is pointing at
    assign rd_data = mem[rd_ptr];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            count  <= 5'd0;
        end else begin

            // Write a new byte in, only if there is room
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= wr_ptr + 1'b1;
            end

            // Pop a byte out, only if there is something to read
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Update how many bytes are stored, based on which
            // of the two operations above actually happened
            if ((wr_en && !full) && (rd_en && !empty)) begin
                // one byte came in, one byte went out at the same time
                count <= count;
            end else if (wr_en && !full) begin
                // only a write happened
                count <= count + 1'b1;
            end else if (rd_en && !empty) begin
                // only a read happened
                count <= count - 1'b1;
            end

        end
    end

endmodule