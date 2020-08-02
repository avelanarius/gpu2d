/*
 * Module `vram`
 *
 * True dual port RAM used for storing
 * (part of) scanline to be displayed.
 *
 * 1024 x 8 bits 
 *
 */
 
module vram(
    input clk_a,
    input we_a,
    input [9:0] addr_a,
    input [7:0] d_a,
    output [7:0] q_a,
    
    input clk_b,
    input we_b,
    input [9:0] addr_b,
    input [7:0] d_b,
    output [7:0] q_b
 );
 
logic [7:0] ram[1023:0]; 
 
always_ff @(posedge clk_a) begin
    if (we_a) begin
        ram[addr_a] <= d_a;
    end
    q_a <= ram[addr_a];
end

always_ff @(posedge clk_b) begin
    if (we_b) begin
        ram[addr_b] <= d_b;
    end
    q_b <= ram[addr_b];
end
 
endmodule : vram