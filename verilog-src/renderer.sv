/*
 * Module `renderer`
 *
 * Renders pixels to VRAM.
 *
 * Default timings are for 800x600 @60Hz CVT-RB. 
 *
 */

module renderer #(
    parameter H_PIXELS = 800,
    parameter H_FRONT_PORCH = 48,
    parameter H_SYNC = 32,
    parameter H_BACK_PORCH = 80,
    parameter H_BLANK = H_FRONT_PORCH + H_SYNC + H_BACK_PORCH,
    parameter H_TOTAL = H_PIXELS + H_BLANK,
    
    parameter H_COUNTER_WIDTH = $clog2(H_TOTAL),
    
    parameter V_PIXELS = 600,
    parameter V_FRONT_PORCH = 3,
    parameter V_SYNC = 4,
    parameter V_BACK_PORCH = 11,
    parameter V_BLANK = V_FRONT_PORCH + V_SYNC + V_BACK_PORCH,
    parameter V_TOTAL = V_PIXELS + V_BLANK,
    
    parameter V_COUNTER_WIDTH = $clog2(V_TOTAL)
)(
    input logic clk,
    
    output vram_even_we,
    output [9:0] vram_even_addr,
    output [7:0] vram_even_d,
    
    output vram_odd_we,
    output [9:0] vram_odd_addr,
    output [7:0] vram_odd_d
);

logic [(H_COUNTER_WIDTH - 1):0] counter_h;
logic [(V_COUNTER_WIDTH - 1):0] counter_v;

/* While `video` module displays a scanline, this module will render the other scanline. */
logic scanline_parity = 1;

always_ff @(posedge clk) begin    
    if (counter_h == (H_TOTAL - 1)) begin
        counter_h <= 0;
        if (counter_v == (V_TOTAL - 1)) begin
            counter_v <= 0;
                scanline_parity <= 1;
        end
        else begin
            counter_v <= counter_v + 1;
                scanline_parity <= !scanline_parity;
        end
    end
    else begin
        counter_h <= counter_h + 1;
    end
end

always_ff @(posedge clk) begin
    if (scanline_parity) begin
        vram_even_we <= 1'b1;
        vram_odd_we <= 1'b0;
        
        vram_even_addr <= counter_h;
        vram_even_d <= (counter_h + counter_v <= 333 ? 8'b11111111 : 8'b0000000);
    end
    else begin
       vram_even_we <= 1'b0;
        vram_odd_we <= 1'b1;
        
        vram_odd_addr <= counter_h;
        vram_odd_d <= (counter_h + counter_v <= 333 ? 8'b11111111 : 8'b0000000);
    end
end

endmodule : renderer
