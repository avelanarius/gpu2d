/*
 * Module `shift_register`
 *
 * Implements a shift register, which
 * reads a new value every N cycles
 * from `in` into `out` and shifts
 * `out` by 1 bit every cycle, filling empty
 * bits with zeros.
 *
 */

module shift_register #(
    parameter N,
    parameter COUNTER_WIDTH = $clog2(N)
)(
    input logic clk,
    input logic [(N - 1):0] in,
    output logic [(N - 1):0] out
);

logic [(COUNTER_WIDTH - 1):0] counter = 0;

always_ff @(posedge clk) begin
    if (counter == (N - 1)) begin
        counter <= 0;
        out <= in;
    end
    else begin
        counter <= counter + 1;
        out <= {1'b0, out[(N - 1):1]};
    end
end
    
endmodule : shift_register
