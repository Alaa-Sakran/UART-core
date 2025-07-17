module clock_divider #(parameter DIVISOR = 2)
(
    input wire clk_i,
    input wire reset_i,
    output reg clk_out
);
localparam count_max = DIVISOR-1; // Maximum count value based on divisor
localparam count_width = $clog2(DIVISOR); // Calculate width of the counter
localparam half_count_max = count_max / 2; // Half of the maximum count value
reg [count_width-1:0] baud_div; // Counter to divide the clock

always @(posedge clk_i or negedge reset_i) begin
    if (!reset_i) begin
        baud_div <= 0;
        clk_out <= 0;
    end else begin
        if (baud_div == half_count_max ) begin
            clk_out <= ~clk_out; // Toggle output clock
            baud_div <= baud_div + 1; // Increment counter
        end else if (baud_div == count_max ) begin
            clk_out <= ~clk_out; // Toggle output clock
            baud_div <= 0; // Reset counter
            end
        else baud_div <= baud_div + 1; // Increment counter
            
        
    end
end


endmodule
