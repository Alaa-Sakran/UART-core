module AXI_UART_RX #(
    parameter baud_rate = 9600,
    parameter WIDTH = 8,
    parameter clk = 200_000,
    parameter sampling_frequency = 8
)(
    input  wire                 clk_i,
    input  wire                 reset_i,
    input  wire                 data_rx_i,
    input  wire                 clear_break_flag,
    input  wire                 framing_control_flag_i,
    input  wire                 overrun_control_flag_i,
    input  wire                 underrun_control_flag_i,
    input  wire                 backpressure_i,
    output wire                 sampling_rate,
    output reg  [WIDTH-1:0]     word_o,
    output reg                  fifo_wr_en,
    output wire                  valid_o,
    output reg                  break_flag,
    output reg  [1:0]           break_counter,
    output reg                  framing_error_flag_o,
    output wire                 overrun_flag_o,
    output wire                 underrun_flag_o
);

// Local parameters
localparam counter_width           = $clog2(WIDTH);
localparam divisor                 = clk / baud_rate;
localparam sampling_divisor       = divisor / sampling_frequency;
localparam sampling_counter_width = $clog2(sampling_frequency);
localparam half_point             = sampling_frequency / 2;

// FSM states
localparam IDLE       = 2'b00;
localparam RECEIVING  = 2'b01;
localparam STOP       = 2'b10;
localparam [1 : 0] NO_BREAK = 2'b00;
localparam [1 : 0] START_BREAK = 2'b01;
localparam [1 : 0] ONGOING_BREAK = 2'b11;

// Internal signals
reg [1:0]               current_state, next_state;
reg [sampling_counter_width-1:0] sampling_counter;
reg [counter_width-1:0] bit_number_counter;
reg sampled_array [3:0];
reg sync0, sync1;

// Error flags auto-clear logic

assign underrun_flag_o = underrun_control_flag_i ? 1'b0 : underrun_flag_o; // left as user logic
assign valid_o = fifo_wr_en;
assign overrun_flag_o  = overrun_control_flag_i ? 1'b0 : overrun_flag_o;

// Clock divider for sampling_rate
clock_divider #(sampling_divisor) clk_div (
    .clk_i   (clk_i),
    .reset_i (reset_i),
    .clk_out (sampling_rate)
);

// Combinational next-state logic
always @* begin
    // default next state
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (sampling_counter == sampling_frequency-1 && sampled_array[3] == 1'b0)
                next_state = RECEIVING;
        end
        RECEIVING: begin
            if (sampling_counter == sampling_frequency-1 && bit_number_counter == WIDTH-1)
                next_state = STOP;
        end
        STOP: begin
            if (sampling_counter == sampling_frequency-1)
                next_state = IDLE;
        end
    endcase
end

// Sequential logic for FSM and outputs
always @(posedge sampling_rate or negedge reset_i) begin
    if (!reset_i) begin
        // Reset all registers
        current_state         <= IDLE;
        sampling_counter      <= 0;
        bit_number_counter    <= 0;
        word_o                <= 0;
        fifo_wr_en            <= 0;
        break_flag            <= 0;
        break_counter         <= 2'b00;
        framing_error_flag_o  <= 0;
        sampled_array[0]      <= 0;
        sampled_array[1]      <= 0;
        sampled_array[2]      <= 0;
        sampled_array[3]      <= 1'b1;
        sync0                 <= 1'b1;
        sync1                 <= 1'b1;
    end else begin
        // Synchronize input
        sync0 <= data_rx_i;
        sync1 <= sync0;
        // Sample at each tick
        sampled_array[3] <= sampled_array[2];
        sampled_array[2] <= sampled_array[1];
        sampled_array[1] <= sampled_array[0];
        sampled_array[0] <= sync1;

        // Sampling counter
        if (sampling_counter == sampling_frequency-1)
            sampling_counter <= 0;
        else
            sampling_counter <= sampling_counter + 1;

        // Bit counter
        if (current_state == RECEIVING && sampling_counter == sampling_frequency-1)
            bit_number_counter <= bit_number_counter + 1;
        else if (current_state == IDLE)
            bit_number_counter <= 0;

        // State transition
        current_state <= next_state;

        // Outputs based on state
        case (current_state)
            IDLE: begin
                fifo_wr_en    <= 0;
                fifo_wr_en <= 0;
            end
            RECEIVING: begin
                fifo_wr_en    <= 0;
                fifo_wr_en <= 0;
            end
            STOP: begin
                if (sampling_counter == sampling_frequency-1) begin
                    // Evaluate stop bit
                    fifo_wr_en <= (sampled_array[3] == 1'b1);
                    framing_error_flag_o <= (sampled_array[3] == 1'b1) ? 0 : 1;
                    // Break detection
                    if (!fifo_wr_en && word_o == 0) begin
                        if (break_counter == NO_BREAK)
                            break_counter <= START_BREAK;
                        else if (break_counter == START_BREAK)
                            break_counter <= ONGOING_BREAK;
                        break_flag <= (break_counter == START_BREAK);
                    end
                end
            end
        endcase

        // Data assembly in RECEIVING
        if (current_state == RECEIVING && sampling_counter == half_point) begin
            // Majority vote of sampled_array[1:3]
            if ((sampled_array[1] + sampled_array[2] + sampled_array[3]) >= 2)
                word_o[bit_number_counter] <= 1'b1;
            else
                word_o[bit_number_counter] <= 1'b0;
        end

        // Clear flags on control signals
        if (framing_control_flag_i)
            framing_error_flag_o <= 0;
        if (clear_break_flag)
            break_flag <= 0;
    end
end

endmodule
