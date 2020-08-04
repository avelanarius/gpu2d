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
    
	output [9:0] cbram_addr,
    input [7:0] cbram_q,
	 
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

typedef enum {HALT, FETCH_X, FETCH_Y, POST_FETCH, PIXEL} e_cycle_type;

e_cycle_type current_cycle;
logic [(V_COUNTER_WIDTH - 1):0] current_v;

logic [(V_COUNTER_WIDTH - 1):0] current_v_min;
logic [(V_COUNTER_WIDTH - 1):0] current_v_max;

logic [(H_COUNTER_WIDTH - 1):0] current_h;
logic [(H_COUNTER_WIDTH - 1):0] current_h_max;

e_cycle_type next_cycle;
logic [(V_COUNTER_WIDTH - 1):0] next_v;

logic [(V_COUNTER_WIDTH - 1):0] next_v_min;
logic [(V_COUNTER_WIDTH - 1):0] next_v_max;

logic [(H_COUNTER_WIDTH - 1):0] next_h;
logic [(H_COUNTER_WIDTH - 1):0] next_h_max;

logic [7:0] current_color;
logic [7:0] next_color;

logic next_vram_we;
logic [9:0] next_vram_addr;
logic [7:0] next_vram_d;

logic next_vram_even_we;
logic [9:0] next_vram_even_addr;
logic [7:0] next_vram_even_d;
    
logic next_vram_odd_we;
logic [9:0] next_vram_odd_addr;
logic [7:0] next_vram_odd_d;

logic [9:0] next_cbram_addr = 0;

always_comb begin
    next_h_max = current_h_max;
    next_v_max = current_v_max;
    next_v_min = current_v_min;
    next_color = current_color;
    next_cbram_addr = cbram_addr;

    if (current_cycle == FETCH_X) begin
        next_cbram_addr = next_cbram_addr + 1;
        next_vram_we = 1'b0;
        next_vram_addr = 10'b0;
        next_vram_d = 8'b0;
        next_v = current_v;
        next_h = current_h;
        if (next_cbram_addr == 99) begin
            next_cycle = HALT;
        end
        else begin
            next_cycle = FETCH_Y;
        end
    end
    else if (current_cycle == FETCH_Y) begin
        next_cbram_addr = next_cbram_addr + 1;
        next_vram_we = 1'b0;
        next_vram_addr = 10'b0;
        next_vram_d = 8'b0;
        next_v = current_v;
        next_h = cbram_q * 3;
        next_h_max = next_h + 32;
        next_cycle = POST_FETCH;
    end
    else if (current_cycle == POST_FETCH) begin
        next_vram_we = 1'b0;
        next_vram_addr = 10'b0;
        next_vram_d = 8'b0;
        next_v = current_v;
        next_v_min = cbram_q * 3;
        next_v_max = next_v_min + 32;
        if (current_v <= next_v_max && current_v >= next_v_min) begin
            next_cycle = PIXEL;
        end
        else begin
            next_cycle = FETCH_X;
        end
        next_h = current_h;
        next_color = 8'b11111111;
    end
    else if (current_cycle == PIXEL) begin
        next_vram_we = 1'b1;
        next_vram_addr = current_h;
        next_vram_d = current_color;
        if (current_h == current_h_max) begin
            next_cycle = FETCH_X;
            next_h = H_PIXELS;
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
    else if (!scanline_parity) begin
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
    if (counter_h == 0/*current_v != counter_v*/) begin
        vram_even_we <= 1'b0;
        vram_odd_we <= 1'b0;
        vram_even_addr <= 0;
        vram_even_d <= 0;
        vram_odd_addr <= 0;
        vram_odd_d <= 0;    
        current_cycle <= PIXEL;
        current_v <= counter_v;
        current_h <= 0;
        current_h_max <= 800;
        current_v_max <= 600;
        current_v_min <= 0;
        current_color <= 55;
        cbram_addr <= 0;
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
        current_h_max <= next_h_max;
        current_v_max <= next_v_max;
        current_v_min <= next_v_min;
        current_color <= next_color;
        cbram_addr <= next_cbram_addr;
    end
end

endmodule : renderer
