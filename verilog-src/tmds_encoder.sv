/*
 * Module `tmds_encoder`
 *
 * tmds encoder. Based on: https://www.fpga4fun.com/HDMI.html,
 * but cleaned up, optimized and pipelined (5 cycle latency).
 *
 */

module tmds_encoder(
    input logic clk,
    input logic [7:0] vd,  
    input logic [1:0] cd,  
    input logic vde, 
    output logic [9:0] out
);

// Pipeline stage 1
wire [3:0] new_nb1s = vd[0] + vd[1] + vd[2] + vd[3] + vd[4] + vd[5] + vd[6] + vd[7];

logic [7:0] vd_pipeline1;
logic vde_pipeline1;
logic [3:0] nb1s_pipeline1;
logic [9:0] tmds_code_pipeline1;

always_ff @(posedge clk) begin 
    vd_pipeline1 <= vd;
    vde_pipeline1 <= vde;
    nb1s_pipeline1 <= new_nb1s;
    unique case (cd)
        2'b00: tmds_code_pipeline1 <= 10'b1101010100;
        2'b01: tmds_code_pipeline1 <= 10'b0010101011;
        2'b10: tmds_code_pipeline1 <= 10'b0101010100;
        2'b11: tmds_code_pipeline1 <= 10'b1010101011;
    endcase
end

// Pipeline stage 2
wire new_xnor = (nb1s_pipeline1 > 4'd4) || (nb1s_pipeline1 == 4'd4 && vd_pipeline1[0] == 1'b0);

logic xnor_pipeline2;
logic [7:0] vd_pipeline2;
logic vde_pipeline2;
logic [9:0] tmds_code_pipeline2;

always_ff @(posedge clk) begin 
    vd_pipeline2 <= vd_pipeline1;
    vde_pipeline2 <= vde_pipeline1;
    tmds_code_pipeline2 <= tmds_code_pipeline1;
    xnor_pipeline2 <= new_xnor;
end

// Pipeline stage 3
wire [8:0] new_q_m = {~xnor_pipeline2, new_q_m[6:0] ^ vd_pipeline2[7:1] ^ {7{xnor_pipeline2}}, 
                             vd_pipeline2[0]};

logic [8:0] q_m_pipeline3;
logic [7:0] vde_pipeline3;
logic [9:0] tmds_code_pipeline3;

always_ff @(posedge clk) begin 
    vde_pipeline3 <= vde_pipeline2;
    tmds_code_pipeline3 <= tmds_code_pipeline2;
    q_m_pipeline3 <= new_q_m;
end

// Pipeline stage 4
wire [3:0] new_balance = q_m_pipeline3[0] + q_m_pipeline3[1] + q_m_pipeline3[2] + q_m_pipeline3[3] 
    + q_m_pipeline3[4] + q_m_pipeline3[5] + q_m_pipeline3[6] + q_m_pipeline3[7] - 4'd4;

logic [3:0] balance_pipeline4;
logic [8:0] q_m_pipeline4;
logic [7:0] vde_pipeline4;
logic [9:0] tmds_code_pipeline4;

always_ff @(posedge clk) begin 
    q_m_pipeline4 <= q_m_pipeline3;
    vde_pipeline4 <= vde_pipeline3;
    tmds_code_pipeline4 <= tmds_code_pipeline3;
    balance_pipeline4 <= new_balance;
end

// Pipeline stage 5
wire [3:0] new_balance_acc_del_00 = balance_pipeline4 - (~q_m_pipeline4[8]);
wire [3:0] new_balance_acc_del_01 = q_m_pipeline4[8] ? balance_pipeline4 : -balance_pipeline4;
wire [3:0] new_balance_acc_del_10 = (q_m_pipeline4[8]) - balance_pipeline4;
wire [3:0] new_balance_acc_del_11 = q_m_pipeline4[8] ? balance_pipeline4 : -balance_pipeline4;

wire [9:0] new_tmds_data_00 = {1'b0, q_m_pipeline4[8], q_m_pipeline4[7:0] ^ {8{1'b0}}};
wire [9:0] new_tmds_data_01 = {~q_m_pipeline4[8], q_m_pipeline4[8], q_m_pipeline4[7:0] ^ {8{~q_m_pipeline4[8]}}};
wire [9:0] new_tmds_data_10 = {1'b1, q_m_pipeline4[8], q_m_pipeline4[7:0] ^ {8{1'b1}}};
wire [9:0] new_tmds_data_11 = {~q_m_pipeline4[8], q_m_pipeline4[8], q_m_pipeline4[7:0] ^ {8{~q_m_pipeline4[8]}}};

logic [3:0] balance_acc_del_00_pipeline5;
logic [3:0] balance_acc_del_01_pipeline5;
logic [3:0] balance_acc_del_10_pipeline5;
logic [3:0] balance_acc_del_11_pipeline5;

logic [9:0] tmds_data_00_pipeline5;
logic [9:0] tmds_data_01_pipeline5;
logic [9:0] tmds_data_10_pipeline5;
logic [9:0] tmds_data_11_pipeline5;

logic [3:0] balance_pipeline5;
logic [7:0] vde_pipeline5;
logic [9:0] tmds_code_pipeline5;

always_ff @(posedge clk) begin 
    balance_acc_del_00_pipeline5 <= new_balance_acc_del_00;
    balance_acc_del_01_pipeline5 <= new_balance_acc_del_01;
    balance_acc_del_10_pipeline5 <= new_balance_acc_del_10;
    balance_acc_del_11_pipeline5 <= new_balance_acc_del_11;
    
    tmds_data_00_pipeline5 <= new_tmds_data_00;
    tmds_data_01_pipeline5 <= new_tmds_data_01;
    tmds_data_10_pipeline5 <= new_tmds_data_10;
    tmds_data_11_pipeline5 <= new_tmds_data_11;
    
    vde_pipeline5 <= vde_pipeline4;
    tmds_code_pipeline5 <= tmds_code_pipeline4;
    balance_pipeline5 <= balance_pipeline4;
end

// Pipeline stage 6
logic [3:0] balance_acc = 0;

wire [3:0] balance_acc_del = balance_sign_eq ? (balance_zero ? balance_acc_del_11_pipeline5 : balance_acc_del_10_pipeline5) : (balance_zero ? balance_acc_del_01_pipeline5 : balance_acc_del_00_pipeline5);

wire [3:0] balance_acc_new = balance_acc + balance_acc_del;

wire [9:0] tmds_data = balance_sign_eq ? (balance_zero ? tmds_data_11_pipeline5 : tmds_data_10_pipeline5) : (balance_zero ? tmds_data_01_pipeline5 : tmds_data_00_pipeline5);

wire balance_sign_eq = (balance_pipeline5[3] == balance_acc[3]); 
wire balance_zero = (balance_pipeline5 == 0 || balance_acc == 0);

always_ff @(posedge clk) begin
    out <= vde_pipeline5 ? tmds_data : tmds_code_pipeline5;
    balance_acc <= vde_pipeline5 ? balance_acc_new : 4'h0;
end

endmodule : tmds_encoder