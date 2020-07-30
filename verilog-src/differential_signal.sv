/*
 * Module `differential_signal`
 *
 * Implements differential signaling used in 
 * Transition-minimized differential signaling (TMDS).
 *
 */

module differential_signal(
    input logic signal,
    output logic p,
    output logic n
);

always_comb begin
    p <= signal;
    n <= !signal;
end

endmodule : differential_signal
