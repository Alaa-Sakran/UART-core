module fifo #(
    parameter WIDTH = 8,
    parameter SIZE  = 16
)(
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  data_i,
    input  wire              wr_en,
    input  wire              pop,
    output reg               overrun_o,
    output reg               underrun_o,
    output wire [WIDTH-1:0]  data_o,
    output wire              full_o,
    output wire              empty_o,
    output wire              backpressure_o
);
  localparam PTR_WIDTH = $clog2(SIZE);
  reg [WIDTH-1:0] fifo_mem [0:SIZE-1];
  reg [PTR_WIDTH-1:0] head, tail;
  wire [PTR_WIDTH-1:0] head_next = (head == SIZE-1) ? 0 : head + 1;
  wire [PTR_WIDTH-1:0] tail_next = (tail == SIZE-1) ? 0 : tail + 1;

  assign empty_o        = (head == tail);
  assign full_o         = (head_next == tail);
  assign backpressure_o = ( (head + 3) >= SIZE ? ((head + 3) - SIZE) : (head + 3) ) == tail;
  assign data_o         = fifo_mem[tail];

  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      head       <= 0;
      tail       <= 0;
      overrun_o  <= 0;
      underrun_o <= 0;
    end else begin
      if (wr_en) begin
        if (!full_o) begin
          fifo_mem[head] <= data_i;
          head           <= head_next;
          overrun_o      <= 0;
        end else begin
          overrun_o      <= 1;
        end
      end
      if (pop) begin
        if (!empty_o) begin
          tail        <= tail_next;
          underrun_o  <= 0;
        end else begin
          underrun_o  <= 1;
        end
      end
    end
  end
endmodule
