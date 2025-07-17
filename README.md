a UART (Universal Asynchronous Receiver/Transmitter) design project with AXI-streamline style.
This project implements a full-duplex UART system with AXI-style interfacing, runtime-configurable baud rate, FIFO buffering, error flags (overrun, underrun, break detection), and clean data/control separation. 

The design is modular and testbench-verified. While the goal wasn't to build a production-ready IP, it gave me hands-on experience with:

FIFO buffer mechanics

AXI-like backpressure and handshaking

Data integrity flags and fault detection

Clock domain crossing considerations.
