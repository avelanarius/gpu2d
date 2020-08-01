#include <iostream>
#include <fstream>

#include <verilated.h>
#include "verilator-generated/gpu2d.h"

/* 
 * 800x600 @60Hz CVT-RB video timings. 
 * See: https://tomverbeure.github.io/video_timings_calculator 
 */
constexpr auto H_PIXELS = 800;
constexpr auto H_FRONT_PORCH = 48;
constexpr auto H_SYNC = 32;
constexpr auto H_BACK_PORCH = 80;
constexpr auto H_BLANK = H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;
constexpr auto H_TOTAL = H_PIXELS + H_BLANK;
    
constexpr auto V_PIXELS = 600;
constexpr auto V_FRONT_PORCH = 3;
constexpr auto V_SYNC = 4;
constexpr auto V_BACK_PORCH = 11;
constexpr auto V_BLANK = V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;
constexpr auto V_TOTAL = V_PIXELS + V_BLANK;

constexpr auto FRAME_COUNT = 5;

void render_frame(gpu2d& instance, int frame) {
    auto filename = "frame" + std::to_string(frame) + ".pgm";
    std::ofstream of(filename, std::ofstream::out | std::ofstream::binary);

    of << "P6\n";
    of << H_PIXELS << " " << V_PIXELS << "\n";
    of << "255\n";

    for (int v = 0; v < V_TOTAL; v++) {
        for (int h = 0; h < H_TOTAL; h++) {
            instance.clk = 1;
            instance.eval();

            instance.clk = 0;
            instance.eval();

            if (v >= V_PIXELS || h >= H_PIXELS) continue;

            char r = instance.red;
            char g = instance.green;
            char b = instance.blue;

            of.write(&r, 1);
            of.write(&g, 1);
            of.write(&b, 1);
        }
    }
}

int main() {
    gpu2d instance;

    for (int frame = 1; frame <= FRAME_COUNT; frame++) {
        render_frame(instance, frame);
    }

    return 0;
}
