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
     input logic pixel_clk,
    
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

logic [5:0] frame_no;

always_ff @(posedge pixel_clk) begin  
    if (counter_h == (H_TOTAL - 1)) begin
        counter_h <= 0;
        if (counter_v == (V_TOTAL - 1)) begin
            counter_v <= 0;
            scanline_parity <= 1;
            frame_no <= frame_no + 1;
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

typedef enum {HALT, PIXEL} e_cycle_type;

e_cycle_type current_cycle;
logic [(V_COUNTER_WIDTH - 1):0] current_v;
logic [(H_COUNTER_WIDTH - 1):0] current_h;

e_cycle_type next_cycle;
logic [(V_COUNTER_WIDTH - 1):0] next_v;
logic [(H_COUNTER_WIDTH - 1):0] next_h;

logic next_vram_we;
logic [9:0] next_vram_addr;
logic [7:0] next_vram_d;

logic next_vram_even_we;
logic [9:0] next_vram_even_addr;
logic [7:0] next_vram_even_d;
    
logic next_vram_odd_we;
logic [9:0] next_vram_odd_addr;
logic [7:0] next_vram_odd_d;

always_comb begin
    if (current_cycle == PIXEL) begin
        next_vram_we = 1'b1;
        next_vram_addr = current_h;
        next_vram_d = (current_h + current_v + frame_no <= 333 && current_h + current_v + frame_no >= 111 ? 8'b11111111 : 8'b0000000);
        if (current_h == 500) begin
            next_cycle = HALT;
            next_h = 500;
            next_v = current_v;
        end
        else begin
            next_cycle = PIXEL;
            next_h = current_h + 1;
            next_v = current_v;
        end
    end
    else /*if (current_cycle == HALT)*/ begin
        next_vram_we = 1'b0;
        next_vram_addr = 10'b0;
        next_vram_d = 8'b0;
        next_cycle = HALT;
        next_v = current_v;
        next_h = current_h;
    end
    
    if (!next_vram_we) begin
        next_vram_even_we = 1'b0;
        next_vram_odd_we = 1'b0;
             
      next_vram_even_addr = 0;
      next_vram_even_d = 0;
      next_vram_odd_addr = 0;
      next_vram_odd_d = 0;
    end
    else if (scanline_parity) begin
      next_vram_even_we = 1'b1;
      next_vram_odd_we = 1'b0;
        
      next_vram_even_addr = next_vram_addr;
      next_vram_even_d = next_vram_d;
      next_vram_odd_addr = 0;
      next_vram_odd_d = 0;
    end
    else begin
      next_vram_even_we = 1'b0;
      next_vram_odd_we = 1'b1;
        
      next_vram_odd_addr = next_vram_addr;
      next_vram_odd_d = next_vram_d;
      next_vram_even_addr = 0;
      next_vram_even_d = 0;
    end
end

always_ff @(posedge clk) begin
    if (next_v != counter_v) begin
        vram_even_we <= 1'b0;
        vram_odd_we <= 1'b0;
        vram_even_addr <= 0;
        vram_even_d <= 0;
        vram_odd_addr <= 0;
        vram_odd_d <= 0;    
        current_cycle <= PIXEL;
        current_v <= counter_v;
        current_h <= 0;
    end
    else begin
        vram_even_we <= next_vram_even_we;
        vram_odd_we <= next_vram_odd_we;
        vram_even_addr <= next_vram_even_addr;
        vram_even_d <= next_vram_even_d;
        vram_odd_addr <= next_vram_odd_addr;
        vram_odd_d <= next_vram_odd_d;  
        current_cycle <= next_cycle;
        current_v <= next_v;
        current_h <= next_h;
    end
end

endmodule : renderer
