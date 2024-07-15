//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
reg         com_valid;
wire        com_valid_nxt;
reg         conv_valid;
wire        conv_valid_nxt;
reg         fc_valid;
wire        fc_valid_nxt;

reg  [31:0] img[4][4];
wire [31:0] img_nxt[4][4];
reg  [31:0] ker[3][3][3];
wire [31:0] ker_nxt[3][3][3];
reg  [31:0] wgt[2][2];
wire [31:0] wgt_nxt[2][2];
reg  [ 1:0] opt;
wire [ 1:0] opt_nxt;

reg  [ 5:0] cnt_input;
wire [ 5:0] cnt_input_nxt;
reg  [ 3:0] cnt_conv;
wire [ 3:0] cnt_conv_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        com_valid <= 0;
        opt <= 0;
        cnt_input <= 0;
    end
    else begin
        com_valid <= com_valid_nxt;
        opt <= opt_nxt;
        cnt_input <= cnt_input_nxt;
    end
end

assign com_valid_nxt = (com_valid) ? ((out_valid) ? 0 : 1) : ((in_valid) ? 1 : 0);
assign opt_nxt = ((in_valid) && (cnt_input == 0) && (!com_valid)) ? Opt : opt;
assign cnt_input_nxt = (in_valid) ? (cnt_input + 1) : 0;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img[0][0] <= 0; img[0][1] <= 0; img[0][2] <= 0; img[0][3] <= 0;
        img[1][0] <= 0; img[1][1] <= 0; img[1][2] <= 0; img[1][3] <= 0;
        img[2][0] <= 0; img[2][1] <= 0; img[2][2] <= 0; img[2][3] <= 0;
        img[3][0] <= 0; img[3][1] <= 0; img[3][2] <= 0; img[3][3] <= 0;
    end
    else begin
        img[0][0] <= img_nxt[0][0]; img[0][1] <= img_nxt[0][1]; img[0][2] <= img_nxt[0][2]; img[0][3] <= img_nxt[0][3];
        img[1][0] <= img_nxt[1][0]; img[1][1] <= img_nxt[1][1]; img[1][2] <= img_nxt[1][2]; img[1][3] <= img_nxt[1][3];
        img[2][0] <= img_nxt[2][0]; img[2][1] <= img_nxt[2][1]; img[2][2] <= img_nxt[2][2]; img[2][3] <= img_nxt[2][3];
        img[3][0] <= img_nxt[3][0]; img[3][1] <= img_nxt[3][1]; img[3][2] <= img_nxt[3][2]; img[3][3] <= img_nxt[3][3];
    end
end

// shift register of img
assign img_nxt[3][3] = (in_valid) ?       Img : img[3][3];
assign img_nxt[3][2] = (in_valid) ? img[3][3] : img[3][2];
assign img_nxt[3][1] = (in_valid) ? img[3][2] : img[3][1];
assign img_nxt[3][0] = (in_valid) ? img[3][1] : img[3][0];

assign img_nxt[2][3] = (in_valid) ? img[3][0] : img[2][3];
assign img_nxt[2][2] = (in_valid) ? img[2][3] : img[2][2];
assign img_nxt[2][1] = (in_valid) ? img[2][2] : img[2][1];
assign img_nxt[2][0] = (in_valid) ? img[2][1] : img[2][0];

assign img_nxt[1][3] = (in_valid) ? img[2][0] : img[1][3];
assign img_nxt[1][2] = (in_valid) ? img[1][3] : img[1][2];
assign img_nxt[1][1] = (in_valid) ? img[1][2] : img[1][1];
assign img_nxt[1][0] = (in_valid) ? img[1][1] : img[1][0];

assign img_nxt[0][3] = (in_valid) ? img[1][0] : img[0][3];
assign img_nxt[0][2] = (in_valid) ? img[0][3] : img[0][2];
assign img_nxt[0][1] = (in_valid) ? img[0][2] : img[0][1];
assign img_nxt[0][0] = (in_valid) ? img[0][1] : img[0][0];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ker[0][0][0] <= 0; ker[0][0][1] <= 0; ker[0][0][2] <= 0;
        ker[0][1][0] <= 0; ker[0][1][1] <= 0; ker[0][1][2] <= 0;
        ker[0][2][0] <= 0; ker[0][2][1] <= 0; ker[0][2][2] <= 0;

        ker[1][0][0] <= 0; ker[1][0][1] <= 0; ker[1][0][2] <= 0;
        ker[1][1][0] <= 0; ker[1][1][1] <= 0; ker[1][1][2] <= 0;
        ker[1][2][0] <= 0; ker[1][2][1] <= 0; ker[1][2][2] <= 0;

        ker[2][0][0] <= 0; ker[2][0][1] <= 0; ker[2][0][2] <= 0;
        ker[2][1][0] <= 0; ker[2][1][1] <= 0; ker[2][1][2] <= 0;
        ker[2][2][0] <= 0; ker[2][2][1] <= 0; ker[2][2][2] <= 0;
    end
    else begin
        ker[0][0][0] <= ker_nxt[0][0][0]; ker[0][0][1] <= ker_nxt[0][0][1]; ker[0][0][2] <= ker_nxt[0][0][2];
        ker[0][1][0] <= ker_nxt[0][1][0]; ker[0][1][1] <= ker_nxt[0][1][1]; ker[0][1][2] <= ker_nxt[0][1][2];
        ker[0][2][0] <= ker_nxt[0][2][0]; ker[0][2][1] <= ker_nxt[0][2][1]; ker[0][2][2] <= ker_nxt[0][2][2];

        ker[1][0][0] <= ker_nxt[1][0][0]; ker[1][0][1] <= ker_nxt[1][0][1]; ker[1][0][2] <= ker_nxt[1][0][2];
        ker[1][1][0] <= ker_nxt[1][1][0]; ker[1][1][1] <= ker_nxt[1][1][1]; ker[1][1][2] <= ker_nxt[1][1][2];
        ker[1][2][0] <= ker_nxt[1][2][0]; ker[1][2][1] <= ker_nxt[1][2][1]; ker[1][2][2] <= ker_nxt[1][2][2];

        ker[2][0][0] <= ker_nxt[2][0][0]; ker[2][0][1] <= ker_nxt[2][0][1]; ker[2][0][2] <= ker_nxt[2][0][2];
        ker[2][1][0] <= ker_nxt[2][1][0]; ker[2][1][1] <= ker_nxt[2][1][1]; ker[2][1][2] <= ker_nxt[2][1][2];
        ker[2][2][0] <= ker_nxt[2][2][0]; ker[2][2][1] <= ker_nxt[2][2][1]; ker[2][2][2] <= ker_nxt[2][2][2];
    end
end

// shift register of kernal
assign ker_nxt[2][2][2] = (in_valid && cnt_input >= 18 && cnt_input < 27) ?       Kernel : ((out_valid) ? 0 : ker[2][2][2]);
assign ker_nxt[2][2][1] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][2][2] : ((out_valid) ? 0 : ker[2][2][1]);
assign ker_nxt[2][2][0] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][2][1] : ((out_valid) ? 0 : ker[2][2][0]);
assign ker_nxt[2][1][2] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][2][0] : ((out_valid) ? 0 : ker[2][1][2]);
assign ker_nxt[2][1][1] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][1][2] : ((out_valid) ? 0 : ker[2][1][1]);
assign ker_nxt[2][1][0] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][1][1] : ((out_valid) ? 0 : ker[2][1][0]);
assign ker_nxt[2][0][2] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][1][0] : ((out_valid) ? 0 : ker[2][0][2]);
assign ker_nxt[2][0][1] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][0][2] : ((out_valid) ? 0 : ker[2][0][1]);
assign ker_nxt[2][0][0] = (in_valid && cnt_input >= 18 && cnt_input < 27) ? ker[2][0][1] : ((out_valid) ? 0 : ker[2][0][0]);

assign ker_nxt[1][2][2] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ?       Kernel : ((cnt_input == 27) ? ker[2][2][2] : ((out_valid) ? 0 : ker[1][2][2]));
assign ker_nxt[1][2][1] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][2][2] : ((cnt_input == 27) ? ker[2][2][1] : ((out_valid) ? 0 : ker[1][2][1]));
assign ker_nxt[1][2][0] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][2][1] : ((cnt_input == 27) ? ker[2][2][0] : ((out_valid) ? 0 : ker[1][2][0]));
assign ker_nxt[1][1][2] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][2][0] : ((cnt_input == 27) ? ker[2][1][2] : ((out_valid) ? 0 : ker[1][1][2]));
assign ker_nxt[1][1][1] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][1][2] : ((cnt_input == 27) ? ker[2][1][1] : ((out_valid) ? 0 : ker[1][1][1]));
assign ker_nxt[1][1][0] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][1][1] : ((cnt_input == 27) ? ker[2][1][0] : ((out_valid) ? 0 : ker[1][1][0])); 
assign ker_nxt[1][0][2] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][1][0] : ((cnt_input == 27) ? ker[2][0][2] : ((out_valid) ? 0 : ker[1][0][2]));
assign ker_nxt[1][0][1] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][0][2] : ((cnt_input == 27) ? ker[2][0][1] : ((out_valid) ? 0 : ker[1][0][1]));
assign ker_nxt[1][0][0] = (in_valid && cnt_input >= 9 && cnt_input < 18)  ? ker[1][0][1] : ((cnt_input == 27) ? ker[2][0][0] : ((out_valid) ? 0 : ker[1][0][0]));

assign ker_nxt[0][2][2] = (in_valid && cnt_input < 9) ?       Kernel : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][2][2] : ker[0][2][2]) : ((out_valid) ? 0 : ker[0][2][2]));
assign ker_nxt[0][2][1] = (in_valid && cnt_input < 9) ? ker[0][2][2] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][2][1] : ker[0][2][2]) : ((out_valid) ? 0 : ker[0][2][1]));
assign ker_nxt[0][2][0] = (in_valid && cnt_input < 9) ? ker[0][2][1] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][2][0] : ker[0][2][1]) : ((out_valid) ? 0 : ker[0][2][0]));
assign ker_nxt[0][1][2] = (in_valid && cnt_input < 9) ? ker[0][2][0] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][1][2] : ker[0][1][1]) : ((out_valid) ? 0 : ker[0][1][2]));
assign ker_nxt[0][1][1] = (in_valid && cnt_input < 9) ? ker[0][1][2] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][1][1] : ker[0][1][0]) : ((out_valid) ? 0 : ker[0][1][1]));
assign ker_nxt[0][1][0] = (in_valid && cnt_input < 9) ? ker[0][1][1] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][1][0] : ker[0][2][0]) : ((out_valid) ? 0 : ker[0][1][0]));
assign ker_nxt[0][0][2] = (in_valid && cnt_input < 9) ? ker[0][1][0] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][0][2] : ker[0][1][2]) : ((out_valid) ? 0 : ker[0][0][2]));
assign ker_nxt[0][0][1] = (in_valid && cnt_input < 9) ? ker[0][0][2] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][0][1] : ker[0][0][2]) : ((out_valid) ? 0 : ker[0][0][1]));
assign ker_nxt[0][0][0] = (in_valid && cnt_input < 9) ? ker[0][0][1] : ((conv_valid) ? ((cnt_conv[3]) ? ker[1][0][0] : ker[0][0][1]) : ((out_valid) ? 0 : ker[0][0][0]));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wgt[0][0] <= 0; wgt[0][1] <= 0;
        wgt[1][0] <= 0; wgt[1][1] <= 0;
    end
    else begin
        wgt[0][0] <= wgt_nxt[0][0]; wgt[0][1] <= wgt_nxt[0][1];
        wgt[1][0] <= wgt_nxt[1][0]; wgt[1][1] <= wgt_nxt[1][1];
    end
end

// shift register of weight
assign wgt_nxt[1][1] = (in_valid && cnt_input < 4) ?    Weight : wgt[1][1];
assign wgt_nxt[1][0] = (in_valid && cnt_input < 4) ? wgt[1][1] : wgt[1][0];
assign wgt_nxt[0][1] = (in_valid && cnt_input < 4) ? wgt[1][0] : wgt[0][1];
assign wgt_nxt[0][0] = (in_valid && cnt_input < 4) ? wgt[0][1] : wgt[0][0];

//---------------------------------------------------------------------
//   PADDING
//---------------------------------------------------------------------
reg  [31:0] img_pad[6][6];
wire [31:0] img_pad_nxt[6][6];

reg  [ 1:0] cnt_conv_1;
wire [ 1:0] cnt_conv_1_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        conv_valid <= 0;
        cnt_conv <= 0;
        cnt_conv_1 <= 0;
    end
    else begin
        conv_valid <= conv_valid_nxt;
        cnt_conv <= cnt_conv_nxt;
        cnt_conv_1 <= cnt_conv_1_nxt;
    end
end

assign conv_valid_nxt = (cnt_conv_1[1] && cnt_conv[3]) ? 0 : ((com_valid && (!cnt_input[3:0]) && (cnt_conv_1 < 3)) ? 1 : ((cnt_conv[3]) ? 0 : conv_valid));
assign cnt_conv_nxt = (conv_valid && (!cnt_conv[3])) ? (cnt_conv + 1) : 0;
assign cnt_conv_1_nxt = (cnt_conv[3]) ? (cnt_conv_1 + 1) : ((out_valid) ? 0 : cnt_conv_1);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_pad[0][0] <= 0; img_pad[0][1] <= 0; img_pad[0][2] <= 0; img_pad[0][3] <= 0; img_pad[0][4] <= 0; img_pad[0][5] <= 0;
        img_pad[1][0] <= 0; img_pad[1][1] <= 0; img_pad[1][2] <= 0; img_pad[1][3] <= 0; img_pad[1][4] <= 0; img_pad[1][5] <= 0;
        img_pad[2][0] <= 0; img_pad[2][1] <= 0; img_pad[2][2] <= 0; img_pad[2][3] <= 0; img_pad[2][4] <= 0; img_pad[2][5] <= 0;
        img_pad[3][0] <= 0; img_pad[3][1] <= 0; img_pad[3][2] <= 0; img_pad[3][3] <= 0; img_pad[3][4] <= 0; img_pad[3][5] <= 0;
        img_pad[4][0] <= 0; img_pad[4][1] <= 0; img_pad[4][2] <= 0; img_pad[4][3] <= 0; img_pad[4][4] <= 0; img_pad[4][5] <= 0;
        img_pad[5][0] <= 0; img_pad[5][1] <= 0; img_pad[5][2] <= 0; img_pad[5][3] <= 0; img_pad[5][4] <= 0; img_pad[5][5] <= 0;
    end
    else begin
        img_pad[0][0] <= img_pad_nxt[0][0]; img_pad[0][1] <= img_pad_nxt[0][1]; img_pad[0][2] <= img_pad_nxt[0][2]; img_pad[0][3] <= img_pad_nxt[0][3]; img_pad[0][4] <= img_pad_nxt[0][4]; img_pad[0][5] <= img_pad_nxt[0][5];
        img_pad[1][0] <= img_pad_nxt[1][0]; img_pad[1][1] <= img_pad_nxt[1][1]; img_pad[1][2] <= img_pad_nxt[1][2]; img_pad[1][3] <= img_pad_nxt[1][3]; img_pad[1][4] <= img_pad_nxt[1][4]; img_pad[1][5] <= img_pad_nxt[1][5];
        img_pad[2][0] <= img_pad_nxt[2][0]; img_pad[2][1] <= img_pad_nxt[2][1]; img_pad[2][2] <= img_pad_nxt[2][2]; img_pad[2][3] <= img_pad_nxt[2][3]; img_pad[2][4] <= img_pad_nxt[2][4]; img_pad[2][5] <= img_pad_nxt[2][5];
        img_pad[3][0] <= img_pad_nxt[3][0]; img_pad[3][1] <= img_pad_nxt[3][1]; img_pad[3][2] <= img_pad_nxt[3][2]; img_pad[3][3] <= img_pad_nxt[3][3]; img_pad[3][4] <= img_pad_nxt[3][4]; img_pad[3][5] <= img_pad_nxt[3][5];
        img_pad[4][0] <= img_pad_nxt[4][0]; img_pad[4][1] <= img_pad_nxt[4][1]; img_pad[4][2] <= img_pad_nxt[4][2]; img_pad[4][3] <= img_pad_nxt[4][3]; img_pad[4][4] <= img_pad_nxt[4][4]; img_pad[4][5] <= img_pad_nxt[4][5];
        img_pad[5][0] <= img_pad_nxt[5][0]; img_pad[5][1] <= img_pad_nxt[5][1]; img_pad[5][2] <= img_pad_nxt[5][2]; img_pad[5][3] <= img_pad_nxt[5][3]; img_pad[5][4] <= img_pad_nxt[5][4]; img_pad[5][5] <= img_pad_nxt[5][5];
    end
end

assign img_pad_nxt[5][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][0] : img_pad[5][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][3] : 0) :img_pad[5][5]);
assign img_pad_nxt[5][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][5] : img_pad[5][3])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][3] : 0) :img_pad[5][4]);
assign img_pad_nxt[5][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][4] : img_pad[5][2])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][2] : 0) :img_pad[5][3]);
assign img_pad_nxt[5][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][3] : img_pad[5][1])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][1] : 0) :img_pad[5][2]);
assign img_pad_nxt[5][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][2] : img_pad[5][0])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][0] : 0) :img_pad[5][1]);
assign img_pad_nxt[5][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[5][1] : img_pad[5][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][0] : 0) :img_pad[5][0]);

assign img_pad_nxt[4][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][0] : img_pad[4][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][3] : 0) :img_pad[4][5]);
assign img_pad_nxt[4][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][5] : img_pad[4][3])) : ((com_valid && (!cnt_input[3:0])) ?                  img[3][3] :img_pad[4][4]);
assign img_pad_nxt[4][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][4] : img_pad[4][2])) : ((com_valid && (!cnt_input[3:0])) ?                  img[3][2] :img_pad[4][3]);
assign img_pad_nxt[4][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][3] : img_pad[4][1])) : ((com_valid && (!cnt_input[3:0])) ?                  img[3][1] :img_pad[4][2]);
assign img_pad_nxt[4][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][2] : img_pad[4][0])) : ((com_valid && (!cnt_input[3:0])) ?                  img[3][0] :img_pad[4][1]);
assign img_pad_nxt[4][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[5][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[4][1] : img_pad[4][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[3][0] : 0) :img_pad[4][0]);

assign img_pad_nxt[3][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][0] : img_pad[3][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[2][3] : 0) :img_pad[3][5]);
assign img_pad_nxt[3][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][5] : img_pad[3][3])) : ((com_valid && (!cnt_input[3:0])) ?                  img[2][3] :img_pad[3][4]);
assign img_pad_nxt[3][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][4] : img_pad[3][2])) : ((com_valid && (!cnt_input[3:0])) ?                  img[2][2] :img_pad[3][3]);
assign img_pad_nxt[3][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][3] : img_pad[3][1])) : ((com_valid && (!cnt_input[3:0])) ?                  img[2][1] :img_pad[3][2]);
assign img_pad_nxt[3][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][2] : img_pad[3][0])) : ((com_valid && (!cnt_input[3:0])) ?                  img[2][0] :img_pad[3][1]);
assign img_pad_nxt[3][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[4][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[3][1] : img_pad[3][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[2][0] : 0) :img_pad[3][0]);

assign img_pad_nxt[2][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][0] : img_pad[2][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[1][3] : 0) :img_pad[2][5]);
assign img_pad_nxt[2][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][5] : img_pad[2][3])) : ((com_valid && (!cnt_input[3:0])) ?                  img[1][3] :img_pad[2][4]);
assign img_pad_nxt[2][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][4] : img_pad[2][2])) : ((com_valid && (!cnt_input[3:0])) ?                  img[1][2] :img_pad[2][3]);
assign img_pad_nxt[2][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][3] : img_pad[2][1])) : ((com_valid && (!cnt_input[3:0])) ?                  img[1][1] :img_pad[2][2]);
assign img_pad_nxt[2][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][2] : img_pad[2][0])) : ((com_valid && (!cnt_input[3:0])) ?                  img[1][0] :img_pad[2][1]);
assign img_pad_nxt[2][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[3][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[2][1] : img_pad[2][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[1][0] : 0) :img_pad[2][0]);

assign img_pad_nxt[1][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][0] : img_pad[1][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][3] : 0) :img_pad[1][5]);
assign img_pad_nxt[1][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][5] : img_pad[1][3])) : ((com_valid && (!cnt_input[3:0])) ?                  img[0][3] :img_pad[1][4]);
assign img_pad_nxt[1][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][4] : img_pad[1][2])) : ((com_valid && (!cnt_input[3:0])) ?                  img[0][2] :img_pad[1][3]);
assign img_pad_nxt[1][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][3] : img_pad[1][1])) : ((com_valid && (!cnt_input[3:0])) ?                  img[0][1] :img_pad[1][2]);
assign img_pad_nxt[1][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][2] : img_pad[1][0])) : ((com_valid && (!cnt_input[3:0])) ?                  img[0][0] :img_pad[1][1]);
assign img_pad_nxt[1][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[2][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[1][1] : img_pad[1][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][0] : 0) :img_pad[1][0]);

assign img_pad_nxt[0][5] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][5] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][0] : img_pad[0][4])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][3] : 0) :img_pad[0][5]);
assign img_pad_nxt[0][4] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][4] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][5] : img_pad[0][3])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][3] : 0) :img_pad[0][4]);
assign img_pad_nxt[0][3] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][3] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][4] : img_pad[0][2])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][2] : 0) :img_pad[0][3]);
assign img_pad_nxt[0][2] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][2] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][3] : img_pad[0][1])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][1] : 0) :img_pad[0][2]);
assign img_pad_nxt[0][1] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][1] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][2] : img_pad[0][0])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][0] : 0) :img_pad[0][1]);
assign img_pad_nxt[0][0] = (conv_valid && (cnt_conv_1 < 3)) ? ((cnt_conv == 2 || cnt_conv == 5) ? img_pad[1][0] : ((cnt_conv < 2 || cnt_conv > 5) ? img_pad[0][1] : img_pad[0][5])) : ((com_valid && (!cnt_input[3:0])) ? ((opt[1]) ? img[0][0] : 0) :img_pad[0][0]);

//---------------------------------------------------------------------
//   CONVOLUTION
//---------------------------------------------------------------------
reg  [31:0] conv[4][4];
wire [31:0] conv_nxt[4][4];

wire [31:0] z_inst_mac[16];
wire [31:0] z0_inst_cmp[4];
wire [31:0] z1_inst_cmp[4];
wire [31:0] z_inst_div;
wire [31:0] z_inst_exp;
wire [31:0] z_inst_ln;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        conv[0][0] <= 0; conv[0][1] <= 0; conv[0][2] <= 0; conv[0][3] <= 0;
        conv[1][0] <= 0; conv[1][1] <= 0; conv[1][2] <= 0; conv[1][3] <= 0;
        conv[2][0] <= 0; conv[2][1] <= 0; conv[2][2] <= 0; conv[2][3] <= 0;
        conv[3][0] <= 0; conv[3][1] <= 0; conv[3][2] <= 0; conv[3][3] <= 0;
    end
    else begin
        conv[0][0] <= conv_nxt[0][0]; conv[0][1] <= conv_nxt[0][1]; conv[0][2] <= conv_nxt[0][2]; conv[0][3] <= conv_nxt[0][3];
        conv[1][0] <= conv_nxt[1][0]; conv[1][1] <= conv_nxt[1][1]; conv[1][2] <= conv_nxt[1][2]; conv[1][3] <= conv_nxt[1][3];
        conv[2][0] <= conv_nxt[2][0]; conv[2][1] <= conv_nxt[2][1]; conv[2][2] <= conv_nxt[2][2]; conv[2][3] <= conv_nxt[2][3];
        conv[3][0] <= conv_nxt[3][0]; conv[3][1] <= conv_nxt[3][1]; conv[3][2] <= conv_nxt[3][2]; conv[3][3] <= conv_nxt[3][3];
    end
end

assign conv_nxt[0][0] = (conv_valid) ? z_inst_mac[ 0] : ((out_valid) ? 0 : conv[0][0]);
assign conv_nxt[0][1] = (conv_valid) ? z_inst_mac[ 1] : ((out_valid) ? 0 : conv[0][1]);
assign conv_nxt[0][2] = (conv_valid) ? z_inst_mac[ 2] : ((out_valid) ? 0 : conv[0][2]);
assign conv_nxt[0][3] = (conv_valid) ? z_inst_mac[ 3] : ((out_valid) ? 0 : conv[0][3]);
assign conv_nxt[1][0] = (conv_valid) ? z_inst_mac[ 4] : ((out_valid) ? 0 : conv[1][0]);
assign conv_nxt[1][1] = (conv_valid) ? z_inst_mac[ 5] : ((out_valid) ? 0 : conv[1][1]);
assign conv_nxt[1][2] = (conv_valid) ? z_inst_mac[ 6] : ((out_valid) ? 0 : conv[1][2]);
assign conv_nxt[1][3] = (conv_valid) ? z_inst_mac[ 7] : ((out_valid) ? 0 : conv[1][3]);
assign conv_nxt[2][0] = (conv_valid) ? z_inst_mac[ 8] : ((out_valid) ? 0 : conv[2][0]);
assign conv_nxt[2][1] = (conv_valid) ? z_inst_mac[ 9] : ((out_valid) ? 0 : conv[2][1]);
assign conv_nxt[2][2] = (conv_valid) ? z_inst_mac[10] : ((out_valid) ? 0 : conv[2][2]);
assign conv_nxt[2][3] = (conv_valid) ? z_inst_mac[11] : ((out_valid) ? 0 : conv[2][3]);
assign conv_nxt[3][0] = (conv_valid) ? z_inst_mac[12] : ((out_valid) ? 0 : conv[3][0]);
assign conv_nxt[3][1] = (conv_valid) ? z_inst_mac[13] : ((out_valid) ? 0 : conv[3][1]);
assign conv_nxt[3][2] = (conv_valid) ? z_inst_mac[14] : ((out_valid) ? 0 : conv[3][2]);
assign conv_nxt[3][3] = (conv_valid) ? z_inst_mac[15] : ((out_valid) ? 0 : conv[3][3]);

//---------------------------------------------------------------------
//   MAXPOOLING
//---------------------------------------------------------------------
reg         mp_valid;
wire        mp_valid_nxt;

reg  [1:0]  cnt_mp;
wire [1:0]  cnt_mp_nxt;

reg  [31:0] mp;
wire [31:0] mp_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mp_valid <= 0;
        cnt_mp <= 0;
    end
    else begin
        mp_valid <= mp_valid_nxt;
        cnt_mp <= cnt_mp_nxt;
    end
end

assign mp_valid_nxt = ((cnt_conv_1[1]) && (cnt_conv[3])) ? 1 : ((cnt_mp < 3) ? mp_valid : 0);
assign cnt_mp_nxt = (mp_valid) ? (cnt_mp + 1) : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mp <= 0;
    end
    else begin
        mp <= mp_nxt;
    end
end

assign mp_nxt = (mp_valid) ? z1_inst_cmp[2] : mp;

//---------------------------------------------------------------------
//   FULLYCONNECTED
//---------------------------------------------------------------------
reg  [ 1:0] cnt_fc;
wire [ 1:0] cnt_fc_nxt;

reg  [31:0] fc[2][2];
wire [31:0] fc_nxt[2][2];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fc_valid <= 0;
        cnt_fc <= 0;
    end
    else begin
        fc_valid <= fc_valid_nxt;
        cnt_fc <= cnt_fc_nxt;
    end
end

assign fc_valid_nxt = (mp_valid) ? 1 : 0;
assign cnt_fc_nxt = (fc_valid) ? (cnt_fc + 1) : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fc[0][0] <= 0; fc[0][1] <= 0;
        fc[1][0] <= 0; fc[1][1] <= 0;
    end
    else begin
        fc[0][0] <= fc_nxt[0][0]; fc[0][1] <= fc_nxt[0][1];
        fc[1][0] <= fc_nxt[1][0]; fc[1][1] <= fc_nxt[1][1];
    end
end

assign fc_nxt[0][0] = (fc_valid) ? z_inst_mac[0] : ((out_valid) ? 0 : fc[0][0]);
assign fc_nxt[0][1] = (fc_valid) ? z_inst_mac[1] : ((out_valid) ? 0 : fc[0][1]);
assign fc_nxt[1][0] = (fc_valid) ? z_inst_mac[2] : ((out_valid) ? 0 : fc[1][0]);
assign fc_nxt[1][1] = (fc_valid) ? z_inst_mac[3] : ((out_valid) ? 0 : fc[1][1]);

//---------------------------------------------------------------------
//   NORMALIZATION
//---------------------------------------------------------------------
reg  norm_valid;
wire norm_valid_nxt;

reg  act_valid;
wire act_valid_nxt;

reg  [ 1:0] cnt_norm;
wire [ 1:0] cnt_norm_nxt;

reg  [31:0] dif;
wire [31:0] dif_nxt;

reg  [31:0] norm[4];
wire [31:0] norm_nxt[4];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        norm_valid <= 0;
        cnt_norm <= 0;
    end
    else begin
        norm_valid <= norm_valid_nxt;
        cnt_norm <= cnt_norm_nxt;
    end
end

assign norm_valid_nxt = ((!mp_valid) && (fc_valid)) ? 1 : (!(cnt_norm[1]) ? norm_valid : 0);
assign cnt_norm_nxt = ((norm_valid) && (!cnt_norm[1])) ? (cnt_norm + 1) : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        norm[0] <= 0;
        norm[1] <= 0;
        norm[2] <= 0;
        norm[3] <= 0;
    end
    else begin
        norm[0] <= norm_nxt[0];
        norm[1] <= norm_nxt[1];
        norm[2] <= norm_nxt[2];
        norm[3] <= norm_nxt[3];
    end
end

assign norm_nxt[3] = (norm_valid) ? ((cnt_norm[1]) ? z_inst_mac[7] : z_inst_mac[11]) : ((act_valid) ?       0 : norm[3]);
assign norm_nxt[2] = (norm_valid) ? ((cnt_norm[1]) ? z_inst_mac[6] : z_inst_mac[10]) : ((act_valid) ? norm[3] : norm[2]);
assign norm_nxt[1] = (norm_valid) ? ((cnt_norm[1]) ? z_inst_mac[5] : z_inst_mac[ 9]) : ((act_valid) ? norm[2] : norm[1]);
assign norm_nxt[0] = (norm_valid) ? ((cnt_norm[1]) ? z_inst_mac[4] : z_inst_mac[ 8]) : ((act_valid) ? norm[1] : norm[0]);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dif <= 0;
    end
    else begin
        dif <= dif_nxt;
    end
end

assign dif_nxt = ((norm_valid) && (!cnt_norm[0])) ? z_inst_mac[12] : dif;

//---------------------------------------------------------------------
//   ACTIVATION
//---------------------------------------------------------------------
reg  [ 2:0] cnt_act;
wire [ 2:0] cnt_act_nxt;

reg  [31:0] exp;
wire [31:0] exp_nxt;
reg  [31:0] num;
wire [31:0] num_nxt;
reg  [31:0] den;
wire [31:0] den_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_valid <= 0;
        cnt_act <= 0;
    end
    else begin
        act_valid <= act_valid_nxt;
        cnt_act <= cnt_act_nxt;
    end
end

assign act_valid_nxt = ((norm_valid) && (cnt_norm[1])) ? 1 : ((cnt_act < 6) ? act_valid : 0);
assign cnt_act_nxt = ((act_valid) && (cnt_act < 6)) ? (cnt_act + 1) : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp <= 0; 
        num <= 0;
        den <= 0;
    end
    else begin
        exp <= exp_nxt;
        num <= num_nxt;
        den <= den_nxt;
    end
end

assign exp_nxt = (act_valid) ? z_inst_exp : 0;
assign num_nxt = (act_valid) ? ((opt == 1) ? (z_inst_mac[14]) : ((opt == 2) ? 32'h3f800000 : z_inst_mac[13])) : 0;
assign den_nxt = (act_valid) ? z_inst_mac[13] : 0;

//---------------------------------------------------------------------
//   MAC
//---------------------------------------------------------------------
reg  [31:0] div;
wire [31:0] div_nxt;

wire [31:0] inst_a_mac[16];
wire [31:0] inst_b_mac[16];
wire [31:0] inst_c_mac[16];

// convolution + fully connected
assign inst_a_mac[ 0] = (conv_valid) ? img_pad[0][0] : (                (fc_valid) ?                                     mp : 0);
assign inst_a_mac[ 1] = (conv_valid) ? img_pad[0][1] : (                (fc_valid) ?                                     mp : 0);
assign inst_a_mac[ 2] = (conv_valid) ? img_pad[0][2] : (                (fc_valid) ?                                     mp : 0);
assign inst_a_mac[ 3] = (conv_valid) ? img_pad[0][3] : (                (fc_valid) ?                                     mp : 0);

assign inst_b_mac[ 0] = (conv_valid) ?  ker[0][0][0] : ((fc_valid && (!cnt_fc[1])) ? ((!cnt_fc[0]) ? wgt[0][0] : wgt[1][0]) : 0);
assign inst_b_mac[ 1] = (conv_valid) ?  ker[0][0][0] : ((fc_valid && (!cnt_fc[1])) ? ((!cnt_fc[0]) ? wgt[0][1] : wgt[1][1]) : 0);
assign inst_b_mac[ 2] = (conv_valid) ?  ker[0][0][0] : ((fc_valid && ( cnt_fc[1])) ? ((!cnt_fc[0]) ? wgt[0][0] : wgt[1][0]) : 0);
assign inst_b_mac[ 3] = (conv_valid) ?  ker[0][0][0] : ((fc_valid && ( cnt_fc[1])) ? ((!cnt_fc[0]) ? wgt[0][1] : wgt[1][1]) : 0);

assign inst_c_mac[ 0] = (conv_valid) ?    conv[0][0] : (                (fc_valid) ?                               fc[0][0] : 0);
assign inst_c_mac[ 1] = (conv_valid) ?    conv[0][1] : (                (fc_valid) ?                               fc[0][1] : 0);
assign inst_c_mac[ 2] = (conv_valid) ?    conv[0][2] : (                (fc_valid) ?                               fc[1][0] : 0);
assign inst_c_mac[ 3] = (conv_valid) ?    conv[0][3] : (                (fc_valid) ?                               fc[1][1] : 0);

// convolution + normalization (x+(-xmin)*(1/(xmax-xmin)))
assign inst_a_mac[ 4] = (conv_valid) ? img_pad[1][0] : (((norm_valid) && (cnt_norm[1])) ? norm[0] : 0);
assign inst_a_mac[ 5] = (conv_valid) ? img_pad[1][1] : (((norm_valid) && (cnt_norm[1])) ? norm[1] : 0);
assign inst_a_mac[ 6] = (conv_valid) ? img_pad[1][2] : (((norm_valid) && (cnt_norm[1])) ? norm[2] : 0);
assign inst_a_mac[ 7] = (conv_valid) ? img_pad[1][3] : (((norm_valid) && (cnt_norm[1])) ? norm[3] : 0);

assign inst_b_mac[ 4] = (conv_valid) ?  ker[0][0][0] : (((norm_valid) && (cnt_norm[1])) ?     div : 0);
assign inst_b_mac[ 5] = (conv_valid) ?  ker[0][0][0] : (((norm_valid) && (cnt_norm[1])) ?     div : 0);
assign inst_b_mac[ 6] = (conv_valid) ?  ker[0][0][0] : (((norm_valid) && (cnt_norm[1])) ?     div : 0);
assign inst_b_mac[ 7] = (conv_valid) ?  ker[0][0][0] : (((norm_valid) && (cnt_norm[1])) ?     div : 0);

assign inst_c_mac[ 4] = (conv_valid) ?    conv[1][0] : (                                            0);
assign inst_c_mac[ 5] = (conv_valid) ?    conv[1][1] : (                                            0);
assign inst_c_mac[ 6] = (conv_valid) ?    conv[1][2] : (                                            0);
assign inst_c_mac[ 7] = (conv_valid) ?    conv[1][3] : (                                            0);

// convolution + normalization (x+(-xmin))
assign inst_a_mac[ 8] = (conv_valid) ? img_pad[2][0] : ((norm_valid) ?                                    fc[0][0] : 0);
assign inst_a_mac[ 9] = (conv_valid) ? img_pad[2][1] : ((norm_valid) ?                                    fc[0][1] : 0);
assign inst_a_mac[10] = (conv_valid) ? img_pad[2][2] : ((norm_valid) ?                                    fc[1][0] : 0);
assign inst_a_mac[11] = (conv_valid) ? img_pad[2][3] : ((norm_valid) ?                                    fc[1][1] : 0);
assign inst_a_mac[12] = (conv_valid) ? img_pad[3][0] : ((norm_valid) ?                              z1_inst_cmp[3] : 0);

assign inst_b_mac[ 8] = (conv_valid) ?  ker[0][0][0] : ((norm_valid) ?                                32'h3f800000 : 0);
assign inst_b_mac[ 9] = (conv_valid) ?  ker[0][0][0] : ((norm_valid) ?                                32'h3f800000 : 0);
assign inst_b_mac[10] = (conv_valid) ?  ker[0][0][0] : ((norm_valid) ?                                32'h3f800000 : 0);
assign inst_b_mac[11] = (conv_valid) ?  ker[0][0][0] : ((norm_valid) ?                                32'h3f800000 : 0);
assign inst_b_mac[12] = (conv_valid) ?  ker[0][0][0] : ((norm_valid) ?                                32'h3f800000 : 0);

assign inst_c_mac[ 8] = (conv_valid) ?    conv[2][0] : ((norm_valid) ? {!z0_inst_cmp[2][31], z0_inst_cmp[2][30:0]} : 0);
assign inst_c_mac[ 9] = (conv_valid) ?    conv[2][1] : ((norm_valid) ? {!z0_inst_cmp[2][31], z0_inst_cmp[2][30:0]} : 0);
assign inst_c_mac[10] = (conv_valid) ?    conv[2][2] : ((norm_valid) ? {!z0_inst_cmp[2][31], z0_inst_cmp[2][30:0]} : 0);
assign inst_c_mac[11] = (conv_valid) ?    conv[2][3] : ((norm_valid) ? {!z0_inst_cmp[2][31], z0_inst_cmp[2][30:0]} : 0);
assign inst_c_mac[12] = (conv_valid) ?    conv[3][0] : ((norm_valid) ? {!z0_inst_cmp[2][31], z0_inst_cmp[2][30:0]} : 0);

// convolution + activation (exp+1 or exp-1)
assign inst_a_mac[13] = (conv_valid) ? img_pad[3][1] : ((act_valid) ?          exp : 0);
assign inst_a_mac[14] = (conv_valid) ? img_pad[3][2] : ((act_valid) ?          exp : 0);
assign inst_b_mac[13] = (conv_valid) ?  ker[0][0][0] : ((act_valid) ? 32'h3f800000 : 0);
assign inst_b_mac[14] = (conv_valid) ?  ker[0][0][0] : ((act_valid) ? 32'h3f800000 : 0);
assign inst_c_mac[13] = (conv_valid) ?    conv[3][1] : ((act_valid) ? 32'h3f800000 : 0);
assign inst_c_mac[14] = (conv_valid) ?    conv[3][2] : ((act_valid) ? 32'hbf800000 : 0);

// convolution
assign inst_a_mac[15] = (conv_valid) ? img_pad[3][3] : 0;
assign inst_b_mac[15] = (conv_valid) ?  ker[0][0][0] : 0;
assign inst_c_mac[15] = (conv_valid) ?    conv[3][3] : 0;

// call IP
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC0(.a(inst_a_mac[ 0]), .b(inst_b_mac[ 0]), .c(inst_c_mac[ 0]), .rnd(3'b000), .z(z_inst_mac[ 0]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC1(.a(inst_a_mac[ 1]), .b(inst_b_mac[ 1]), .c(inst_c_mac[ 1]), .rnd(3'b000), .z(z_inst_mac[ 1]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC2(.a(inst_a_mac[ 2]), .b(inst_b_mac[ 2]), .c(inst_c_mac[ 2]), .rnd(3'b000), .z(z_inst_mac[ 2]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC3(.a(inst_a_mac[ 3]), .b(inst_b_mac[ 3]), .c(inst_c_mac[ 3]), .rnd(3'b000), .z(z_inst_mac[ 3]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC4(.a(inst_a_mac[ 4]), .b(inst_b_mac[ 4]), .c(inst_c_mac[ 4]), .rnd(3'b000), .z(z_inst_mac[ 4]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC5(.a(inst_a_mac[ 5]), .b(inst_b_mac[ 5]), .c(inst_c_mac[ 5]), .rnd(3'b000), .z(z_inst_mac[ 5]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC6(.a(inst_a_mac[ 6]), .b(inst_b_mac[ 6]), .c(inst_c_mac[ 6]), .rnd(3'b000), .z(z_inst_mac[ 6]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC7(.a(inst_a_mac[ 7]), .b(inst_b_mac[ 7]), .c(inst_c_mac[ 7]), .rnd(3'b000), .z(z_inst_mac[ 7]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC8(.a(inst_a_mac[ 8]), .b(inst_b_mac[ 8]), .c(inst_c_mac[ 8]), .rnd(3'b000), .z(z_inst_mac[ 8]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  MAC9(.a(inst_a_mac[ 9]), .b(inst_b_mac[ 9]), .c(inst_c_mac[ 9]), .rnd(3'b000), .z(z_inst_mac[ 9]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC10(.a(inst_a_mac[10]), .b(inst_b_mac[10]), .c(inst_c_mac[10]), .rnd(3'b000), .z(z_inst_mac[10]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC11(.a(inst_a_mac[11]), .b(inst_b_mac[11]), .c(inst_c_mac[11]), .rnd(3'b000), .z(z_inst_mac[11]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC12(.a(inst_a_mac[12]), .b(inst_b_mac[12]), .c(inst_c_mac[12]), .rnd(3'b000), .z(z_inst_mac[12]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC13(.a(inst_a_mac[13]), .b(inst_b_mac[13]), .c(inst_c_mac[13]), .rnd(3'b000), .z(z_inst_mac[13]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC14(.a(inst_a_mac[14]), .b(inst_b_mac[14]), .c(inst_c_mac[14]), .rnd(3'b000), .z(z_inst_mac[14]));
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) MAC15(.a(inst_a_mac[15]), .b(inst_b_mac[15]), .c(inst_c_mac[15]), .rnd(3'b000), .z(z_inst_mac[15]));

//---------------------------------------------------------------------
//   CMP
//---------------------------------------------------------------------
wire [31:0] inst_a_cmp[4];
wire [31:0] inst_b_cmp[4];

// maxpooling: find maximum of convolution
// normalization: find maximum and minimum of fullyconnected
assign inst_a_cmp[0] = (mp_valid) ? ((cnt_mp == 0) ? conv[0][0] : ((cnt_mp == 1) ? conv[0][2] : ((cnt_mp == 2) ? conv[2][0] : conv[2][2]))) : ((norm_valid) ? fc[0][0] : 0);
assign inst_a_cmp[1] = (mp_valid) ? ((cnt_mp == 0) ? conv[0][1] : ((cnt_mp == 1) ? conv[0][3] : ((cnt_mp == 2) ? conv[2][1] : conv[2][3]))) : ((norm_valid) ? fc[0][1] : 0);
assign inst_a_cmp[2] = (  mp_valid) ? z1_inst_cmp[0] : ((norm_valid) ? z0_inst_cmp[0] : 0);
assign inst_a_cmp[3] = (norm_valid) ? z1_inst_cmp[0] : (                                0);

assign inst_b_cmp[0] = (mp_valid) ? ((cnt_mp == 0) ? conv[1][0] : ((cnt_mp == 1) ? conv[1][2] : ((cnt_mp == 2) ? conv[3][0] : conv[3][2]))) : ((norm_valid) ? fc[1][0] : 0);
assign inst_b_cmp[1] = (mp_valid) ? ((cnt_mp == 0) ? conv[1][1] : ((cnt_mp == 1) ? conv[1][3] : ((cnt_mp == 2) ? conv[3][1] : conv[3][3]))) : ((norm_valid) ? fc[1][1] : 0);
assign inst_b_cmp[2] = (  mp_valid) ? z1_inst_cmp[1] : ((norm_valid) ? z0_inst_cmp[1] : 0);
assign inst_b_cmp[3] = (norm_valid) ? z1_inst_cmp[1] : (                                0);

// call IP
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CMP0(.a( inst_a_cmp[0]), .b( inst_b_cmp[0]), .zctr(1'b0), .z0(z0_inst_cmp[0]), .z1(z1_inst_cmp[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CMP1(.a( inst_a_cmp[1]), .b( inst_b_cmp[1]), .zctr(1'b0), .z0(z0_inst_cmp[1]), .z1(z1_inst_cmp[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CMP2(.a( inst_a_cmp[2]), .b( inst_b_cmp[2]), .zctr(1'b0), .z0(z0_inst_cmp[2]), .z1(z1_inst_cmp[2]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CMP3(.a( inst_a_cmp[3]), .b( inst_b_cmp[3]), .zctr(1'b0), .z0(z0_inst_cmp[3]), .z1(z1_inst_cmp[3]));

//---------------------------------------------------------------------
//   DIV
//---------------------------------------------------------------------
wire [31:0] inst_a_div;
wire [31:0] inst_b_div;

// normalization: 1/(xmax-xmin)
// activation: num/den
assign inst_a_div = ((norm_valid) && (cnt_norm)) ? 32'h3f800000 : ((act_valid) ? num : 32'h3f800000);

assign inst_b_div = ((norm_valid) && (cnt_norm)) ?          dif : ((act_valid) ? den : 32'h3f800000);

// call IP
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) DIV0(.a(inst_a_div), .b(inst_b_div), .rnd(3'b000), .z(z_inst_div));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div <= 0;
    end
    else begin
        div <= div_nxt;
    end
end

assign div_nxt = z_inst_div;

//---------------------------------------------------------------------
//   EXP
//---------------------------------------------------------------------
reg  [31:0] inst_a_exp_tmp;
wire [31:0] inst_a_exp;

always @(*) begin
    case (opt)
        1: inst_a_exp_tmp = {norm[0][31], norm[0][30:23] + 1, norm[0][22:0]};
        2: inst_a_exp_tmp = {!norm[0][31], norm[0][30:0]};
        default: inst_a_exp_tmp = norm[0];
    endcase
end

assign inst_a_exp = inst_a_exp_tmp;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) EXP0(.a(inst_a_exp), .z(z_inst_exp));

//---------------------------------------------------------------------
//   LN
//---------------------------------------------------------------------
wire [31:0] inst_a_ln;

assign inst_a_ln = (act_valid) ? num : 0;

DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance) LN0(.a(inst_a_ln), .z(z_inst_ln));

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
wire        out_valid_nxt;

reg  [ 1:0] cnt_out;
wire [ 1:0] cnt_out_nxt;

wire [31:0] out_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        cnt_out <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
        cnt_out <= cnt_out_nxt;
    end
end

assign out_valid_nxt = (((!opt) && (act_valid) && (!cnt_act)) || (((opt == 1) || (opt == 2)) && (cnt_act == 2)) || ((opt == 3) && (cnt_act == 2))) ? 1 : ((cnt_out < 3) ? out_valid : 0);
assign cnt_out_nxt = ((out_valid) && (cnt_out < 3)) ? (cnt_out + 1) : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else begin
        out <= out_nxt;
    end
end

assign out_nxt = (cnt_out < 3) ? (((!opt) && (act_valid)) ? norm[0] : ((out_valid) ? (((opt == 1) || (opt == 2)) ? z_inst_div : z_inst_ln) : ((((opt == 1) || (opt == 2)) && (cnt_act == 2)) ? z_inst_div : ((((opt == 3) && (cnt_act == 2))) ? z_inst_ln : 0)))) : 0;

endmodule
