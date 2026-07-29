UART-FIFO

Verilog-based UART transmitter with a 16-byte FIFO buffer, baud-rate generator, controller FSM, and self-checking simulation testbench. Designed for 9600 baud communication using a 50 MHz system clock.

Overview

This project implements a complete, synthesizable data path for transmitting bytes over a UART serial link, with automatic buffering so a producer can write bytes faster than the line can send them without stalling.

User Input
     |
     V
+-----------+
|   FIFO    |   16 x 8-bit synchronous FIFO
+-----------+
     |
     V
+-----------+
| Controller|   drains FIFO into UART TX whenever idle
+-----------+
     |
     V
+-----------+
| UART TX   |   IDLE -> START -> DATA -> STOP FSM
+-----------+
     |
 UART_TX pin

Whenever the UART transmitter is idle and the FIFO is not empty, the controller automatically pops the next byte and starts a new frame. No frame runs long or short — the baud generator resynchronizes its internal counter the instant a new frame begins, guaranteeing every start bit, data bit, and stop bit lasts exactly one baud period.

Features
8N1 UART framing — 1 start bit, 8 data bits (LSB first), 1 stop bit, no parity
9600 baud from a 50 MHz clock (5208 clock cycles per bit)
16-deep, 8-bit-wide synchronous FIFO with proper full/empty flag generation — verified to reject writes when full with zero data corruption or overflow, even under concurrent read/write bursts
Automatic FIFO-to-UART dispatch — no software/manual triggering required
Race-condition-free handshake between controller and transmitter (busy is combinational, closing a 1-cycle window that would otherwise drop bytes)
Self-checking testbench with an independent bit-level UART receiver model that reconstructs transmitted bytes and prints them for verification
Written entirely in Verilog-2001 — no SystemVerilog constructs, no interfaces/structs/enums, beginner-readable RTL throughout
Repository structure
uart-fifo/
├── fifo.v                 # 16x8 synchronous FIFO (write/read pointers, full/empty flags)
├── baud_generator.v       # 50 MHz -> 9600 baud tick generator, with frame-sync restart
├── uart_tx.v              # UART transmitter FSM (IDLE/START/DATA/STOP)
├── uart_controller.v      # Glue logic: drains FIFO into UART TX when idle
├── top_uart_fifo.v        # Top-level module wiring all blocks together
├── tb_top_uart_fifo.v     # Self-checking testbench (pushes "HELLO", verifies output)
└── README.md
Module descriptions
fifo.v	Single-clock synchronous FIFO. Depth 16, width 8. Tracks fill level with a count register; full/empty are derived from it.
baud_generator.v	Free-running modulo-5208 counter that emits a single-cycle tick pulse once per 9600-baud bit period. Accepts a sync_reset input so the transmitter can realign the counter phase to the start of every new frame.
uart_tx.v	4-state FSM (IDLE, START, DATA, STOP) that shifts out one byte, LSB first, framed with start/stop bits. busy is combinational to avoid a handshake race with the controller.
uart_controller.v	Watches fifo_empty and uart_busy; whenever the UART is idle and the FIFO has data, pops one byte and pulses tx_start.
top_uart_fifo.v	Instantiates and connects all four blocks; exposes a simple wr_en/wr_data write port and the serial uart_tx_pin output.
tb_top_uart_fifo.v	Drives a 50 MHz clock, applies reset, pushes the bytes for "HELLO" into the FIFO, and includes an independent UART receiver model (mid-bit sampling) that reconstructs and prints each received byte for verification. Dumps uart_fifo.vcd for waveform inspection.