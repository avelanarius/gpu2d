/*
 * Module `video`
 *
 * Generates video data with
 * appropriate video signal timings as
 * specified using module parameters.
 *
 * See: https://tomverbeure.github.io/video_timings_calculator
 * for timings. Default value represent 800x600 @60Hz CVT-RB. 
 *
 */

module video #(
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
    
    output logic vsync,
    output logic hsync,
    output logic draw_area,
    
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

logic [(H_COUNTER_WIDTH - 1):0] counter_h;
logic [(V_COUNTER_WIDTH - 1):0] counter_v;

logic [10:0] licznik;

always_ff @(posedge clk) begin
    draw_area <= (counter_h < H_PIXELS && counter_v < V_PIXELS);
    
    if (counter_h == (H_TOTAL - 1)) begin
        counter_h <= 0;
        if (counter_v == (V_TOTAL - 1)) begin
            counter_v <= 0;
        end
        else begin
            counter_v <= counter_v + 1;
        end
    end
    else begin
        counter_h <= counter_h + 1;
    end
	 
	 if (counter_h == 0 && counter_v == 0) licznik <= licznik + 75;
        
    hsync <= (counter_h >= (H_PIXELS + H_FRONT_PORCH) && counter_h < (H_PIXELS + H_FRONT_PORCH + H_SYNC)); 
    vsync <= (counter_v >= (V_PIXELS + V_FRONT_PORCH) && counter_v < (V_PIXELS + V_FRONT_PORCH + V_SYNC)); 
end

always_comb begin
    if (draw_area) begin
        /* @FIXME(Piotr Grabowski, 2020-07-31): lint_off for testing. */
        /* verilator lint_off WIDTH */
        red = counter_h / 8;
        green = counter_h / 4 + licznik;
        blue = counter_h | counter_v;
        /* verilator lint_on WIDTH */
    end
    else begin
        red = 0;
        green = 0;
        blue = 0;
    end
end

endmodule : video
