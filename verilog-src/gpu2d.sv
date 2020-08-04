/*
 * Module `gpu2d`
 *
 * Main module of the project, implementing
 * a 2D graphics GPU with HDMI output interface.
 *
 * Parts of core HDMI code based on
 * https://maximator-fpga.org/examples/
 */
 
module gpu2d(
    input logic clk,
    
    /* HDMI port pins. */
    output logic [2:0] datap,
    output logic [2:0] datan,
    output logic clkp,
    output logic clkn
);

logic [9:0] vram1_addr_a;
logic [7:0] vram1_q_a;

logic [9:0] vram2_addr_a;
logic [7:0] vram2_q_a;
    
logic vram1_we_b;
logic [9:0] vram1_addr_b;
logic [7:0] vram1_d_b;

logic vram2_we_b;
logic [9:0] vram2_addr_b;
logic [7:0] vram2_d_b;

logic [9:0] cbram_addr_a;
logic [7:0] cbram_q_a;

vram vram1(
    .clk_a(pixel_clock),
    .we_a(1'b0),
    .addr_a(vram1_addr_a),
    .d_a(8'b0),
    .q_a(vram1_q_a),
    
    .clk_b(renderer_clock),
    .we_b(vram1_we_b),
    .addr_b(vram1_addr_b),
    .d_b(vram1_d_b)
);

vram vram2(
    .clk_a(pixel_clock),
    .we_a(1'b0),
    .addr_a(vram2_addr_a),
    .d_a(8'b0),
    .q_a(vram2_q_a),
    
    .clk_b(renderer_clock),
    .we_b(vram2_we_b),
    .addr_b(vram2_addr_b),
    .d_b(vram2_d_b)
);

cbram cb(
   .clk_a(renderer_clock),
   .we_a(1'b0),
   .addr_a(cbram_addr_a),
   .d_a(8'b0),
   .q_a(cbram_q_a),
   
   .clk_b(renderer_clock),
   .we_b(1'b0)
);

logic pixel_clock;
logic tmds_clock;
logic renderer_clock;

/* tmds_clock is expected to clocked with 10x frequency of pixel_clock. */
pll pll(
    .inclk0(clk),
    .c0(tmds_clock),
    .c1(pixel_clock),
    .c2(renderer_clock)
);

logic hsync, vsync, draw_area;
logic [7:0] red, green, blue;

/* 800x600 @60Hz CVT-RB. */
video #(
    .H_PIXELS(800),
    .H_FRONT_PORCH(48),
    .H_SYNC(32),
    .H_BACK_PORCH(80),
    
    .V_PIXELS(600),
    .V_FRONT_PORCH(3),
    .V_SYNC(4),
    .V_BACK_PORCH(11)
) video(
    .clk(pixel_clock),
    
    .vsync(vsync),
    .hsync(hsync),
    
    .vram_even_addr(vram1_addr_a),
    .vram_even_q(vram1_q_a),
     
    .vram_odd_addr(vram2_addr_a),
    .vram_odd_q(vram2_q_a),
     
    .draw_area(draw_area),
    .red(red),
    .green(green),
    .blue(blue)
);

renderer render(
    .clk(renderer_clock),
    .pixel_clk(pixel_clock),

	 .cbram_addr(cbram_addr_a),
	 .cbram_q(cbram_q_a),
	 
    .vram_even_we(vram1_we_b),
    .vram_even_addr(vram1_addr_b),
    .vram_even_d(vram1_d_b),
    
    .vram_odd_we(vram2_we_b),
    .vram_odd_addr(vram2_addr_b),
    .vram_odd_d(vram2_d_b)
);

logic [9:0] tmds_red, tmds_green, tmds_blue;
logic [9:0] tmds_shift_red, tmds_shift_green, tmds_shift_blue;

tmds_encoder tmds_r(
    .clk(pixel_clock), 
    .vd(red), 
    .cd(2'b00), 
    .vde(draw_area), 
    .out(tmds_red)
);

tmds_encoder tmds_g(
    .clk(pixel_clock), 
    .vd(green), 
    .cd(2'b00), 
    .vde(draw_area), 
    .out(tmds_green)
);

tmds_encoder tmds_b(
    .clk(pixel_clock), 
    .vd(blue), 
    .cd({vsync, hsync}), 
    .vde(draw_area), 
    .out(tmds_blue)
);

shift_register #(
    .N(10)
) shift_r(
    .clk(tmds_clock),
    .in(tmds_red),
    .out(tmds_shift_red)
);

shift_register #(
    .N(10)
) shift_g(
    .clk(tmds_clock),
    .in(tmds_green),
    .out(tmds_shift_green)
);

shift_register #(
    .N(10)
) shift_b(
    .clk(tmds_clock),
    .in(tmds_blue),
    .out(tmds_shift_blue)
);

differential_signal ds_clk(
    .signal(pixel_clock),
    .p(clkp),
    .n(clkn)
);

differential_signal ds_r(
    .signal(tmds_shift_red[0]),
    .p(datap[2]),
    .n(datan[2])
);

differential_signal ds_g(
    .signal(tmds_shift_green[0]),
    .p(datap[1]),
    .n(datan[1])
);

differential_signal ds_b(
    .signal(tmds_shift_blue[0]),
    .p(datap[0]),
    .n(datan[0])
);

endmodule : gpu2d
