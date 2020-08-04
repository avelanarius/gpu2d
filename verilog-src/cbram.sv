/*
 * Module `cbram`
 *
 * True dual port RAM used for storing
 * command buffer.
 *
 * 1024 x 8 bits 
 *
 */
 
module cbram(
    input clk_a,
    input we_a,
    input [9:0] addr_a,
    input [7:0] d_a,
    output [7:0] q_a,
    
    input clk_b,
    input we_b,
    input [9:0] addr_b,
    input [7:0] d_b,
    output [7:0] q_b
 );
 
logic [7:0] ram[1023:0]; 
initial begin
    // Z
    ram[0] = 79 / 3;
    ram[1] = 76 / 3;
    ram[2] = 123 / 3;
    ram[3] = 79 / 3;
    ram[4] = 153 / 3;
    ram[5] = 80 / 3;
    ram[6] = 142 / 3;
    ram[7] = 116 / 3;
    ram[8] = 100 / 3;
    ram[9] = 174 / 3;
    ram[10] = 71 / 3;
    ram[11] = 210 / 3;
    ram[12] =147 / 3;
    ram[13] =211 / 3;
    ram[14] =174 / 3;
    ram[15] =208 / 3;
    // O
    ram[16] =440 / 3;
    ram[17] =85 / 3;
    ram[18] =449 / 3;
    ram[19] =104 / 3;
    ram[20] =510 / 3;
    ram[21] =145 / 3;
    ram[22] =500 / 3;
    ram[23] =192 / 3;
    ram[24] =444 / 3;
    ram[25] =206 / 3;
    ram[26] =390 / 3;
    ram[27] =156 / 3;
    ram[28] =395 / 3;
    ram[29] =123 / 3;
    // C
    ram[30] =173 / 3;
    ram[31] =340 / 3;
    ram[32] =119 / 3;
    ram[33] =333 / 3;
    ram[34] =87 / 3;
    ram[35] =369 / 3;
    ram[36] =77 / 3;
    ram[37] =407 / 3;
    ram[38] =94 / 3 ;
    ram[39] =437 / 3;
    ram[40] =147 / 3;
    ram[41] =461 / 3;
    ram[42] =180 / 3;
    ram[43] =444 / 3;
    // H
    ram[44] =365 / 3;
    ram[45] =325/ 3;
    ram[46] =361/ 3;
    ram[47] =367/ 3;
    ram[48] =364/ 3;
    ram[49] =404/ 3;
    ram[50] =364/ 3;
    ram[51] =434/ 3;
    ram[52] =364/ 3;
    ram[53] =457/ 3;
    ram[54] =398/ 3;
    ram[55] =389/ 3;
    ram[56] =431/ 3;
    ram[57] =389/ 3;
    ram[58] =453/ 3;
    ram[59] =326/ 3;
    ram[60] =454/ 3;
    ram[61] =358/ 3;
    ram[62] =455/ 3;
    ram[63] =387/ 3;
    ram[64] =457/ 3;
    ram[65] =419/ 3;
    ram[66] =455/ 3;
    ram[67] =452/ 3;
    // U
    ram[68] =581/ 3;
    ram[69] =328/ 3;
    ram[70] =581/ 3;
    ram[71] =363/ 3;
    ram[72] =576/ 3;
    ram[73] =410/ 3;
    ram[74] =587/ 3;
    ram[75] =442/ 3;
    ram[76] =611/ 3;
    ram[77] =457/ 3;
    ram[78] =645/ 3;
    ram[79] =458/ 3;
    ram[80] =669/ 3;
    ram[81] =442/ 3;
    ram[82] =670/ 3;
    ram[83] =403/ 3;
    ram[84] =671/ 3;
    ram[85] =370/ 3;
    ram[86] =670/ 3;
    ram[87] =331/ 3;
    // other
    ram[88] =119/ 3;
    ram[89] =146/ 3;
    ram[90] =495/ 3;
    ram[91] =94/ 3;
    ram[92] =400/ 3;
    ram[93] =190/ 3;
    ram[94] =97/ 3;
    ram[95] =209/ 3;
    ram[96] =170/ 3;
    ram[97] =79/ 3;
    //ram[6] = 
end
 
always_ff @(posedge clk_a) begin
    if (we_a) begin
        ram[addr_a] <= d_a;
    end
    q_a <= ram[addr_a];
end

always_ff @(posedge clk_b) begin
    if (we_b) begin
        ram[addr_b] <= d_b;
    end
    q_b <= ram[addr_b];
end
 
endmodule : cbram