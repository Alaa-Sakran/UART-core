module AXI_UART_TX #(
    parameter WIDTH      = 8,
    parameter clk        = 100_000,
    parameter baud_rate  = 9600
)(
    input  wire               clk_i,
    input  wire               reset_i,
    input  wire [WIDTH-1:0]   data_i,
    input  wire               tenable_i,
    input  wire               fifo_empty_i,
    input  wire               backpressure_i,
    output wire               tick_rate,
    output wire               busy_o,
    output wire               tready_o,
    output reg                pop,
    output reg                data_tx_o
);

// Local params
localparam divisor        = clk / baud_rate;
localparam counter_width  = $clog2(WIDTH);
localparam maxwidth       = WIDTH - 1;

// FSM states
localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

// Registers
reg [1:0] current_state, next_state;
reg [counter_width-1:0] bit_counter;
reg [WIDTH-1:0] data_buffer;

// Handshake and status
assign tready_o = !fifo_empty_i;               // Ready when FIFO not empty
assign tx_en    = tenable_i && tready_o && !backpressure_i;
assign busy_o   = (current_state != IDLE);

// Baud clock divider
clock_divider #(divisor) clk_div (
    .clk_i   (clk_i),
    .reset_i (reset_i),
    .clk_out (tick_rate)
);

// Next-state logic
always @* begin
    next_state = current_state;
    case (current_state)
        IDLE:  if (tx_en)      next_state = START;
        START:                next_state = DATA;
        DATA:  if (bit_counter == maxwidth) next_state = STOP;
        STOP:                 next_state = IDLE;
    endcase
end

// Sequential: state, counters, outputs
always @(posedge tick_rate or negedge reset_i) begin
    if (!reset_i) begin
        current_state <= IDLE;
        bit_counter   <= 0;
        pop           <= 0;
        data_tx_o     <= 1'b1;
        data_buffer   <= 0;
    end else begin
        // State update
        current_state <= next_state;

        // Bit counter
        if (current_state == DATA)
            bit_counter <= bit_counter + 1;
        else
            bit_counter <= 0;

        // Outputs
        case (current_state)
            IDLE: begin
                data_tx_o <= 1'b1;
                pop       <= 1'b0;
            end
            START: begin
                data_buffer <= data_i; // Load data into buffer
                data_tx_o <= 1'b0;
                pop       <= 1'b1;  // pop at start bit
            end
            DATA: begin
                data_tx_o <= data_buffer[bit_counter];
                pop       <= 1'b0;
            end
            STOP: begin
                data_tx_o <= 1'b1;
                pop       <= 1'b0;
            end
        endcase
    end
end

endmodule
