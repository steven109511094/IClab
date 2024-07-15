//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================

input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Parameter & Interger
// ===============================================================

parameter IDLE  = 0,
          IN    = 1,
          CAL   = 2,
          OUT_0 = 3,
          OUT_1 = 4,
          OUT_2 = 5,
          OUT_3 = 6,
          OUT_4 = 7;

parameter A = 8'b00000001, // idx of A in height & code: 0
          B = 8'b00000010, // idx of B in height & code: 1
          C = 8'b00000100, // idx of C in height & code: 2
          E = 8'b00001000, // idx of E in height & code: 3
          I = 8'b00010000, // idx of I in height & code: 4
          L = 8'b00100000, // idx of L in height & code: 5
          O = 8'b01000000, // idx of O in height & code: 6
          V = 8'b10000000; // idx of V in height & code: 7

integer i;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================

// FSM
reg  [2:0] state;
reg  [2:0] state_nxt;

reg  [2:0] cnt_in_8;
wire [2:0] cnt_in_8_nxt;

// INPUT
reg  in_valid_reg;
wire in_valid_nxt;

reg  out_mode_reg;
wire out_mode_nxt;

// restore character of node
reg  [7:0] char         [8];
reg  [7:0] char_nxt     [8];

// restore weight of node
reg  [4:0] weight       [8];
reg  [4:0] weight_nxt   [8];

// restore height(depth) of node
reg  [3:0] height       [8];
reg  [3:0] height_nxt   [8];

// restore huffman code(reverse) of node
reg  [7:0] code         [8];
reg  [7:0] code_nxt     [8];

reg  [7:0] text;

// CAL
// wire for connecting different encode layer
// only use [7][8] actually, but i am lazy to fix it zzz
reg  [7:0] sort_char    [8][8];
reg  [7:0] comb_char    [8][8];

reg  [4:0] sort_weight  [8][8];
reg  [4:0] comb_weight  [8][8];

reg  [3:0] comb_height  [8][8];

reg  [7:0] comb_code    [8][8];

// OUTPUT
reg  [7:0] out;
reg  [7:0] out_nxt;

reg  [3:0] out_height;
reg  [3:0] out_height_nxt;

wire out_valid_nxt;
wire out_code_nxt;

// Sort IP
wire [7:0] sort_in_char;
wire [9:0] sort_in_wgt;
wire [7:0] sort_out_char;

// ===============================================================
// FSM
// ===============================================================

// DFF of state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_nxt;
    end
end

// comb of state
always @(*) begin
    case (state)
        IDLE: state_nxt = (in_valid) ? IN : IDLE;
        IN: state_nxt = (cnt_in_8 == 7) ? CAL : IN;
        CAL: state_nxt = OUT_0;
        OUT_0: state_nxt = (out_height == 1) ? OUT_1 : OUT_0;
        OUT_1: state_nxt = (out_height == 1) ? OUT_2 : OUT_1;
        OUT_2: state_nxt = (out_height == 1) ? OUT_3 : OUT_2;
        OUT_3: state_nxt = (out_height == 1) ? OUT_4 : OUT_3;
        OUT_4: state_nxt = (out_height == 1) ? IDLE : OUT_4;
    endcase
end

// DFF of cnt_in_8
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_in_8 <= 0;
    end
    else begin
        cnt_in_8 <= cnt_in_8_nxt;
    end
end

// comb of cnt_in_8
assign cnt_in_8_nxt = (in_valid) ? cnt_in_8 + 1 : cnt_in_8;

// ===============================================================
// INPUT
// ===============================================================

// DFF of input signal
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_reg <= 0;
        out_mode_reg <= 0;
    end
    else begin
        in_valid_reg <= in_valid_nxt;
        out_mode_reg <= out_mode_nxt;
    end
end

// comb of input signal
assign in_valid_nxt = in_valid;
assign out_mode_nxt = ((in_valid) && !(in_valid_reg)) ? out_mode : out_mode_reg;

// DFF of char
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (i = 0; i < 8; i=i+1) begin
            char[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i=i+1) begin
            char[i] <= char_nxt[i];
        end  
    end
end

// comb of char
always @(*) begin
    case (state)
        IDLE: begin
            if(!in_valid) begin
                char_nxt[0] = 0;
                char_nxt[1] = 0;
                char_nxt[2] = 0;
                char_nxt[3] = 0;
                char_nxt[4] = 0;
                char_nxt[5] = 0;
                char_nxt[6] = 0;
                char_nxt[7] = 0;
            end
            else begin
                char_nxt[0] = 0;
                char_nxt[1] = 0;
                char_nxt[2] = 0;
                char_nxt[3] = 0;
                char_nxt[4] = 0;
                char_nxt[5] = 0;
                char_nxt[6] = 0;
                char_nxt[7] = text;
            end
        end
        IN: begin
            char_nxt[0] = comb_char[6][0];
            char_nxt[1] = comb_char[6][1];
            char_nxt[2] = comb_char[6][2];
            char_nxt[3] = comb_char[6][3];
            char_nxt[4] = comb_char[6][4];
            char_nxt[5] = comb_char[6][5];
            char_nxt[6] = comb_char[6][6];
            char_nxt[7] = comb_char[6][7];
        end
        CAL: begin
            char_nxt[0] = comb_char[1][0];
            char_nxt[1] = comb_char[1][1];
            char_nxt[2] = comb_char[1][2];
            char_nxt[3] = comb_char[1][3];
            char_nxt[4] = comb_char[1][4];
            char_nxt[5] = comb_char[1][5];
            char_nxt[6] = comb_char[1][6];
            char_nxt[7] = comb_char[1][7];
        end
        default: begin
            char_nxt[0] = char[0];
            char_nxt[1] = char[1];
            char_nxt[2] = char[2];
            char_nxt[3] = char[3];
            char_nxt[4] = char[4];
            char_nxt[5] = char[5];
            char_nxt[6] = char[6];
            char_nxt[7] = char[7];
        end
    endcase
end

// DFF of weight
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (i = 0; i < 8; i=i+1) begin
            weight[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 8; i=i+1) begin
            weight[i] <= weight_nxt[i];
        end  
    end
end

// comb of weight
always @(*) begin
    case (state)
        IDLE: begin
            if(!in_valid) begin
                weight_nxt[0] = 0;
                weight_nxt[1] = 0;
                weight_nxt[2] = 0;
                weight_nxt[3] = 0;
                weight_nxt[4] = 0;
                weight_nxt[5] = 0;
                weight_nxt[6] = 0;
                weight_nxt[7] = 0; 
            end
            else begin
                weight_nxt[0] = 0;
                weight_nxt[1] = 0;
                weight_nxt[2] = 0;
                weight_nxt[3] = 0;
                weight_nxt[4] = 0;
                weight_nxt[5] = 0;
                weight_nxt[6] = 0;
                weight_nxt[7] = in_weight;
            end
        end
        IN: begin
            weight_nxt[0] = comb_weight[6][0];
            weight_nxt[1] = comb_weight[6][1];
            weight_nxt[2] = comb_weight[6][2];
            weight_nxt[3] = comb_weight[6][3];
            weight_nxt[4] = comb_weight[6][4];
            weight_nxt[5] = comb_weight[6][5];
            weight_nxt[6] = comb_weight[6][6];
            weight_nxt[7] = comb_weight[6][7];
        end
        CAL: begin
            weight_nxt[0] = comb_weight[1][0];
            weight_nxt[1] = comb_weight[1][1];
            weight_nxt[2] = comb_weight[1][2];
            weight_nxt[3] = comb_weight[1][3];
            weight_nxt[4] = comb_weight[1][4];
            weight_nxt[5] = comb_weight[1][5];
            weight_nxt[6] = comb_weight[1][6];
            weight_nxt[7] = comb_weight[1][7];
        end
        default: begin
            weight_nxt[0] = weight[0];
            weight_nxt[1] = weight[1];
            weight_nxt[2] = weight[2];
            weight_nxt[3] = weight[3];
            weight_nxt[4] = weight[4];
            weight_nxt[5] = weight[5];
            weight_nxt[6] = weight[6];
            weight_nxt[7] = weight[7];
        end
    endcase
end

// DFF of height
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i=i+1) begin
            height[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 8; i=i+1) begin
            height[i] <= height_nxt[i];
        end
    end
end

// comb of height
always @(*) begin
    case (state)
        IDLE: begin
            height_nxt[0] = 0;
            height_nxt[1] = 0;
            height_nxt[2] = 0;
            height_nxt[3] = 0;
            height_nxt[4] = 0;
            height_nxt[5] = 0;
            height_nxt[6] = 0;
            height_nxt[7] = 0;
        end
        IN: begin
            height_nxt[0] = comb_height[6][0];
            height_nxt[1] = comb_height[6][1];
            height_nxt[2] = comb_height[6][2];
            height_nxt[3] = comb_height[6][3];
            height_nxt[4] = comb_height[6][4];
            height_nxt[5] = comb_height[6][5];
            height_nxt[6] = comb_height[6][6];
            height_nxt[7] = comb_height[6][7];
        end
        CAL: begin
            height_nxt[0] = comb_height[1][0];
            height_nxt[1] = comb_height[1][1];
            height_nxt[2] = comb_height[1][2];
            height_nxt[3] = comb_height[1][3];
            height_nxt[4] = comb_height[1][4];
            height_nxt[5] = comb_height[1][5];
            height_nxt[6] = comb_height[1][6];
            height_nxt[7] = comb_height[1][7];
        end
        default: begin
            height_nxt[0] = height[0];
            height_nxt[1] = height[1];
            height_nxt[2] = height[2];
            height_nxt[3] = height[3];
            height_nxt[4] = height[4];
            height_nxt[5] = height[5];
            height_nxt[6] = height[6];
            height_nxt[7] = height[7];
        end
    endcase
end

// DFF of code
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i=i+1) begin
            code[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 8; i=i+1) begin
            code[i] <= code_nxt[i];
        end
    end
end

// comb of code
always @(*) begin
    case (state)
        IDLE: begin
            code_nxt[0] = 0;
            code_nxt[1] = 0;
            code_nxt[2] = 0;
            code_nxt[3] = 0;
            code_nxt[4] = 0;
            code_nxt[5] = 0;
            code_nxt[6] = 0;
            code_nxt[7] = 0;
        end
        IN: begin
            code_nxt[0] = comb_code[6][0];
            code_nxt[1] = comb_code[6][1];
            code_nxt[2] = comb_code[6][2];
            code_nxt[3] = comb_code[6][3];
            code_nxt[4] = comb_code[6][4];
            code_nxt[5] = comb_code[6][5];
            code_nxt[6] = comb_code[6][6];
            code_nxt[7] = comb_code[6][7];
        end
        CAL: begin
            code_nxt[0] = comb_code[1][0];
            code_nxt[1] = comb_code[1][1];
            code_nxt[2] = comb_code[1][2];
            code_nxt[3] = comb_code[1][3];
            code_nxt[4] = comb_code[1][4];
            code_nxt[5] = comb_code[1][5];
            code_nxt[6] = comb_code[1][6];
            code_nxt[7] = comb_code[1][7];
        end
        default: begin
            code_nxt[0] = code[0];
            code_nxt[1] = code[1];
            code_nxt[2] = code[2];
            code_nxt[3] = code[3];
            code_nxt[4] = code[4];
            code_nxt[5] = code[5];
            code_nxt[6] = code[6];
            code_nxt[7] = code[7];
        end
    endcase
end

// text
always @(*) begin
    case (cnt_in_8)
        0: text = A;
        1: text = B;
        2: text = C;
        3: text = E;
        4: text = I;
        5: text = L;
        6: text = O;
        7: text = V;
    endcase
end

// insertion sort of IN
always @(*) begin
    case (state)
        IN: begin
            if(cnt_in_8 != 7) begin // First 7 inputs
                // tmp[7]
                if((in_weight > weight[4]) || !(char[4])) begin
                    if((in_weight > weight[6]) || !(char[6])) begin
                        if((in_weight > weight[7]) || !(char[7])) begin
                            sort_weight[7][7] =     in_weight;      sort_char[7][7] =    text;
                            sort_weight[7][6] =     weight[7];      sort_char[7][6] = char[7];
                            sort_weight[7][5] =     weight[6];      sort_char[7][5] = char[6];
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     in_weight;      sort_char[7][6] =    text;
                            sort_weight[7][5] =     weight[6];      sort_char[7][5] = char[6];
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                    else begin
                        if((in_weight > weight[5] || !(char[5]))) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     in_weight;      sort_char[7][5] =    text;
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     in_weight;      sort_char[7][4] =    text;
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                end
                else begin
                    if((in_weight > weight[2]) || !(char[2])) begin
                        if((in_weight > weight[3]) || !(char[3])) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     in_weight;      sort_char[7][3] =    text;
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     in_weight;      sort_char[7][2] =    text;
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                    else begin
                        if((in_weight > weight[1]) || !(char[1])) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     weight[2];      sort_char[7][2] = char[2];
                            sort_weight[7][1] =     in_weight;      sort_char[7][1] =    text;
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     weight[2];      sort_char[7][2] = char[2];
                            sort_weight[7][1] =     weight[1];      sort_char[7][1] = char[1];
                            sort_weight[7][0] =     in_weight;      sort_char[7][0] =    text;
                        end
                    end
                end

                // tmp[6]
                sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                sort_weight[6][5] = comb_weight[7][5];      sort_char[6][5] = comb_char[7][5];
                sort_weight[6][4] = comb_weight[7][4];      sort_char[6][4] = comb_char[7][4];
                sort_weight[6][3] = comb_weight[7][3];      sort_char[6][3] = comb_char[7][3];
                sort_weight[6][2] = comb_weight[7][2];      sort_char[6][2] = comb_char[7][2];
                sort_weight[6][1] = comb_weight[7][1];      sort_char[6][1] = comb_char[7][1];
                sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
            end
            else begin // Last inputs
                // tmp[7]
                if(in_weight > weight[4]) begin
                    if(in_weight > weight[6]) begin
                        if(in_weight > weight[7]) begin
                            sort_weight[7][7] =     in_weight;      sort_char[7][7] =    text;
                            sort_weight[7][6] =     weight[7];      sort_char[7][6] = char[7];
                            sort_weight[7][5] =     weight[6];      sort_char[7][5] = char[6];
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     in_weight;      sort_char[7][6] =    text;
                            sort_weight[7][5] =     weight[6];      sort_char[7][5] = char[6];
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                    else begin
                        if(in_weight > weight[5]) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     in_weight;      sort_char[7][5] =    text;
                            sort_weight[7][4] =     weight[5];      sort_char[7][4] = char[5];
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     in_weight;      sort_char[7][4] =    text;
                            sort_weight[7][3] =     weight[4];      sort_char[7][3] = char[4];
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                end
                else begin
                    if(in_weight > weight[2]) begin
                        if(in_weight > weight[3]) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     in_weight;      sort_char[7][3] =    text;
                            sort_weight[7][2] =     weight[3];      sort_char[7][2] = char[3];
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     in_weight;      sort_char[7][2] =    text;
                            sort_weight[7][1] =     weight[2];      sort_char[7][1] = char[2];
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                    end
                    else begin
                        if(in_weight > weight[1]) begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     weight[2];      sort_char[7][2] = char[2];
                            sort_weight[7][1] =     in_weight;      sort_char[7][1] =    text;
                            sort_weight[7][0] =     weight[1];      sort_char[7][0] = char[1];
                        end
                        ////////////////////////////////////////////////
                        else begin
                            sort_weight[7][7] =     weight[7];      sort_char[7][7] = char[7];
                            sort_weight[7][6] =     weight[6];      sort_char[7][6] = char[6];
                            sort_weight[7][5] =     weight[5];      sort_char[7][5] = char[5];
                            sort_weight[7][4] =     weight[4];      sort_char[7][4] = char[4];
                            sort_weight[7][3] =     weight[3];      sort_char[7][3] = char[3];
                            sort_weight[7][2] =     weight[2];      sort_char[7][2] = char[2];
                            sort_weight[7][1] =     weight[1];      sort_char[7][1] = char[1];
                            sort_weight[7][0] =     in_weight;      sort_char[7][0] =    text;
                        end
                        /////////////////////////////////////////////////
                    end
                end

                // tmp[6]
                if(comb_weight[7][1] > comb_weight[7][4]) begin
                    if(comb_weight[7][1] > comb_weight[7][6]) begin
                        if(comb_weight[7][1] > comb_weight[7][7]) begin
                            sort_weight[6][7] = comb_weight[7][1];      sort_char[6][7] = comb_char[7][1];
                            sort_weight[6][6] = comb_weight[7][7];      sort_char[6][6] = comb_char[7][7];
                            sort_weight[6][5] = comb_weight[7][6];      sort_char[6][5] = comb_char[7][6];
                            sort_weight[6][4] = comb_weight[7][5];      sort_char[6][4] = comb_char[7][5];
                            sort_weight[6][3] = comb_weight[7][4];      sort_char[6][3] = comb_char[7][4];
                            sort_weight[6][2] = comb_weight[7][3];      sort_char[6][2] = comb_char[7][3];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                        else begin
                            sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                            sort_weight[6][6] = comb_weight[7][1];      sort_char[6][6] = comb_char[7][1];
                            sort_weight[6][5] = comb_weight[7][6];      sort_char[6][5] = comb_char[7][6];
                            sort_weight[6][4] = comb_weight[7][5];      sort_char[6][4] = comb_char[7][5];
                            sort_weight[6][3] = comb_weight[7][4];      sort_char[6][3] = comb_char[7][4];
                            sort_weight[6][2] = comb_weight[7][3];      sort_char[6][2] = comb_char[7][3];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                    end
                    else begin
                        if(comb_weight[7][1] > comb_weight[7][5]) begin
                            sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                            sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                            sort_weight[6][5] = comb_weight[7][1];      sort_char[6][5] = comb_char[7][1];
                            sort_weight[6][4] = comb_weight[7][5];      sort_char[6][4] = comb_char[7][5];
                            sort_weight[6][3] = comb_weight[7][4];      sort_char[6][3] = comb_char[7][4];
                            sort_weight[6][2] = comb_weight[7][3];      sort_char[6][2] = comb_char[7][3];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                        else begin
                            sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                            sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                            sort_weight[6][5] = comb_weight[7][5];      sort_char[6][5] = comb_char[7][5];
                            sort_weight[6][4] = comb_weight[7][1];      sort_char[6][4] = comb_char[7][1];
                            sort_weight[6][3] = comb_weight[7][4];      sort_char[6][3] = comb_char[7][4];
                            sort_weight[6][2] = comb_weight[7][3];      sort_char[6][2] = comb_char[7][3];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                    end
                end
                else begin
                    if(comb_weight[7][1] > comb_weight[7][2]) begin
                        if(comb_weight[7][1] > comb_weight[7][3]) begin
                            sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                            sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                            sort_weight[6][5] = comb_weight[7][5];      sort_char[6][5] = comb_char[7][5];
                            sort_weight[6][4] = comb_weight[7][4];      sort_char[6][4] = comb_char[7][4];
                            sort_weight[6][3] = comb_weight[7][1];      sort_char[6][3] = comb_char[7][1];
                            sort_weight[6][2] = comb_weight[7][3];      sort_char[6][2] = comb_char[7][3];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                        else begin
                            sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                            sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                            sort_weight[6][5] = comb_weight[7][5];      sort_char[6][5] = comb_char[7][5];
                            sort_weight[6][4] = comb_weight[7][4];      sort_char[6][4] = comb_char[7][4];
                            sort_weight[6][3] = comb_weight[7][3];      sort_char[6][3] = comb_char[7][3];
                            sort_weight[6][2] = comb_weight[7][1];      sort_char[6][2] = comb_char[7][1];
                            sort_weight[6][1] = comb_weight[7][2];      sort_char[6][1] = comb_char[7][2];
                            sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                        end
                    end
                    else begin
                        sort_weight[6][7] = comb_weight[7][7];      sort_char[6][7] = comb_char[7][7];
                        sort_weight[6][6] = comb_weight[7][6];      sort_char[6][6] = comb_char[7][6];
                        sort_weight[6][5] = comb_weight[7][5];      sort_char[6][5] = comb_char[7][5];
                        sort_weight[6][4] = comb_weight[7][4];      sort_char[6][4] = comb_char[7][4];
                        sort_weight[6][3] = comb_weight[7][3];      sort_char[6][3] = comb_char[7][3];
                        sort_weight[6][2] = comb_weight[7][2];      sort_char[6][2] = comb_char[7][2];
                        sort_weight[6][1] = comb_weight[7][1];      sort_char[6][1] = comb_char[7][1];
                        sort_weight[6][0] = comb_weight[7][0];      sort_char[6][0] = comb_char[7][0];
                    end
                end
            end
        end
        default: begin
            sort_weight[7][7] = 0;   sort_char[7][7] = 0;   
            sort_weight[7][6] = 0;   sort_char[7][6] = 0;   
            sort_weight[7][5] = 0;   sort_char[7][5] = 0;   
            sort_weight[7][4] = 0;   sort_char[7][4] = 0;   
            sort_weight[7][3] = 0;   sort_char[7][3] = 0;   
            sort_weight[7][2] = 0;   sort_char[7][2] = 0;   
            sort_weight[7][1] = 0;   sort_char[7][1] = 0;   
            sort_weight[7][0] = 0;   sort_char[7][0] = 0;   

            sort_weight[6][7] = 0;   sort_char[6][7] = 0;
            sort_weight[6][6] = 0;   sort_char[6][6] = 0;
            sort_weight[6][5] = 0;   sort_char[6][5] = 0;
            sort_weight[6][4] = 0;   sort_char[6][4] = 0;
            sort_weight[6][3] = 0;   sort_char[6][3] = 0;
            sort_weight[6][2] = 0;   sort_char[6][2] = 0;
            sort_weight[6][1] = 0;   sort_char[6][1] = 0;
            sort_weight[6][0] = 0;   sort_char[6][0] = 0;
        end
    endcase
end

// combination of IN
always @(*) begin
    case (state)
        IN: begin
            if(cnt_in_8 != 7) begin
                comb_weight[7][7] = sort_weight[7][7];      comb_char[7][7] = sort_char[7][7];
                comb_weight[7][6] = sort_weight[7][6];      comb_char[7][6] = sort_char[7][6];
                comb_weight[7][5] = sort_weight[7][5];      comb_char[7][5] = sort_char[7][5];
                comb_weight[7][4] = sort_weight[7][4];      comb_char[7][4] = sort_char[7][4];
                comb_weight[7][3] = sort_weight[7][3];      comb_char[7][3] = sort_char[7][3];
                comb_weight[7][2] = sort_weight[7][2];      comb_char[7][2] = sort_char[7][2];
                comb_weight[7][1] = sort_weight[7][1];      comb_char[7][1] = sort_char[7][1];
                comb_weight[7][0] = sort_weight[7][0];      comb_char[7][0] = sort_char[7][0];

                comb_weight[6][7] = sort_weight[6][7];      comb_char[6][7] = sort_char[6][7];
                comb_weight[6][6] = sort_weight[6][6];      comb_char[6][6] = sort_char[6][6];
                comb_weight[6][5] = sort_weight[6][5];      comb_char[6][5] = sort_char[6][5];
                comb_weight[6][4] = sort_weight[6][4];      comb_char[6][4] = sort_char[6][4];
                comb_weight[6][3] = sort_weight[6][3];      comb_char[6][3] = sort_char[6][3];
                comb_weight[6][2] = sort_weight[6][2];      comb_char[6][2] = sort_char[6][2];
                comb_weight[6][1] = sort_weight[6][1];      comb_char[6][1] = sort_char[6][1];
                comb_weight[6][0] = sort_weight[6][0];      comb_char[6][0] = sort_char[6][0];

                comb_height[7][7] =         height[7];      comb_code[7][7] =         code[7];
                comb_height[7][6] =         height[6];      comb_code[7][6] =         code[6];
                comb_height[7][5] =         height[5];      comb_code[7][5] =         code[5];
                comb_height[7][4] =         height[4];      comb_code[7][4] =         code[4];
                comb_height[7][3] =         height[3];      comb_code[7][3] =         code[3];
                comb_height[7][2] =         height[2];      comb_code[7][2] =         code[2];
                comb_height[7][1] =         height[1];      comb_code[7][1] =         code[1];
                comb_height[7][0] =         height[0];      comb_code[7][0] =         code[0];

                comb_height[6][7] = comb_height[7][7];      comb_code[6][7] = comb_code[7][7];
                comb_height[6][6] = comb_height[7][6];      comb_code[6][6] = comb_code[7][6];
                comb_height[6][5] = comb_height[7][5];      comb_code[6][5] = comb_code[7][5];
                comb_height[6][4] = comb_height[7][4];      comb_code[6][4] = comb_code[7][4];
                comb_height[6][3] = comb_height[7][3];      comb_code[6][3] = comb_code[7][3];
                comb_height[6][2] = comb_height[7][2];      comb_code[6][2] = comb_code[7][2];
                comb_height[6][1] = comb_height[7][1];      comb_code[6][1] = comb_code[7][1];
                comb_height[6][0] = comb_height[7][0];      comb_code[6][0] = comb_code[7][0];
            end
            else begin
                comb_weight[7][7] =                     sort_weight[7][7];      comb_char[7][7] =                   sort_char[7][7];
                comb_weight[7][6] =                     sort_weight[7][6];      comb_char[7][6] =                   sort_char[7][6];
                comb_weight[7][5] =                     sort_weight[7][5];      comb_char[7][5] =                   sort_char[7][5];
                comb_weight[7][4] =                     sort_weight[7][4];      comb_char[7][4] =                   sort_char[7][4];
                comb_weight[7][3] =                     sort_weight[7][3];      comb_char[7][3] =                   sort_char[7][3];
                comb_weight[7][2] =                     sort_weight[7][2];      comb_char[7][2] =                   sort_char[7][2];
                comb_weight[7][1] = sort_weight[7][1] + sort_weight[7][0];      comb_char[7][1] = sort_char[7][1] | sort_char[7][0];
                comb_weight[7][0] =                                     0;      comb_char[7][0] =                                 0;

                comb_weight[6][7] =                     sort_weight[6][7];      comb_char[6][7] =                   sort_char[6][7];
                comb_weight[6][6] =                     sort_weight[6][6];      comb_char[6][6] =                   sort_char[6][6];
                comb_weight[6][5] =                     sort_weight[6][5];      comb_char[6][5] =                   sort_char[6][5];
                comb_weight[6][4] =                     sort_weight[6][4];      comb_char[6][4] =                   sort_char[6][4];
                comb_weight[6][3] =                     sort_weight[6][3];      comb_char[6][3] =                   sort_char[6][3];
                comb_weight[6][2] = sort_weight[6][2] + sort_weight[6][1];      comb_char[6][2] = sort_char[6][2] | sort_char[6][1];
                comb_weight[6][1] =                                     0;      comb_char[6][1] =                                 0;
                comb_weight[6][0] =                                     0;      comb_char[6][0] =                                 0;

                comb_height[7][7] = ((sort_char[7][1] & V) || (sort_char[7][0] & V)) ?         (height[7] + 1) :         height[7];     comb_code[7][7] = (sort_char[7][1] & V) ?         {code[7][6:0], 1'b0} : ((sort_char[7][0] & V) ?         {code[7][6:0], 1'b1} :         code[7]);
                comb_height[7][6] = ((sort_char[7][1] & O) || (sort_char[7][0] & O)) ?         (height[6] + 1) :         height[6];     comb_code[7][6] = (sort_char[7][1] & O) ?         {code[6][6:0], 1'b0} : ((sort_char[7][0] & O) ?         {code[6][6:0], 1'b1} :         code[6]);
                comb_height[7][5] = ((sort_char[7][1] & L) || (sort_char[7][0] & L)) ?         (height[5] + 1) :         height[5];     comb_code[7][5] = (sort_char[7][1] & L) ?         {code[5][6:0], 1'b0} : ((sort_char[7][0] & L) ?         {code[5][6:0], 1'b1} :         code[5]);
                comb_height[7][4] = ((sort_char[7][1] & I) || (sort_char[7][0] & I)) ?         (height[4] + 1) :         height[4];     comb_code[7][4] = (sort_char[7][1] & I) ?         {code[4][6:0], 1'b0} : ((sort_char[7][0] & I) ?         {code[4][6:0], 1'b1} :         code[4]);
                comb_height[7][3] = ((sort_char[7][1] & E) || (sort_char[7][0] & E)) ?         (height[3] + 1) :         height[3];     comb_code[7][3] = (sort_char[7][1] & E) ?         {code[3][6:0], 1'b0} : ((sort_char[7][0] & E) ?         {code[3][6:0], 1'b1} :         code[3]);
                comb_height[7][2] = ((sort_char[7][1] & C) || (sort_char[7][0] & C)) ?         (height[2] + 1) :         height[2];     comb_code[7][2] = (sort_char[7][1] & C) ?         {code[2][6:0], 1'b0} : ((sort_char[7][0] & C) ?         {code[2][6:0], 1'b1} :         code[2]);
                comb_height[7][1] = ((sort_char[7][1] & B) || (sort_char[7][0] & B)) ?         (height[1] + 1) :         height[1];     comb_code[7][1] = (sort_char[7][1] & B) ?         {code[1][6:0], 1'b0} : ((sort_char[7][0] & B) ?         {code[1][6:0], 1'b1} :         code[1]);
                comb_height[7][0] = ((sort_char[7][1] & A) || (sort_char[7][0] & A)) ?         (height[0] + 1) :         height[0];     comb_code[7][0] = (sort_char[7][1] & A) ?         {code[0][6:0], 1'b0} : ((sort_char[7][0] & A) ?         {code[0][6:0], 1'b1} :         code[0]);

                comb_height[6][7] = ((sort_char[6][2] & V) || (sort_char[6][1] & V)) ? (comb_height[7][7] + 1) : comb_height[7][7];     comb_code[6][7] = (sort_char[6][2] & V) ? {comb_code[7][7][6:0], 1'b0} : ((sort_char[6][1] & V) ? {comb_code[7][7][6:0], 1'b1} : comb_code[7][7]);
                comb_height[6][6] = ((sort_char[6][2] & O) || (sort_char[6][1] & O)) ? (comb_height[7][6] + 1) : comb_height[7][6];     comb_code[6][6] = (sort_char[6][2] & O) ? {comb_code[7][6][6:0], 1'b0} : ((sort_char[6][1] & O) ? {comb_code[7][6][6:0], 1'b1} : comb_code[7][6]);
                comb_height[6][5] = ((sort_char[6][2] & L) || (sort_char[6][1] & L)) ? (comb_height[7][5] + 1) : comb_height[7][5];     comb_code[6][5] = (sort_char[6][2] & L) ? {comb_code[7][5][6:0], 1'b0} : ((sort_char[6][1] & L) ? {comb_code[7][5][6:0], 1'b1} : comb_code[7][5]);
                comb_height[6][4] = ((sort_char[6][2] & I) || (sort_char[6][1] & I)) ? (comb_height[7][4] + 1) : comb_height[7][4];     comb_code[6][4] = (sort_char[6][2] & I) ? {comb_code[7][4][6:0], 1'b0} : ((sort_char[6][1] & I) ? {comb_code[7][4][6:0], 1'b1} : comb_code[7][4]);
                comb_height[6][3] = ((sort_char[6][2] & E) || (sort_char[6][1] & E)) ? (comb_height[7][3] + 1) : comb_height[7][3];     comb_code[6][3] = (sort_char[6][2] & E) ? {comb_code[7][3][6:0], 1'b0} : ((sort_char[6][1] & E) ? {comb_code[7][3][6:0], 1'b1} : comb_code[7][3]);
                comb_height[6][2] = ((sort_char[6][2] & C) || (sort_char[6][1] & C)) ? (comb_height[7][2] + 1) : comb_height[7][2];     comb_code[6][2] = (sort_char[6][2] & C) ? {comb_code[7][2][6:0], 1'b0} : ((sort_char[6][1] & C) ? {comb_code[7][2][6:0], 1'b1} : comb_code[7][2]);
                comb_height[6][1] = ((sort_char[6][2] & B) || (sort_char[6][1] & B)) ? (comb_height[7][1] + 1) : comb_height[7][1];     comb_code[6][1] = (sort_char[6][2] & B) ? {comb_code[7][1][6:0], 1'b0} : ((sort_char[6][1] & B) ? {comb_code[7][1][6:0], 1'b1} : comb_code[7][1]);
                comb_height[6][0] = ((sort_char[6][2] & A) || (sort_char[6][1] & A)) ? (comb_height[7][0] + 1) : comb_height[7][0];     comb_code[6][0] = (sort_char[6][2] & A) ? {comb_code[7][0][6:0], 1'b0} : ((sort_char[6][1] & A) ? {comb_code[7][0][6:0], 1'b1} : comb_code[7][0]);
            end
        end 
        default: begin
            comb_weight[7][7] = 0;   comb_char[7][7] = 0;   
            comb_weight[7][6] = 0;   comb_char[7][6] = 0;   
            comb_weight[7][5] = 0;   comb_char[7][5] = 0;   
            comb_weight[7][4] = 0;   comb_char[7][4] = 0;   
            comb_weight[7][3] = 0;   comb_char[7][3] = 0;   
            comb_weight[7][2] = 0;   comb_char[7][2] = 0;   
            comb_weight[7][1] = 0;   comb_char[7][1] = 0;   
            comb_weight[7][0] = 0;   comb_char[7][0] = 0;   

            comb_weight[6][7] = 0;   comb_char[6][7] = 0;
            comb_weight[6][6] = 0;   comb_char[6][6] = 0;
            comb_weight[6][5] = 0;   comb_char[6][5] = 0;
            comb_weight[6][4] = 0;   comb_char[6][4] = 0;
            comb_weight[6][3] = 0;   comb_char[6][3] = 0;
            comb_weight[6][2] = 0;   comb_char[6][2] = 0;
            comb_weight[6][1] = 0;   comb_char[6][1] = 0;
            comb_weight[6][0] = 0;   comb_char[6][0] = 0;

            comb_height[7][7] = 0;   comb_code[7][7] = 0;   
            comb_height[7][6] = 0;   comb_code[7][6] = 0;   
            comb_height[7][5] = 0;   comb_code[7][5] = 0;   
            comb_height[7][4] = 0;   comb_code[7][4] = 0;   
            comb_height[7][3] = 0;   comb_code[7][3] = 0;   
            comb_height[7][2] = 0;   comb_code[7][2] = 0;   
            comb_height[7][1] = 0;   comb_code[7][1] = 0;   
            comb_height[7][0] = 0;   comb_code[7][0] = 0;

            comb_height[6][7] = 0;   comb_code[6][7] = 0;   
            comb_height[6][6] = 0;   comb_code[6][6] = 0;   
            comb_height[6][5] = 0;   comb_code[6][5] = 0;   
            comb_height[6][4] = 0;   comb_code[6][4] = 0;   
            comb_height[6][3] = 0;   comb_code[6][3] = 0;   
            comb_height[6][2] = 0;   comb_code[6][2] = 0;   
            comb_height[6][1] = 0;   comb_code[6][1] = 0;   
            comb_height[6][0] = 0;   comb_code[6][0] = 0;
        end
    endcase
end

// ===============================================================
// CAL
// ===============================================================

// insertion sort of CAL
always @(*) begin
    case (state)
        CAL: begin
            // tmp[5]
            if(weight[2] > weight[4]) begin
                if(weight[2] > weight[6]) begin
                    if(weight[2] > weight[7]) begin
                        sort_weight[5][7] = weight[2];      sort_char[5][7] = char[2];
                        sort_weight[5][6] = weight[7];      sort_char[5][6] = char[7];
                        sort_weight[5][5] = weight[6];      sort_char[5][5] = char[6];
                        sort_weight[5][4] = weight[5];      sort_char[5][4] = char[5];
                        sort_weight[5][3] = weight[4];      sort_char[5][3] = char[4];
                        sort_weight[5][2] = weight[3];      sort_char[5][2] = char[3];
                        sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                        sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                    end
                    else begin
                        sort_weight[5][7] = weight[7];      sort_char[5][7] = char[7];
                        sort_weight[5][6] = weight[2];      sort_char[5][6] = char[2];
                        sort_weight[5][5] = weight[6];      sort_char[5][5] = char[6];
                        sort_weight[5][4] = weight[5];      sort_char[5][4] = char[5];
                        sort_weight[5][3] = weight[4];      sort_char[5][3] = char[4];
                        sort_weight[5][2] = weight[3];      sort_char[5][2] = char[3];
                        sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                        sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                    end
                end
                else begin
                    if(weight[2] > weight[5]) begin
                        sort_weight[5][7] = weight[7];      sort_char[5][7] = char[7];
                        sort_weight[5][6] = weight[6];      sort_char[5][6] = char[6];
                        sort_weight[5][5] = weight[2];      sort_char[5][5] = char[2];
                        sort_weight[5][4] = weight[5];      sort_char[5][4] = char[5];
                        sort_weight[5][3] = weight[4];      sort_char[5][3] = char[4];
                        sort_weight[5][2] = weight[3];      sort_char[5][2] = char[3];
                        sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                        sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                    end
                    else begin
                        sort_weight[5][7] = weight[7];      sort_char[5][7] = char[7];
                        sort_weight[5][6] = weight[6];      sort_char[5][6] = char[6];
                        sort_weight[5][5] = weight[5];      sort_char[5][5] = char[5];
                        sort_weight[5][4] = weight[2];      sort_char[5][4] = char[2];
                        sort_weight[5][3] = weight[4];      sort_char[5][3] = char[4];
                        sort_weight[5][2] = weight[3];      sort_char[5][2] = char[3];
                        sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                        sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                    end
                end
            end
            else begin
                if(weight[2] > weight[3]) begin
                    sort_weight[5][7] = weight[7];      sort_char[5][7] = char[7];
                    sort_weight[5][6] = weight[6];      sort_char[5][6] = char[6];
                    sort_weight[5][5] = weight[5];      sort_char[5][5] = char[5];
                    sort_weight[5][4] = weight[4];      sort_char[5][4] = char[4];
                    sort_weight[5][3] = weight[2];      sort_char[5][3] = char[2];
                    sort_weight[5][2] = weight[3];      sort_char[5][2] = char[3];
                    sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                    sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                end
                else begin
                    sort_weight[5][7] = weight[7];      sort_char[5][7] = char[7];
                    sort_weight[5][6] = weight[6];      sort_char[5][6] = char[6];
                    sort_weight[5][5] = weight[5];      sort_char[5][5] = char[5];
                    sort_weight[5][4] = weight[4];      sort_char[5][4] = char[4];
                    sort_weight[5][3] = weight[3];      sort_char[5][3] = char[3];
                    sort_weight[5][2] = weight[2];      sort_char[5][2] = char[2];
                    sort_weight[5][1] = weight[1];      sort_char[5][1] = char[1];
                    sort_weight[5][0] = weight[0];      sort_char[5][0] = char[0];
                end
            end

            // tmp[4]
            if(comb_weight[5][3] > comb_weight[5][4]) begin
                if(comb_weight[5][3] > comb_weight[5][6]) begin
                    if(comb_weight[5][3] > comb_weight[5][7]) begin
                        sort_weight[4][7] = comb_weight[5][3];      sort_char[4][7] = comb_char[5][3];
                        sort_weight[4][6] = comb_weight[5][7];      sort_char[4][6] = comb_char[5][7];
                        sort_weight[4][5] = comb_weight[5][6];      sort_char[4][5] = comb_char[5][6];
                        sort_weight[4][4] = comb_weight[5][5];      sort_char[4][4] = comb_char[5][5];
                        sort_weight[4][3] = comb_weight[5][4];      sort_char[4][3] = comb_char[5][4];
                        sort_weight[4][2] = comb_weight[5][2];      sort_char[4][2] = comb_char[5][2];
                        sort_weight[4][1] = comb_weight[5][1];      sort_char[4][1] = comb_char[5][1];
                        sort_weight[4][0] = comb_weight[5][0];      sort_char[4][0] = comb_char[5][0];
                    end
                    else begin
                        sort_weight[4][7] = comb_weight[5][7];      sort_char[4][7] = comb_char[5][7];
                        sort_weight[4][6] = comb_weight[5][3];      sort_char[4][6] = comb_char[5][3];
                        sort_weight[4][5] = comb_weight[5][6];      sort_char[4][5] = comb_char[5][6];
                        sort_weight[4][4] = comb_weight[5][5];      sort_char[4][4] = comb_char[5][5];
                        sort_weight[4][3] = comb_weight[5][4];      sort_char[4][3] = comb_char[5][4];
                        sort_weight[4][2] = comb_weight[5][2];      sort_char[4][2] = comb_char[5][2];
                        sort_weight[4][1] = comb_weight[5][1];      sort_char[4][1] = comb_char[5][1];
                        sort_weight[4][0] = comb_weight[5][0];      sort_char[4][0] = comb_char[5][0];
                    end
                end
                else begin
                    if(comb_weight[5][3] > comb_weight[5][5]) begin
                        sort_weight[4][7] = comb_weight[5][7];      sort_char[4][7] = comb_char[5][7];
                        sort_weight[4][6] = comb_weight[5][6];      sort_char[4][6] = comb_char[5][6];
                        sort_weight[4][5] = comb_weight[5][3];      sort_char[4][5] = comb_char[5][3];
                        sort_weight[4][4] = comb_weight[5][5];      sort_char[4][4] = comb_char[5][5];
                        sort_weight[4][3] = comb_weight[5][4];      sort_char[4][3] = comb_char[5][4];
                        sort_weight[4][2] = comb_weight[5][2];      sort_char[4][2] = comb_char[5][2];
                        sort_weight[4][1] = comb_weight[5][1];      sort_char[4][1] = comb_char[5][1];
                        sort_weight[4][0] = comb_weight[5][0];      sort_char[4][0] = comb_char[5][0];
                    end
                    else begin
                        sort_weight[4][7] = comb_weight[5][7];      sort_char[4][7] = comb_char[5][7];
                        sort_weight[4][6] = comb_weight[5][6];      sort_char[4][6] = comb_char[5][6];
                        sort_weight[4][5] = comb_weight[5][5];      sort_char[4][5] = comb_char[5][5];
                        sort_weight[4][4] = comb_weight[5][3];      sort_char[4][4] = comb_char[5][3];
                        sort_weight[4][3] = comb_weight[5][4];      sort_char[4][3] = comb_char[5][4];
                        sort_weight[4][2] = comb_weight[5][2];      sort_char[4][2] = comb_char[5][2];
                        sort_weight[4][1] = comb_weight[5][1];      sort_char[4][1] = comb_char[5][1];
                        sort_weight[4][0] = comb_weight[5][0];      sort_char[4][0] = comb_char[5][0];
                    end
                end
            end
            else begin
                sort_weight[4][7] = comb_weight[5][7];      sort_char[4][7] = comb_char[5][7];
                sort_weight[4][6] = comb_weight[5][6];      sort_char[4][6] = comb_char[5][6];
                sort_weight[4][5] = comb_weight[5][5];      sort_char[4][5] = comb_char[5][5];
                sort_weight[4][4] = comb_weight[5][4];      sort_char[4][4] = comb_char[5][4];
                sort_weight[4][3] = comb_weight[5][3];      sort_char[4][3] = comb_char[5][3];
                sort_weight[4][2] = comb_weight[5][2];      sort_char[4][2] = comb_char[5][2];
                sort_weight[4][1] = comb_weight[5][1];      sort_char[4][1] = comb_char[5][1];
                sort_weight[4][0] = comb_weight[5][0];      sort_char[4][0] = comb_char[5][0];
            end

            // tmp[3]
            if(comb_weight[4][4] > comb_weight[4][6]) begin
                if(comb_weight[4][4] > comb_weight[4][7]) begin
                    sort_weight[3][7] = comb_weight[4][4];      sort_char[3][7] = comb_char[4][4];
                    sort_weight[3][6] = comb_weight[4][7];      sort_char[3][6] = comb_char[4][7];
                    sort_weight[3][5] = comb_weight[4][6];      sort_char[3][5] = comb_char[4][6];
                    sort_weight[3][4] = comb_weight[4][5];      sort_char[3][4] = comb_char[4][5];
                    sort_weight[3][3] = comb_weight[4][3];      sort_char[3][3] = comb_char[4][3];
                    sort_weight[3][2] = comb_weight[4][2];      sort_char[3][2] = comb_char[4][2];
                    sort_weight[3][1] = comb_weight[4][1];      sort_char[3][1] = comb_char[4][1];
                    sort_weight[3][0] = comb_weight[4][0];      sort_char[3][0] = comb_char[4][0];
                end
                else begin
                    sort_weight[3][7] = comb_weight[4][7];      sort_char[3][7] = comb_char[4][7];
                    sort_weight[3][6] = comb_weight[4][4];      sort_char[3][6] = comb_char[4][4];
                    sort_weight[3][5] = comb_weight[4][6];      sort_char[3][5] = comb_char[4][6];
                    sort_weight[3][4] = comb_weight[4][5];      sort_char[3][4] = comb_char[4][5];
                    sort_weight[3][3] = comb_weight[4][3];      sort_char[3][3] = comb_char[4][3];
                    sort_weight[3][2] = comb_weight[4][2];      sort_char[3][2] = comb_char[4][2];
                    sort_weight[3][1] = comb_weight[4][1];      sort_char[3][1] = comb_char[4][1];
                    sort_weight[3][0] = comb_weight[4][0];      sort_char[3][0] = comb_char[4][0];
                end
            end
            else begin
                if(comb_weight[4][4] > comb_weight[4][5]) begin
                    sort_weight[3][7] = comb_weight[4][7];      sort_char[3][7] = comb_char[4][7];
                    sort_weight[3][6] = comb_weight[4][6];      sort_char[3][6] = comb_char[4][6];
                    sort_weight[3][5] = comb_weight[4][4];      sort_char[3][5] = comb_char[4][4];
                    sort_weight[3][4] = comb_weight[4][5];      sort_char[3][4] = comb_char[4][5];
                    sort_weight[3][3] = comb_weight[4][3];      sort_char[3][3] = comb_char[4][3];
                    sort_weight[3][2] = comb_weight[4][2];      sort_char[3][2] = comb_char[4][2];
                    sort_weight[3][1] = comb_weight[4][1];      sort_char[3][1] = comb_char[4][1];
                    sort_weight[3][0] = comb_weight[4][0];      sort_char[3][0] = comb_char[4][0];
                end
                else begin
                    sort_weight[3][7] = comb_weight[4][7];      sort_char[3][7] = comb_char[4][7];
                    sort_weight[3][6] = comb_weight[4][6];      sort_char[3][6] = comb_char[4][6];
                    sort_weight[3][5] = comb_weight[4][5];      sort_char[3][5] = comb_char[4][5];
                    sort_weight[3][4] = comb_weight[4][4];      sort_char[3][4] = comb_char[4][4];
                    sort_weight[3][3] = comb_weight[4][3];      sort_char[3][3] = comb_char[4][3];
                    sort_weight[3][2] = comb_weight[4][2];      sort_char[3][2] = comb_char[4][2];
                    sort_weight[3][1] = comb_weight[4][1];      sort_char[3][1] = comb_char[4][1];
                    sort_weight[3][0] = comb_weight[4][0];      sort_char[3][0] = comb_char[4][0];
                end
            end

            // tmp[2]
            if(comb_weight[3][5] > comb_weight[3][6]) begin
                if(comb_weight[3][5] > comb_weight[3][7]) begin
                    sort_weight[2][7] = comb_weight[3][5];      sort_char[2][7] = comb_char[3][5];
                    sort_weight[2][6] = comb_weight[3][7];      sort_char[2][6] = comb_char[3][7];
                    sort_weight[2][5] = comb_weight[3][6];      sort_char[2][5] = comb_char[3][6];
                    sort_weight[2][4] = comb_weight[3][4];      sort_char[2][4] = comb_char[3][4];
                    sort_weight[2][3] = comb_weight[3][3];      sort_char[2][3] = comb_char[3][3];
                    sort_weight[2][2] = comb_weight[3][2];      sort_char[2][2] = comb_char[3][2];
                    sort_weight[2][1] = comb_weight[3][1];      sort_char[2][1] = comb_char[3][1];
                    sort_weight[2][0] = comb_weight[3][0];      sort_char[2][0] = comb_char[3][0];
                end
                else begin
                    sort_weight[2][7] = comb_weight[3][7];      sort_char[2][7] = comb_char[3][7];
                    sort_weight[2][6] = comb_weight[3][5];      sort_char[2][6] = comb_char[3][5];
                    sort_weight[2][5] = comb_weight[3][6];      sort_char[2][5] = comb_char[3][6];
                    sort_weight[2][4] = comb_weight[3][4];      sort_char[2][4] = comb_char[3][4];
                    sort_weight[2][3] = comb_weight[3][3];      sort_char[2][3] = comb_char[3][3];
                    sort_weight[2][2] = comb_weight[3][2];      sort_char[2][2] = comb_char[3][2];
                    sort_weight[2][1] = comb_weight[3][1];      sort_char[2][1] = comb_char[3][1];
                    sort_weight[2][0] = comb_weight[3][0];      sort_char[2][0] = comb_char[3][0];
                end
            end
            else begin
                sort_weight[2][7] = comb_weight[3][7];      sort_char[2][7] = comb_char[3][7];
                sort_weight[2][6] = comb_weight[3][6];      sort_char[2][6] = comb_char[3][6];
                sort_weight[2][5] = comb_weight[3][5];      sort_char[2][5] = comb_char[3][5];
                sort_weight[2][4] = comb_weight[3][4];      sort_char[2][4] = comb_char[3][4];
                sort_weight[2][3] = comb_weight[3][3];      sort_char[2][3] = comb_char[3][3];
                sort_weight[2][2] = comb_weight[3][2];      sort_char[2][2] = comb_char[3][2];
                sort_weight[2][1] = comb_weight[3][1];      sort_char[2][1] = comb_char[3][1];
                sort_weight[2][0] = comb_weight[3][0];      sort_char[2][0] = comb_char[3][0];
            end

            // tmp[1]
            if(comb_weight[2][6] > comb_weight[2][7]) begin
                sort_weight[1][7] = comb_weight[2][6];      sort_char[1][7] = comb_char[2][6];
                sort_weight[1][6] = comb_weight[2][7];      sort_char[1][6] = comb_char[2][7];
                sort_weight[1][5] = comb_weight[2][5];      sort_char[1][5] = comb_char[2][5];
                sort_weight[1][4] = comb_weight[2][4];      sort_char[1][4] = comb_char[2][4];
                sort_weight[1][3] = comb_weight[2][3];      sort_char[1][3] = comb_char[2][3];
                sort_weight[1][2] = comb_weight[2][2];      sort_char[1][2] = comb_char[2][2];
                sort_weight[1][1] = comb_weight[2][1];      sort_char[1][1] = comb_char[2][1];
                sort_weight[1][0] = comb_weight[2][0];      sort_char[1][0] = comb_char[2][0];
            end
            else begin
                sort_weight[1][7] = comb_weight[2][7];      sort_char[1][7] = comb_char[2][7];
                sort_weight[1][6] = comb_weight[2][6];      sort_char[1][6] = comb_char[2][6];
                sort_weight[1][5] = comb_weight[2][5];      sort_char[1][5] = comb_char[2][5];
                sort_weight[1][4] = comb_weight[2][4];      sort_char[1][4] = comb_char[2][4];
                sort_weight[1][3] = comb_weight[2][3];      sort_char[1][3] = comb_char[2][3];
                sort_weight[1][2] = comb_weight[2][2];      sort_char[1][2] = comb_char[2][2];
                sort_weight[1][1] = comb_weight[2][1];      sort_char[1][1] = comb_char[2][1];
                sort_weight[1][0] = comb_weight[2][0];      sort_char[1][0] = comb_char[2][0];
            end
        end
        default: begin
            sort_weight[5][7] = 0;   sort_char[5][7] = 0;   
            sort_weight[5][6] = 0;   sort_char[5][6] = 0;   
            sort_weight[5][5] = 0;   sort_char[5][5] = 0;   
            sort_weight[5][4] = 0;   sort_char[5][4] = 0;   
            sort_weight[5][3] = 0;   sort_char[5][3] = 0;   
            sort_weight[5][2] = 0;   sort_char[5][2] = 0;   
            sort_weight[5][1] = 0;   sort_char[5][1] = 0;   
            sort_weight[5][0] = 0;   sort_char[5][0] = 0;   

            sort_weight[4][7] = 0;   sort_char[4][7] = 0;
            sort_weight[4][6] = 0;   sort_char[4][6] = 0;
            sort_weight[4][5] = 0;   sort_char[4][5] = 0;
            sort_weight[4][4] = 0;   sort_char[4][4] = 0;
            sort_weight[4][3] = 0;   sort_char[4][3] = 0;
            sort_weight[4][2] = 0;   sort_char[4][2] = 0;
            sort_weight[4][1] = 0;   sort_char[4][1] = 0;
            sort_weight[4][0] = 0;   sort_char[4][0] = 0;

            sort_weight[3][7] = 0;   sort_char[3][7] = 0;   
            sort_weight[3][6] = 0;   sort_char[3][6] = 0;   
            sort_weight[3][5] = 0;   sort_char[3][5] = 0;   
            sort_weight[3][4] = 0;   sort_char[3][4] = 0;   
            sort_weight[3][3] = 0;   sort_char[3][3] = 0;   
            sort_weight[3][2] = 0;   sort_char[3][2] = 0;   
            sort_weight[3][1] = 0;   sort_char[3][1] = 0;   
            sort_weight[3][0] = 0;   sort_char[3][0] = 0;   

            sort_weight[2][7] = 0;   sort_char[2][7] = 0;
            sort_weight[2][6] = 0;   sort_char[2][6] = 0;
            sort_weight[2][5] = 0;   sort_char[2][5] = 0;
            sort_weight[2][4] = 0;   sort_char[2][4] = 0;
            sort_weight[2][3] = 0;   sort_char[2][3] = 0;
            sort_weight[2][2] = 0;   sort_char[2][2] = 0;
            sort_weight[2][1] = 0;   sort_char[2][1] = 0;
            sort_weight[2][0] = 0;   sort_char[2][0] = 0;

            sort_weight[1][7] = 0;   sort_char[1][7] = 0;
            sort_weight[1][6] = 0;   sort_char[1][6] = 0;
            sort_weight[1][5] = 0;   sort_char[1][5] = 0;
            sort_weight[1][4] = 0;   sort_char[1][4] = 0;
            sort_weight[1][3] = 0;   sort_char[1][3] = 0;
            sort_weight[1][2] = 0;   sort_char[1][2] = 0;
            sort_weight[1][1] = 0;   sort_char[1][1] = 0;
            sort_weight[1][0] = 0;   sort_char[1][0] = 0;
        end
    endcase
end

// combination of CAL
always @(*) begin
    case (state)
        CAL: begin
            comb_weight[5][7] =                     sort_weight[5][7];      comb_char[5][7] =                   sort_char[5][7];
            comb_weight[5][6] =                     sort_weight[5][6];      comb_char[5][6] =                   sort_char[5][6];
            comb_weight[5][5] =                     sort_weight[5][5];      comb_char[5][5] =                   sort_char[5][5];
            comb_weight[5][4] =                     sort_weight[5][4];      comb_char[5][4] =                   sort_char[5][4];
            comb_weight[5][3] = sort_weight[5][3] + sort_weight[5][2];      comb_char[5][3] = sort_char[5][3] | sort_char[5][2];
            comb_weight[5][2] =                                     0;      comb_char[5][2] =                                 0;
            comb_weight[5][1] =                                     0;      comb_char[5][1] =                                 0;
            comb_weight[5][0] =                                     0;      comb_char[5][0] =                                 0;

            comb_weight[4][7] =                     sort_weight[4][7];      comb_char[4][7] =                   sort_char[4][7];
            comb_weight[4][6] =                     sort_weight[4][6];      comb_char[4][6] =                   sort_char[4][6];
            comb_weight[4][5] =                     sort_weight[4][5];      comb_char[4][5] =                   sort_char[4][5];
            comb_weight[4][4] = sort_weight[4][4] + sort_weight[4][3];      comb_char[4][4] = sort_char[4][4] | sort_char[4][3];
            comb_weight[4][3] =                                     0;      comb_char[4][3] =                                 0;
            comb_weight[4][2] =                                     0;      comb_char[4][2] =                                 0;
            comb_weight[4][1] =                                     0;      comb_char[4][1] =                                 0;
            comb_weight[4][0] =                                     0;      comb_char[4][0] =                                 0;

            comb_weight[3][7] =                     sort_weight[3][7];      comb_char[3][7] =                   sort_char[3][7];
            comb_weight[3][6] =                     sort_weight[3][6];      comb_char[3][6] =                   sort_char[3][6];
            comb_weight[3][5] = sort_weight[3][5] + sort_weight[3][4];      comb_char[3][5] = sort_char[3][5] | sort_char[3][4];
            comb_weight[3][4] =                                     0;      comb_char[3][4] =                                 0;
            comb_weight[3][3] =                                     0;      comb_char[3][3] =                                 0;
            comb_weight[3][2] =                                     0;      comb_char[3][2] =                                 0;
            comb_weight[3][1] =                                     0;      comb_char[3][1] =                                 0;
            comb_weight[3][0] =                                     0;      comb_char[3][0] =                                 0;

            comb_weight[2][7] =                     sort_weight[2][7];      comb_char[2][7] =                   sort_char[2][7];
            comb_weight[2][6] = sort_weight[2][6] + sort_weight[2][5];      comb_char[2][6] = sort_char[2][6] | sort_char[2][5];
            comb_weight[2][5] =                                     0;      comb_char[2][5] =                                 0;
            comb_weight[2][4] =                                     0;      comb_char[2][4] =                                 0;
            comb_weight[2][3] =                                     0;      comb_char[2][3] =                                 0;
            comb_weight[2][2] =                                     0;      comb_char[2][2] =                                 0;
            comb_weight[2][1] =                                     0;      comb_char[2][1] =                                 0;
            comb_weight[2][0] =                                     0;      comb_char[2][0] =                                 0;

            comb_weight[1][7] = sort_weight[1][7] + sort_weight[1][6];      comb_char[1][7] = sort_char[1][7] | sort_char[1][6];
            comb_weight[1][6] =                                     0;      comb_char[1][6] =                                 0;
            comb_weight[1][5] =                                     0;      comb_char[1][5] =                                 0;
            comb_weight[1][4] =                                     0;      comb_char[1][4] =                                 0;
            comb_weight[1][3] =                                     0;      comb_char[1][3] =                                 0;
            comb_weight[1][2] =                                     0;      comb_char[1][2] =                                 0;
            comb_weight[1][1] =                                     0;      comb_char[1][1] =                                 0;
            comb_weight[1][0] =                                     0;      comb_char[1][0] =                                 0;

            comb_height[5][7] = ((sort_char[5][3] & V) || (sort_char[5][2] & V)) ?         (height[7] + 1) :         height[7];     comb_code[5][7] = (sort_char[5][3] & V) ?         {code[7][6:0], 1'b0} : ((sort_char[5][2] & V) ?         {code[7][6:0], 1'b1} :         code[7]);
            comb_height[5][6] = ((sort_char[5][3] & O) || (sort_char[5][2] & O)) ?         (height[6] + 1) :         height[6];     comb_code[5][6] = (sort_char[5][3] & O) ?         {code[6][6:0], 1'b0} : ((sort_char[5][2] & O) ?         {code[6][6:0], 1'b1} :         code[6]);
            comb_height[5][5] = ((sort_char[5][3] & L) || (sort_char[5][2] & L)) ?         (height[5] + 1) :         height[5];     comb_code[5][5] = (sort_char[5][3] & L) ?         {code[5][6:0], 1'b0} : ((sort_char[5][2] & L) ?         {code[5][6:0], 1'b1} :         code[5]);
            comb_height[5][4] = ((sort_char[5][3] & I) || (sort_char[5][2] & I)) ?         (height[4] + 1) :         height[4];     comb_code[5][4] = (sort_char[5][3] & I) ?         {code[4][6:0], 1'b0} : ((sort_char[5][2] & I) ?         {code[4][6:0], 1'b1} :         code[4]);
            comb_height[5][3] = ((sort_char[5][3] & E) || (sort_char[5][2] & E)) ?         (height[3] + 1) :         height[3];     comb_code[5][3] = (sort_char[5][3] & E) ?         {code[3][6:0], 1'b0} : ((sort_char[5][2] & E) ?         {code[3][6:0], 1'b1} :         code[3]);
            comb_height[5][2] = ((sort_char[5][3] & C) || (sort_char[5][2] & C)) ?         (height[2] + 1) :         height[2];     comb_code[5][2] = (sort_char[5][3] & C) ?         {code[2][6:0], 1'b0} : ((sort_char[5][2] & C) ?         {code[2][6:0], 1'b1} :         code[2]);
            comb_height[5][1] = ((sort_char[5][3] & B) || (sort_char[5][2] & B)) ?         (height[1] + 1) :         height[1];     comb_code[5][1] = (sort_char[5][3] & B) ?         {code[1][6:0], 1'b0} : ((sort_char[5][2] & B) ?         {code[1][6:0], 1'b1} :         code[1]);
            comb_height[5][0] = ((sort_char[5][3] & A) || (sort_char[5][2] & A)) ?         (height[0] + 1) :         height[0];     comb_code[5][0] = (sort_char[5][3] & A) ?         {code[0][6:0], 1'b0} : ((sort_char[5][2] & A) ?         {code[0][6:0], 1'b1} :         code[0]);

            comb_height[4][7] = ((sort_char[4][4] & V) || (sort_char[4][3] & V)) ? (comb_height[5][7] + 1) : comb_height[5][7];     comb_code[4][7] = (sort_char[4][4] & V) ? {comb_code[5][7][6:0], 1'b0} : ((sort_char[4][3] & V) ? {comb_code[5][7][6:0], 1'b1} : comb_code[5][7]);
            comb_height[4][6] = ((sort_char[4][4] & O) || (sort_char[4][3] & O)) ? (comb_height[5][6] + 1) : comb_height[5][6];     comb_code[4][6] = (sort_char[4][4] & O) ? {comb_code[5][6][6:0], 1'b0} : ((sort_char[4][3] & O) ? {comb_code[5][6][6:0], 1'b1} : comb_code[5][6]);
            comb_height[4][5] = ((sort_char[4][4] & L) || (sort_char[4][3] & L)) ? (comb_height[5][5] + 1) : comb_height[5][5];     comb_code[4][5] = (sort_char[4][4] & L) ? {comb_code[5][5][6:0], 1'b0} : ((sort_char[4][3] & L) ? {comb_code[5][5][6:0], 1'b1} : comb_code[5][5]);
            comb_height[4][4] = ((sort_char[4][4] & I) || (sort_char[4][3] & I)) ? (comb_height[5][4] + 1) : comb_height[5][4];     comb_code[4][4] = (sort_char[4][4] & I) ? {comb_code[5][4][6:0], 1'b0} : ((sort_char[4][3] & I) ? {comb_code[5][4][6:0], 1'b1} : comb_code[5][4]);
            comb_height[4][3] = ((sort_char[4][4] & E) || (sort_char[4][3] & E)) ? (comb_height[5][3] + 1) : comb_height[5][3];     comb_code[4][3] = (sort_char[4][4] & E) ? {comb_code[5][3][6:0], 1'b0} : ((sort_char[4][3] & E) ? {comb_code[5][3][6:0], 1'b1} : comb_code[5][3]);
            comb_height[4][2] = ((sort_char[4][4] & C) || (sort_char[4][3] & C)) ? (comb_height[5][2] + 1) : comb_height[5][2];     comb_code[4][2] = (sort_char[4][4] & C) ? {comb_code[5][2][6:0], 1'b0} : ((sort_char[4][3] & C) ? {comb_code[5][2][6:0], 1'b1} : comb_code[5][2]);
            comb_height[4][1] = ((sort_char[4][4] & B) || (sort_char[4][3] & B)) ? (comb_height[5][1] + 1) : comb_height[5][1];     comb_code[4][1] = (sort_char[4][4] & B) ? {comb_code[5][1][6:0], 1'b0} : ((sort_char[4][3] & B) ? {comb_code[5][1][6:0], 1'b1} : comb_code[5][1]);
            comb_height[4][0] = ((sort_char[4][4] & A) || (sort_char[4][3] & A)) ? (comb_height[5][0] + 1) : comb_height[5][0];     comb_code[4][0] = (sort_char[4][4] & A) ? {comb_code[5][0][6:0], 1'b0} : ((sort_char[4][3] & A) ? {comb_code[5][0][6:0], 1'b1} : comb_code[5][0]);

            comb_height[3][7] = ((sort_char[3][5] & V) || (sort_char[3][4] & V)) ? (comb_height[4][7] + 1) : comb_height[4][7];     comb_code[3][7] = (sort_char[3][5] & V) ? {comb_code[4][7][6:0], 1'b0} : ((sort_char[3][4] & V) ? {comb_code[4][7][6:0], 1'b1} : comb_code[4][7]);
            comb_height[3][6] = ((sort_char[3][5] & O) || (sort_char[3][4] & O)) ? (comb_height[4][6] + 1) : comb_height[4][6];     comb_code[3][6] = (sort_char[3][5] & O) ? {comb_code[4][6][6:0], 1'b0} : ((sort_char[3][4] & O) ? {comb_code[4][6][6:0], 1'b1} : comb_code[4][6]);
            comb_height[3][5] = ((sort_char[3][5] & L) || (sort_char[3][4] & L)) ? (comb_height[4][5] + 1) : comb_height[4][5];     comb_code[3][5] = (sort_char[3][5] & L) ? {comb_code[4][5][6:0], 1'b0} : ((sort_char[3][4] & L) ? {comb_code[4][5][6:0], 1'b1} : comb_code[4][5]);
            comb_height[3][4] = ((sort_char[3][5] & I) || (sort_char[3][4] & I)) ? (comb_height[4][4] + 1) : comb_height[4][4];     comb_code[3][4] = (sort_char[3][5] & I) ? {comb_code[4][4][6:0], 1'b0} : ((sort_char[3][4] & I) ? {comb_code[4][4][6:0], 1'b1} : comb_code[4][4]);
            comb_height[3][3] = ((sort_char[3][5] & E) || (sort_char[3][4] & E)) ? (comb_height[4][3] + 1) : comb_height[4][3];     comb_code[3][3] = (sort_char[3][5] & E) ? {comb_code[4][3][6:0], 1'b0} : ((sort_char[3][4] & E) ? {comb_code[4][3][6:0], 1'b1} : comb_code[4][3]);
            comb_height[3][2] = ((sort_char[3][5] & C) || (sort_char[3][4] & C)) ? (comb_height[4][2] + 1) : comb_height[4][2];     comb_code[3][2] = (sort_char[3][5] & C) ? {comb_code[4][2][6:0], 1'b0} : ((sort_char[3][4] & C) ? {comb_code[4][2][6:0], 1'b1} : comb_code[4][2]);
            comb_height[3][1] = ((sort_char[3][5] & B) || (sort_char[3][4] & B)) ? (comb_height[4][1] + 1) : comb_height[4][1];     comb_code[3][1] = (sort_char[3][5] & B) ? {comb_code[4][1][6:0], 1'b0} : ((sort_char[3][4] & B) ? {comb_code[4][1][6:0], 1'b1} : comb_code[4][1]);
            comb_height[3][0] = ((sort_char[3][5] & A) || (sort_char[3][4] & A)) ? (comb_height[4][0] + 1) : comb_height[4][0];     comb_code[3][0] = (sort_char[3][5] & A) ? {comb_code[4][0][6:0], 1'b0} : ((sort_char[3][4] & A) ? {comb_code[4][0][6:0], 1'b1} : comb_code[4][0]);

            comb_height[2][7] = ((sort_char[2][6] & V) || (sort_char[2][5] & V)) ? (comb_height[3][7] + 1) : comb_height[3][7];     comb_code[2][7] = (sort_char[2][6] & V) ? {comb_code[3][7][6:0], 1'b0} : ((sort_char[2][5] & V) ? {comb_code[3][7][6:0], 1'b1} : comb_code[3][7]);
            comb_height[2][6] = ((sort_char[2][6] & O) || (sort_char[2][5] & O)) ? (comb_height[3][6] + 1) : comb_height[3][6];     comb_code[2][6] = (sort_char[2][6] & O) ? {comb_code[3][6][6:0], 1'b0} : ((sort_char[2][5] & O) ? {comb_code[3][6][6:0], 1'b1} : comb_code[3][6]);
            comb_height[2][5] = ((sort_char[2][6] & L) || (sort_char[2][5] & L)) ? (comb_height[3][5] + 1) : comb_height[3][5];     comb_code[2][5] = (sort_char[2][6] & L) ? {comb_code[3][5][6:0], 1'b0} : ((sort_char[2][5] & L) ? {comb_code[3][5][6:0], 1'b1} : comb_code[3][5]);
            comb_height[2][4] = ((sort_char[2][6] & I) || (sort_char[2][5] & I)) ? (comb_height[3][4] + 1) : comb_height[3][4];     comb_code[2][4] = (sort_char[2][6] & I) ? {comb_code[3][4][6:0], 1'b0} : ((sort_char[2][5] & I) ? {comb_code[3][4][6:0], 1'b1} : comb_code[3][4]);
            comb_height[2][3] = ((sort_char[2][6] & E) || (sort_char[2][5] & E)) ? (comb_height[3][3] + 1) : comb_height[3][3];     comb_code[2][3] = (sort_char[2][6] & E) ? {comb_code[3][3][6:0], 1'b0} : ((sort_char[2][5] & E) ? {comb_code[3][3][6:0], 1'b1} : comb_code[3][3]);
            comb_height[2][2] = ((sort_char[2][6] & C) || (sort_char[2][5] & C)) ? (comb_height[3][2] + 1) : comb_height[3][2];     comb_code[2][2] = (sort_char[2][6] & C) ? {comb_code[3][2][6:0], 1'b0} : ((sort_char[2][5] & C) ? {comb_code[3][2][6:0], 1'b1} : comb_code[3][2]);
            comb_height[2][1] = ((sort_char[2][6] & B) || (sort_char[2][5] & B)) ? (comb_height[3][1] + 1) : comb_height[3][1];     comb_code[2][1] = (sort_char[2][6] & B) ? {comb_code[3][1][6:0], 1'b0} : ((sort_char[2][5] & B) ? {comb_code[3][1][6:0], 1'b1} : comb_code[3][1]);
            comb_height[2][0] = ((sort_char[2][6] & A) || (sort_char[2][5] & A)) ? (comb_height[3][0] + 1) : comb_height[3][0];     comb_code[2][0] = (sort_char[2][6] & A) ? {comb_code[3][0][6:0], 1'b0} : ((sort_char[2][5] & A) ? {comb_code[3][0][6:0], 1'b1} : comb_code[3][0]);

            comb_height[1][7] = ((sort_char[1][7] & V) || (sort_char[1][6] & V)) ? (comb_height[2][7] + 1) : comb_height[2][7];     comb_code[1][7] = (sort_char[1][7] & V) ? {comb_code[2][7][6:0], 1'b0} : ((sort_char[1][6] & V) ? {comb_code[2][7][6:0], 1'b1} : comb_code[2][7]);
            comb_height[1][6] = ((sort_char[1][7] & O) || (sort_char[1][6] & O)) ? (comb_height[2][6] + 1) : comb_height[2][6];     comb_code[1][6] = (sort_char[1][7] & O) ? {comb_code[2][6][6:0], 1'b0} : ((sort_char[1][6] & O) ? {comb_code[2][6][6:0], 1'b1} : comb_code[2][6]);
            comb_height[1][5] = ((sort_char[1][7] & L) || (sort_char[1][6] & L)) ? (comb_height[2][5] + 1) : comb_height[2][5];     comb_code[1][5] = (sort_char[1][7] & L) ? {comb_code[2][5][6:0], 1'b0} : ((sort_char[1][6] & L) ? {comb_code[2][5][6:0], 1'b1} : comb_code[2][5]);
            comb_height[1][4] = ((sort_char[1][7] & I) || (sort_char[1][6] & I)) ? (comb_height[2][4] + 1) : comb_height[2][4];     comb_code[1][4] = (sort_char[1][7] & I) ? {comb_code[2][4][6:0], 1'b0} : ((sort_char[1][6] & I) ? {comb_code[2][4][6:0], 1'b1} : comb_code[2][4]);
            comb_height[1][3] = ((sort_char[1][7] & E) || (sort_char[1][6] & E)) ? (comb_height[2][3] + 1) : comb_height[2][3];     comb_code[1][3] = (sort_char[1][7] & E) ? {comb_code[2][3][6:0], 1'b0} : ((sort_char[1][6] & E) ? {comb_code[2][3][6:0], 1'b1} : comb_code[2][3]);
            comb_height[1][2] = ((sort_char[1][7] & C) || (sort_char[1][6] & C)) ? (comb_height[2][2] + 1) : comb_height[2][2];     comb_code[1][2] = (sort_char[1][7] & C) ? {comb_code[2][2][6:0], 1'b0} : ((sort_char[1][6] & C) ? {comb_code[2][2][6:0], 1'b1} : comb_code[2][2]);
            comb_height[1][1] = ((sort_char[1][7] & B) || (sort_char[1][6] & B)) ? (comb_height[2][1] + 1) : comb_height[2][1];     comb_code[1][1] = (sort_char[1][7] & B) ? {comb_code[2][1][6:0], 1'b0} : ((sort_char[1][6] & B) ? {comb_code[2][1][6:0], 1'b1} : comb_code[2][1]);
            comb_height[1][0] = ((sort_char[1][7] & A) || (sort_char[1][6] & A)) ? (comb_height[2][0] + 1) : comb_height[2][0];     comb_code[1][0] = (sort_char[1][7] & A) ? {comb_code[2][0][6:0], 1'b0} : ((sort_char[1][6] & A) ? {comb_code[2][0][6:0], 1'b1} : comb_code[2][0]);
        end
        default: begin
            comb_weight[5][7] = 0;   comb_char[5][7] = 0;   
            comb_weight[5][6] = 0;   comb_char[5][6] = 0;   
            comb_weight[5][5] = 0;   comb_char[5][5] = 0;   
            comb_weight[5][4] = 0;   comb_char[5][4] = 0;   
            comb_weight[5][3] = 0;   comb_char[5][3] = 0;   
            comb_weight[5][2] = 0;   comb_char[5][2] = 0;   
            comb_weight[5][1] = 0;   comb_char[5][1] = 0;   
            comb_weight[5][0] = 0;   comb_char[5][0] = 0;

            comb_weight[4][7] = 0;   comb_char[4][7] = 0;   
            comb_weight[4][6] = 0;   comb_char[4][6] = 0;   
            comb_weight[4][5] = 0;   comb_char[4][5] = 0;   
            comb_weight[4][4] = 0;   comb_char[4][4] = 0;   
            comb_weight[4][3] = 0;   comb_char[4][3] = 0;   
            comb_weight[4][2] = 0;   comb_char[4][2] = 0;   
            comb_weight[4][1] = 0;   comb_char[4][1] = 0;   
            comb_weight[4][0] = 0;   comb_char[4][0] = 0;

            comb_weight[3][7] = 0;   comb_char[3][7] = 0;   
            comb_weight[3][6] = 0;   comb_char[3][6] = 0;   
            comb_weight[3][5] = 0;   comb_char[3][5] = 0;   
            comb_weight[3][4] = 0;   comb_char[3][4] = 0;   
            comb_weight[3][3] = 0;   comb_char[3][3] = 0;   
            comb_weight[3][2] = 0;   comb_char[3][2] = 0;   
            comb_weight[3][1] = 0;   comb_char[3][1] = 0;   
            comb_weight[3][0] = 0;   comb_char[3][0] = 0;

            comb_weight[2][7] = 0;   comb_char[2][7] = 0;   
            comb_weight[2][6] = 0;   comb_char[2][6] = 0;   
            comb_weight[2][5] = 0;   comb_char[2][5] = 0;   
            comb_weight[2][4] = 0;   comb_char[2][4] = 0;   
            comb_weight[2][3] = 0;   comb_char[2][3] = 0;   
            comb_weight[2][2] = 0;   comb_char[2][2] = 0;   
            comb_weight[2][1] = 0;   comb_char[2][1] = 0;   
            comb_weight[2][0] = 0;   comb_char[2][0] = 0;

            comb_weight[1][7] = 0;   comb_char[1][7] = 0;   
            comb_weight[1][6] = 0;   comb_char[1][6] = 0;   
            comb_weight[1][5] = 0;   comb_char[1][5] = 0;   
            comb_weight[1][4] = 0;   comb_char[1][4] = 0;   
            comb_weight[1][3] = 0;   comb_char[1][3] = 0;   
            comb_weight[1][2] = 0;   comb_char[1][2] = 0;   
            comb_weight[1][1] = 0;   comb_char[1][1] = 0;   
            comb_weight[1][0] = 0;   comb_char[1][0] = 0;

            comb_height[5][7] = 0;   comb_code[5][7] = 0;   
            comb_height[5][6] = 0;   comb_code[5][6] = 0;   
            comb_height[5][5] = 0;   comb_code[5][5] = 0;   
            comb_height[5][4] = 0;   comb_code[5][4] = 0;   
            comb_height[5][3] = 0;   comb_code[5][3] = 0;   
            comb_height[5][2] = 0;   comb_code[5][2] = 0;   
            comb_height[5][1] = 0;   comb_code[5][1] = 0;   
            comb_height[5][0] = 0;   comb_code[5][0] = 0;

            comb_height[4][7] = 0;   comb_code[4][7] = 0;   
            comb_height[4][6] = 0;   comb_code[4][6] = 0;   
            comb_height[4][5] = 0;   comb_code[4][5] = 0;   
            comb_height[4][4] = 0;   comb_code[4][4] = 0;   
            comb_height[4][3] = 0;   comb_code[4][3] = 0;   
            comb_height[4][2] = 0;   comb_code[4][2] = 0;   
            comb_height[4][1] = 0;   comb_code[4][1] = 0;   
            comb_height[4][0] = 0;   comb_code[4][0] = 0;

            comb_height[3][7] = 0;   comb_code[3][7] = 0;   
            comb_height[3][6] = 0;   comb_code[3][6] = 0;   
            comb_height[3][5] = 0;   comb_code[3][5] = 0;   
            comb_height[3][4] = 0;   comb_code[3][4] = 0;   
            comb_height[3][3] = 0;   comb_code[3][3] = 0;   
            comb_height[3][2] = 0;   comb_code[3][2] = 0;   
            comb_height[3][1] = 0;   comb_code[3][1] = 0;   
            comb_height[3][0] = 0;   comb_code[3][0] = 0;

            comb_height[2][7] = 0;   comb_code[2][7] = 0;   
            comb_height[2][6] = 0;   comb_code[2][6] = 0;   
            comb_height[2][5] = 0;   comb_code[2][5] = 0;   
            comb_height[2][4] = 0;   comb_code[2][4] = 0;   
            comb_height[2][3] = 0;   comb_code[2][3] = 0;   
            comb_height[2][2] = 0;   comb_code[2][2] = 0;   
            comb_height[2][1] = 0;   comb_code[2][1] = 0;   
            comb_height[2][0] = 0;   comb_code[2][0] = 0;

            comb_height[1][7] = 0;   comb_code[1][7] = 0;   
            comb_height[1][6] = 0;   comb_code[1][6] = 0;   
            comb_height[1][5] = 0;   comb_code[1][5] = 0;   
            comb_height[1][4] = 0;   comb_code[1][4] = 0;   
            comb_height[1][3] = 0;   comb_code[1][3] = 0;   
            comb_height[1][2] = 0;   comb_code[1][2] = 0;   
            comb_height[1][1] = 0;   comb_code[1][1] = 0;   
            comb_height[1][0] = 0;   comb_code[1][0] = 0;
        end
    endcase
end

// ===============================================================
// OUTPUT
// ===============================================================

// DFF of out & out_height
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
        out_height <= 0;
    end
    else begin
        out <= out_nxt;
        out_height <= out_height_nxt;
    end
end

// comb of out & out_height
always @(*) begin
    case (state)
        CAL: begin // output code of I
            out_nxt = comb_code[1][4];
            out_height_nxt = comb_height[1][4];
        end
        OUT_0: begin // output code of C/L
            out_nxt = (out_height == 1) ? ((out_mode_reg) ? code[2] : code[5]) : {1'b0, out[7:1]};
            out_height_nxt = (out_height == 1) ? ((out_mode_reg) ? height[2] : height[5]) : (out_height - 1);
        end
        OUT_1: begin // output code of L/O
            out_nxt = (out_height == 1) ? ((out_mode_reg) ? code[5] : code[6]) : {1'b0, out[7:1]};
            out_height_nxt = (out_height == 1) ? ((out_mode_reg) ? height[5] : height[6]) : (out_height - 1);
        end
        OUT_2: begin // output code of A/V
            out_nxt = (out_height == 1) ? ((out_mode_reg) ? code[0] : code[7]) : {1'b0, out[7:1]};
            out_height_nxt = (out_height == 1) ? ((out_mode_reg) ? height[0] : height[7]) : (out_height - 1);
        end
        OUT_3: begin // output code of B/E
            out_nxt = (out_height == 1) ? ((out_mode_reg) ? code[1] : code[3]) : {1'b0, out[7:1]};
            out_height_nxt = (out_height == 1) ? ((out_mode_reg) ? height[1] : height[3]) : (out_height - 1);
        end
        OUT_4: begin
            out_nxt = {1'b0, out[7:1]};
            out_height_nxt = out_height - 1;
        end
        default: begin
            out_nxt = 0;
            out_height_nxt = 0;
        end
    endcase
end

// DFF of output signal
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_code <= 0;
    end
    else begin
        out_valid <= out_valid_nxt; 
        out_code <= out_code_nxt;
    end
end

// comb of output signal
assign out_valid_nxt = (state == CAL) ? 1 : ((state == OUT_4) && (out_height == 1)) ? 0 : out_valid;
assign out_code_nxt = ((state == CAL) || ((out_valid) && !((state == OUT_4) && (out_height == 1)))) ? out_nxt[0] : 0;

// ======================================================
// Sort IP
// ======================================================

// magic? ^_^
assign sort_in_char = {text, text};

assign sort_in_wgt = {in_weight, in_weight};

SORT_IP #(.IP_WIDTH(4'd2)) I_SORT_IP(.IN_character(sort_in_char), .IN_weight(sort_in_wgt), .OUT_character(sort_out_char));

endmodule