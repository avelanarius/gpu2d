.PHONY: clean

verilator-generated:
	verilator -Wall -cc ../verilog-src/video.sv --prefix gpu2d --Mdir verilator-generated

render-frames: verilator-generated render-frames.cpp
	g++ verilator-generated/gpu2d.cpp verilator-generated/gpu2d__Syms.cpp /usr/share/verilator/include/verilated.cpp render-frames.cpp -o render-frames -I/usr/share/verilator/include

clean:
	rm -rf verilator-generated
	rm -rf render-frames
