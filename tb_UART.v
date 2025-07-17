`timescale 10ps / 1ps
`include "uart_header.vh"
module tb_UART();
reg clk;
reg wr_en;
wire pop;
wire full_o;
wire empty_o;
wire valid_o;
wire [7:0] data_rx_o;
wire [7:0] AXI_o;
wire [7:0] data_o;
reg reset;
reg [7:0] data_i;
wire  data_tx_o;
reg tenable_i;
integer i=0;
wire tick_rate;
wire op_AXI;
wire full_rx_o;
wire empty__rx_o;
wire fifo_wr_en; // Write enable for FIFO in RX
reg clear_break_flag; // Input to clear break flag
wire break_flag; // Flag to indicate a break condition
wire busy_o;
wire backpressure_otx; // Backpressure signal from FIFO
wire backpressure_orx; // Backpressure signal from RX FIFO
reg framing_control_flag; // Control flag for framing error
wire framing_error_flag; // Framing error flag
reg overrun_control_flag; // Control flag for overrun error
wire overrun_flag; // Overrun error flag
wire underrun_flag; // Underrun error flag
reg underrun_control_flag; // Control flag for underrun error
wire tready_o;
wire sampling_rate; // Sampling rate for clock divider

AXI_UART_TX #(
    .WIDTH(8),
    .clk(200_000), 
    .baud_rate(9600)
) uart_tx_inst (
    .clk_i(clk),
    .reset_i(reset),
    .data_i(data_o),
    .data_tx_o(data_tx_o),
    .tenable_i(tenable_i),
    .fifo_empty_i(empty_o), // Check if FIFO is empty
    .pop(pop),
    .tick_rate(tick_rate),
    .busy_o(busy_o),
    .backpressure_i(backpressure_otx), // Connect backpressure signal
    .tready_o(tready_o)
);
fifo #(8, 16) fifo_inst (
    .clk(tick_rate),
    .reset(reset),
    .data_i(data_i),
    .data_o(data_o),
    .wr_en(wr_en),
    .pop(pop),
    .full_o(full_o),
    .empty_o(empty_o),
    .backpressure_o(backpressure_otx) // Connect backpressure signal
);

fifo #(8, 16) fifo_rx_inst (
    .clk(sampling_rate),
    .reset(reset),
    .data_i(data_rx_o), // Connect RX output to FIFO input
    .data_o(AXI_o), // Output data from FIFO
    .wr_en(fifo_wr_en), // Write enable based on valid output
    .pop(pop_AXI),
    .full_o(full_rx_o),
    .empty_o(empty__rx_o),
    .backpressure_o(backpressure_orx), // Connect backpressure signal
    .overrun_o(overrun_flag), // Connect overrun output
    .underrun_o(underrun_flag) // Connect underrun output
);
AXI_UART_RX #(
    .baud_rate(9600),
    .WIDTH(8),
    .clk(200_000),
    .sampling_frequency(8)
) uart_rx_inst (
    .clk_i(clk),
    .reset_i(reset),
    .data_rx_i(data_tx_o), // Connect TX output to RX input
    .word_o(data_rx_o), 
    .valid_o(valid_o), // Error output not used in this testbench
    .fifo_wr_en(fifo_wr_en), // Write enable for FIFO in RX
    .break_flag(break_flag), // Flag to indicate a break condition
    .clear_break_flag(clear_break_flag), // Input to clear break flag
    .backpressure_i(backpressure_orx), // Connect backpressure signal
    .framing_error_flag_o(framing_error_flag), // Framing error flag
    .framing_control_flag_i(framing_control_flag), // Control flag for framing error
    .overrun_flag_o(overrun_flag), // Overrun error flag
    .overrun_control_flag_i(overrun_control_flag), // Control flag for overrun error
    .underrun_flag_o(underrun_flag), // Underrun error flag
    .underrun_control_flag_i(underrun_control_flag), // Control flag for
    .sampling_rate(sampling_rate) // Sampling rate for clock divider
);
initial begin
    clk = 0;
    reset = 1;
    tenable_i = 1;   
    #5 reset = 0; // Release reset after 5 time units
    #4 reset = 1; // Reapply reset after 10 time units
    wr_en = 1; // Enable write
    for (i = 0; i < 16; i = i + 1) begin
        data_i = i[7:0]; // Write data to FIFO
        #14; // Wait for some time before next write
    end
    wr_en = 0; // Disable write
    
end

always begin #2 clk = ~clk; end

initial begin
    $dumpfile ("tb.fst");
    $dumpvars (0,   tb_UART);
    $dumpvars (1,   fifo_inst.fifo_mem[1]); // Explicitly dump the internal fifo_mem array
    $dumpvars (2,   fifo_inst.fifo_mem[2]); // Explicitly dump the internal fifo_mem array
    $dumpvars (3,   fifo_inst.fifo_mem[3]); // Explicitly dump the internal fifo_mem array
    $dumpvars (4,   fifo_inst.fifo_mem[4]); // Explicitly dump the internal fifo_mem array
    $dumpvars (5,   fifo_inst.fifo_mem[5]); // Explicitly dump the internal fifo_mem array
    $dumpvars (6,   fifo_inst.fifo_mem[6]); // Explicitly dump the internal fifo_mem array
    $dumpvars (7,   fifo_inst.fifo_mem[7]); // Explicitly dump the internal fifo_mem array
    $dumpvars (8,   fifo_inst.fifo_mem[8]); // Explicitly dump the internal fifo_mem array
    $dumpvars (9,   fifo_inst.fifo_mem[9]); // Explicitly dump the internal fifo_mem array
    $dumpvars (10,  fifo_inst.fifo_mem[10]); // Explicitly dump the internal fifo_mem array
    $dumpvars (11, fifo_inst.fifo_mem[11]); // Explicitly dump the internal fifo_mem array
    $dumpvars (12, fifo_inst.fifo_mem[12]); // Explicitly dump the internal fifo_mem array
    $dumpvars (13, fifo_inst.fifo_mem[13]); // Explicitly dump the internal fifo_mem array
    $dumpvars (14, fifo_inst.fifo_mem[14]); // Explicitly dump the internal fifo_mem array
    $dumpvars (15, fifo_inst.fifo_mem[15]); // Explicitly dump the internal fifo
    $dumpvars (16, fifo_inst.fifo_mem[0]);
    $dumpvars (17, uart_rx_inst.sampled_array[0]); // Dump sampled_array[0]
    $dumpvars (18, uart_rx_inst.sampled_array[1]); // Dump sampled_array[1]
    $dumpvars (19, uart_rx_inst.sampled_array[2]); // Dump sampled_array[2]
    $dumpvars (20, uart_rx_inst.sampled_array[3]); // Dump sampled_array[3]
end
initial begin
    #6000; // Run the simulation for 1000 time units
    $finish; // End the simulation
end
endmodule
