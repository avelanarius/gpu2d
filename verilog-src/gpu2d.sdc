create_clock -name {clk} -period 100.000 -waveform { 0.000 50.000 } [get_ports { clk }]
derive_pll_clocks
derive_clock_uncertainty
