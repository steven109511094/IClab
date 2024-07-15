module CAD(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    mode,
    matrix_size,
    matrix,
    matrix_idx,
    // output signals
    out_valid,
    out_value
    );

input [1:0] matrix_size;
input clk;
input [7:0] matrix;
input rst_n;
input [3:0] matrix_idx;
input in_valid2;

input mode;
input in_valid;
output reg out_valid;
output reg out_value;

//=======================================================
//                     PARAMETER
//=======================================================
parameter IDLE       = 0,
          IN_IMG     = 1,
          IN_IDX     = 2,
          IN_KER     = 3,
          OUT        = 4,
          CAL_DECONV = 5,
          CAL_CONV   = 6,
          CAL_MAXPL  = 7;

//=======================================================
//                     REG and WIRE
//=======================================================
// FSM
reg  [ 2:0] state;
reg  [ 2:0] state_nxt;

// INPUT
reg  [ 1:0] matrix_size_reg;
wire [ 1:0] matrix_size_nxt;

reg  [ 7:0] matrix_reg;
wire [ 7:0] matrix_nxt;

reg        mode_reg;
wire       mode_nxt;

reg  [ 3:0] matrix_idx_reg;
wire [ 3:0] matrix_idx_nxt;

reg  [ 3:0] img_idx;
wire [ 3:0] img_idx_nxt;

reg  [ 3:0] ker_idx;
wire [ 3:0] ker_idx_nxt;

// COUNTERS
reg  [ 9:0] cnt_in_1024;
wire [ 9:0] cnt_in_1024_nxt;

reg  [ 3:0] cnt_in_16;
wire [ 3:0] cnt_in_16_nxt;

reg  [ 4:0] cnt_in_25;
wire [ 4:0] cnt_in_25_nxt;

reg  [ 2:0] cnt_in_5;
wire [ 2:0] cnt_in_5_nxt;

reg  [ 1:0] cnt_in_4;
wire [ 1:0] cnt_in_4_nxt;

reg  [ 3:0] cnt_conv;
wire [ 3:0] cnt_conv_nxt;

reg  [ 5:0] cnt_out_bit;
wire [ 5:0] cnt_out_bit_nxt;

reg  [ 5:0] cnt_out_col;
wire [ 5:0] cnt_out_col_nxt;

reg  [ 5:0] cnt_out_row;
wire [ 5:0] cnt_out_row_nxt;

// CONVOLUTION
reg  signed [ 7:0] img     [2][2][8];
reg  signed [ 7:0] img_nxt [2][2][8];
reg  signed [ 7:0] ker     [5];
reg  signed [ 7:0] ker_nxt [5];

reg  signed [19:0] tmp     [2][2];
reg  signed [19:0] tmp_nxt [2][2];

// MAXPOOLING
wire        [ 2:0] tmp_deconv_idx;

reg  signed [19:0] out;
reg  signed [19:0] out_nxt;

// DECONVOLUTION
reg  cnt_deconv;
wire cnt_deconv_nxt;

reg  signed [ 7:0] img_deconv       [5][2][8];
reg  signed [ 7:0] img_deconv_nxt   [5][2][8];
reg  signed [ 7:0] ker_deconv       [5][5];
reg  signed [ 7:0] ker_deconv_nxt   [5][5];

reg  signed [19:0] tmp_deconv       [5];
reg  signed [19:0] tmp_deconv_nxt   [5];

// OUTPUT
reg  [ 5:0] cnt_out_max;

wire out_valid_nxt;
wire out_value_nxt;

// MULTIPLIER
wire [1:0] offset_row;

reg  signed [ 7:0] mul_a [5][5];
reg  signed [ 7:0] mul_b [5][5];
reg  signed [19:0] mul_z [5][5];

// COMPARATOR
reg  signed [19:0] cmp_a [3];
reg  signed [19:0] cmp_b [3];
reg  signed [19:0] cmp_z [3];

// SRAM OF IMAGE
reg  [ 3:0] bandwidth;
reg  [10:0] origin;

reg  [ 5:0] row;
reg  [10:0] pos;

reg  [ 5:0] row_deconv;
reg  [10:0] pos_deconv;

reg  [10:0] addr_img_nxt;
reg  [10:0] addr_img;

wire        WEB_img_nxt;
reg         WEB_img;

wire [ 7:0] DI_img_nxt [8];
reg  [ 7:0] DI_img     [8];

wire [ 7:0] DO_img     [8];

// SRAM OF KERNAL
wire [2:0] cnt_in_5_5_nxt;
reg  [2:0] cnt_in_5_5;

reg  [6:0] addr_ker_nxt;
reg  [6:0] addr_ker;

wire       WEB_ker_nxt;
reg        WEB_ker;

wire [7:0] DI_ker_nxt[5];
reg  [7:0] DI_ker[5];

wire [7:0] DO_ker[5];

//=======================================================
//                     FSM
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_nxt;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) begin
                state_nxt = IN_IMG;
            end
            else if(in_valid2) begin
                state_nxt = IN_IDX;
            end
            else begin
                state_nxt = IDLE;
            end
        end 
        IN_IMG: begin
            if ((!matrix_size_reg) && (cnt_in_1024 == 63) && (cnt_in_16 == 15)) begin
                state_nxt = IN_KER;
            end
            else if((matrix_size_reg[0]) && (cnt_in_1024 == 255) && (cnt_in_16 == 15)) begin
                state_nxt = IN_KER;
            end
            else if((matrix_size_reg[1]) && (cnt_in_1024 == 1023) && (cnt_in_16 == 15)) begin
                state_nxt = IN_KER;
            end
            else begin
                state_nxt = IN_IMG;
            end
        end
        IN_IDX: begin
            if(cnt_in_4 == 3) begin
                if(mode_reg == 0) begin
                    state_nxt = CAL_CONV;
                end
                else begin
                    state_nxt = CAL_DECONV;
                end
            end
            else begin
                state_nxt = IN_IDX;
            end
        end
        IN_KER: begin
            if((cnt_in_25 == 24) && (cnt_in_16 == 15)) begin
                state_nxt = IDLE;
            end
            else begin
                state_nxt = IN_KER;
            end
        end
        CAL_CONV: begin
            if(cnt_conv == 5) begin
                state_nxt = CAL_MAXPL;
            end
            else begin
                state_nxt = CAL_CONV;
            end
        end
        CAL_MAXPL: begin
            state_nxt = OUT;
        end
        CAL_DECONV: begin
            if(cnt_deconv == 1) begin
                state_nxt = OUT;
            end
            else begin
                state_nxt = CAL_DECONV;
            end
        end
        OUT: begin
            if((cnt_out_bit == 19) && (cnt_out_col == cnt_out_max) && (cnt_out_row == cnt_out_max)) begin
                state_nxt = IDLE;
            end
            else begin
                state_nxt = OUT;
            end
        end
        default: begin
            state_nxt = state;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_in_1024 <= 0;
        cnt_in_16 <= 0;
        cnt_in_25 <= 0;
        cnt_in_5 <= 0;
        cnt_in_4 <= 0;
    end
    else begin
        cnt_in_1024 <= cnt_in_1024_nxt;
        cnt_in_16 <= cnt_in_16_nxt;
        cnt_in_25 <= cnt_in_25_nxt;
        cnt_in_5 <= cnt_in_5_nxt;
        cnt_in_4 <= cnt_in_4_nxt;
    end
end

assign cnt_in_1024_nxt = ((state == IN_IMG) && !(((!matrix_size_reg) && (cnt_in_1024 == 63)) || ((matrix_size_reg[0]) && (cnt_in_1024 == 255)) || ((matrix_size_reg[1]) && (cnt_in_1024 == 1023)))) ? cnt_in_1024 + 1 : 0;
assign cnt_in_16_nxt = (((!matrix_size_reg) && (cnt_in_1024 == 63)) || ((matrix_size_reg[0]) && (cnt_in_1024 == 255)) || ((matrix_size_reg[1]) && (cnt_in_1024 == 1023)) || (cnt_in_25 == 24)) ? cnt_in_16 + 1 : cnt_in_16;
assign cnt_in_25_nxt = ((state == IN_KER) && !(cnt_in_25 == 24)) ? cnt_in_25 + 1 : 0;
assign cnt_in_5_nxt = ((state == IN_KER) && !(cnt_in_5 == 4)) ? cnt_in_5 + 1 : 0;
assign cnt_in_4_nxt = (state == IN_IDX) ? cnt_in_4 + 1 : 0; // 0: input img_idx, 1: input ker_img + set 1st img addr, 2: set 2nd img addr + set ker addr, 3: get 1st img value

//=======================================================
//                     INPUT
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        matrix_reg <= 0;
        matrix_size_reg <= 0;
    end
    else begin
        matrix_reg <= matrix_nxt;
        matrix_size_reg <= matrix_size_nxt;
    end
end

assign matrix_size_nxt = ((in_valid) && (state == IDLE)) ? matrix_size : matrix_size_reg;
assign matrix_nxt = (((in_valid) && (state == IDLE)) || (state == IN_IMG) || (state == IN_KER)) ? matrix : matrix_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mode_reg <= 0;
        matrix_idx_reg <= 0;
        img_idx <= 0;
        ker_idx <= 0;
    end
    else begin
        mode_reg <= mode_nxt;
        matrix_idx_reg <= matrix_idx_nxt;
        img_idx <= img_idx_nxt;
        ker_idx <= ker_idx_nxt;
    end
end

assign mode_nxt = ((in_valid2) && (state == IDLE)) ? mode : mode_reg;
assign matrix_idx_nxt = (((in_valid2) && (state == IDLE)) || (state == IN_IDX)) ? matrix_idx : matrix_idx_reg;
assign img_idx_nxt = ((state == IN_IDX) && (cnt_in_4 == 0)) ? matrix_idx_reg : img_idx;
assign ker_idx_nxt = ((state == IN_IDX) && (cnt_in_4 == 1)) ? matrix_idx_reg : ker_idx;

//=======================================================
//                    CONVOLUTION
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_conv <= 0;
    end
    else begin
        cnt_conv <= cnt_conv_nxt;
    end
end

assign cnt_conv_nxt = ((state == CAL_CONV) && !(cnt_conv == 5)) ? cnt_conv + 1 : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img[0][0][0] <= 0;    img[0][1][0] <= 0;
        img[0][0][1] <= 0;    img[0][1][1] <= 0;
        img[0][0][2] <= 0;    img[0][1][2] <= 0;
        img[0][0][3] <= 0;    img[0][1][3] <= 0;
        img[0][0][4] <= 0;    img[0][1][4] <= 0;
        img[0][0][5] <= 0;    img[0][1][5] <= 0;
        img[0][0][6] <= 0;    img[0][1][6] <= 0;
        img[0][0][7] <= 0;    img[0][1][7] <= 0;

        img[1][0][0] <= 0;    img[1][1][0] <= 0;
        img[1][0][1] <= 0;    img[1][1][1] <= 0;
        img[1][0][2] <= 0;    img[1][1][2] <= 0;
        img[1][0][3] <= 0;    img[1][1][3] <= 0;
        img[1][0][4] <= 0;    img[1][1][4] <= 0;
        img[1][0][5] <= 0;    img[1][1][5] <= 0;
        img[1][0][6] <= 0;    img[1][1][6] <= 0;
        img[1][0][7] <= 0;    img[1][1][7] <= 0;
    end
    else begin
        img[0][0][0] <= img_nxt[0][0][0];    img[0][1][0] <= img_nxt[0][1][0];
        img[0][0][1] <= img_nxt[0][0][1];    img[0][1][1] <= img_nxt[0][1][1];
        img[0][0][2] <= img_nxt[0][0][2];    img[0][1][2] <= img_nxt[0][1][2];
        img[0][0][3] <= img_nxt[0][0][3];    img[0][1][3] <= img_nxt[0][1][3];
        img[0][0][4] <= img_nxt[0][0][4];    img[0][1][4] <= img_nxt[0][1][4];
        img[0][0][5] <= img_nxt[0][0][5];    img[0][1][5] <= img_nxt[0][1][5];
        img[0][0][6] <= img_nxt[0][0][6];    img[0][1][6] <= img_nxt[0][1][6];
        img[0][0][7] <= img_nxt[0][0][7];    img[0][1][7] <= img_nxt[0][1][7];

        img[1][0][0] <= img_nxt[1][0][0];    img[1][1][0] <= img_nxt[1][1][0];
        img[1][0][1] <= img_nxt[1][0][1];    img[1][1][1] <= img_nxt[1][1][1];
        img[1][0][2] <= img_nxt[1][0][2];    img[1][1][2] <= img_nxt[1][1][2];
        img[1][0][3] <= img_nxt[1][0][3];    img[1][1][3] <= img_nxt[1][1][3];
        img[1][0][4] <= img_nxt[1][0][4];    img[1][1][4] <= img_nxt[1][1][4];
        img[1][0][5] <= img_nxt[1][0][5];    img[1][1][5] <= img_nxt[1][1][5];
        img[1][0][6] <= img_nxt[1][0][6];    img[1][1][6] <= img_nxt[1][1][6];
        img[1][0][7] <= img_nxt[1][0][7];    img[1][1][7] <= img_nxt[1][1][7];
    end
end

always @(*) begin
    if(((state == IN_IDX) && (cnt_in_4 == 3)) || (state == CAL_CONV)) begin
        img_nxt[0][0][0] = img[1][0][0];    img_nxt[0][1][0] = img[0][1][0];
        img_nxt[0][0][1] = img[1][0][1];    img_nxt[0][1][1] = img[0][1][1];
        img_nxt[0][0][2] = img[1][0][2];    img_nxt[0][1][2] = img[0][1][2];
        img_nxt[0][0][3] = img[1][0][3];    img_nxt[0][1][3] = img[0][1][3];
        img_nxt[0][0][4] = img[1][0][4];    img_nxt[0][1][4] = img[0][1][4];
        img_nxt[0][0][5] = img[1][0][5];    img_nxt[0][1][5] = img[0][1][5];
        img_nxt[0][0][6] = img[1][0][6];    img_nxt[0][1][6] = img[0][1][6];
        img_nxt[0][0][7] = img[1][0][7];    img_nxt[0][1][7] = img[0][1][7];

        img_nxt[1][0][0] =    DO_img[0];    img_nxt[1][1][0] = img[1][1][0];
        img_nxt[1][0][1] =    DO_img[1];    img_nxt[1][1][1] = img[1][1][1];
        img_nxt[1][0][2] =    DO_img[2];    img_nxt[1][1][2] = img[1][1][2];
        img_nxt[1][0][3] =    DO_img[3];    img_nxt[1][1][3] = img[1][1][3];
        img_nxt[1][0][4] =    DO_img[4];    img_nxt[1][1][4] = img[1][1][4];
        img_nxt[1][0][5] =    DO_img[5];    img_nxt[1][1][5] = img[1][1][5];
        img_nxt[1][0][6] =    DO_img[6];    img_nxt[1][1][6] = img[1][1][6];
        img_nxt[1][0][7] =    DO_img[7];    img_nxt[1][1][7] = img[1][1][7];
    end
    else if(state == OUT) begin
        if(((cnt_out_bit >= 2) &&(cnt_out_bit < 6) && (!cnt_out_bit[2])) || ((cnt_out_bit >= 6) && (cnt_out_bit < 14) && (!cnt_out_bit[0]))) begin
            img_nxt[0][0][0] = img[1][0][0];    img_nxt[0][1][0] = img[0][1][0];
            img_nxt[0][0][1] = img[1][0][1];    img_nxt[0][1][1] = img[0][1][1];
            img_nxt[0][0][2] = img[1][0][2];    img_nxt[0][1][2] = img[0][1][2];
            img_nxt[0][0][3] = img[1][0][3];    img_nxt[0][1][3] = img[0][1][3];
            img_nxt[0][0][4] = img[1][0][4];    img_nxt[0][1][4] = img[0][1][4];
            img_nxt[0][0][5] = img[1][0][5];    img_nxt[0][1][5] = img[0][1][5];
            img_nxt[0][0][6] = img[1][0][6];    img_nxt[0][1][6] = img[0][1][6];
            img_nxt[0][0][7] = img[1][0][7];    img_nxt[0][1][7] = img[0][1][7];

            img_nxt[1][0][0] =    DO_img[0];    img_nxt[1][1][0] = img[1][1][0];
            img_nxt[1][0][1] =    DO_img[1];    img_nxt[1][1][1] = img[1][1][1];
            img_nxt[1][0][2] =    DO_img[2];    img_nxt[1][1][2] = img[1][1][2];
            img_nxt[1][0][3] =    DO_img[3];    img_nxt[1][1][3] = img[1][1][3];
            img_nxt[1][0][4] =    DO_img[4];    img_nxt[1][1][4] = img[1][1][4];
            img_nxt[1][0][5] =    DO_img[5];    img_nxt[1][1][5] = img[1][1][5];
            img_nxt[1][0][6] =    DO_img[6];    img_nxt[1][1][6] = img[1][1][6];
            img_nxt[1][0][7] =    DO_img[7];    img_nxt[1][1][7] = img[1][1][7];
        end
        else if(((cnt_out_bit >= 2) &&(cnt_out_bit < 6) && (cnt_out_bit[2])) || ((cnt_out_bit >= 6) && (cnt_out_bit < 14) && (cnt_out_bit[0]))) begin
            img_nxt[0][0][0] = img[0][0][0];    img_nxt[0][1][0] = img[1][1][0];
            img_nxt[0][0][1] = img[0][0][1];    img_nxt[0][1][1] = img[1][1][1];
            img_nxt[0][0][2] = img[0][0][2];    img_nxt[0][1][2] = img[1][1][2];
            img_nxt[0][0][3] = img[0][0][3];    img_nxt[0][1][3] = img[1][1][3];
            img_nxt[0][0][4] = img[0][0][4];    img_nxt[0][1][4] = img[1][1][4];
            img_nxt[0][0][5] = img[0][0][5];    img_nxt[0][1][5] = img[1][1][5];
            img_nxt[0][0][6] = img[0][0][6];    img_nxt[0][1][6] = img[1][1][6];
            img_nxt[0][0][7] = img[0][0][7];    img_nxt[0][1][7] = img[1][1][7];

            img_nxt[1][0][0] = img[1][0][0];    img_nxt[1][1][0] =    DO_img[0];
            img_nxt[1][0][1] = img[1][0][1];    img_nxt[1][1][1] =    DO_img[1];
            img_nxt[1][0][2] = img[1][0][2];    img_nxt[1][1][2] =    DO_img[2];
            img_nxt[1][0][3] = img[1][0][3];    img_nxt[1][1][3] =    DO_img[3];
            img_nxt[1][0][4] = img[1][0][4];    img_nxt[1][1][4] =    DO_img[4];
            img_nxt[1][0][5] = img[1][0][5];    img_nxt[1][1][5] =    DO_img[5];
            img_nxt[1][0][6] = img[1][0][6];    img_nxt[1][1][6] =    DO_img[6];
            img_nxt[1][0][7] = img[1][0][7];    img_nxt[1][1][7] =    DO_img[7];
        end
        else begin
            img_nxt[0][0][0] = img[0][0][0];    img_nxt[0][1][0] = img[0][1][0];
            img_nxt[0][0][1] = img[0][0][1];    img_nxt[0][1][1] = img[0][1][1];
            img_nxt[0][0][2] = img[0][0][2];    img_nxt[0][1][2] = img[0][1][2];
            img_nxt[0][0][3] = img[0][0][3];    img_nxt[0][1][3] = img[0][1][3];
            img_nxt[0][0][4] = img[0][0][4];    img_nxt[0][1][4] = img[0][1][4];
            img_nxt[0][0][5] = img[0][0][5];    img_nxt[0][1][5] = img[0][1][5];
            img_nxt[0][0][6] = img[0][0][6];    img_nxt[0][1][6] = img[0][1][6];
            img_nxt[0][0][7] = img[0][0][7];    img_nxt[0][1][7] = img[0][1][7];

            img_nxt[1][0][0] = img[1][0][0];    img_nxt[1][1][0] = img[1][1][0];
            img_nxt[1][0][1] = img[1][0][1];    img_nxt[1][1][1] = img[1][1][1];
            img_nxt[1][0][2] = img[1][0][2];    img_nxt[1][1][2] = img[1][1][2];
            img_nxt[1][0][3] = img[1][0][3];    img_nxt[1][1][3] = img[1][1][3];
            img_nxt[1][0][4] = img[1][0][4];    img_nxt[1][1][4] = img[1][1][4];
            img_nxt[1][0][5] = img[1][0][5];    img_nxt[1][1][5] = img[1][1][5];
            img_nxt[1][0][6] = img[1][0][6];    img_nxt[1][1][6] = img[1][1][6];
            img_nxt[1][0][7] = img[1][0][7];    img_nxt[1][1][7] = img[1][1][7];
        end
    end
    else begin
        img_nxt[0][0][0] = img[0][0][0];    img_nxt[0][1][0] = img[0][1][0];
        img_nxt[0][0][1] = img[0][0][1];    img_nxt[0][1][1] = img[0][1][1];
        img_nxt[0][0][2] = img[0][0][2];    img_nxt[0][1][2] = img[0][1][2];
        img_nxt[0][0][3] = img[0][0][3];    img_nxt[0][1][3] = img[0][1][3];
        img_nxt[0][0][4] = img[0][0][4];    img_nxt[0][1][4] = img[0][1][4];
        img_nxt[0][0][5] = img[0][0][5];    img_nxt[0][1][5] = img[0][1][5];
        img_nxt[0][0][6] = img[0][0][6];    img_nxt[0][1][6] = img[0][1][6];
        img_nxt[0][0][7] = img[0][0][7];    img_nxt[0][1][7] = img[0][1][7];

        img_nxt[1][0][0] = img[1][0][0];    img_nxt[1][1][0] = img[1][1][0];
        img_nxt[1][0][1] = img[1][0][1];    img_nxt[1][1][1] = img[1][1][1];
        img_nxt[1][0][2] = img[1][0][2];    img_nxt[1][1][2] = img[1][1][2];
        img_nxt[1][0][3] = img[1][0][3];    img_nxt[1][1][3] = img[1][1][3];
        img_nxt[1][0][4] = img[1][0][4];    img_nxt[1][1][4] = img[1][1][4];
        img_nxt[1][0][5] = img[1][0][5];    img_nxt[1][1][5] = img[1][1][5];
        img_nxt[1][0][6] = img[1][0][6];    img_nxt[1][1][6] = img[1][1][6];
        img_nxt[1][0][7] = img[1][0][7];    img_nxt[1][1][7] = img[1][1][7];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ker[0] <= 0;
        ker[1] <= 0;
        ker[2] <= 0;
        ker[3] <= 0;
        ker[4] <= 0;
    end
    else begin
        ker[0] <= ker_nxt[0];
        ker[1] <= ker_nxt[1];
        ker[2] <= ker_nxt[2];
        ker[3] <= ker_nxt[3];
        ker[4] <= ker_nxt[4];
    end
end

always @(*) begin
    if((state == CAL_CONV) || (state == CAL_DECONV) || (state == OUT)) begin
        ker_nxt[0] = DO_ker[0];
        ker_nxt[1] = DO_ker[1];
        ker_nxt[2] = DO_ker[2];
        ker_nxt[3] = DO_ker[3];
        ker_nxt[4] = DO_ker[4];
    end
    else begin
        ker_nxt[0] = ker[0];
        ker_nxt[1] = ker[1];
        ker_nxt[2] = ker[2];
        ker_nxt[3] = ker[3];
        ker_nxt[4] = ker[4];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tmp[0][0] <= 0;
        tmp[0][1] <= 0;
        tmp[1][0] <= 0;
        tmp[1][1] <= 0;
    end
    else begin
        tmp[0][0] <= tmp_nxt[0][0];
        tmp[0][1] <= tmp_nxt[0][1];
        tmp[1][0] <= tmp_nxt[1][0];
        tmp[1][1] <= tmp_nxt[1][1];
    end
end

always @(*) begin
    if(state == CAL_CONV) begin
        if(!cnt_conv) begin
            tmp_nxt[0][0] = 0;
            tmp_nxt[0][1] = 0;
            tmp_nxt[1][0] = 0;
            tmp_nxt[1][1] = 0;
        end
        else if(cnt_conv < 6) begin
            tmp_nxt[0][0] = (mul_z[0][0] + mul_z[0][1]) + (mul_z[0][2] + mul_z[0][3]) + (mul_z[0][4] + tmp[0][0]);
            tmp_nxt[0][1] = (mul_z[1][0] + mul_z[1][1]) + (mul_z[1][2] + mul_z[1][3]) + (mul_z[1][4] + tmp[0][1]);
            tmp_nxt[1][0] = (mul_z[2][0] + mul_z[2][1]) + (mul_z[2][2] + mul_z[2][3]) + (mul_z[2][4] + tmp[1][0]);
            tmp_nxt[1][1] = (mul_z[3][0] + mul_z[3][1]) + (mul_z[3][2] + mul_z[3][3]) + (mul_z[3][4] + tmp[1][1]);
        end
        else begin
            tmp_nxt[0][0] = tmp[0][0];
            tmp_nxt[0][1] = tmp[0][1];
            tmp_nxt[1][0] = tmp[1][0];
            tmp_nxt[1][1] = tmp[1][1];
        end
    end
    else if(state == OUT) begin
        if(!cnt_out_bit) begin
            tmp_nxt[0][0] = 0;
            tmp_nxt[0][1] = 0;
            tmp_nxt[1][0] = 0;
            tmp_nxt[1][1] = 0;
        end
        else if((cnt_out_bit >= 6) && (cnt_out_bit < 15) && !(cnt_out_bit[0])) begin
            tmp_nxt[0][0] = (mul_z[0][0] + mul_z[0][1]) + (mul_z[0][2] + mul_z[0][3]) + (mul_z[0][4] + tmp[0][0]);
            tmp_nxt[0][1] = (mul_z[1][0] + mul_z[1][1]) + (mul_z[1][2] + mul_z[1][3]) + (mul_z[1][4] + tmp[0][1]);
            tmp_nxt[1][0] = (mul_z[2][0] + mul_z[2][1]) + (mul_z[2][2] + mul_z[2][3]) + (mul_z[2][4] + tmp[1][0]);
            tmp_nxt[1][1] = (mul_z[3][0] + mul_z[3][1]) + (mul_z[3][2] + mul_z[3][3]) + (mul_z[3][4] + tmp[1][1]);
        end
        else begin
            tmp_nxt[0][0] = tmp[0][0];
            tmp_nxt[0][1] = tmp[0][1];
            tmp_nxt[1][0] = tmp[1][0];
            tmp_nxt[1][1] = tmp[1][1];
        end
    end
    else begin
        tmp_nxt[0][0] = tmp[0][0];
        tmp_nxt[0][1] = tmp[0][1];
        tmp_nxt[1][0] = tmp[1][0];
        tmp_nxt[1][1] = tmp[1][1];
    end
end

//=======================================================
//                    DECONVOLUTION
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_deconv <= 0;
    end
    else begin
        cnt_deconv <= cnt_deconv_nxt;
    end
end

assign cnt_deconv_nxt = (state == CAL_DECONV) ? cnt_deconv + 1 : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_deconv[0][0][0] <= 0;   img_deconv[0][1][0] <= 0;
        img_deconv[0][0][1] <= 0;   img_deconv[0][1][1] <= 0;
        img_deconv[0][0][2] <= 0;   img_deconv[0][1][2] <= 0;
        img_deconv[0][0][3] <= 0;   img_deconv[0][1][3] <= 0;
        img_deconv[0][0][4] <= 0;   img_deconv[0][1][4] <= 0;
        img_deconv[0][0][5] <= 0;   img_deconv[0][1][5] <= 0;
        img_deconv[0][0][6] <= 0;   img_deconv[0][1][6] <= 0;
        img_deconv[0][0][7] <= 0;   img_deconv[0][1][7] <= 0;

        img_deconv[1][0][0] <= 0;   img_deconv[1][1][0] <= 0;
        img_deconv[1][0][1] <= 0;   img_deconv[1][1][1] <= 0;
        img_deconv[1][0][2] <= 0;   img_deconv[1][1][2] <= 0;
        img_deconv[1][0][3] <= 0;   img_deconv[1][1][3] <= 0;
        img_deconv[1][0][4] <= 0;   img_deconv[1][1][4] <= 0;
        img_deconv[1][0][5] <= 0;   img_deconv[1][1][5] <= 0;
        img_deconv[1][0][6] <= 0;   img_deconv[1][1][6] <= 0;
        img_deconv[1][0][7] <= 0;   img_deconv[1][1][7] <= 0;

        img_deconv[2][0][0] <= 0;   img_deconv[2][1][0] <= 0;
        img_deconv[2][0][1] <= 0;   img_deconv[2][1][1] <= 0;
        img_deconv[2][0][2] <= 0;   img_deconv[2][1][2] <= 0;
        img_deconv[2][0][3] <= 0;   img_deconv[2][1][3] <= 0;
        img_deconv[2][0][4] <= 0;   img_deconv[2][1][4] <= 0;
        img_deconv[2][0][5] <= 0;   img_deconv[2][1][5] <= 0;
        img_deconv[2][0][6] <= 0;   img_deconv[2][1][6] <= 0;
        img_deconv[2][0][7] <= 0;   img_deconv[2][1][7] <= 0;

        img_deconv[3][0][0] <= 0;   img_deconv[3][1][0] <= 0;
        img_deconv[3][0][1] <= 0;   img_deconv[3][1][1] <= 0;
        img_deconv[3][0][2] <= 0;   img_deconv[3][1][2] <= 0;
        img_deconv[3][0][3] <= 0;   img_deconv[3][1][3] <= 0;
        img_deconv[3][0][4] <= 0;   img_deconv[3][1][4] <= 0;
        img_deconv[3][0][5] <= 0;   img_deconv[3][1][5] <= 0;
        img_deconv[3][0][6] <= 0;   img_deconv[3][1][6] <= 0;
        img_deconv[3][0][7] <= 0;   img_deconv[3][1][7] <= 0;

        img_deconv[4][0][0] <= 0;   img_deconv[4][1][0] <= 0;
        img_deconv[4][0][1] <= 0;   img_deconv[4][1][1] <= 0;
        img_deconv[4][0][2] <= 0;   img_deconv[4][1][2] <= 0;
        img_deconv[4][0][3] <= 0;   img_deconv[4][1][3] <= 0;
        img_deconv[4][0][4] <= 0;   img_deconv[4][1][4] <= 0;
        img_deconv[4][0][5] <= 0;   img_deconv[4][1][5] <= 0;
        img_deconv[4][0][6] <= 0;   img_deconv[4][1][6] <= 0;
        img_deconv[4][0][7] <= 0;   img_deconv[4][1][7] <= 0;
    end
    else begin
        img_deconv[0][0][0] <= img_deconv_nxt[0][0][0];   img_deconv[0][1][0] <= img_deconv_nxt[0][1][0];
        img_deconv[0][0][1] <= img_deconv_nxt[0][0][1];   img_deconv[0][1][1] <= img_deconv_nxt[0][1][1];
        img_deconv[0][0][2] <= img_deconv_nxt[0][0][2];   img_deconv[0][1][2] <= img_deconv_nxt[0][1][2];
        img_deconv[0][0][3] <= img_deconv_nxt[0][0][3];   img_deconv[0][1][3] <= img_deconv_nxt[0][1][3];
        img_deconv[0][0][4] <= img_deconv_nxt[0][0][4];   img_deconv[0][1][4] <= img_deconv_nxt[0][1][4];
        img_deconv[0][0][5] <= img_deconv_nxt[0][0][5];   img_deconv[0][1][5] <= img_deconv_nxt[0][1][5];
        img_deconv[0][0][6] <= img_deconv_nxt[0][0][6];   img_deconv[0][1][6] <= img_deconv_nxt[0][1][6];
        img_deconv[0][0][7] <= img_deconv_nxt[0][0][7];   img_deconv[0][1][7] <= img_deconv_nxt[0][1][7];

        img_deconv[1][0][0] <= img_deconv_nxt[1][0][0];   img_deconv[1][1][0] <= img_deconv_nxt[1][1][0];
        img_deconv[1][0][1] <= img_deconv_nxt[1][0][1];   img_deconv[1][1][1] <= img_deconv_nxt[1][1][1];
        img_deconv[1][0][2] <= img_deconv_nxt[1][0][2];   img_deconv[1][1][2] <= img_deconv_nxt[1][1][2];
        img_deconv[1][0][3] <= img_deconv_nxt[1][0][3];   img_deconv[1][1][3] <= img_deconv_nxt[1][1][3];
        img_deconv[1][0][4] <= img_deconv_nxt[1][0][4];   img_deconv[1][1][4] <= img_deconv_nxt[1][1][4];
        img_deconv[1][0][5] <= img_deconv_nxt[1][0][5];   img_deconv[1][1][5] <= img_deconv_nxt[1][1][5];
        img_deconv[1][0][6] <= img_deconv_nxt[1][0][6];   img_deconv[1][1][6] <= img_deconv_nxt[1][1][6];
        img_deconv[1][0][7] <= img_deconv_nxt[1][0][7];   img_deconv[1][1][7] <= img_deconv_nxt[1][1][7];

        img_deconv[2][0][0] <= img_deconv_nxt[2][0][0];   img_deconv[2][1][0] <= img_deconv_nxt[2][1][0];
        img_deconv[2][0][1] <= img_deconv_nxt[2][0][1];   img_deconv[2][1][1] <= img_deconv_nxt[2][1][1];
        img_deconv[2][0][2] <= img_deconv_nxt[2][0][2];   img_deconv[2][1][2] <= img_deconv_nxt[2][1][2];
        img_deconv[2][0][3] <= img_deconv_nxt[2][0][3];   img_deconv[2][1][3] <= img_deconv_nxt[2][1][3];
        img_deconv[2][0][4] <= img_deconv_nxt[2][0][4];   img_deconv[2][1][4] <= img_deconv_nxt[2][1][4];
        img_deconv[2][0][5] <= img_deconv_nxt[2][0][5];   img_deconv[2][1][5] <= img_deconv_nxt[2][1][5];
        img_deconv[2][0][6] <= img_deconv_nxt[2][0][6];   img_deconv[2][1][6] <= img_deconv_nxt[2][1][6];
        img_deconv[2][0][7] <= img_deconv_nxt[2][0][7];   img_deconv[2][1][7] <= img_deconv_nxt[2][1][7];

        img_deconv[3][0][0] <= img_deconv_nxt[3][0][0];   img_deconv[3][1][0] <= img_deconv_nxt[3][1][0];
        img_deconv[3][0][1] <= img_deconv_nxt[3][0][1];   img_deconv[3][1][1] <= img_deconv_nxt[3][1][1];
        img_deconv[3][0][2] <= img_deconv_nxt[3][0][2];   img_deconv[3][1][2] <= img_deconv_nxt[3][1][2];
        img_deconv[3][0][3] <= img_deconv_nxt[3][0][3];   img_deconv[3][1][3] <= img_deconv_nxt[3][1][3];
        img_deconv[3][0][4] <= img_deconv_nxt[3][0][4];   img_deconv[3][1][4] <= img_deconv_nxt[3][1][4];
        img_deconv[3][0][5] <= img_deconv_nxt[3][0][5];   img_deconv[3][1][5] <= img_deconv_nxt[3][1][5];
        img_deconv[3][0][6] <= img_deconv_nxt[3][0][6];   img_deconv[3][1][6] <= img_deconv_nxt[3][1][6];
        img_deconv[3][0][7] <= img_deconv_nxt[3][0][7];   img_deconv[3][1][7] <= img_deconv_nxt[3][1][7];

        img_deconv[4][0][0] <= img_deconv_nxt[4][0][0];   img_deconv[4][1][0] <= img_deconv_nxt[4][1][0];
        img_deconv[4][0][1] <= img_deconv_nxt[4][0][1];   img_deconv[4][1][1] <= img_deconv_nxt[4][1][1];
        img_deconv[4][0][2] <= img_deconv_nxt[4][0][2];   img_deconv[4][1][2] <= img_deconv_nxt[4][1][2];
        img_deconv[4][0][3] <= img_deconv_nxt[4][0][3];   img_deconv[4][1][3] <= img_deconv_nxt[4][1][3];
        img_deconv[4][0][4] <= img_deconv_nxt[4][0][4];   img_deconv[4][1][4] <= img_deconv_nxt[4][1][4];
        img_deconv[4][0][5] <= img_deconv_nxt[4][0][5];   img_deconv[4][1][5] <= img_deconv_nxt[4][1][5];
        img_deconv[4][0][6] <= img_deconv_nxt[4][0][6];   img_deconv[4][1][6] <= img_deconv_nxt[4][1][6];
        img_deconv[4][0][7] <= img_deconv_nxt[4][0][7];   img_deconv[4][1][7] <= img_deconv_nxt[4][1][7];
    end
end

always @(*) begin
    if((state == IN_IDX) && (cnt_in_4 == 3)) begin
        img_deconv_nxt[0][0][0] = DO_img[0];    img_deconv_nxt[0][1][0] = 0;
        img_deconv_nxt[0][0][1] = DO_img[1];    img_deconv_nxt[0][1][1] = 0;
        img_deconv_nxt[0][0][2] = DO_img[2];    img_deconv_nxt[0][1][2] = 0;
        img_deconv_nxt[0][0][3] = DO_img[3];    img_deconv_nxt[0][1][3] = 0;
        img_deconv_nxt[0][0][4] = DO_img[4];    img_deconv_nxt[0][1][4] = 0;
        img_deconv_nxt[0][0][5] = DO_img[5];    img_deconv_nxt[0][1][5] = 0;
        img_deconv_nxt[0][0][6] = DO_img[6];    img_deconv_nxt[0][1][6] = 0;
        img_deconv_nxt[0][0][7] = DO_img[7];    img_deconv_nxt[0][1][7] = 0;

        img_deconv_nxt[1][0][0] =         0;    img_deconv_nxt[1][1][0] = 0;
        img_deconv_nxt[1][0][1] =         0;    img_deconv_nxt[1][1][1] = 0;
        img_deconv_nxt[1][0][2] =         0;    img_deconv_nxt[1][1][2] = 0;
        img_deconv_nxt[1][0][3] =         0;    img_deconv_nxt[1][1][3] = 0;
        img_deconv_nxt[1][0][4] =         0;    img_deconv_nxt[1][1][4] = 0;
        img_deconv_nxt[1][0][5] =         0;    img_deconv_nxt[1][1][5] = 0;
        img_deconv_nxt[1][0][6] =         0;    img_deconv_nxt[1][1][6] = 0;
        img_deconv_nxt[1][0][7] =         0;    img_deconv_nxt[1][1][7] = 0;

        img_deconv_nxt[2][0][0] =         0;    img_deconv_nxt[2][1][0] = 0;
        img_deconv_nxt[2][0][1] =         0;    img_deconv_nxt[2][1][1] = 0;
        img_deconv_nxt[2][0][2] =         0;    img_deconv_nxt[2][1][2] = 0;
        img_deconv_nxt[2][0][3] =         0;    img_deconv_nxt[2][1][3] = 0;
        img_deconv_nxt[2][0][4] =         0;    img_deconv_nxt[2][1][4] = 0;
        img_deconv_nxt[2][0][5] =         0;    img_deconv_nxt[2][1][5] = 0;
        img_deconv_nxt[2][0][6] =         0;    img_deconv_nxt[2][1][6] = 0;
        img_deconv_nxt[2][0][7] =         0;    img_deconv_nxt[2][1][7] = 0;

        img_deconv_nxt[3][0][0] =         0;    img_deconv_nxt[3][1][0] = 0;
        img_deconv_nxt[3][0][1] =         0;    img_deconv_nxt[3][1][1] = 0;
        img_deconv_nxt[3][0][2] =         0;    img_deconv_nxt[3][1][2] = 0;
        img_deconv_nxt[3][0][3] =         0;    img_deconv_nxt[3][1][3] = 0;
        img_deconv_nxt[3][0][4] =         0;    img_deconv_nxt[3][1][4] = 0;
        img_deconv_nxt[3][0][5] =         0;    img_deconv_nxt[3][1][5] = 0;
        img_deconv_nxt[3][0][6] =         0;    img_deconv_nxt[3][1][6] = 0;
        img_deconv_nxt[3][0][7] =         0;    img_deconv_nxt[3][1][7] = 0;

        img_deconv_nxt[4][0][0] =         0;    img_deconv_nxt[4][1][0] = 0;
        img_deconv_nxt[4][0][1] =         0;    img_deconv_nxt[4][1][1] = 0;
        img_deconv_nxt[4][0][2] =         0;    img_deconv_nxt[4][1][2] = 0;
        img_deconv_nxt[4][0][3] =         0;    img_deconv_nxt[4][1][3] = 0;
        img_deconv_nxt[4][0][4] =         0;    img_deconv_nxt[4][1][4] = 0;
        img_deconv_nxt[4][0][5] =         0;    img_deconv_nxt[4][1][5] = 0;
        img_deconv_nxt[4][0][6] =         0;    img_deconv_nxt[4][1][6] = 0;
        img_deconv_nxt[4][0][7] =         0;    img_deconv_nxt[4][1][7] = 0;
    end
    else if(state == OUT) begin
        if(cnt_out_bit >= 2 && cnt_out_bit < 7) begin
            img_deconv_nxt[0][0][0] = img_deconv[1][0][0];    img_deconv_nxt[0][1][0] = img_deconv[0][1][0];
            img_deconv_nxt[0][0][1] = img_deconv[1][0][1];    img_deconv_nxt[0][1][1] = img_deconv[0][1][1];
            img_deconv_nxt[0][0][2] = img_deconv[1][0][2];    img_deconv_nxt[0][1][2] = img_deconv[0][1][2];
            img_deconv_nxt[0][0][3] = img_deconv[1][0][3];    img_deconv_nxt[0][1][3] = img_deconv[0][1][3];
            img_deconv_nxt[0][0][4] = img_deconv[1][0][4];    img_deconv_nxt[0][1][4] = img_deconv[0][1][4];
            img_deconv_nxt[0][0][5] = img_deconv[1][0][5];    img_deconv_nxt[0][1][5] = img_deconv[0][1][5];
            img_deconv_nxt[0][0][6] = img_deconv[1][0][6];    img_deconv_nxt[0][1][6] = img_deconv[0][1][6];
            img_deconv_nxt[0][0][7] = img_deconv[1][0][7];    img_deconv_nxt[0][1][7] = img_deconv[0][1][7];

            img_deconv_nxt[1][0][0] = img_deconv[2][0][0];    img_deconv_nxt[1][1][0] = img_deconv[1][1][0];
            img_deconv_nxt[1][0][1] = img_deconv[2][0][1];    img_deconv_nxt[1][1][1] = img_deconv[1][1][1];
            img_deconv_nxt[1][0][2] = img_deconv[2][0][2];    img_deconv_nxt[1][1][2] = img_deconv[1][1][2];
            img_deconv_nxt[1][0][3] = img_deconv[2][0][3];    img_deconv_nxt[1][1][3] = img_deconv[1][1][3];
            img_deconv_nxt[1][0][4] = img_deconv[2][0][4];    img_deconv_nxt[1][1][4] = img_deconv[1][1][4];
            img_deconv_nxt[1][0][5] = img_deconv[2][0][5];    img_deconv_nxt[1][1][5] = img_deconv[1][1][5];
            img_deconv_nxt[1][0][6] = img_deconv[2][0][6];    img_deconv_nxt[1][1][6] = img_deconv[1][1][6];
            img_deconv_nxt[1][0][7] = img_deconv[2][0][7];    img_deconv_nxt[1][1][7] = img_deconv[1][1][7];

            img_deconv_nxt[2][0][0] = img_deconv[3][0][0];    img_deconv_nxt[2][1][0] = img_deconv[2][1][0];
            img_deconv_nxt[2][0][1] = img_deconv[3][0][1];    img_deconv_nxt[2][1][1] = img_deconv[2][1][1];
            img_deconv_nxt[2][0][2] = img_deconv[3][0][2];    img_deconv_nxt[2][1][2] = img_deconv[2][1][2];
            img_deconv_nxt[2][0][3] = img_deconv[3][0][3];    img_deconv_nxt[2][1][3] = img_deconv[2][1][3];
            img_deconv_nxt[2][0][4] = img_deconv[3][0][4];    img_deconv_nxt[2][1][4] = img_deconv[2][1][4];
            img_deconv_nxt[2][0][5] = img_deconv[3][0][5];    img_deconv_nxt[2][1][5] = img_deconv[2][1][5];
            img_deconv_nxt[2][0][6] = img_deconv[3][0][6];    img_deconv_nxt[2][1][6] = img_deconv[2][1][6];
            img_deconv_nxt[2][0][7] = img_deconv[3][0][7];    img_deconv_nxt[2][1][7] = img_deconv[2][1][7];

            img_deconv_nxt[3][0][0] = img_deconv[4][0][0];    img_deconv_nxt[3][1][0] = img_deconv[3][1][0];
            img_deconv_nxt[3][0][1] = img_deconv[4][0][1];    img_deconv_nxt[3][1][1] = img_deconv[3][1][1];
            img_deconv_nxt[3][0][2] = img_deconv[4][0][2];    img_deconv_nxt[3][1][2] = img_deconv[3][1][2];
            img_deconv_nxt[3][0][3] = img_deconv[4][0][3];    img_deconv_nxt[3][1][3] = img_deconv[3][1][3];
            img_deconv_nxt[3][0][4] = img_deconv[4][0][4];    img_deconv_nxt[3][1][4] = img_deconv[3][1][4];
            img_deconv_nxt[3][0][5] = img_deconv[4][0][5];    img_deconv_nxt[3][1][5] = img_deconv[3][1][5];
            img_deconv_nxt[3][0][6] = img_deconv[4][0][6];    img_deconv_nxt[3][1][6] = img_deconv[3][1][6];
            img_deconv_nxt[3][0][7] = img_deconv[4][0][7];    img_deconv_nxt[3][1][7] = img_deconv[3][1][7];

            img_deconv_nxt[4][0][0] =           DO_img[0];    img_deconv_nxt[4][1][0] = img_deconv[4][1][0];
            img_deconv_nxt[4][0][1] =           DO_img[1];    img_deconv_nxt[4][1][1] = img_deconv[4][1][1];
            img_deconv_nxt[4][0][2] =           DO_img[2];    img_deconv_nxt[4][1][2] = img_deconv[4][1][2];
            img_deconv_nxt[4][0][3] =           DO_img[3];    img_deconv_nxt[4][1][3] = img_deconv[4][1][3];
            img_deconv_nxt[4][0][4] =           DO_img[4];    img_deconv_nxt[4][1][4] = img_deconv[4][1][4];
            img_deconv_nxt[4][0][5] =           DO_img[5];    img_deconv_nxt[4][1][5] = img_deconv[4][1][5];
            img_deconv_nxt[4][0][6] =           DO_img[6];    img_deconv_nxt[4][1][6] = img_deconv[4][1][6];
            img_deconv_nxt[4][0][7] =           DO_img[7];    img_deconv_nxt[4][1][7] = img_deconv[4][1][7];
        end
        else if(cnt_out_bit >= 7 && cnt_out_bit < 12) begin
            img_deconv_nxt[0][0][0] = img_deconv[0][0][0];    img_deconv_nxt[0][1][0] = img_deconv[1][1][0];
            img_deconv_nxt[0][0][1] = img_deconv[0][0][1];    img_deconv_nxt[0][1][1] = img_deconv[1][1][1];
            img_deconv_nxt[0][0][2] = img_deconv[0][0][2];    img_deconv_nxt[0][1][2] = img_deconv[1][1][2];
            img_deconv_nxt[0][0][3] = img_deconv[0][0][3];    img_deconv_nxt[0][1][3] = img_deconv[1][1][3];
            img_deconv_nxt[0][0][4] = img_deconv[0][0][4];    img_deconv_nxt[0][1][4] = img_deconv[1][1][4];
            img_deconv_nxt[0][0][5] = img_deconv[0][0][5];    img_deconv_nxt[0][1][5] = img_deconv[1][1][5];
            img_deconv_nxt[0][0][6] = img_deconv[0][0][6];    img_deconv_nxt[0][1][6] = img_deconv[1][1][6];
            img_deconv_nxt[0][0][7] = img_deconv[0][0][7];    img_deconv_nxt[0][1][7] = img_deconv[1][1][7];

            img_deconv_nxt[1][0][0] = img_deconv[1][0][0];    img_deconv_nxt[1][1][0] = img_deconv[2][1][0];
            img_deconv_nxt[1][0][1] = img_deconv[1][0][1];    img_deconv_nxt[1][1][1] = img_deconv[2][1][1];
            img_deconv_nxt[1][0][2] = img_deconv[1][0][2];    img_deconv_nxt[1][1][2] = img_deconv[2][1][2];
            img_deconv_nxt[1][0][3] = img_deconv[1][0][3];    img_deconv_nxt[1][1][3] = img_deconv[2][1][3];
            img_deconv_nxt[1][0][4] = img_deconv[1][0][4];    img_deconv_nxt[1][1][4] = img_deconv[2][1][4];
            img_deconv_nxt[1][0][5] = img_deconv[1][0][5];    img_deconv_nxt[1][1][5] = img_deconv[2][1][5];
            img_deconv_nxt[1][0][6] = img_deconv[1][0][6];    img_deconv_nxt[1][1][6] = img_deconv[2][1][6];
            img_deconv_nxt[1][0][7] = img_deconv[1][0][7];    img_deconv_nxt[1][1][7] = img_deconv[2][1][7];

            img_deconv_nxt[2][0][0] = img_deconv[2][0][0];    img_deconv_nxt[2][1][0] = img_deconv[3][1][0];
            img_deconv_nxt[2][0][1] = img_deconv[2][0][1];    img_deconv_nxt[2][1][1] = img_deconv[3][1][1];
            img_deconv_nxt[2][0][2] = img_deconv[2][0][2];    img_deconv_nxt[2][1][2] = img_deconv[3][1][2];
            img_deconv_nxt[2][0][3] = img_deconv[2][0][3];    img_deconv_nxt[2][1][3] = img_deconv[3][1][3];
            img_deconv_nxt[2][0][4] = img_deconv[2][0][4];    img_deconv_nxt[2][1][4] = img_deconv[3][1][4];
            img_deconv_nxt[2][0][5] = img_deconv[2][0][5];    img_deconv_nxt[2][1][5] = img_deconv[3][1][5];
            img_deconv_nxt[2][0][6] = img_deconv[2][0][6];    img_deconv_nxt[2][1][6] = img_deconv[3][1][6];
            img_deconv_nxt[2][0][7] = img_deconv[2][0][7];    img_deconv_nxt[2][1][7] = img_deconv[3][1][7];

            img_deconv_nxt[3][0][0] = img_deconv[3][0][0];    img_deconv_nxt[3][1][0] = img_deconv[4][1][0];
            img_deconv_nxt[3][0][1] = img_deconv[3][0][1];    img_deconv_nxt[3][1][1] = img_deconv[4][1][1];
            img_deconv_nxt[3][0][2] = img_deconv[3][0][2];    img_deconv_nxt[3][1][2] = img_deconv[4][1][2];
            img_deconv_nxt[3][0][3] = img_deconv[3][0][3];    img_deconv_nxt[3][1][3] = img_deconv[4][1][3];
            img_deconv_nxt[3][0][4] = img_deconv[3][0][4];    img_deconv_nxt[3][1][4] = img_deconv[4][1][4];
            img_deconv_nxt[3][0][5] = img_deconv[3][0][5];    img_deconv_nxt[3][1][5] = img_deconv[4][1][5];
            img_deconv_nxt[3][0][6] = img_deconv[3][0][6];    img_deconv_nxt[3][1][6] = img_deconv[4][1][6];
            img_deconv_nxt[3][0][7] = img_deconv[3][0][7];    img_deconv_nxt[3][1][7] = img_deconv[4][1][7];

            img_deconv_nxt[4][0][0] = img_deconv[4][0][0];    img_deconv_nxt[4][1][0] =           DO_img[0];
            img_deconv_nxt[4][0][1] = img_deconv[4][0][1];    img_deconv_nxt[4][1][1] =           DO_img[1];
            img_deconv_nxt[4][0][2] = img_deconv[4][0][2];    img_deconv_nxt[4][1][2] =           DO_img[2];
            img_deconv_nxt[4][0][3] = img_deconv[4][0][3];    img_deconv_nxt[4][1][3] =           DO_img[3];
            img_deconv_nxt[4][0][4] = img_deconv[4][0][4];    img_deconv_nxt[4][1][4] =           DO_img[4];
            img_deconv_nxt[4][0][5] = img_deconv[4][0][5];    img_deconv_nxt[4][1][5] =           DO_img[5];
            img_deconv_nxt[4][0][6] = img_deconv[4][0][6];    img_deconv_nxt[4][1][6] =           DO_img[6];
            img_deconv_nxt[4][0][7] = img_deconv[4][0][7];    img_deconv_nxt[4][1][7] =           DO_img[7];
        end
        else begin
            img_deconv_nxt[0][0][0] = img_deconv[0][0][0];    img_deconv_nxt[0][1][0] = img_deconv[0][1][0];
            img_deconv_nxt[0][0][1] = img_deconv[0][0][1];    img_deconv_nxt[0][1][1] = img_deconv[0][1][1];
            img_deconv_nxt[0][0][2] = img_deconv[0][0][2];    img_deconv_nxt[0][1][2] = img_deconv[0][1][2];
            img_deconv_nxt[0][0][3] = img_deconv[0][0][3];    img_deconv_nxt[0][1][3] = img_deconv[0][1][3];
            img_deconv_nxt[0][0][4] = img_deconv[0][0][4];    img_deconv_nxt[0][1][4] = img_deconv[0][1][4];
            img_deconv_nxt[0][0][5] = img_deconv[0][0][5];    img_deconv_nxt[0][1][5] = img_deconv[0][1][5];
            img_deconv_nxt[0][0][6] = img_deconv[0][0][6];    img_deconv_nxt[0][1][6] = img_deconv[0][1][6];
            img_deconv_nxt[0][0][7] = img_deconv[0][0][7];    img_deconv_nxt[0][1][7] = img_deconv[0][1][7];

            img_deconv_nxt[1][0][0] = img_deconv[1][0][0];    img_deconv_nxt[1][1][0] = img_deconv[1][1][0];
            img_deconv_nxt[1][0][1] = img_deconv[1][0][1];    img_deconv_nxt[1][1][1] = img_deconv[1][1][1];
            img_deconv_nxt[1][0][2] = img_deconv[1][0][2];    img_deconv_nxt[1][1][2] = img_deconv[1][1][2];
            img_deconv_nxt[1][0][3] = img_deconv[1][0][3];    img_deconv_nxt[1][1][3] = img_deconv[1][1][3];
            img_deconv_nxt[1][0][4] = img_deconv[1][0][4];    img_deconv_nxt[1][1][4] = img_deconv[1][1][4];
            img_deconv_nxt[1][0][5] = img_deconv[1][0][5];    img_deconv_nxt[1][1][5] = img_deconv[1][1][5];
            img_deconv_nxt[1][0][6] = img_deconv[1][0][6];    img_deconv_nxt[1][1][6] = img_deconv[1][1][6];
            img_deconv_nxt[1][0][7] = img_deconv[1][0][7];    img_deconv_nxt[1][1][7] = img_deconv[1][1][7];

            img_deconv_nxt[2][0][0] = img_deconv[2][0][0];    img_deconv_nxt[2][1][0] = img_deconv[2][1][0];
            img_deconv_nxt[2][0][1] = img_deconv[2][0][1];    img_deconv_nxt[2][1][1] = img_deconv[2][1][1];
            img_deconv_nxt[2][0][2] = img_deconv[2][0][2];    img_deconv_nxt[2][1][2] = img_deconv[2][1][2];
            img_deconv_nxt[2][0][3] = img_deconv[2][0][3];    img_deconv_nxt[2][1][3] = img_deconv[2][1][3];
            img_deconv_nxt[2][0][4] = img_deconv[2][0][4];    img_deconv_nxt[2][1][4] = img_deconv[2][1][4];
            img_deconv_nxt[2][0][5] = img_deconv[2][0][5];    img_deconv_nxt[2][1][5] = img_deconv[2][1][5];
            img_deconv_nxt[2][0][6] = img_deconv[2][0][6];    img_deconv_nxt[2][1][6] = img_deconv[2][1][6];
            img_deconv_nxt[2][0][7] = img_deconv[2][0][7];    img_deconv_nxt[2][1][7] = img_deconv[2][1][7];

            img_deconv_nxt[3][0][0] = img_deconv[3][0][0];    img_deconv_nxt[3][1][0] = img_deconv[3][1][0];
            img_deconv_nxt[3][0][1] = img_deconv[3][0][1];    img_deconv_nxt[3][1][1] = img_deconv[3][1][1];
            img_deconv_nxt[3][0][2] = img_deconv[3][0][2];    img_deconv_nxt[3][1][2] = img_deconv[3][1][2];
            img_deconv_nxt[3][0][3] = img_deconv[3][0][3];    img_deconv_nxt[3][1][3] = img_deconv[3][1][3];
            img_deconv_nxt[3][0][4] = img_deconv[3][0][4];    img_deconv_nxt[3][1][4] = img_deconv[3][1][4];
            img_deconv_nxt[3][0][5] = img_deconv[3][0][5];    img_deconv_nxt[3][1][5] = img_deconv[3][1][5];
            img_deconv_nxt[3][0][6] = img_deconv[3][0][6];    img_deconv_nxt[3][1][6] = img_deconv[3][1][6];
            img_deconv_nxt[3][0][7] = img_deconv[3][0][7];    img_deconv_nxt[3][1][7] = img_deconv[3][1][7];

            img_deconv_nxt[4][0][0] = img_deconv[4][0][0];    img_deconv_nxt[4][1][0] = img_deconv[4][1][0];
            img_deconv_nxt[4][0][1] = img_deconv[4][0][1];    img_deconv_nxt[4][1][1] = img_deconv[4][1][1];
            img_deconv_nxt[4][0][2] = img_deconv[4][0][2];    img_deconv_nxt[4][1][2] = img_deconv[4][1][2];
            img_deconv_nxt[4][0][3] = img_deconv[4][0][3];    img_deconv_nxt[4][1][3] = img_deconv[4][1][3];
            img_deconv_nxt[4][0][4] = img_deconv[4][0][4];    img_deconv_nxt[4][1][4] = img_deconv[4][1][4];
            img_deconv_nxt[4][0][5] = img_deconv[4][0][5];    img_deconv_nxt[4][1][5] = img_deconv[4][1][5];
            img_deconv_nxt[4][0][6] = img_deconv[4][0][6];    img_deconv_nxt[4][1][6] = img_deconv[4][1][6];
            img_deconv_nxt[4][0][7] = img_deconv[4][0][7];    img_deconv_nxt[4][1][7] = img_deconv[4][1][7];
        end
    end
    else begin
        img_deconv_nxt[0][0][0] = img_deconv[0][0][0];    img_deconv_nxt[0][1][0] = img_deconv[0][1][0];
        img_deconv_nxt[0][0][1] = img_deconv[0][0][1];    img_deconv_nxt[0][1][1] = img_deconv[0][1][1];
        img_deconv_nxt[0][0][2] = img_deconv[0][0][2];    img_deconv_nxt[0][1][2] = img_deconv[0][1][2];
        img_deconv_nxt[0][0][3] = img_deconv[0][0][3];    img_deconv_nxt[0][1][3] = img_deconv[0][1][3];
        img_deconv_nxt[0][0][4] = img_deconv[0][0][4];    img_deconv_nxt[0][1][4] = img_deconv[0][1][4];
        img_deconv_nxt[0][0][5] = img_deconv[0][0][5];    img_deconv_nxt[0][1][5] = img_deconv[0][1][5];
        img_deconv_nxt[0][0][6] = img_deconv[0][0][6];    img_deconv_nxt[0][1][6] = img_deconv[0][1][6];
        img_deconv_nxt[0][0][7] = img_deconv[0][0][7];    img_deconv_nxt[0][1][7] = img_deconv[0][1][7];

        img_deconv_nxt[1][0][0] = img_deconv[1][0][0];    img_deconv_nxt[1][1][0] = img_deconv[1][1][0];
        img_deconv_nxt[1][0][1] = img_deconv[1][0][1];    img_deconv_nxt[1][1][1] = img_deconv[1][1][1];
        img_deconv_nxt[1][0][2] = img_deconv[1][0][2];    img_deconv_nxt[1][1][2] = img_deconv[1][1][2];
        img_deconv_nxt[1][0][3] = img_deconv[1][0][3];    img_deconv_nxt[1][1][3] = img_deconv[1][1][3];
        img_deconv_nxt[1][0][4] = img_deconv[1][0][4];    img_deconv_nxt[1][1][4] = img_deconv[1][1][4];
        img_deconv_nxt[1][0][5] = img_deconv[1][0][5];    img_deconv_nxt[1][1][5] = img_deconv[1][1][5];
        img_deconv_nxt[1][0][6] = img_deconv[1][0][6];    img_deconv_nxt[1][1][6] = img_deconv[1][1][6];
        img_deconv_nxt[1][0][7] = img_deconv[1][0][7];    img_deconv_nxt[1][1][7] = img_deconv[1][1][7];

        img_deconv_nxt[2][0][0] = img_deconv[2][0][0];    img_deconv_nxt[2][1][0] = img_deconv[2][1][0];
        img_deconv_nxt[2][0][1] = img_deconv[2][0][1];    img_deconv_nxt[2][1][1] = img_deconv[2][1][1];
        img_deconv_nxt[2][0][2] = img_deconv[2][0][2];    img_deconv_nxt[2][1][2] = img_deconv[2][1][2];
        img_deconv_nxt[2][0][3] = img_deconv[2][0][3];    img_deconv_nxt[2][1][3] = img_deconv[2][1][3];
        img_deconv_nxt[2][0][4] = img_deconv[2][0][4];    img_deconv_nxt[2][1][4] = img_deconv[2][1][4];
        img_deconv_nxt[2][0][5] = img_deconv[2][0][5];    img_deconv_nxt[2][1][5] = img_deconv[2][1][5];
        img_deconv_nxt[2][0][6] = img_deconv[2][0][6];    img_deconv_nxt[2][1][6] = img_deconv[2][1][6];
        img_deconv_nxt[2][0][7] = img_deconv[2][0][7];    img_deconv_nxt[2][1][7] = img_deconv[2][1][7];

        img_deconv_nxt[3][0][0] = img_deconv[3][0][0];    img_deconv_nxt[3][1][0] = img_deconv[3][1][0];
        img_deconv_nxt[3][0][1] = img_deconv[3][0][1];    img_deconv_nxt[3][1][1] = img_deconv[3][1][1];
        img_deconv_nxt[3][0][2] = img_deconv[3][0][2];    img_deconv_nxt[3][1][2] = img_deconv[3][1][2];
        img_deconv_nxt[3][0][3] = img_deconv[3][0][3];    img_deconv_nxt[3][1][3] = img_deconv[3][1][3];
        img_deconv_nxt[3][0][4] = img_deconv[3][0][4];    img_deconv_nxt[3][1][4] = img_deconv[3][1][4];
        img_deconv_nxt[3][0][5] = img_deconv[3][0][5];    img_deconv_nxt[3][1][5] = img_deconv[3][1][5];
        img_deconv_nxt[3][0][6] = img_deconv[3][0][6];    img_deconv_nxt[3][1][6] = img_deconv[3][1][6];
        img_deconv_nxt[3][0][7] = img_deconv[3][0][7];    img_deconv_nxt[3][1][7] = img_deconv[3][1][7];

        img_deconv_nxt[4][0][0] = img_deconv[4][0][0];    img_deconv_nxt[4][1][0] = img_deconv[4][1][0];
        img_deconv_nxt[4][0][1] = img_deconv[4][0][1];    img_deconv_nxt[4][1][1] = img_deconv[4][1][1];
        img_deconv_nxt[4][0][2] = img_deconv[4][0][2];    img_deconv_nxt[4][1][2] = img_deconv[4][1][2];
        img_deconv_nxt[4][0][3] = img_deconv[4][0][3];    img_deconv_nxt[4][1][3] = img_deconv[4][1][3];
        img_deconv_nxt[4][0][4] = img_deconv[4][0][4];    img_deconv_nxt[4][1][4] = img_deconv[4][1][4];
        img_deconv_nxt[4][0][5] = img_deconv[4][0][5];    img_deconv_nxt[4][1][5] = img_deconv[4][1][5];
        img_deconv_nxt[4][0][6] = img_deconv[4][0][6];    img_deconv_nxt[4][1][6] = img_deconv[4][1][6];
        img_deconv_nxt[4][0][7] = img_deconv[4][0][7];    img_deconv_nxt[4][1][7] = img_deconv[4][1][7];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ker_deconv[0][0] <= 0;  ker_deconv[0][1] <= 0;  ker_deconv[0][2] <= 0;  ker_deconv[0][3] <= 0;  ker_deconv[0][4] <= 0;
        ker_deconv[1][0] <= 0;  ker_deconv[1][1] <= 0;  ker_deconv[1][2] <= 0;  ker_deconv[1][3] <= 0;  ker_deconv[1][4] <= 0;
        ker_deconv[2][0] <= 0;  ker_deconv[2][1] <= 0;  ker_deconv[2][2] <= 0;  ker_deconv[2][3] <= 0;  ker_deconv[2][4] <= 0;
        ker_deconv[3][0] <= 0;  ker_deconv[3][1] <= 0;  ker_deconv[3][2] <= 0;  ker_deconv[3][3] <= 0;  ker_deconv[3][4] <= 0;
        ker_deconv[4][0] <= 0;  ker_deconv[4][1] <= 0;  ker_deconv[4][2] <= 0;  ker_deconv[4][3] <= 0;  ker_deconv[4][4] <= 0;
    end
    else begin
        ker_deconv[0][0] <= ker_deconv_nxt[0][0];   ker_deconv[0][1] <= ker_deconv_nxt[0][1];   ker_deconv[0][2] <= ker_deconv_nxt[0][2];   ker_deconv[0][3] <= ker_deconv_nxt[0][3];   ker_deconv[0][4] <= ker_deconv_nxt[0][4];
        ker_deconv[1][0] <= ker_deconv_nxt[1][0];   ker_deconv[1][1] <= ker_deconv_nxt[1][1];   ker_deconv[1][2] <= ker_deconv_nxt[1][2];   ker_deconv[1][3] <= ker_deconv_nxt[1][3];   ker_deconv[1][4] <= ker_deconv_nxt[1][4];
        ker_deconv[2][0] <= ker_deconv_nxt[2][0];   ker_deconv[2][1] <= ker_deconv_nxt[2][1];   ker_deconv[2][2] <= ker_deconv_nxt[2][2];   ker_deconv[2][3] <= ker_deconv_nxt[2][3];   ker_deconv[2][4] <= ker_deconv_nxt[2][4];
        ker_deconv[3][0] <= ker_deconv_nxt[3][0];   ker_deconv[3][1] <= ker_deconv_nxt[3][1];   ker_deconv[3][2] <= ker_deconv_nxt[3][2];   ker_deconv[3][3] <= ker_deconv_nxt[3][3];   ker_deconv[3][4] <= ker_deconv_nxt[3][4];
        ker_deconv[4][0] <= ker_deconv_nxt[4][0];   ker_deconv[4][1] <= ker_deconv_nxt[4][1];   ker_deconv[4][2] <= ker_deconv_nxt[4][2];   ker_deconv[4][3] <= ker_deconv_nxt[4][3];   ker_deconv[4][4] <= ker_deconv_nxt[4][4];
    end
end

always @(*) begin
    if(state == CAL_DECONV) begin
        ker_deconv_nxt[0][0] = DO_ker[0];   ker_deconv_nxt[0][1] = DO_ker[1];   ker_deconv_nxt[0][2] = DO_ker[2];   ker_deconv_nxt[0][3] = DO_ker[3];   ker_deconv_nxt[0][4] = DO_ker[4];
        ker_deconv_nxt[1][0] =         0;   ker_deconv_nxt[1][1] =         0;   ker_deconv_nxt[1][2] =         0;   ker_deconv_nxt[1][3] =         0;   ker_deconv_nxt[1][4] =         0;
        ker_deconv_nxt[2][0] =         0;   ker_deconv_nxt[2][1] =         0;   ker_deconv_nxt[2][2] =         0;   ker_deconv_nxt[2][3] =         0;   ker_deconv_nxt[2][4] =         0;
        ker_deconv_nxt[3][0] =         0;   ker_deconv_nxt[3][1] =         0;   ker_deconv_nxt[3][2] =         0;   ker_deconv_nxt[3][3] =         0;   ker_deconv_nxt[3][4] =         0;
        ker_deconv_nxt[4][0] =         0;   ker_deconv_nxt[4][1] =         0;   ker_deconv_nxt[4][2] =         0;   ker_deconv_nxt[4][3] =         0;   ker_deconv_nxt[4][4] =         0;
    end
    else if((state == OUT) && (cnt_out_bit >= 7) && (cnt_out_bit < 12)) begin
        ker_deconv_nxt[0][0] = ker_deconv[1][0];   ker_deconv_nxt[0][1] = ker_deconv[1][1];   ker_deconv_nxt[0][2] = ker_deconv[1][2];   ker_deconv_nxt[0][3] = ker_deconv[1][3];   ker_deconv_nxt[0][4] = ker_deconv[1][4];
        ker_deconv_nxt[1][0] = ker_deconv[2][0];   ker_deconv_nxt[1][1] = ker_deconv[2][1];   ker_deconv_nxt[1][2] = ker_deconv[2][2];   ker_deconv_nxt[1][3] = ker_deconv[2][3];   ker_deconv_nxt[1][4] = ker_deconv[2][4];
        ker_deconv_nxt[2][0] = ker_deconv[3][0];   ker_deconv_nxt[2][1] = ker_deconv[3][1];   ker_deconv_nxt[2][2] = ker_deconv[3][2];   ker_deconv_nxt[2][3] = ker_deconv[3][3];   ker_deconv_nxt[2][4] = ker_deconv[3][4];
        ker_deconv_nxt[3][0] = ker_deconv[4][0];   ker_deconv_nxt[3][1] = ker_deconv[4][1];   ker_deconv_nxt[3][2] = ker_deconv[4][2];   ker_deconv_nxt[3][3] = ker_deconv[4][3];   ker_deconv_nxt[3][4] = ker_deconv[4][4];
        ker_deconv_nxt[4][0] =        DO_ker[0];   ker_deconv_nxt[4][1] =        DO_ker[1];   ker_deconv_nxt[4][2] =        DO_ker[2];   ker_deconv_nxt[4][3] =        DO_ker[3];   ker_deconv_nxt[4][4] =        DO_ker[4];
    end
    else begin
        ker_deconv_nxt[0][0] = ker_deconv[0][0];   ker_deconv_nxt[0][1] = ker_deconv[0][1];   ker_deconv_nxt[0][2] = ker_deconv[0][2];   ker_deconv_nxt[0][3] = ker_deconv[0][3];   ker_deconv_nxt[0][4] = ker_deconv[0][4];
        ker_deconv_nxt[1][0] = ker_deconv[1][0];   ker_deconv_nxt[1][1] = ker_deconv[1][1];   ker_deconv_nxt[1][2] = ker_deconv[1][2];   ker_deconv_nxt[1][3] = ker_deconv[1][3];   ker_deconv_nxt[1][4] = ker_deconv[1][4];
        ker_deconv_nxt[2][0] = ker_deconv[2][0];   ker_deconv_nxt[2][1] = ker_deconv[2][1];   ker_deconv_nxt[2][2] = ker_deconv[2][2];   ker_deconv_nxt[2][3] = ker_deconv[2][3];   ker_deconv_nxt[2][4] = ker_deconv[2][4];
        ker_deconv_nxt[3][0] = ker_deconv[3][0];   ker_deconv_nxt[3][1] = ker_deconv[3][1];   ker_deconv_nxt[3][2] = ker_deconv[3][2];   ker_deconv_nxt[3][3] = ker_deconv[3][3];   ker_deconv_nxt[3][4] = ker_deconv[3][4];
        ker_deconv_nxt[4][0] = ker_deconv[4][0];   ker_deconv_nxt[4][1] = ker_deconv[4][1];   ker_deconv_nxt[4][2] = ker_deconv[4][2];   ker_deconv_nxt[4][3] = ker_deconv[4][3];   ker_deconv_nxt[4][4] = ker_deconv[4][4];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tmp_deconv[0] <= 0;
        tmp_deconv[1] <= 0;
        tmp_deconv[2] <= 0;
        tmp_deconv[3] <= 0;
        tmp_deconv[4] <= 0;
    end
    else begin
        tmp_deconv[0] <= tmp_deconv_nxt[0];
        tmp_deconv[1] <= tmp_deconv_nxt[1];
        tmp_deconv[2] <= tmp_deconv_nxt[2];
        tmp_deconv[3] <= tmp_deconv_nxt[3];
        tmp_deconv[4] <= tmp_deconv_nxt[4];
    end
end

assign tmp_deconv_idx = cnt_out_bit - 12;

always @(*) begin
    if(state == OUT) begin
        case (tmp_deconv_idx)
            0: begin
                tmp_deconv_nxt[0] = tmp_deconv[0] + mul_z[0][0];
                tmp_deconv_nxt[1] = tmp_deconv[1] + mul_z[0][1];
                tmp_deconv_nxt[2] = tmp_deconv[2] + mul_z[0][2];
                tmp_deconv_nxt[3] = tmp_deconv[3] + mul_z[0][3];
                tmp_deconv_nxt[4] = tmp_deconv[4] + mul_z[0][4];
            end
            1: begin
                tmp_deconv_nxt[0] = tmp_deconv[0] + mul_z[1][0];
                tmp_deconv_nxt[1] = tmp_deconv[1] + mul_z[1][1];
                tmp_deconv_nxt[2] = tmp_deconv[2] + mul_z[1][2];
                tmp_deconv_nxt[3] = tmp_deconv[3] + mul_z[1][3];
                tmp_deconv_nxt[4] = tmp_deconv[4] + mul_z[1][4];
            end
            2: begin
                tmp_deconv_nxt[0] = tmp_deconv[0] + mul_z[2][0];
                tmp_deconv_nxt[1] = tmp_deconv[1] + mul_z[2][1];
                tmp_deconv_nxt[2] = tmp_deconv[2] + mul_z[2][2];
                tmp_deconv_nxt[3] = tmp_deconv[3] + mul_z[2][3];
                tmp_deconv_nxt[4] = tmp_deconv[4] + mul_z[2][4];
            end
            3: begin
                tmp_deconv_nxt[0] = tmp_deconv[0] + mul_z[3][0];
                tmp_deconv_nxt[1] = tmp_deconv[1] + mul_z[3][1];
                tmp_deconv_nxt[2] = tmp_deconv[2] + mul_z[3][2];
                tmp_deconv_nxt[3] = tmp_deconv[3] + mul_z[3][3];
                tmp_deconv_nxt[4] = tmp_deconv[4] + mul_z[3][4];
            end
            4: begin
                tmp_deconv_nxt[0] = tmp_deconv[0] + mul_z[4][0];
                tmp_deconv_nxt[1] = tmp_deconv[1] + mul_z[4][1];
                tmp_deconv_nxt[2] = tmp_deconv[2] + mul_z[4][2];
                tmp_deconv_nxt[3] = tmp_deconv[3] + mul_z[4][3];
                tmp_deconv_nxt[4] = tmp_deconv[4] + mul_z[4][4];
            end
            7: begin
                tmp_deconv_nxt[0] = 0;
                tmp_deconv_nxt[1] = 0;
                tmp_deconv_nxt[2] = 0;
                tmp_deconv_nxt[3] = 0;
                tmp_deconv_nxt[4] = 0;
            end
            default: begin
                tmp_deconv_nxt[0] = tmp_deconv[0];
                tmp_deconv_nxt[1] = tmp_deconv[1];
                tmp_deconv_nxt[2] = tmp_deconv[2];
                tmp_deconv_nxt[3] = tmp_deconv[3];
                tmp_deconv_nxt[4] = tmp_deconv[4];
            end
        endcase
    end
    else begin
        tmp_deconv_nxt[0] = 0;
        tmp_deconv_nxt[1] = 0;
        tmp_deconv_nxt[2] = 0;
        tmp_deconv_nxt[3] = 0;
        tmp_deconv_nxt[4] = 0;
    end
end

//=======================================================
//                    OUTPUT
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_out_bit <= 0;
        cnt_out_col <= 0;
        cnt_out_row <= 0;
    end
    else begin
        cnt_out_bit <= cnt_out_bit_nxt;
        cnt_out_col <= cnt_out_col_nxt;
        cnt_out_row <= cnt_out_row_nxt;
    end
end

assign cnt_out_max = (!matrix_size_reg) ? ((!mode_reg) ? 1 : 11) : ((matrix_size_reg[0]) ? ((!mode_reg) ? 5 : 19) : ((!mode_reg) ? 13 : 35));
assign cnt_out_bit_nxt = ((state == OUT) && (cnt_out_bit != 19)) ? cnt_out_bit + 1 : 0;
assign cnt_out_col_nxt = ((state == OUT) && (cnt_out_bit == 19)) ? ((cnt_out_col == cnt_out_max) ? 0 : (cnt_out_col + 1)) : ((state == IDLE) ? 0 : cnt_out_col);
assign cnt_out_row_nxt = ((state == OUT) && (cnt_out_bit == 19) && (cnt_out_col == cnt_out_max)) ? (cnt_out_row + 1) : ((state == IDLE) ? 0 :  cnt_out_row);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else begin
        out <= out_nxt;
    end
end

always @(*) begin
    if((state == CAL_MAXPL) || ((!mode_reg) && (cnt_out_bit == 19))) begin
        out_nxt = cmp_z[2];
    end
    else if((state == CAL_DECONV) && (cnt_deconv == 1)) begin
        out_nxt = mul_z[0][4];
    end
    else if(((mode_reg) && (cnt_out_bit == 19))) begin
        out_nxt = (tmp_deconv[0] + tmp_deconv[1]) + (tmp_deconv[2] + tmp_deconv[3]) + tmp_deconv[4]; 
    end
    else if(state == OUT) begin
        out_nxt = out >> 1;
    end
    else begin
        out_nxt = out;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_value <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
        out_value <= out_value_nxt;
    end
end

assign out_valid_nxt = (state == OUT) ? 1 : 0;
assign out_value_nxt = (state == OUT) ? out[0] : 0;

//=======================================================
//                    MULTIPLIER
//=======================================================
assign offset_row = cnt_out_row - (cnt_out_max + 1);

always @(*) begin
    if(state == CAL_CONV) begin
        mul_a[0][0] = img[0][0][0]; mul_a[0][1] = img[0][0][1]; mul_a[0][2] = img[0][0][2]; mul_a[0][3] = img[0][0][3]; mul_a[0][4] = img[0][0][4];
        mul_a[1][0] = img[0][0][1]; mul_a[1][1] = img[0][0][2]; mul_a[1][2] = img[0][0][3]; mul_a[1][3] = img[0][0][4]; mul_a[1][4] = img[0][0][5];
        mul_a[2][0] = img[1][0][0]; mul_a[2][1] = img[1][0][1]; mul_a[2][2] = img[1][0][2]; mul_a[2][3] = img[1][0][3]; mul_a[2][4] = img[1][0][4];
        mul_a[3][0] = img[1][0][1]; mul_a[3][1] = img[1][0][2]; mul_a[3][2] = img[1][0][3]; mul_a[3][3] = img[1][0][4]; mul_a[3][4] = img[1][0][5];
        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
    end
    else if(state == CAL_DECONV) begin
        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = img_deconv[0][0][0];
        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] =                   0;
        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] =                   0;
        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] =                   0;
        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] =                   0;
    end
    else if(state == OUT) begin
        if(!mode_reg) begin
            if(!matrix_size_reg) begin
                case (cnt_out_col[0])
                    0: begin
                        mul_a[0][0] = img[0][0][2]; mul_a[0][1] = img[0][0][3]; mul_a[0][2] = img[0][0][4]; mul_a[0][3] = img[0][0][5]; mul_a[0][4] = img[0][0][6]; 
                        mul_a[1][0] = img[0][0][3]; mul_a[1][1] = img[0][0][4]; mul_a[1][2] = img[0][0][5]; mul_a[1][3] = img[0][0][6]; mul_a[1][4] = img[0][0][7];
                        mul_a[2][0] = img[1][0][2]; mul_a[2][1] = img[1][0][3]; mul_a[2][2] = img[1][0][4]; mul_a[2][3] = img[1][0][5]; mul_a[2][4] = img[1][0][6];
                        mul_a[3][0] = img[1][0][3]; mul_a[3][1] = img[1][0][4]; mul_a[3][2] = img[1][0][5]; mul_a[3][3] = img[1][0][6]; mul_a[3][4] = img[1][0][7];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end 
                    1 : begin
                        mul_a[0][0] = img[0][0][0]; mul_a[0][1] = img[0][0][1]; mul_a[0][2] = img[0][0][2]; mul_a[0][3] = img[0][0][3]; mul_a[0][4] = img[0][0][4];
                        mul_a[1][0] = img[0][0][1]; mul_a[1][1] = img[0][0][2]; mul_a[1][2] = img[0][0][3]; mul_a[1][3] = img[0][0][4]; mul_a[1][4] = img[0][0][5];
                        mul_a[2][0] = img[1][0][0]; mul_a[2][1] = img[1][0][1]; mul_a[2][2] = img[1][0][2]; mul_a[2][3] = img[1][0][3]; mul_a[2][4] = img[1][0][4];
                        mul_a[3][0] = img[1][0][1]; mul_a[3][1] = img[1][0][2]; mul_a[3][2] = img[1][0][3]; mul_a[3][3] = img[1][0][4]; mul_a[3][4] = img[1][0][5];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                endcase
            end
            else if(matrix_size_reg[0]) begin
                case (cnt_out_col[3:0])
                    0: begin
                        mul_a[0][0] = img[0][0][2]; mul_a[0][1] = img[0][0][3]; mul_a[0][2] = img[0][0][4]; mul_a[0][3] = img[0][0][5]; mul_a[0][4] = img[0][0][6]; 
                        mul_a[1][0] = img[0][0][3]; mul_a[1][1] = img[0][0][4]; mul_a[1][2] = img[0][0][5]; mul_a[1][3] = img[0][0][6]; mul_a[1][4] = img[0][0][7];
                        mul_a[2][0] = img[1][0][2]; mul_a[2][1] = img[1][0][3]; mul_a[2][2] = img[1][0][4]; mul_a[2][3] = img[1][0][5]; mul_a[2][4] = img[1][0][6];
                        mul_a[3][0] = img[1][0][3]; mul_a[3][1] = img[1][0][4]; mul_a[3][2] = img[1][0][5]; mul_a[3][3] = img[1][0][6]; mul_a[3][4] = img[1][0][7];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end 
                    1: begin
                        mul_a[0][0] = img[0][0][4]; mul_a[0][1] = img[0][0][5]; mul_a[0][2] = img[0][0][6]; mul_a[0][3] = img[0][0][7]; mul_a[0][4] = img[0][1][0];
                        mul_a[1][0] = img[0][0][5]; mul_a[1][1] = img[0][0][6]; mul_a[1][2] = img[0][0][7]; mul_a[1][3] = img[0][1][0]; mul_a[1][4] = img[0][1][1];
                        mul_a[2][0] = img[1][0][4]; mul_a[2][1] = img[1][0][5]; mul_a[2][2] = img[1][0][6]; mul_a[2][3] = img[1][0][7]; mul_a[2][4] = img[1][1][0];
                        mul_a[3][0] = img[1][0][5]; mul_a[3][1] = img[1][0][6]; mul_a[3][2] = img[1][0][7]; mul_a[3][3] = img[1][1][0]; mul_a[3][4] = img[1][1][1];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                    2: begin
                        mul_a[0][0] = img[0][0][6]; mul_a[0][1] = img[0][0][7]; mul_a[0][2] = img[0][1][0]; mul_a[0][3] = img[0][1][1]; mul_a[0][4] = img[0][1][2];
                        mul_a[1][0] = img[0][0][7]; mul_a[1][1] = img[0][1][0]; mul_a[1][2] = img[0][1][1]; mul_a[1][3] = img[0][1][2]; mul_a[1][4] = img[0][1][3];
                        mul_a[2][0] = img[1][0][6]; mul_a[2][1] = img[1][0][7]; mul_a[2][2] = img[1][1][0]; mul_a[2][3] = img[1][1][1]; mul_a[2][4] = img[1][1][2];
                        mul_a[3][0] = img[1][0][7]; mul_a[3][1] = img[1][1][0]; mul_a[3][2] = img[1][1][1]; mul_a[3][3] = img[1][1][2]; mul_a[3][4] = img[1][1][3];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                    3: begin
                        mul_a[0][0] = img[0][1][0]; mul_a[0][1] = img[0][1][1]; mul_a[0][2] = img[0][1][2]; mul_a[0][3] = img[0][1][3]; mul_a[0][4] = img[0][1][4];
                        mul_a[1][0] = img[0][1][1]; mul_a[1][1] = img[0][1][2]; mul_a[1][2] = img[0][1][3]; mul_a[1][3] = img[0][1][4]; mul_a[1][4] = img[0][1][5];
                        mul_a[2][0] = img[1][1][0]; mul_a[2][1] = img[1][1][1]; mul_a[2][2] = img[1][1][2]; mul_a[2][3] = img[1][1][3]; mul_a[2][4] = img[1][1][4];
                        mul_a[3][0] = img[1][1][1]; mul_a[3][1] = img[1][1][2]; mul_a[3][2] = img[1][1][3]; mul_a[3][3] = img[1][1][4]; mul_a[3][4] = img[1][1][5];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                    4: begin
                        mul_a[0][0] = img[0][1][2]; mul_a[0][1] = img[0][1][3]; mul_a[0][2] = img[0][1][4]; mul_a[0][3] = img[0][1][5]; mul_a[0][4] = img[0][1][6];
                        mul_a[1][0] = img[0][1][3]; mul_a[1][1] = img[0][1][4]; mul_a[1][2] = img[0][1][5]; mul_a[1][3] = img[0][1][6]; mul_a[1][4] = img[0][1][7];
                        mul_a[2][0] = img[1][1][2]; mul_a[2][1] = img[1][1][3]; mul_a[2][2] = img[1][1][4]; mul_a[2][3] = img[1][1][5]; mul_a[2][4] = img[1][1][6];
                        mul_a[3][0] = img[1][1][3]; mul_a[3][1] = img[1][1][4]; mul_a[3][2] = img[1][1][5]; mul_a[3][3] = img[1][1][6]; mul_a[3][4] = img[1][1][7];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                    5: begin
                        mul_a[0][0] = img[0][0][0]; mul_a[0][1] = img[0][0][1]; mul_a[0][2] = img[0][0][2]; mul_a[0][3] = img[0][0][3]; mul_a[0][4] = img[0][0][4];
                        mul_a[1][0] = img[0][0][1]; mul_a[1][1] = img[0][0][2]; mul_a[1][2] = img[0][0][3]; mul_a[1][3] = img[0][0][4]; mul_a[1][4] = img[0][0][5];
                        mul_a[2][0] = img[1][0][0]; mul_a[2][1] = img[1][0][1]; mul_a[2][2] = img[1][0][2]; mul_a[2][3] = img[1][0][3]; mul_a[2][4] = img[1][0][4];
                        mul_a[3][0] = img[1][0][1]; mul_a[3][1] = img[1][0][2]; mul_a[3][2] = img[1][0][3]; mul_a[3][3] = img[1][0][4]; mul_a[3][4] = img[1][0][5];
                        mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                    end
                    default: begin
                        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = 0;
                        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] = 0;
                        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] = 0;
                        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] = 0;
                        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] = 0;
                    end
                endcase
            end
            else begin
                if(!cnt_out_col) begin
                    mul_a[0][0] = img[0][0][2]; mul_a[0][1] = img[0][0][3]; mul_a[0][2] = img[0][0][4]; mul_a[0][3] = img[0][0][5]; mul_a[0][4] = img[0][0][6]; 
                    mul_a[1][0] = img[0][0][3]; mul_a[1][1] = img[0][0][4]; mul_a[1][2] = img[0][0][5]; mul_a[1][3] = img[0][0][6]; mul_a[1][4] = img[0][0][7];
                    mul_a[2][0] = img[1][0][2]; mul_a[2][1] = img[1][0][3]; mul_a[2][2] = img[1][0][4]; mul_a[2][3] = img[1][0][5]; mul_a[2][4] = img[1][0][6];
                    mul_a[3][0] = img[1][0][3]; mul_a[3][1] = img[1][0][4]; mul_a[3][2] = img[1][0][5]; mul_a[3][3] = img[1][0][6]; mul_a[3][4] = img[1][0][7];
                    mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                end
                else if(cnt_out_col != 13) begin
                    case (cnt_out_col[1:0])
                        1: begin
                            mul_a[0][0] = img[0][0][4]; mul_a[0][1] = img[0][0][5]; mul_a[0][2] = img[0][0][6]; mul_a[0][3] = img[0][0][7]; mul_a[0][4] = img[0][1][0];
                            mul_a[1][0] = img[0][0][5]; mul_a[1][1] = img[0][0][6]; mul_a[1][2] = img[0][0][7]; mul_a[1][3] = img[0][1][0]; mul_a[1][4] = img[0][1][1];
                            mul_a[2][0] = img[1][0][4]; mul_a[2][1] = img[1][0][5]; mul_a[2][2] = img[1][0][6]; mul_a[2][3] = img[1][0][7]; mul_a[2][4] = img[1][1][0];
                            mul_a[3][0] = img[1][0][5]; mul_a[3][1] = img[1][0][6]; mul_a[3][2] = img[1][0][7]; mul_a[3][3] = img[1][1][0]; mul_a[3][4] = img[1][1][1];
                            mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                        end
                        2: begin
                            mul_a[0][0] = img[0][0][6]; mul_a[0][1] = img[0][0][7]; mul_a[0][2] = img[0][1][0]; mul_a[0][3] = img[0][1][1]; mul_a[0][4] = img[0][1][2];
                            mul_a[1][0] = img[0][0][7]; mul_a[1][1] = img[0][1][0]; mul_a[1][2] = img[0][1][1]; mul_a[1][3] = img[0][1][2]; mul_a[1][4] = img[0][1][3];
                            mul_a[2][0] = img[1][0][6]; mul_a[2][1] = img[1][0][7]; mul_a[2][2] = img[1][1][0]; mul_a[2][3] = img[1][1][1]; mul_a[2][4] = img[1][1][2];
                            mul_a[3][0] = img[1][0][7]; mul_a[3][1] = img[1][1][0]; mul_a[3][2] = img[1][1][1]; mul_a[3][3] = img[1][1][2]; mul_a[3][4] = img[1][1][3];
                            mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                        end
                        3: begin
                            mul_a[0][0] = img[0][1][0]; mul_a[0][1] = img[0][1][1]; mul_a[0][2] = img[0][1][2]; mul_a[0][3] = img[0][1][3]; mul_a[0][4] = img[0][1][4];
                            mul_a[1][0] = img[0][1][1]; mul_a[1][1] = img[0][1][2]; mul_a[1][2] = img[0][1][3]; mul_a[1][3] = img[0][1][4]; mul_a[1][4] = img[0][1][5];
                            mul_a[2][0] = img[1][1][0]; mul_a[2][1] = img[1][1][1]; mul_a[2][2] = img[1][1][2]; mul_a[2][3] = img[1][1][3]; mul_a[2][4] = img[1][1][4];
                            mul_a[3][0] = img[1][1][1]; mul_a[3][1] = img[1][1][2]; mul_a[3][2] = img[1][1][3]; mul_a[3][3] = img[1][1][4]; mul_a[3][4] = img[1][1][5];
                            mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                        end
                        0: begin
                            mul_a[0][0] = img[0][1][2]; mul_a[0][1] = img[0][1][3]; mul_a[0][2] = img[0][1][4]; mul_a[0][3] = img[0][1][5]; mul_a[0][4] = img[0][1][6];
                            mul_a[1][0] = img[0][1][3]; mul_a[1][1] = img[0][1][4]; mul_a[1][2] = img[0][1][5]; mul_a[1][3] = img[0][1][6]; mul_a[1][4] = img[0][1][7];
                            mul_a[2][0] = img[1][1][2]; mul_a[2][1] = img[1][1][3]; mul_a[2][2] = img[1][1][4]; mul_a[2][3] = img[1][1][5]; mul_a[2][4] = img[1][1][6];
                            mul_a[3][0] = img[1][1][3]; mul_a[3][1] = img[1][1][4]; mul_a[3][2] = img[1][1][5]; mul_a[3][3] = img[1][1][6]; mul_a[3][4] = img[1][1][7];
                            mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                        end
                    endcase
                end
                else begin
                    mul_a[0][0] = img[0][0][0]; mul_a[0][1] = img[0][0][1]; mul_a[0][2] = img[0][0][2]; mul_a[0][3] = img[0][0][3]; mul_a[0][4] = img[0][0][4];
                    mul_a[1][0] = img[0][0][1]; mul_a[1][1] = img[0][0][2]; mul_a[1][2] = img[0][0][3]; mul_a[1][3] = img[0][0][4]; mul_a[1][4] = img[0][0][5];
                    mul_a[2][0] = img[1][0][0]; mul_a[2][1] = img[1][0][1]; mul_a[2][2] = img[1][0][2]; mul_a[2][3] = img[1][0][3]; mul_a[2][4] = img[1][0][4];
                    mul_a[3][0] = img[1][0][1]; mul_a[3][1] = img[1][0][2]; mul_a[3][2] = img[1][0][3]; mul_a[3][3] = img[1][0][4]; mul_a[3][4] = img[1][0][5];
                    mul_a[4][0] =            0; mul_a[4][1] =            0; mul_a[4][2] =            0; mul_a[4][3] =            0; mul_a[4][4] =            0;
                end
            end
        end
        else begin
            if(!matrix_size_reg) begin
                case (cnt_out_col)
                    11: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] = img_deconv[0][0][0];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] = img_deconv[1][0][0];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] = img_deconv[2][0][0];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] = img_deconv[3][0][0];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] = img_deconv[4][0][0];
                    end
                    0: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] = img_deconv[0][0][0]; mul_a[0][4] = img_deconv[0][0][1];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] = img_deconv[1][0][0]; mul_a[1][4] = img_deconv[1][0][1];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] = img_deconv[2][0][0]; mul_a[2][4] = img_deconv[2][0][1];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] = img_deconv[3][0][0]; mul_a[3][4] = img_deconv[3][0][1];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] = img_deconv[4][0][0]; mul_a[4][4] = img_deconv[4][0][1];
                    end 
                    1: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] = img_deconv[0][0][0]; mul_a[0][3] = img_deconv[0][0][1]; mul_a[0][4] = img_deconv[0][0][2];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] = img_deconv[1][0][0]; mul_a[1][3] = img_deconv[1][0][1]; mul_a[1][4] = img_deconv[1][0][2];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] = img_deconv[2][0][0]; mul_a[2][3] = img_deconv[2][0][1]; mul_a[2][4] = img_deconv[2][0][2];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] = img_deconv[3][0][0]; mul_a[3][3] = img_deconv[3][0][1]; mul_a[3][4] = img_deconv[3][0][2];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] = img_deconv[4][0][0]; mul_a[4][3] = img_deconv[4][0][1]; mul_a[4][4] = img_deconv[4][0][2];
                    end
                    2: begin
                        mul_a[0][0] =                   0; mul_a[0][1] = img_deconv[0][0][0]; mul_a[0][2] = img_deconv[0][0][1]; mul_a[0][3] = img_deconv[0][0][2]; mul_a[0][4] = img_deconv[0][0][3];
                        mul_a[1][0] =                   0; mul_a[1][1] = img_deconv[1][0][0]; mul_a[1][2] = img_deconv[1][0][1]; mul_a[1][3] = img_deconv[1][0][2]; mul_a[1][4] = img_deconv[1][0][3];
                        mul_a[2][0] =                   0; mul_a[2][1] = img_deconv[2][0][0]; mul_a[2][2] = img_deconv[2][0][1]; mul_a[2][3] = img_deconv[2][0][2]; mul_a[2][4] = img_deconv[2][0][3];
                        mul_a[3][0] =                   0; mul_a[3][1] = img_deconv[3][0][0]; mul_a[3][2] = img_deconv[3][0][1]; mul_a[3][3] = img_deconv[3][0][2]; mul_a[3][4] = img_deconv[3][0][3];
                        mul_a[4][0] =                   0; mul_a[4][1] = img_deconv[4][0][0]; mul_a[4][2] = img_deconv[4][0][1]; mul_a[4][3] = img_deconv[4][0][2]; mul_a[4][4] = img_deconv[4][0][3];
                    end
                    3: begin
                        mul_a[0][0] = img_deconv[0][0][0]; mul_a[0][1] = img_deconv[0][0][1]; mul_a[0][2] = img_deconv[0][0][2]; mul_a[0][3] = img_deconv[0][0][3]; mul_a[0][4] = img_deconv[0][0][4];
                        mul_a[1][0] = img_deconv[1][0][0]; mul_a[1][1] = img_deconv[1][0][1]; mul_a[1][2] = img_deconv[1][0][2]; mul_a[1][3] = img_deconv[1][0][3]; mul_a[1][4] = img_deconv[1][0][4];
                        mul_a[2][0] = img_deconv[2][0][0]; mul_a[2][1] = img_deconv[2][0][1]; mul_a[2][2] = img_deconv[2][0][2]; mul_a[2][3] = img_deconv[2][0][3]; mul_a[2][4] = img_deconv[2][0][4];
                        mul_a[3][0] = img_deconv[3][0][0]; mul_a[3][1] = img_deconv[3][0][1]; mul_a[3][2] = img_deconv[3][0][2]; mul_a[3][3] = img_deconv[3][0][3]; mul_a[3][4] = img_deconv[3][0][4];
                        mul_a[4][0] = img_deconv[4][0][0]; mul_a[4][1] = img_deconv[4][0][1]; mul_a[4][2] = img_deconv[4][0][2]; mul_a[4][3] = img_deconv[4][0][3]; mul_a[4][4] = img_deconv[4][0][4];
                    end
                    4: begin
                        mul_a[0][0] = img_deconv[0][0][1]; mul_a[0][1] = img_deconv[0][0][2]; mul_a[0][2] = img_deconv[0][0][3]; mul_a[0][3] = img_deconv[0][0][4]; mul_a[0][4] = img_deconv[0][0][5];
                        mul_a[1][0] = img_deconv[1][0][1]; mul_a[1][1] = img_deconv[1][0][2]; mul_a[1][2] = img_deconv[1][0][3]; mul_a[1][3] = img_deconv[1][0][4]; mul_a[1][4] = img_deconv[1][0][5];
                        mul_a[2][0] = img_deconv[2][0][1]; mul_a[2][1] = img_deconv[2][0][2]; mul_a[2][2] = img_deconv[2][0][3]; mul_a[2][3] = img_deconv[2][0][4]; mul_a[2][4] = img_deconv[2][0][5];
                        mul_a[3][0] = img_deconv[3][0][1]; mul_a[3][1] = img_deconv[3][0][2]; mul_a[3][2] = img_deconv[3][0][3]; mul_a[3][3] = img_deconv[3][0][4]; mul_a[3][4] = img_deconv[3][0][5];
                        mul_a[4][0] = img_deconv[4][0][1]; mul_a[4][1] = img_deconv[4][0][2]; mul_a[4][2] = img_deconv[4][0][3]; mul_a[4][3] = img_deconv[4][0][4]; mul_a[4][4] = img_deconv[4][0][5];
                    end
                    5: begin
                        mul_a[0][0] = img_deconv[0][0][2]; mul_a[0][1] = img_deconv[0][0][3]; mul_a[0][2] = img_deconv[0][0][4]; mul_a[0][3] = img_deconv[0][0][5]; mul_a[0][4] = img_deconv[0][0][6];
                        mul_a[1][0] = img_deconv[1][0][2]; mul_a[1][1] = img_deconv[1][0][3]; mul_a[1][2] = img_deconv[1][0][4]; mul_a[1][3] = img_deconv[1][0][5]; mul_a[1][4] = img_deconv[1][0][6];
                        mul_a[2][0] = img_deconv[2][0][2]; mul_a[2][1] = img_deconv[2][0][3]; mul_a[2][2] = img_deconv[2][0][4]; mul_a[2][3] = img_deconv[2][0][5]; mul_a[2][4] = img_deconv[2][0][6];
                        mul_a[3][0] = img_deconv[3][0][2]; mul_a[3][1] = img_deconv[3][0][3]; mul_a[3][2] = img_deconv[3][0][4]; mul_a[3][3] = img_deconv[3][0][5]; mul_a[3][4] = img_deconv[3][0][6];
                        mul_a[4][0] = img_deconv[4][0][2]; mul_a[4][1] = img_deconv[4][0][3]; mul_a[4][2] = img_deconv[4][0][4]; mul_a[4][3] = img_deconv[4][0][5]; mul_a[4][4] = img_deconv[4][0][6];
                    end
                    6: begin
                        mul_a[0][0] = img_deconv[0][0][3]; mul_a[0][1] = img_deconv[0][0][4]; mul_a[0][2] = img_deconv[0][0][5]; mul_a[0][3] = img_deconv[0][0][6]; mul_a[0][4] = img_deconv[0][0][7];
                        mul_a[1][0] = img_deconv[1][0][3]; mul_a[1][1] = img_deconv[1][0][4]; mul_a[1][2] = img_deconv[1][0][5]; mul_a[1][3] = img_deconv[1][0][6]; mul_a[1][4] = img_deconv[1][0][7];
                        mul_a[2][0] = img_deconv[2][0][3]; mul_a[2][1] = img_deconv[2][0][4]; mul_a[2][2] = img_deconv[2][0][5]; mul_a[2][3] = img_deconv[2][0][6]; mul_a[2][4] = img_deconv[2][0][7];
                        mul_a[3][0] = img_deconv[3][0][3]; mul_a[3][1] = img_deconv[3][0][4]; mul_a[3][2] = img_deconv[3][0][5]; mul_a[3][3] = img_deconv[3][0][6]; mul_a[3][4] = img_deconv[3][0][7];
                        mul_a[4][0] = img_deconv[4][0][3]; mul_a[4][1] = img_deconv[4][0][4]; mul_a[4][2] = img_deconv[4][0][5]; mul_a[4][3] = img_deconv[4][0][6]; mul_a[4][4] = img_deconv[4][0][7];
                    end
                    7: begin
                        mul_a[0][0] = img_deconv[0][0][4]; mul_a[0][1] = img_deconv[0][0][5]; mul_a[0][2] = img_deconv[0][0][6]; mul_a[0][3] = img_deconv[0][0][7]; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][0][4]; mul_a[1][1] = img_deconv[1][0][5]; mul_a[1][2] = img_deconv[1][0][6]; mul_a[1][3] = img_deconv[1][0][7]; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][0][4]; mul_a[2][1] = img_deconv[2][0][5]; mul_a[2][2] = img_deconv[2][0][6]; mul_a[2][3] = img_deconv[2][0][7]; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][0][4]; mul_a[3][1] = img_deconv[3][0][5]; mul_a[3][2] = img_deconv[3][0][6]; mul_a[3][3] = img_deconv[3][0][7]; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][0][4]; mul_a[4][1] = img_deconv[4][0][5]; mul_a[4][2] = img_deconv[4][0][6]; mul_a[4][3] = img_deconv[4][0][7]; mul_a[4][4] =                   0;
                    end
                    8: begin
                        mul_a[0][0] = img_deconv[0][0][5]; mul_a[0][1] = img_deconv[0][0][6]; mul_a[0][2] = img_deconv[0][0][7]; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][0][5]; mul_a[1][1] = img_deconv[1][0][6]; mul_a[1][2] = img_deconv[1][0][7]; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][0][5]; mul_a[2][1] = img_deconv[2][0][6]; mul_a[2][2] = img_deconv[2][0][7]; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][0][5]; mul_a[3][1] = img_deconv[3][0][6]; mul_a[3][2] = img_deconv[3][0][7]; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][0][5]; mul_a[4][1] = img_deconv[4][0][6]; mul_a[4][2] = img_deconv[4][0][7]; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    9: begin
                        mul_a[0][0] = img_deconv[0][0][6]; mul_a[0][1] = img_deconv[0][0][7]; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][0][6]; mul_a[1][1] = img_deconv[1][0][7]; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][0][6]; mul_a[2][1] = img_deconv[2][0][7]; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][0][6]; mul_a[3][1] = img_deconv[3][0][7]; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][0][6]; mul_a[4][1] = img_deconv[4][0][7]; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    10: begin
                        mul_a[0][0] = img_deconv[0][0][7]; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][0][7]; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][0][7]; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][0][7]; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][0][7]; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    default: begin
                        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = 0;
                        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] = 0;
                        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] = 0;
                        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] = 0;
                        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] = 0;
                    end
                endcase
            end
            else if(matrix_size_reg[0]) begin
                case (cnt_out_col)
                    19: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] = img_deconv[0][0][0];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] = img_deconv[1][0][0];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] = img_deconv[2][0][0];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] = img_deconv[3][0][0];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] = img_deconv[4][0][0];
                    end
                    0: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] = img_deconv[0][0][0]; mul_a[0][4] = img_deconv[0][0][1];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] = img_deconv[1][0][0]; mul_a[1][4] = img_deconv[1][0][1];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] = img_deconv[2][0][0]; mul_a[2][4] = img_deconv[2][0][1];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] = img_deconv[3][0][0]; mul_a[3][4] = img_deconv[3][0][1];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] = img_deconv[4][0][0]; mul_a[4][4] = img_deconv[4][0][1];
                    end 
                    1: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] = img_deconv[0][0][0]; mul_a[0][3] = img_deconv[0][0][1]; mul_a[0][4] = img_deconv[0][0][2];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] = img_deconv[1][0][0]; mul_a[1][3] = img_deconv[1][0][1]; mul_a[1][4] = img_deconv[1][0][2];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] = img_deconv[2][0][0]; mul_a[2][3] = img_deconv[2][0][1]; mul_a[2][4] = img_deconv[2][0][2];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] = img_deconv[3][0][0]; mul_a[3][3] = img_deconv[3][0][1]; mul_a[3][4] = img_deconv[3][0][2];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] = img_deconv[4][0][0]; mul_a[4][3] = img_deconv[4][0][1]; mul_a[4][4] = img_deconv[4][0][2];
                    end
                    2: begin
                        mul_a[0][0] =                   0; mul_a[0][1] = img_deconv[0][0][0]; mul_a[0][2] = img_deconv[0][0][1]; mul_a[0][3] = img_deconv[0][0][2]; mul_a[0][4] = img_deconv[0][0][3];
                        mul_a[1][0] =                   0; mul_a[1][1] = img_deconv[1][0][0]; mul_a[1][2] = img_deconv[1][0][1]; mul_a[1][3] = img_deconv[1][0][2]; mul_a[1][4] = img_deconv[1][0][3];
                        mul_a[2][0] =                   0; mul_a[2][1] = img_deconv[2][0][0]; mul_a[2][2] = img_deconv[2][0][1]; mul_a[2][3] = img_deconv[2][0][2]; mul_a[2][4] = img_deconv[2][0][3];
                        mul_a[3][0] =                   0; mul_a[3][1] = img_deconv[3][0][0]; mul_a[3][2] = img_deconv[3][0][1]; mul_a[3][3] = img_deconv[3][0][2]; mul_a[3][4] = img_deconv[3][0][3];
                        mul_a[4][0] =                   0; mul_a[4][1] = img_deconv[4][0][0]; mul_a[4][2] = img_deconv[4][0][1]; mul_a[4][3] = img_deconv[4][0][2]; mul_a[4][4] = img_deconv[4][0][3];
                    end
                    3: begin
                        mul_a[0][0] = img_deconv[0][0][0]; mul_a[0][1] = img_deconv[0][0][1]; mul_a[0][2] = img_deconv[0][0][2]; mul_a[0][3] = img_deconv[0][0][3]; mul_a[0][4] = img_deconv[0][0][4];
                        mul_a[1][0] = img_deconv[1][0][0]; mul_a[1][1] = img_deconv[1][0][1]; mul_a[1][2] = img_deconv[1][0][2]; mul_a[1][3] = img_deconv[1][0][3]; mul_a[1][4] = img_deconv[1][0][4];
                        mul_a[2][0] = img_deconv[2][0][0]; mul_a[2][1] = img_deconv[2][0][1]; mul_a[2][2] = img_deconv[2][0][2]; mul_a[2][3] = img_deconv[2][0][3]; mul_a[2][4] = img_deconv[2][0][4];
                        mul_a[3][0] = img_deconv[3][0][0]; mul_a[3][1] = img_deconv[3][0][1]; mul_a[3][2] = img_deconv[3][0][2]; mul_a[3][3] = img_deconv[3][0][3]; mul_a[3][4] = img_deconv[3][0][4];
                        mul_a[4][0] = img_deconv[4][0][0]; mul_a[4][1] = img_deconv[4][0][1]; mul_a[4][2] = img_deconv[4][0][2]; mul_a[4][3] = img_deconv[4][0][3]; mul_a[4][4] = img_deconv[4][0][4];
                    end
                    4: begin
                        mul_a[0][0] = img_deconv[0][0][1]; mul_a[0][1] = img_deconv[0][0][2]; mul_a[0][2] = img_deconv[0][0][3]; mul_a[0][3] = img_deconv[0][0][4]; mul_a[0][4] = img_deconv[0][0][5];
                        mul_a[1][0] = img_deconv[1][0][1]; mul_a[1][1] = img_deconv[1][0][2]; mul_a[1][2] = img_deconv[1][0][3]; mul_a[1][3] = img_deconv[1][0][4]; mul_a[1][4] = img_deconv[1][0][5];
                        mul_a[2][0] = img_deconv[2][0][1]; mul_a[2][1] = img_deconv[2][0][2]; mul_a[2][2] = img_deconv[2][0][3]; mul_a[2][3] = img_deconv[2][0][4]; mul_a[2][4] = img_deconv[2][0][5];
                        mul_a[3][0] = img_deconv[3][0][1]; mul_a[3][1] = img_deconv[3][0][2]; mul_a[3][2] = img_deconv[3][0][3]; mul_a[3][3] = img_deconv[3][0][4]; mul_a[3][4] = img_deconv[3][0][5];
                        mul_a[4][0] = img_deconv[4][0][1]; mul_a[4][1] = img_deconv[4][0][2]; mul_a[4][2] = img_deconv[4][0][3]; mul_a[4][3] = img_deconv[4][0][4]; mul_a[4][4] = img_deconv[4][0][5];
                    end
                    5: begin
                        mul_a[0][0] = img_deconv[0][0][2]; mul_a[0][1] = img_deconv[0][0][3]; mul_a[0][2] = img_deconv[0][0][4]; mul_a[0][3] = img_deconv[0][0][5]; mul_a[0][4] = img_deconv[0][0][6];
                        mul_a[1][0] = img_deconv[1][0][2]; mul_a[1][1] = img_deconv[1][0][3]; mul_a[1][2] = img_deconv[1][0][4]; mul_a[1][3] = img_deconv[1][0][5]; mul_a[1][4] = img_deconv[1][0][6];
                        mul_a[2][0] = img_deconv[2][0][2]; mul_a[2][1] = img_deconv[2][0][3]; mul_a[2][2] = img_deconv[2][0][4]; mul_a[2][3] = img_deconv[2][0][5]; mul_a[2][4] = img_deconv[2][0][6];
                        mul_a[3][0] = img_deconv[3][0][2]; mul_a[3][1] = img_deconv[3][0][3]; mul_a[3][2] = img_deconv[3][0][4]; mul_a[3][3] = img_deconv[3][0][5]; mul_a[3][4] = img_deconv[3][0][6];
                        mul_a[4][0] = img_deconv[4][0][2]; mul_a[4][1] = img_deconv[4][0][3]; mul_a[4][2] = img_deconv[4][0][4]; mul_a[4][3] = img_deconv[4][0][5]; mul_a[4][4] = img_deconv[4][0][6];
                    end
                    6: begin
                        mul_a[0][0] = img_deconv[0][0][3]; mul_a[0][1] = img_deconv[0][0][4]; mul_a[0][2] = img_deconv[0][0][5]; mul_a[0][3] = img_deconv[0][0][6]; mul_a[0][4] = img_deconv[0][0][7];
                        mul_a[1][0] = img_deconv[1][0][3]; mul_a[1][1] = img_deconv[1][0][4]; mul_a[1][2] = img_deconv[1][0][5]; mul_a[1][3] = img_deconv[1][0][6]; mul_a[1][4] = img_deconv[1][0][7];
                        mul_a[2][0] = img_deconv[2][0][3]; mul_a[2][1] = img_deconv[2][0][4]; mul_a[2][2] = img_deconv[2][0][5]; mul_a[2][3] = img_deconv[2][0][6]; mul_a[2][4] = img_deconv[2][0][7];
                        mul_a[3][0] = img_deconv[3][0][3]; mul_a[3][1] = img_deconv[3][0][4]; mul_a[3][2] = img_deconv[3][0][5]; mul_a[3][3] = img_deconv[3][0][6]; mul_a[3][4] = img_deconv[3][0][7];
                        mul_a[4][0] = img_deconv[4][0][3]; mul_a[4][1] = img_deconv[4][0][4]; mul_a[4][2] = img_deconv[4][0][5]; mul_a[4][3] = img_deconv[4][0][6]; mul_a[4][4] = img_deconv[4][0][7];
                    end
                    7: begin
                        mul_a[0][0] = img_deconv[0][0][4]; mul_a[0][1] = img_deconv[0][0][5]; mul_a[0][2] = img_deconv[0][0][6]; mul_a[0][3] = img_deconv[0][0][7]; mul_a[0][4] = img_deconv[0][1][0];
                        mul_a[1][0] = img_deconv[1][0][4]; mul_a[1][1] = img_deconv[1][0][5]; mul_a[1][2] = img_deconv[1][0][6]; mul_a[1][3] = img_deconv[1][0][7]; mul_a[1][4] = img_deconv[1][1][0];
                        mul_a[2][0] = img_deconv[2][0][4]; mul_a[2][1] = img_deconv[2][0][5]; mul_a[2][2] = img_deconv[2][0][6]; mul_a[2][3] = img_deconv[2][0][7]; mul_a[2][4] = img_deconv[2][1][0];
                        mul_a[3][0] = img_deconv[3][0][4]; mul_a[3][1] = img_deconv[3][0][5]; mul_a[3][2] = img_deconv[3][0][6]; mul_a[3][3] = img_deconv[3][0][7]; mul_a[3][4] = img_deconv[3][1][0];
                        mul_a[4][0] = img_deconv[4][0][4]; mul_a[4][1] = img_deconv[4][0][5]; mul_a[4][2] = img_deconv[4][0][6]; mul_a[4][3] = img_deconv[4][0][7]; mul_a[4][4] = img_deconv[4][1][0];
                    end
                    8: begin
                        mul_a[0][0] = img_deconv[0][0][5]; mul_a[0][1] = img_deconv[0][0][6]; mul_a[0][2] = img_deconv[0][0][7]; mul_a[0][3] = img_deconv[0][1][0]; mul_a[0][4] = img_deconv[0][1][1];
                        mul_a[1][0] = img_deconv[1][0][5]; mul_a[1][1] = img_deconv[1][0][6]; mul_a[1][2] = img_deconv[1][0][7]; mul_a[1][3] = img_deconv[1][1][0]; mul_a[1][4] = img_deconv[1][1][1];
                        mul_a[2][0] = img_deconv[2][0][5]; mul_a[2][1] = img_deconv[2][0][6]; mul_a[2][2] = img_deconv[2][0][7]; mul_a[2][3] = img_deconv[2][1][0]; mul_a[2][4] = img_deconv[2][1][1];
                        mul_a[3][0] = img_deconv[3][0][5]; mul_a[3][1] = img_deconv[3][0][6]; mul_a[3][2] = img_deconv[3][0][7]; mul_a[3][3] = img_deconv[3][1][0]; mul_a[3][4] = img_deconv[3][1][1];
                        mul_a[4][0] = img_deconv[4][0][5]; mul_a[4][1] = img_deconv[4][0][6]; mul_a[4][2] = img_deconv[4][0][7]; mul_a[4][3] = img_deconv[4][1][0]; mul_a[4][4] = img_deconv[4][1][1];
                    end
                    9: begin
                        mul_a[0][0] = img_deconv[0][0][6]; mul_a[0][1] = img_deconv[0][0][7]; mul_a[0][2] = img_deconv[0][1][0]; mul_a[0][3] = img_deconv[0][1][1]; mul_a[0][4] = img_deconv[0][1][2];
                        mul_a[1][0] = img_deconv[1][0][6]; mul_a[1][1] = img_deconv[1][0][7]; mul_a[1][2] = img_deconv[1][1][0]; mul_a[1][3] = img_deconv[1][1][1]; mul_a[1][4] = img_deconv[1][1][2];
                        mul_a[2][0] = img_deconv[2][0][6]; mul_a[2][1] = img_deconv[2][0][7]; mul_a[2][2] = img_deconv[2][1][0]; mul_a[2][3] = img_deconv[2][1][1]; mul_a[2][4] = img_deconv[2][1][2];
                        mul_a[3][0] = img_deconv[3][0][6]; mul_a[3][1] = img_deconv[3][0][7]; mul_a[3][2] = img_deconv[3][1][0]; mul_a[3][3] = img_deconv[3][1][1]; mul_a[3][4] = img_deconv[3][1][2];
                        mul_a[4][0] = img_deconv[4][0][6]; mul_a[4][1] = img_deconv[4][0][7]; mul_a[4][2] = img_deconv[4][1][0]; mul_a[4][3] = img_deconv[4][1][1]; mul_a[4][4] = img_deconv[4][1][2];
                    end
                    10: begin
                        mul_a[0][0] = img_deconv[0][0][7]; mul_a[0][1] = img_deconv[0][1][0]; mul_a[0][2] = img_deconv[0][1][1]; mul_a[0][3] = img_deconv[0][1][2]; mul_a[0][4] = img_deconv[0][1][3];
                        mul_a[1][0] = img_deconv[1][0][7]; mul_a[1][1] = img_deconv[1][1][0]; mul_a[1][2] = img_deconv[1][1][1]; mul_a[1][3] = img_deconv[1][1][2]; mul_a[1][4] = img_deconv[1][1][3];
                        mul_a[2][0] = img_deconv[2][0][7]; mul_a[2][1] = img_deconv[2][1][0]; mul_a[2][2] = img_deconv[2][1][1]; mul_a[2][3] = img_deconv[2][1][2]; mul_a[2][4] = img_deconv[2][1][3];
                        mul_a[3][0] = img_deconv[3][0][7]; mul_a[3][1] = img_deconv[3][1][0]; mul_a[3][2] = img_deconv[3][1][1]; mul_a[3][3] = img_deconv[3][1][2]; mul_a[3][4] = img_deconv[3][1][3];
                        mul_a[4][0] = img_deconv[4][0][7]; mul_a[4][1] = img_deconv[4][1][0]; mul_a[4][2] = img_deconv[4][1][1]; mul_a[4][3] = img_deconv[4][1][2]; mul_a[4][4] = img_deconv[4][1][3];
                    end
                    11: begin
                        mul_a[0][0] = img_deconv[0][1][0]; mul_a[0][1] = img_deconv[0][1][1]; mul_a[0][2] = img_deconv[0][1][2]; mul_a[0][3] = img_deconv[0][1][3]; mul_a[0][4] = img_deconv[0][1][4];
                        mul_a[1][0] = img_deconv[1][1][0]; mul_a[1][1] = img_deconv[1][1][1]; mul_a[1][2] = img_deconv[1][1][2]; mul_a[1][3] = img_deconv[1][1][3]; mul_a[1][4] = img_deconv[1][1][4];
                        mul_a[2][0] = img_deconv[2][1][0]; mul_a[2][1] = img_deconv[2][1][1]; mul_a[2][2] = img_deconv[2][1][2]; mul_a[2][3] = img_deconv[2][1][3]; mul_a[2][4] = img_deconv[2][1][4];
                        mul_a[3][0] = img_deconv[3][1][0]; mul_a[3][1] = img_deconv[3][1][1]; mul_a[3][2] = img_deconv[3][1][2]; mul_a[3][3] = img_deconv[3][1][3]; mul_a[3][4] = img_deconv[3][1][4];
                        mul_a[4][0] = img_deconv[4][1][0]; mul_a[4][1] = img_deconv[4][1][1]; mul_a[4][2] = img_deconv[4][1][2]; mul_a[4][3] = img_deconv[4][1][3]; mul_a[4][4] = img_deconv[4][1][4];
                    end
                    12: begin
                        mul_a[0][0] = img_deconv[0][1][1]; mul_a[0][1] = img_deconv[0][1][2]; mul_a[0][2] = img_deconv[0][1][3]; mul_a[0][3] = img_deconv[0][1][4]; mul_a[0][4] = img_deconv[0][1][5];
                        mul_a[1][0] = img_deconv[1][1][1]; mul_a[1][1] = img_deconv[1][1][2]; mul_a[1][2] = img_deconv[1][1][3]; mul_a[1][3] = img_deconv[1][1][4]; mul_a[1][4] = img_deconv[1][1][5];
                        mul_a[2][0] = img_deconv[2][1][1]; mul_a[2][1] = img_deconv[2][1][2]; mul_a[2][2] = img_deconv[2][1][3]; mul_a[2][3] = img_deconv[2][1][4]; mul_a[2][4] = img_deconv[2][1][5];
                        mul_a[3][0] = img_deconv[3][1][1]; mul_a[3][1] = img_deconv[3][1][2]; mul_a[3][2] = img_deconv[3][1][3]; mul_a[3][3] = img_deconv[3][1][4]; mul_a[3][4] = img_deconv[3][1][5];
                        mul_a[4][0] = img_deconv[4][1][1]; mul_a[4][1] = img_deconv[4][1][2]; mul_a[4][2] = img_deconv[4][1][3]; mul_a[4][3] = img_deconv[4][1][4]; mul_a[4][4] = img_deconv[4][1][5];
                    end
                    13: begin
                        mul_a[0][0] = img_deconv[0][1][2]; mul_a[0][1] = img_deconv[0][1][3]; mul_a[0][2] = img_deconv[0][1][4]; mul_a[0][3] = img_deconv[0][1][5]; mul_a[0][4] = img_deconv[0][1][6];
                        mul_a[1][0] = img_deconv[1][1][2]; mul_a[1][1] = img_deconv[1][1][3]; mul_a[1][2] = img_deconv[1][1][4]; mul_a[1][3] = img_deconv[1][1][5]; mul_a[1][4] = img_deconv[1][1][6];
                        mul_a[2][0] = img_deconv[2][1][2]; mul_a[2][1] = img_deconv[2][1][3]; mul_a[2][2] = img_deconv[2][1][4]; mul_a[2][3] = img_deconv[2][1][5]; mul_a[2][4] = img_deconv[2][1][6];
                        mul_a[3][0] = img_deconv[3][1][2]; mul_a[3][1] = img_deconv[3][1][3]; mul_a[3][2] = img_deconv[3][1][4]; mul_a[3][3] = img_deconv[3][1][5]; mul_a[3][4] = img_deconv[3][1][6];
                        mul_a[4][0] = img_deconv[4][1][2]; mul_a[4][1] = img_deconv[4][1][3]; mul_a[4][2] = img_deconv[4][1][4]; mul_a[4][3] = img_deconv[4][1][5]; mul_a[4][4] = img_deconv[4][1][6];
                    end
                    14: begin
                        mul_a[0][0] = img_deconv[0][1][3]; mul_a[0][1] = img_deconv[0][1][4]; mul_a[0][2] = img_deconv[0][1][5]; mul_a[0][3] = img_deconv[0][1][6]; mul_a[0][4] = img_deconv[0][1][7];
                        mul_a[1][0] = img_deconv[1][1][3]; mul_a[1][1] = img_deconv[1][1][4]; mul_a[1][2] = img_deconv[1][1][5]; mul_a[1][3] = img_deconv[1][1][6]; mul_a[1][4] = img_deconv[1][1][7];
                        mul_a[2][0] = img_deconv[2][1][3]; mul_a[2][1] = img_deconv[2][1][4]; mul_a[2][2] = img_deconv[2][1][5]; mul_a[2][3] = img_deconv[2][1][6]; mul_a[2][4] = img_deconv[2][1][7];
                        mul_a[3][0] = img_deconv[3][1][3]; mul_a[3][1] = img_deconv[3][1][4]; mul_a[3][2] = img_deconv[3][1][5]; mul_a[3][3] = img_deconv[3][1][6]; mul_a[3][4] = img_deconv[3][1][7];
                        mul_a[4][0] = img_deconv[4][1][3]; mul_a[4][1] = img_deconv[4][1][4]; mul_a[4][2] = img_deconv[4][1][5]; mul_a[4][3] = img_deconv[4][1][6]; mul_a[4][4] = img_deconv[4][1][7];
                    end
                    15: begin
                        mul_a[0][0] = img_deconv[0][1][4]; mul_a[0][1] = img_deconv[0][1][5]; mul_a[0][2] = img_deconv[0][1][6]; mul_a[0][3] = img_deconv[0][1][7]; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][4]; mul_a[1][1] = img_deconv[1][1][5]; mul_a[1][2] = img_deconv[1][1][6]; mul_a[1][3] = img_deconv[1][1][7]; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][4]; mul_a[2][1] = img_deconv[2][1][5]; mul_a[2][2] = img_deconv[2][1][6]; mul_a[2][3] = img_deconv[2][1][7]; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][4]; mul_a[3][1] = img_deconv[3][1][5]; mul_a[3][2] = img_deconv[3][1][6]; mul_a[3][3] = img_deconv[3][1][7]; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][4]; mul_a[4][1] = img_deconv[4][1][5]; mul_a[4][2] = img_deconv[4][1][6]; mul_a[4][3] = img_deconv[4][1][7]; mul_a[4][4] =                   0;
                    end
                    16: begin
                        mul_a[0][0] = img_deconv[0][1][5]; mul_a[0][1] = img_deconv[0][1][6]; mul_a[0][2] = img_deconv[0][1][7]; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][5]; mul_a[1][1] = img_deconv[1][1][6]; mul_a[1][2] = img_deconv[1][1][7]; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][5]; mul_a[2][1] = img_deconv[2][1][6]; mul_a[2][2] = img_deconv[2][1][7]; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][5]; mul_a[3][1] = img_deconv[3][1][6]; mul_a[3][2] = img_deconv[3][1][7]; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][5]; mul_a[4][1] = img_deconv[4][1][6]; mul_a[4][2] = img_deconv[4][1][7]; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    17: begin
                        mul_a[0][0] = img_deconv[0][1][6]; mul_a[0][1] = img_deconv[0][1][7]; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][6]; mul_a[1][1] = img_deconv[1][1][7]; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][6]; mul_a[2][1] = img_deconv[2][1][7]; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][6]; mul_a[3][1] = img_deconv[3][1][7]; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][6]; mul_a[4][1] = img_deconv[4][1][7]; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    18: begin
                        mul_a[0][0] = img_deconv[0][1][7]; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][7]; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][7]; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][7]; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][7]; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    default: begin
                        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = 0;
                        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] = 0;
                        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] = 0;
                        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] = 0;
                        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] = 0;
                    end
                endcase
            end
            else begin
                case (cnt_out_col)
                    35: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] = img_deconv[0][0][0];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] = img_deconv[1][0][0];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] = img_deconv[2][0][0];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] = img_deconv[3][0][0];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] = img_deconv[4][0][0];
                    end
                    0: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] = img_deconv[0][0][0]; mul_a[0][4] = img_deconv[0][0][1];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] = img_deconv[1][0][0]; mul_a[1][4] = img_deconv[1][0][1];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] = img_deconv[2][0][0]; mul_a[2][4] = img_deconv[2][0][1];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] = img_deconv[3][0][0]; mul_a[3][4] = img_deconv[3][0][1];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] = img_deconv[4][0][0]; mul_a[4][4] = img_deconv[4][0][1];
                    end 
                    1: begin
                        mul_a[0][0] =                   0; mul_a[0][1] =                   0; mul_a[0][2] = img_deconv[0][0][0]; mul_a[0][3] = img_deconv[0][0][1]; mul_a[0][4] = img_deconv[0][0][2];
                        mul_a[1][0] =                   0; mul_a[1][1] =                   0; mul_a[1][2] = img_deconv[1][0][0]; mul_a[1][3] = img_deconv[1][0][1]; mul_a[1][4] = img_deconv[1][0][2];
                        mul_a[2][0] =                   0; mul_a[2][1] =                   0; mul_a[2][2] = img_deconv[2][0][0]; mul_a[2][3] = img_deconv[2][0][1]; mul_a[2][4] = img_deconv[2][0][2];
                        mul_a[3][0] =                   0; mul_a[3][1] =                   0; mul_a[3][2] = img_deconv[3][0][0]; mul_a[3][3] = img_deconv[3][0][1]; mul_a[3][4] = img_deconv[3][0][2];
                        mul_a[4][0] =                   0; mul_a[4][1] =                   0; mul_a[4][2] = img_deconv[4][0][0]; mul_a[4][3] = img_deconv[4][0][1]; mul_a[4][4] = img_deconv[4][0][2];
                    end
                    2: begin
                        mul_a[0][0] =                   0; mul_a[0][1] = img_deconv[0][0][0]; mul_a[0][2] = img_deconv[0][0][1]; mul_a[0][3] = img_deconv[0][0][2]; mul_a[0][4] = img_deconv[0][0][3];
                        mul_a[1][0] =                   0; mul_a[1][1] = img_deconv[1][0][0]; mul_a[1][2] = img_deconv[1][0][1]; mul_a[1][3] = img_deconv[1][0][2]; mul_a[1][4] = img_deconv[1][0][3];
                        mul_a[2][0] =                   0; mul_a[2][1] = img_deconv[2][0][0]; mul_a[2][2] = img_deconv[2][0][1]; mul_a[2][3] = img_deconv[2][0][2]; mul_a[2][4] = img_deconv[2][0][3];
                        mul_a[3][0] =                   0; mul_a[3][1] = img_deconv[3][0][0]; mul_a[3][2] = img_deconv[3][0][1]; mul_a[3][3] = img_deconv[3][0][2]; mul_a[3][4] = img_deconv[3][0][3];
                        mul_a[4][0] =                   0; mul_a[4][1] = img_deconv[4][0][0]; mul_a[4][2] = img_deconv[4][0][1]; mul_a[4][3] = img_deconv[4][0][2]; mul_a[4][4] = img_deconv[4][0][3];
                    end
                    3, 11, 19: begin
                        mul_a[0][0] = img_deconv[0][0][0]; mul_a[0][1] = img_deconv[0][0][1]; mul_a[0][2] = img_deconv[0][0][2]; mul_a[0][3] = img_deconv[0][0][3]; mul_a[0][4] = img_deconv[0][0][4];
                        mul_a[1][0] = img_deconv[1][0][0]; mul_a[1][1] = img_deconv[1][0][1]; mul_a[1][2] = img_deconv[1][0][2]; mul_a[1][3] = img_deconv[1][0][3]; mul_a[1][4] = img_deconv[1][0][4];
                        mul_a[2][0] = img_deconv[2][0][0]; mul_a[2][1] = img_deconv[2][0][1]; mul_a[2][2] = img_deconv[2][0][2]; mul_a[2][3] = img_deconv[2][0][3]; mul_a[2][4] = img_deconv[2][0][4];
                        mul_a[3][0] = img_deconv[3][0][0]; mul_a[3][1] = img_deconv[3][0][1]; mul_a[3][2] = img_deconv[3][0][2]; mul_a[3][3] = img_deconv[3][0][3]; mul_a[3][4] = img_deconv[3][0][4];
                        mul_a[4][0] = img_deconv[4][0][0]; mul_a[4][1] = img_deconv[4][0][1]; mul_a[4][2] = img_deconv[4][0][2]; mul_a[4][3] = img_deconv[4][0][3]; mul_a[4][4] = img_deconv[4][0][4];
                    end
                    4, 12, 20: begin
                        mul_a[0][0] = img_deconv[0][0][1]; mul_a[0][1] = img_deconv[0][0][2]; mul_a[0][2] = img_deconv[0][0][3]; mul_a[0][3] = img_deconv[0][0][4]; mul_a[0][4] = img_deconv[0][0][5];
                        mul_a[1][0] = img_deconv[1][0][1]; mul_a[1][1] = img_deconv[1][0][2]; mul_a[1][2] = img_deconv[1][0][3]; mul_a[1][3] = img_deconv[1][0][4]; mul_a[1][4] = img_deconv[1][0][5];
                        mul_a[2][0] = img_deconv[2][0][1]; mul_a[2][1] = img_deconv[2][0][2]; mul_a[2][2] = img_deconv[2][0][3]; mul_a[2][3] = img_deconv[2][0][4]; mul_a[2][4] = img_deconv[2][0][5];
                        mul_a[3][0] = img_deconv[3][0][1]; mul_a[3][1] = img_deconv[3][0][2]; mul_a[3][2] = img_deconv[3][0][3]; mul_a[3][3] = img_deconv[3][0][4]; mul_a[3][4] = img_deconv[3][0][5];
                        mul_a[4][0] = img_deconv[4][0][1]; mul_a[4][1] = img_deconv[4][0][2]; mul_a[4][2] = img_deconv[4][0][3]; mul_a[4][3] = img_deconv[4][0][4]; mul_a[4][4] = img_deconv[4][0][5];
                    end
                    5, 13, 21: begin
                        mul_a[0][0] = img_deconv[0][0][2]; mul_a[0][1] = img_deconv[0][0][3]; mul_a[0][2] = img_deconv[0][0][4]; mul_a[0][3] = img_deconv[0][0][5]; mul_a[0][4] = img_deconv[0][0][6];
                        mul_a[1][0] = img_deconv[1][0][2]; mul_a[1][1] = img_deconv[1][0][3]; mul_a[1][2] = img_deconv[1][0][4]; mul_a[1][3] = img_deconv[1][0][5]; mul_a[1][4] = img_deconv[1][0][6];
                        mul_a[2][0] = img_deconv[2][0][2]; mul_a[2][1] = img_deconv[2][0][3]; mul_a[2][2] = img_deconv[2][0][4]; mul_a[2][3] = img_deconv[2][0][5]; mul_a[2][4] = img_deconv[2][0][6];
                        mul_a[3][0] = img_deconv[3][0][2]; mul_a[3][1] = img_deconv[3][0][3]; mul_a[3][2] = img_deconv[3][0][4]; mul_a[3][3] = img_deconv[3][0][5]; mul_a[3][4] = img_deconv[3][0][6];
                        mul_a[4][0] = img_deconv[4][0][2]; mul_a[4][1] = img_deconv[4][0][3]; mul_a[4][2] = img_deconv[4][0][4]; mul_a[4][3] = img_deconv[4][0][5]; mul_a[4][4] = img_deconv[4][0][6];
                    end
                    6, 14, 22: begin
                        mul_a[0][0] = img_deconv[0][0][3]; mul_a[0][1] = img_deconv[0][0][4]; mul_a[0][2] = img_deconv[0][0][5]; mul_a[0][3] = img_deconv[0][0][6]; mul_a[0][4] = img_deconv[0][0][7];
                        mul_a[1][0] = img_deconv[1][0][3]; mul_a[1][1] = img_deconv[1][0][4]; mul_a[1][2] = img_deconv[1][0][5]; mul_a[1][3] = img_deconv[1][0][6]; mul_a[1][4] = img_deconv[1][0][7];
                        mul_a[2][0] = img_deconv[2][0][3]; mul_a[2][1] = img_deconv[2][0][4]; mul_a[2][2] = img_deconv[2][0][5]; mul_a[2][3] = img_deconv[2][0][6]; mul_a[2][4] = img_deconv[2][0][7];
                        mul_a[3][0] = img_deconv[3][0][3]; mul_a[3][1] = img_deconv[3][0][4]; mul_a[3][2] = img_deconv[3][0][5]; mul_a[3][3] = img_deconv[3][0][6]; mul_a[3][4] = img_deconv[3][0][7];
                        mul_a[4][0] = img_deconv[4][0][3]; mul_a[4][1] = img_deconv[4][0][4]; mul_a[4][2] = img_deconv[4][0][5]; mul_a[4][3] = img_deconv[4][0][6]; mul_a[4][4] = img_deconv[4][0][7];
                    end
                    7, 15, 23: begin
                        mul_a[0][0] = img_deconv[0][0][4]; mul_a[0][1] = img_deconv[0][0][5]; mul_a[0][2] = img_deconv[0][0][6]; mul_a[0][3] = img_deconv[0][0][7]; mul_a[0][4] = img_deconv[0][1][0];
                        mul_a[1][0] = img_deconv[1][0][4]; mul_a[1][1] = img_deconv[1][0][5]; mul_a[1][2] = img_deconv[1][0][6]; mul_a[1][3] = img_deconv[1][0][7]; mul_a[1][4] = img_deconv[1][1][0];
                        mul_a[2][0] = img_deconv[2][0][4]; mul_a[2][1] = img_deconv[2][0][5]; mul_a[2][2] = img_deconv[2][0][6]; mul_a[2][3] = img_deconv[2][0][7]; mul_a[2][4] = img_deconv[2][1][0];
                        mul_a[3][0] = img_deconv[3][0][4]; mul_a[3][1] = img_deconv[3][0][5]; mul_a[3][2] = img_deconv[3][0][6]; mul_a[3][3] = img_deconv[3][0][7]; mul_a[3][4] = img_deconv[3][1][0];
                        mul_a[4][0] = img_deconv[4][0][4]; mul_a[4][1] = img_deconv[4][0][5]; mul_a[4][2] = img_deconv[4][0][6]; mul_a[4][3] = img_deconv[4][0][7]; mul_a[4][4] = img_deconv[4][1][0];
                    end
                    8, 16, 24: begin
                        mul_a[0][0] = img_deconv[0][0][5]; mul_a[0][1] = img_deconv[0][0][6]; mul_a[0][2] = img_deconv[0][0][7]; mul_a[0][3] = img_deconv[0][1][0]; mul_a[0][4] = img_deconv[0][1][1];
                        mul_a[1][0] = img_deconv[1][0][5]; mul_a[1][1] = img_deconv[1][0][6]; mul_a[1][2] = img_deconv[1][0][7]; mul_a[1][3] = img_deconv[1][1][0]; mul_a[1][4] = img_deconv[1][1][1];
                        mul_a[2][0] = img_deconv[2][0][5]; mul_a[2][1] = img_deconv[2][0][6]; mul_a[2][2] = img_deconv[2][0][7]; mul_a[2][3] = img_deconv[2][1][0]; mul_a[2][4] = img_deconv[2][1][1];
                        mul_a[3][0] = img_deconv[3][0][5]; mul_a[3][1] = img_deconv[3][0][6]; mul_a[3][2] = img_deconv[3][0][7]; mul_a[3][3] = img_deconv[3][1][0]; mul_a[3][4] = img_deconv[3][1][1];
                        mul_a[4][0] = img_deconv[4][0][5]; mul_a[4][1] = img_deconv[4][0][6]; mul_a[4][2] = img_deconv[4][0][7]; mul_a[4][3] = img_deconv[4][1][0]; mul_a[4][4] = img_deconv[4][1][1];
                    end
                    9, 17, 25: begin
                        mul_a[0][0] = img_deconv[0][0][6]; mul_a[0][1] = img_deconv[0][0][7]; mul_a[0][2] = img_deconv[0][1][0]; mul_a[0][3] = img_deconv[0][1][1]; mul_a[0][4] = img_deconv[0][1][2];
                        mul_a[1][0] = img_deconv[1][0][6]; mul_a[1][1] = img_deconv[1][0][7]; mul_a[1][2] = img_deconv[1][1][0]; mul_a[1][3] = img_deconv[1][1][1]; mul_a[1][4] = img_deconv[1][1][2];
                        mul_a[2][0] = img_deconv[2][0][6]; mul_a[2][1] = img_deconv[2][0][7]; mul_a[2][2] = img_deconv[2][1][0]; mul_a[2][3] = img_deconv[2][1][1]; mul_a[2][4] = img_deconv[2][1][2];
                        mul_a[3][0] = img_deconv[3][0][6]; mul_a[3][1] = img_deconv[3][0][7]; mul_a[3][2] = img_deconv[3][1][0]; mul_a[3][3] = img_deconv[3][1][1]; mul_a[3][4] = img_deconv[3][1][2];
                        mul_a[4][0] = img_deconv[4][0][6]; mul_a[4][1] = img_deconv[4][0][7]; mul_a[4][2] = img_deconv[4][1][0]; mul_a[4][3] = img_deconv[4][1][1]; mul_a[4][4] = img_deconv[4][1][2];
                    end
                    10, 18, 26: begin
                        mul_a[0][0] = img_deconv[0][0][7]; mul_a[0][1] = img_deconv[0][1][0]; mul_a[0][2] = img_deconv[0][1][1]; mul_a[0][3] = img_deconv[0][1][2]; mul_a[0][4] = img_deconv[0][1][3];
                        mul_a[1][0] = img_deconv[1][0][7]; mul_a[1][1] = img_deconv[1][1][0]; mul_a[1][2] = img_deconv[1][1][1]; mul_a[1][3] = img_deconv[1][1][2]; mul_a[1][4] = img_deconv[1][1][3];
                        mul_a[2][0] = img_deconv[2][0][7]; mul_a[2][1] = img_deconv[2][1][0]; mul_a[2][2] = img_deconv[2][1][1]; mul_a[2][3] = img_deconv[2][1][2]; mul_a[2][4] = img_deconv[2][1][3];
                        mul_a[3][0] = img_deconv[3][0][7]; mul_a[3][1] = img_deconv[3][1][0]; mul_a[3][2] = img_deconv[3][1][1]; mul_a[3][3] = img_deconv[3][1][2]; mul_a[3][4] = img_deconv[3][1][3];
                        mul_a[4][0] = img_deconv[4][0][7]; mul_a[4][1] = img_deconv[4][1][0]; mul_a[4][2] = img_deconv[4][1][1]; mul_a[4][3] = img_deconv[4][1][2]; mul_a[4][4] = img_deconv[4][1][3];
                    end
                    27: begin
                        mul_a[0][0] = img_deconv[0][1][0]; mul_a[0][1] = img_deconv[0][1][1]; mul_a[0][2] = img_deconv[0][1][2]; mul_a[0][3] = img_deconv[0][1][3]; mul_a[0][4] = img_deconv[0][1][4];
                        mul_a[1][0] = img_deconv[1][1][0]; mul_a[1][1] = img_deconv[1][1][1]; mul_a[1][2] = img_deconv[1][1][2]; mul_a[1][3] = img_deconv[1][1][3]; mul_a[1][4] = img_deconv[1][1][4];
                        mul_a[2][0] = img_deconv[2][1][0]; mul_a[2][1] = img_deconv[2][1][1]; mul_a[2][2] = img_deconv[2][1][2]; mul_a[2][3] = img_deconv[2][1][3]; mul_a[2][4] = img_deconv[2][1][4];
                        mul_a[3][0] = img_deconv[3][1][0]; mul_a[3][1] = img_deconv[3][1][1]; mul_a[3][2] = img_deconv[3][1][2]; mul_a[3][3] = img_deconv[3][1][3]; mul_a[3][4] = img_deconv[3][1][4];
                        mul_a[4][0] = img_deconv[4][1][0]; mul_a[4][1] = img_deconv[4][1][1]; mul_a[4][2] = img_deconv[4][1][2]; mul_a[4][3] = img_deconv[4][1][3]; mul_a[4][4] = img_deconv[4][1][4];
                    end
                    28: begin
                        mul_a[0][0] = img_deconv[0][1][1]; mul_a[0][1] = img_deconv[0][1][2]; mul_a[0][2] = img_deconv[0][1][3]; mul_a[0][3] = img_deconv[0][1][4]; mul_a[0][4] = img_deconv[0][1][5];
                        mul_a[1][0] = img_deconv[1][1][1]; mul_a[1][1] = img_deconv[1][1][2]; mul_a[1][2] = img_deconv[1][1][3]; mul_a[1][3] = img_deconv[1][1][4]; mul_a[1][4] = img_deconv[1][1][5];
                        mul_a[2][0] = img_deconv[2][1][1]; mul_a[2][1] = img_deconv[2][1][2]; mul_a[2][2] = img_deconv[2][1][3]; mul_a[2][3] = img_deconv[2][1][4]; mul_a[2][4] = img_deconv[2][1][5];
                        mul_a[3][0] = img_deconv[3][1][1]; mul_a[3][1] = img_deconv[3][1][2]; mul_a[3][2] = img_deconv[3][1][3]; mul_a[3][3] = img_deconv[3][1][4]; mul_a[3][4] = img_deconv[3][1][5];
                        mul_a[4][0] = img_deconv[4][1][1]; mul_a[4][1] = img_deconv[4][1][2]; mul_a[4][2] = img_deconv[4][1][3]; mul_a[4][3] = img_deconv[4][1][4]; mul_a[4][4] = img_deconv[4][1][5];
                    end
                    29: begin
                        mul_a[0][0] = img_deconv[0][1][2]; mul_a[0][1] = img_deconv[0][1][3]; mul_a[0][2] = img_deconv[0][1][4]; mul_a[0][3] = img_deconv[0][1][5]; mul_a[0][4] = img_deconv[0][1][6];
                        mul_a[1][0] = img_deconv[1][1][2]; mul_a[1][1] = img_deconv[1][1][3]; mul_a[1][2] = img_deconv[1][1][4]; mul_a[1][3] = img_deconv[1][1][5]; mul_a[1][4] = img_deconv[1][1][6];
                        mul_a[2][0] = img_deconv[2][1][2]; mul_a[2][1] = img_deconv[2][1][3]; mul_a[2][2] = img_deconv[2][1][4]; mul_a[2][3] = img_deconv[2][1][5]; mul_a[2][4] = img_deconv[2][1][6];
                        mul_a[3][0] = img_deconv[3][1][2]; mul_a[3][1] = img_deconv[3][1][3]; mul_a[3][2] = img_deconv[3][1][4]; mul_a[3][3] = img_deconv[3][1][5]; mul_a[3][4] = img_deconv[3][1][6];
                        mul_a[4][0] = img_deconv[4][1][2]; mul_a[4][1] = img_deconv[4][1][3]; mul_a[4][2] = img_deconv[4][1][4]; mul_a[4][3] = img_deconv[4][1][5]; mul_a[4][4] = img_deconv[4][1][6];
                    end
                    30: begin
                        mul_a[0][0] = img_deconv[0][1][3]; mul_a[0][1] = img_deconv[0][1][4]; mul_a[0][2] = img_deconv[0][1][5]; mul_a[0][3] = img_deconv[0][1][6]; mul_a[0][4] = img_deconv[0][1][7];
                        mul_a[1][0] = img_deconv[1][1][3]; mul_a[1][1] = img_deconv[1][1][4]; mul_a[1][2] = img_deconv[1][1][5]; mul_a[1][3] = img_deconv[1][1][6]; mul_a[1][4] = img_deconv[1][1][7];
                        mul_a[2][0] = img_deconv[2][1][3]; mul_a[2][1] = img_deconv[2][1][4]; mul_a[2][2] = img_deconv[2][1][5]; mul_a[2][3] = img_deconv[2][1][6]; mul_a[2][4] = img_deconv[2][1][7];
                        mul_a[3][0] = img_deconv[3][1][3]; mul_a[3][1] = img_deconv[3][1][4]; mul_a[3][2] = img_deconv[3][1][5]; mul_a[3][3] = img_deconv[3][1][6]; mul_a[3][4] = img_deconv[3][1][7];
                        mul_a[4][0] = img_deconv[4][1][3]; mul_a[4][1] = img_deconv[4][1][4]; mul_a[4][2] = img_deconv[4][1][5]; mul_a[4][3] = img_deconv[4][1][6]; mul_a[4][4] = img_deconv[4][1][7];
                    end
                    31: begin
                        mul_a[0][0] = img_deconv[0][1][4]; mul_a[0][1] = img_deconv[0][1][5]; mul_a[0][2] = img_deconv[0][1][6]; mul_a[0][3] = img_deconv[0][1][7]; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][4]; mul_a[1][1] = img_deconv[1][1][5]; mul_a[1][2] = img_deconv[1][1][6]; mul_a[1][3] = img_deconv[1][1][7]; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][4]; mul_a[2][1] = img_deconv[2][1][5]; mul_a[2][2] = img_deconv[2][1][6]; mul_a[2][3] = img_deconv[2][1][7]; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][4]; mul_a[3][1] = img_deconv[3][1][5]; mul_a[3][2] = img_deconv[3][1][6]; mul_a[3][3] = img_deconv[3][1][7]; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][4]; mul_a[4][1] = img_deconv[4][1][5]; mul_a[4][2] = img_deconv[4][1][6]; mul_a[4][3] = img_deconv[4][1][7]; mul_a[4][4] =                   0;
                    end
                    32: begin
                        mul_a[0][0] = img_deconv[0][1][5]; mul_a[0][1] = img_deconv[0][1][6]; mul_a[0][2] = img_deconv[0][1][7]; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][5]; mul_a[1][1] = img_deconv[1][1][6]; mul_a[1][2] = img_deconv[1][1][7]; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][5]; mul_a[2][1] = img_deconv[2][1][6]; mul_a[2][2] = img_deconv[2][1][7]; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][5]; mul_a[3][1] = img_deconv[3][1][6]; mul_a[3][2] = img_deconv[3][1][7]; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][5]; mul_a[4][1] = img_deconv[4][1][6]; mul_a[4][2] = img_deconv[4][1][7]; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    33: begin
                        mul_a[0][0] = img_deconv[0][1][6]; mul_a[0][1] = img_deconv[0][1][7]; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][6]; mul_a[1][1] = img_deconv[1][1][7]; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][6]; mul_a[2][1] = img_deconv[2][1][7]; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][6]; mul_a[3][1] = img_deconv[3][1][7]; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][6]; mul_a[4][1] = img_deconv[4][1][7]; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    34: begin
                        mul_a[0][0] = img_deconv[0][1][7]; mul_a[0][1] =                   0; mul_a[0][2] =                   0; mul_a[0][3] =                   0; mul_a[0][4] =                   0;
                        mul_a[1][0] = img_deconv[1][1][7]; mul_a[1][1] =                   0; mul_a[1][2] =                   0; mul_a[1][3] =                   0; mul_a[1][4] =                   0;
                        mul_a[2][0] = img_deconv[2][1][7]; mul_a[2][1] =                   0; mul_a[2][2] =                   0; mul_a[2][3] =                   0; mul_a[2][4] =                   0;
                        mul_a[3][0] = img_deconv[3][1][7]; mul_a[3][1] =                   0; mul_a[3][2] =                   0; mul_a[3][3] =                   0; mul_a[3][4] =                   0;
                        mul_a[4][0] = img_deconv[4][1][7]; mul_a[4][1] =                   0; mul_a[4][2] =                   0; mul_a[4][3] =                   0; mul_a[4][4] =                   0;
                    end
                    default: begin
                        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = 0;
                        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] = 0;
                        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] = 0;
                        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] = 0;
                        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] = 0;
                    end
                endcase
            end
        end
    end
    else begin
        mul_a[0][0] = 0; mul_a[0][1] = 0; mul_a[0][2] = 0; mul_a[0][3] = 0; mul_a[0][4] = 0;
        mul_a[1][0] = 0; mul_a[1][1] = 0; mul_a[1][2] = 0; mul_a[1][3] = 0; mul_a[1][4] = 0;
        mul_a[2][0] = 0; mul_a[2][1] = 0; mul_a[2][2] = 0; mul_a[2][3] = 0; mul_a[2][4] = 0;
        mul_a[3][0] = 0; mul_a[3][1] = 0; mul_a[3][2] = 0; mul_a[3][3] = 0; mul_a[3][4] = 0;
        mul_a[4][0] = 0; mul_a[4][1] = 0; mul_a[4][2] = 0; mul_a[4][3] = 0; mul_a[4][4] = 0;
    end
end

always @(*) begin
    if(((state == CAL_CONV) && (cnt_conv)) || ((state == OUT) && (!mode_reg))) begin
        mul_b[0][0] = ker[0]; mul_b[0][1] = ker[1]; mul_b[0][2] = ker[2]; mul_b[0][3] = ker[3]; mul_b[0][4] = ker[4];
        mul_b[1][0] = ker[0]; mul_b[1][1] = ker[1]; mul_b[1][2] = ker[2]; mul_b[1][3] = ker[3]; mul_b[1][4] = ker[4];
        mul_b[2][0] = ker[0]; mul_b[2][1] = ker[1]; mul_b[2][2] = ker[2]; mul_b[2][3] = ker[3]; mul_b[2][4] = ker[4];
        mul_b[3][0] = ker[0]; mul_b[3][1] = ker[1]; mul_b[3][2] = ker[2]; mul_b[3][3] = ker[3]; mul_b[3][4] = ker[4];
        mul_b[4][0] = ker[0]; mul_b[4][1] = ker[1]; mul_b[4][2] = ker[2]; mul_b[4][3] = ker[3]; mul_b[4][4] = ker[4];
    end
    else if((state == CAL_DECONV) || ((state == OUT) && (mode_reg))) begin
        if(cnt_out_row < 4) begin
            case (cnt_out_row[1:0])
                0: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] = ker_deconv[0][4]; mul_b[0][1] = ker_deconv[0][3]; mul_b[0][2] = ker_deconv[0][2]; mul_b[0][3] = ker_deconv[0][1]; mul_b[0][4] = ker_deconv[0][0];
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                    else begin
                        mul_b[0][0] = ker_deconv[1][4]; mul_b[0][1] = ker_deconv[1][3]; mul_b[0][2] = ker_deconv[1][2]; mul_b[0][3] = ker_deconv[1][1]; mul_b[0][4] = ker_deconv[1][0];
                        mul_b[1][0] = ker_deconv[0][4]; mul_b[1][1] = ker_deconv[0][3]; mul_b[1][2] = ker_deconv[0][2]; mul_b[1][3] = ker_deconv[0][1]; mul_b[1][4] = ker_deconv[0][0];
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                end 
                1: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] = ker_deconv[1][4]; mul_b[0][1] = ker_deconv[1][3]; mul_b[0][2] = ker_deconv[1][2]; mul_b[0][3] = ker_deconv[1][1]; mul_b[0][4] = ker_deconv[1][0];
                        mul_b[1][0] = ker_deconv[0][4]; mul_b[1][1] = ker_deconv[0][3]; mul_b[1][2] = ker_deconv[0][2]; mul_b[1][3] = ker_deconv[0][1]; mul_b[1][4] = ker_deconv[0][0];
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                    else begin
                        mul_b[0][0] = ker_deconv[2][4]; mul_b[0][1] = ker_deconv[2][3]; mul_b[0][2] = ker_deconv[2][2]; mul_b[0][3] = ker_deconv[2][1]; mul_b[0][4] = ker_deconv[2][0];
                        mul_b[1][0] = ker_deconv[1][4]; mul_b[1][1] = ker_deconv[1][3]; mul_b[1][2] = ker_deconv[1][2]; mul_b[1][3] = ker_deconv[1][1]; mul_b[1][4] = ker_deconv[1][0];
                        mul_b[2][0] = ker_deconv[0][4]; mul_b[2][1] = ker_deconv[0][3]; mul_b[2][2] = ker_deconv[0][2]; mul_b[2][3] = ker_deconv[0][1]; mul_b[2][4] = ker_deconv[0][0];
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                end
                2: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] = ker_deconv[2][4]; mul_b[0][1] = ker_deconv[2][3]; mul_b[0][2] = ker_deconv[2][2]; mul_b[0][3] = ker_deconv[2][1]; mul_b[0][4] = ker_deconv[2][0];
                        mul_b[1][0] = ker_deconv[1][4]; mul_b[1][1] = ker_deconv[1][3]; mul_b[1][2] = ker_deconv[1][2]; mul_b[1][3] = ker_deconv[1][1]; mul_b[1][4] = ker_deconv[1][0];
                        mul_b[2][0] = ker_deconv[0][4]; mul_b[2][1] = ker_deconv[0][3]; mul_b[2][2] = ker_deconv[0][2]; mul_b[2][3] = ker_deconv[0][1]; mul_b[2][4] = ker_deconv[0][0];
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                    else begin
                        mul_b[0][0] = ker_deconv[3][4]; mul_b[0][1] = ker_deconv[3][3]; mul_b[0][2] = ker_deconv[3][2]; mul_b[0][3] = ker_deconv[3][1]; mul_b[0][4] = ker_deconv[3][0];
                        mul_b[1][0] = ker_deconv[2][4]; mul_b[1][1] = ker_deconv[2][3]; mul_b[1][2] = ker_deconv[2][2]; mul_b[1][3] = ker_deconv[2][1]; mul_b[1][4] = ker_deconv[2][0];
                        mul_b[2][0] = ker_deconv[1][4]; mul_b[2][1] = ker_deconv[1][3]; mul_b[2][2] = ker_deconv[1][2]; mul_b[2][3] = ker_deconv[1][1]; mul_b[2][4] = ker_deconv[1][0];
                        mul_b[3][0] = ker_deconv[0][4]; mul_b[3][1] = ker_deconv[0][3]; mul_b[3][2] = ker_deconv[0][2]; mul_b[3][3] = ker_deconv[0][1]; mul_b[3][4] = ker_deconv[0][0];
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                end
                3: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] = ker_deconv[3][4]; mul_b[0][1] = ker_deconv[3][3]; mul_b[0][2] = ker_deconv[3][2]; mul_b[0][3] = ker_deconv[3][1]; mul_b[0][4] = ker_deconv[3][0];
                        mul_b[1][0] = ker_deconv[2][4]; mul_b[1][1] = ker_deconv[2][3]; mul_b[1][2] = ker_deconv[2][2]; mul_b[1][3] = ker_deconv[2][1]; mul_b[1][4] = ker_deconv[2][0];
                        mul_b[2][0] = ker_deconv[1][4]; mul_b[2][1] = ker_deconv[1][3]; mul_b[2][2] = ker_deconv[1][2]; mul_b[2][3] = ker_deconv[1][1]; mul_b[2][4] = ker_deconv[1][0];
                        mul_b[3][0] = ker_deconv[0][4]; mul_b[3][1] = ker_deconv[0][3]; mul_b[3][2] = ker_deconv[0][2]; mul_b[3][3] = ker_deconv[0][1]; mul_b[3][4] = ker_deconv[0][0];
                        mul_b[4][0] =                0; mul_b[4][1] =                0; mul_b[4][2] =                0; mul_b[4][3] =                0; mul_b[4][4] =                0;
                    end
                    else begin
                        mul_b[0][0] = ker_deconv[4][4]; mul_b[0][1] = ker_deconv[4][3]; mul_b[0][2] = ker_deconv[4][2]; mul_b[0][3] = ker_deconv[4][1]; mul_b[0][4] = ker_deconv[4][0];
                        mul_b[1][0] = ker_deconv[3][4]; mul_b[1][1] = ker_deconv[3][3]; mul_b[1][2] = ker_deconv[3][2]; mul_b[1][3] = ker_deconv[3][1]; mul_b[1][4] = ker_deconv[3][0];
                        mul_b[2][0] = ker_deconv[2][4]; mul_b[2][1] = ker_deconv[2][3]; mul_b[2][2] = ker_deconv[2][2]; mul_b[2][3] = ker_deconv[2][1]; mul_b[2][4] = ker_deconv[2][0];
                        mul_b[3][0] = ker_deconv[1][4]; mul_b[3][1] = ker_deconv[1][3]; mul_b[3][2] = ker_deconv[1][2]; mul_b[3][3] = ker_deconv[1][1]; mul_b[3][4] = ker_deconv[1][0];
                        mul_b[4][0] = ker_deconv[0][4]; mul_b[4][1] = ker_deconv[0][3]; mul_b[4][2] = ker_deconv[0][2]; mul_b[4][3] = ker_deconv[0][1]; mul_b[4][4] = ker_deconv[0][0];
                    end
                end
                default begin
                    mul_b[0][0] = 0; mul_b[0][1] = 0; mul_b[0][2] = 0; mul_b[0][3] = 0; mul_b[0][4] = 0;
                    mul_b[1][0] = 0; mul_b[1][1] = 0; mul_b[1][2] = 0; mul_b[1][3] = 0; mul_b[1][4] = 0;
                    mul_b[2][0] = 0; mul_b[2][1] = 0; mul_b[2][2] = 0; mul_b[2][3] = 0; mul_b[2][4] = 0;
                    mul_b[3][0] = 0; mul_b[3][1] = 0; mul_b[3][2] = 0; mul_b[3][3] = 0; mul_b[3][4] = 0;
                    mul_b[4][0] = 0; mul_b[4][1] = 0; mul_b[4][2] = 0; mul_b[4][3] = 0; mul_b[4][4] = 0;
                end
            endcase
        end
        else if(cnt_out_row > (cnt_out_max - 4)) begin
            case (offset_row)
                0: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] = ker_deconv[4][4]; mul_b[1][1] = ker_deconv[4][3]; mul_b[1][2] = ker_deconv[4][2]; mul_b[1][3] = ker_deconv[4][1]; mul_b[1][4] = ker_deconv[4][0];
                        mul_b[2][0] = ker_deconv[3][4]; mul_b[2][1] = ker_deconv[3][3]; mul_b[2][2] = ker_deconv[3][2]; mul_b[2][3] = ker_deconv[3][1]; mul_b[2][4] = ker_deconv[3][0];
                        mul_b[3][0] = ker_deconv[2][4]; mul_b[3][1] = ker_deconv[2][3]; mul_b[3][2] = ker_deconv[2][2]; mul_b[3][3] = ker_deconv[2][1]; mul_b[3][4] = ker_deconv[2][0];
                        mul_b[4][0] = ker_deconv[1][4]; mul_b[4][1] = ker_deconv[1][3]; mul_b[4][2] = ker_deconv[1][2]; mul_b[4][3] = ker_deconv[1][1]; mul_b[4][4] = ker_deconv[1][0];
                    end
                    else begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] = ker_deconv[4][4]; mul_b[2][1] = ker_deconv[4][3]; mul_b[2][2] = ker_deconv[4][2]; mul_b[2][3] = ker_deconv[4][1]; mul_b[2][4] = ker_deconv[4][0];
                        mul_b[3][0] = ker_deconv[3][4]; mul_b[3][1] = ker_deconv[3][3]; mul_b[3][2] = ker_deconv[3][2]; mul_b[3][3] = ker_deconv[3][1]; mul_b[3][4] = ker_deconv[3][0];
                        mul_b[4][0] = ker_deconv[2][4]; mul_b[4][1] = ker_deconv[2][3]; mul_b[4][2] = ker_deconv[2][2]; mul_b[4][3] = ker_deconv[2][1]; mul_b[4][4] = ker_deconv[2][0];
                    end
                end 
                1: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] = ker_deconv[4][4]; mul_b[2][1] = ker_deconv[4][3]; mul_b[2][2] = ker_deconv[4][2]; mul_b[2][3] = ker_deconv[4][1]; mul_b[2][4] = ker_deconv[4][0];
                        mul_b[3][0] = ker_deconv[3][4]; mul_b[3][1] = ker_deconv[3][3]; mul_b[3][2] = ker_deconv[3][2]; mul_b[3][3] = ker_deconv[3][1]; mul_b[3][4] = ker_deconv[3][0];
                        mul_b[4][0] = ker_deconv[2][4]; mul_b[4][1] = ker_deconv[2][3]; mul_b[4][2] = ker_deconv[2][2]; mul_b[4][3] = ker_deconv[2][1]; mul_b[4][4] = ker_deconv[2][0];
                    end
                    else begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] = ker_deconv[4][4]; mul_b[3][1] = ker_deconv[4][3]; mul_b[3][2] = ker_deconv[4][2]; mul_b[3][3] = ker_deconv[4][1]; mul_b[3][4] = ker_deconv[4][0];
                        mul_b[4][0] = ker_deconv[3][4]; mul_b[4][1] = ker_deconv[3][3]; mul_b[4][2] = ker_deconv[3][2]; mul_b[4][3] = ker_deconv[3][1]; mul_b[4][4] = ker_deconv[3][0];
                    end
                end
                2: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] = ker_deconv[4][4]; mul_b[3][1] = ker_deconv[4][3]; mul_b[3][2] = ker_deconv[4][2]; mul_b[3][3] = ker_deconv[4][1]; mul_b[3][4] = ker_deconv[4][0];
                        mul_b[4][0] = ker_deconv[3][4]; mul_b[4][1] = ker_deconv[3][3]; mul_b[4][2] = ker_deconv[3][2]; mul_b[4][3] = ker_deconv[3][1]; mul_b[4][4] = ker_deconv[3][0];
                    end
                    else begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] = ker_deconv[4][4]; mul_b[4][1] = ker_deconv[4][3]; mul_b[4][2] = ker_deconv[4][2]; mul_b[4][3] = ker_deconv[4][1]; mul_b[4][4] = ker_deconv[4][0];
                    end
                end
                3: begin
                    if(cnt_out_col != cnt_out_max) begin
                        mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                        mul_b[1][0] =                0; mul_b[1][1] =                0; mul_b[1][2] =                0; mul_b[1][3] =                0; mul_b[1][4] =                0;
                        mul_b[2][0] =                0; mul_b[2][1] =                0; mul_b[2][2] =                0; mul_b[2][3] =                0; mul_b[2][4] =                0;
                        mul_b[3][0] =                0; mul_b[3][1] =                0; mul_b[3][2] =                0; mul_b[3][3] =                0; mul_b[3][4] =                0;
                        mul_b[4][0] = ker_deconv[4][4]; mul_b[4][1] = ker_deconv[4][3]; mul_b[4][2] = ker_deconv[4][2]; mul_b[4][3] = ker_deconv[4][1]; mul_b[4][4] = ker_deconv[4][0];
                    end
                    else begin
                        mul_b[0][0] = 0; mul_b[0][1] = 0; mul_b[0][2] = 0; mul_b[0][3] = 0; mul_b[0][4] = 0;
                        mul_b[1][0] = 0; mul_b[1][1] = 0; mul_b[1][2] = 0; mul_b[1][3] = 0; mul_b[1][4] = 0;
                        mul_b[2][0] = 0; mul_b[2][1] = 0; mul_b[2][2] = 0; mul_b[2][3] = 0; mul_b[2][4] = 0;
                        mul_b[3][0] = 0; mul_b[3][1] = 0; mul_b[3][2] = 0; mul_b[3][3] = 0; mul_b[3][4] = 0;
                        mul_b[4][0] = 0; mul_b[4][1] = 0; mul_b[4][2] = 0; mul_b[4][3] = 0; mul_b[4][4] = 0;
                    end
                end
                default begin
                    mul_b[0][0] = 0; mul_b[0][1] = 0; mul_b[0][2] = 0; mul_b[0][3] = 0; mul_b[0][4] = 0;
                    mul_b[1][0] = 0; mul_b[1][1] = 0; mul_b[1][2] = 0; mul_b[1][3] = 0; mul_b[1][4] = 0;
                    mul_b[2][0] = 0; mul_b[2][1] = 0; mul_b[2][2] = 0; mul_b[2][3] = 0; mul_b[2][4] = 0;
                    mul_b[3][0] = 0; mul_b[3][1] = 0; mul_b[3][2] = 0; mul_b[3][3] = 0; mul_b[3][4] = 0;
                    mul_b[4][0] = 0; mul_b[4][1] = 0; mul_b[4][2] = 0; mul_b[4][3] = 0; mul_b[4][4] = 0;
                end
            endcase
        end
        else begin
            if((cnt_out_col != cnt_out_max) || (cnt_out_row != (cnt_out_max - 4))) begin
                mul_b[0][0] = ker_deconv[4][4]; mul_b[0][1] = ker_deconv[4][3]; mul_b[0][2] = ker_deconv[4][2]; mul_b[0][3] = ker_deconv[4][1]; mul_b[0][4] = ker_deconv[4][0];
                mul_b[1][0] = ker_deconv[3][4]; mul_b[1][1] = ker_deconv[3][3]; mul_b[1][2] = ker_deconv[3][2]; mul_b[1][3] = ker_deconv[3][1]; mul_b[1][4] = ker_deconv[3][0];
                mul_b[2][0] = ker_deconv[2][4]; mul_b[2][1] = ker_deconv[2][3]; mul_b[2][2] = ker_deconv[2][2]; mul_b[2][3] = ker_deconv[2][1]; mul_b[2][4] = ker_deconv[2][0];
                mul_b[3][0] = ker_deconv[1][4]; mul_b[3][1] = ker_deconv[1][3]; mul_b[3][2] = ker_deconv[1][2]; mul_b[3][3] = ker_deconv[1][1]; mul_b[3][4] = ker_deconv[1][0];
                mul_b[4][0] = ker_deconv[0][4]; mul_b[4][1] = ker_deconv[0][3]; mul_b[4][2] = ker_deconv[0][2]; mul_b[4][3] = ker_deconv[0][1]; mul_b[4][4] = ker_deconv[0][0];
            end
            else begin
                mul_b[0][0] =                0; mul_b[0][1] =                0; mul_b[0][2] =                0; mul_b[0][3] =                0; mul_b[0][4] =                0;
                mul_b[1][0] = ker_deconv[4][4]; mul_b[1][1] = ker_deconv[4][3]; mul_b[1][2] = ker_deconv[4][2]; mul_b[1][3] = ker_deconv[4][1]; mul_b[1][4] = ker_deconv[4][0];
                mul_b[2][0] = ker_deconv[3][4]; mul_b[2][1] = ker_deconv[3][3]; mul_b[2][2] = ker_deconv[3][2]; mul_b[2][3] = ker_deconv[3][1]; mul_b[2][4] = ker_deconv[3][0];
                mul_b[3][0] = ker_deconv[2][4]; mul_b[3][1] = ker_deconv[2][3]; mul_b[3][2] = ker_deconv[2][2]; mul_b[3][3] = ker_deconv[2][1]; mul_b[3][4] = ker_deconv[2][0];
                mul_b[4][0] = ker_deconv[1][4]; mul_b[4][1] = ker_deconv[1][3]; mul_b[4][2] = ker_deconv[1][2]; mul_b[4][3] = ker_deconv[1][1]; mul_b[4][4] = ker_deconv[1][0];
            end
        end
    end
    else begin
        mul_b[0][0] = 0; mul_b[0][1] = 0; mul_b[0][2] = 0; mul_b[0][3] = 0; mul_b[0][4] = 0;
        mul_b[1][0] = 0; mul_b[1][1] = 0; mul_b[1][2] = 0; mul_b[1][3] = 0; mul_b[1][4] = 0;
        mul_b[2][0] = 0; mul_b[2][1] = 0; mul_b[2][2] = 0; mul_b[2][3] = 0; mul_b[2][4] = 0;
        mul_b[3][0] = 0; mul_b[3][1] = 0; mul_b[3][2] = 0; mul_b[3][3] = 0; mul_b[3][4] = 0;
        mul_b[4][0] = 0; mul_b[4][1] = 0; mul_b[4][2] = 0; mul_b[4][3] = 0; mul_b[4][4] = 0;
    end
end

always @(*) begin
    mul_z[0][0] = mul_a[0][0] * mul_b[0][0]; mul_z[0][1] = mul_a[0][1] * mul_b[0][1]; mul_z[0][2] = mul_a[0][2] * mul_b[0][2]; mul_z[0][3] = mul_a[0][3] * mul_b[0][3]; mul_z[0][4] = mul_a[0][4] * mul_b[0][4]; 
    mul_z[1][0] = mul_a[1][0] * mul_b[1][0]; mul_z[1][1] = mul_a[1][1] * mul_b[1][1]; mul_z[1][2] = mul_a[1][2] * mul_b[1][2]; mul_z[1][3] = mul_a[1][3] * mul_b[1][3]; mul_z[1][4] = mul_a[1][4] * mul_b[1][4];
    mul_z[2][0] = mul_a[2][0] * mul_b[2][0]; mul_z[2][1] = mul_a[2][1] * mul_b[2][1]; mul_z[2][2] = mul_a[2][2] * mul_b[2][2]; mul_z[2][3] = mul_a[2][3] * mul_b[2][3]; mul_z[2][4] = mul_a[2][4] * mul_b[2][4];
    mul_z[3][0] = mul_a[3][0] * mul_b[3][0]; mul_z[3][1] = mul_a[3][1] * mul_b[3][1]; mul_z[3][2] = mul_a[3][2] * mul_b[3][2]; mul_z[3][3] = mul_a[3][3] * mul_b[3][3]; mul_z[3][4] = mul_a[3][4] * mul_b[3][4];
    mul_z[4][0] = mul_a[4][0] * mul_b[4][0]; mul_z[4][1] = mul_a[4][1] * mul_b[4][1]; mul_z[4][2] = mul_a[4][2] * mul_b[4][2]; mul_z[4][3] = mul_a[4][3] * mul_b[4][3]; mul_z[4][4] = mul_a[4][4] * mul_b[4][4];
end

//=======================================================
//                    COMPARATOR
//=======================================================
always @(*) begin
    cmp_a[0] = tmp[0][0];
    cmp_a[1] = tmp[1][0];
    cmp_a[2] =  cmp_z[0];
end

always @(*) begin
    cmp_b[0] = tmp[0][1];
    cmp_b[1] = tmp[1][1];
    cmp_b[2] =  cmp_z[1];
end

always @(*) begin
    cmp_z[0] = (cmp_a[0] > cmp_b[0]) ? cmp_a[0] : cmp_b[0];
    cmp_z[1] = (cmp_a[1] > cmp_b[1]) ? cmp_a[1] : cmp_b[1];
    cmp_z[2] = (cmp_a[2] > cmp_b[2]) ? cmp_a[2] : cmp_b[2];
end

//=======================================================
//                    SRAM OF IMAGE
//======================================================= 
assign bandwidth = (!matrix_size_reg) ? 1 : (matrix_size_reg[0] ? 2 : 4);
assign origin = {img_idx, 7'b0};

always @(*) begin
    if((cnt_out_col == cnt_out_max) && (cnt_out_row != cnt_out_max)) begin
        row = (cnt_out_row + cnt_out_row) + 2;
    end
    else begin
        row = (cnt_out_row + cnt_out_row);
    end
end
assign pos = origin + row * bandwidth;

always @(*) begin
    if(cnt_out_row < 4) begin
        row_deconv = 0;
    end
    else if(cnt_out_row < (cnt_out_max - 4)) begin
        if((cnt_out_col == cnt_out_max) && (cnt_out_row != cnt_out_max)) begin
            row_deconv = cnt_out_row - 4 + 1;
        end
        else begin
            row_deconv = cnt_out_row - 4;
        end
    end
    else begin
        row_deconv = cnt_out_max - 4 - 4; // 1st -4: cnt_out_max exceeds image_size 4; 2nd -4: the start point should keep 4 from edge of image;
    end
end
assign pos_deconv = origin + row_deconv * bandwidth;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_img <= 0;
    end    
    else begin
        addr_img <= addr_img_nxt;
    end
end

always @(*) begin
    if(state == IN_IMG) begin
        addr_img_nxt = {cnt_in_16,cnt_in_1024[9:3]};
    end
    else if(state == IN_IDX) begin
        if(cnt_in_4 == 1) begin
            addr_img_nxt = origin;
        end
        else if(!mode_reg) begin
            addr_img_nxt = addr_img + bandwidth;
        end
        else begin
            addr_img_nxt = addr_img;
        end
    end
    else if(state == CAL_CONV) begin
        if(cnt_conv < 3) begin
           addr_img_nxt = addr_img + bandwidth; 
        end
        else begin
            addr_img_nxt = origin;
        end
    end
    else if(state == OUT) begin
        if(!mode_reg) begin
            if(cnt_out_bit < 4) begin
                case (cnt_out_bit)
                    0: begin
                        if(matrix_size_reg[1]) begin
                            if(cnt_out_col < 5) begin
                                addr_img_nxt = pos;
                            end
                            else if(cnt_out_col < 9) begin
                                addr_img_nxt = pos + 1;
                            end
                            else if(cnt_out_col < 13) begin
                                addr_img_nxt = pos + 2;
                            end
                            else begin
                                addr_img_nxt = pos;
                            end
                        end
                        else begin
                            addr_img_nxt = pos;
                        end
                    end
                    1: addr_img_nxt = addr_img + bandwidth;
                    2: addr_img_nxt = addr_img - bandwidth + 1;
                    3: addr_img_nxt = addr_img + bandwidth;
                    default: addr_img_nxt = addr_img;
                endcase
            end
            else if(cnt_out_bit < 12) begin
                if(!cnt_out_bit[0]) begin
                    addr_img_nxt = addr_img - 1 + bandwidth;
                end
                else begin
                    addr_img_nxt = addr_img + 1;
                end
            end
            else begin
                addr_img_nxt = addr_img;
            end
        end
        else begin
            if(cnt_out_bit < 10) begin
                case (cnt_out_bit)
                    0: begin
                        if(matrix_size_reg[1]) begin
                            if(cnt_out_col < 11) begin
                                addr_img_nxt = pos_deconv; 
                            end
                            else if(cnt_out_col < 19) begin
                                addr_img_nxt = pos_deconv + 1; 
                            end
                            else if(cnt_out_col < 35) begin
                                addr_img_nxt = pos_deconv + 2; 
                            end
                            else begin
                                addr_img_nxt = pos_deconv; 
                            end
                        end
                        else begin
                            addr_img_nxt = pos_deconv; 
                        end
                    end
                    5: begin
                        if(matrix_size_reg[1]) begin
                            if(cnt_out_col < 11) begin
                                addr_img_nxt = pos_deconv + 1; 
                            end
                            else if(cnt_out_col < 19) begin
                                addr_img_nxt = pos_deconv + 2; 
                            end
                            else if(cnt_out_col < 35) begin
                                addr_img_nxt = pos_deconv + 3; 
                            end
                            else begin
                                addr_img_nxt = pos_deconv; 
                            end
                        end
                        else begin
                            addr_img_nxt = pos_deconv + 1; 
                        end
                    end
                    default: addr_img_nxt = addr_img + bandwidth;
                endcase
            end
            else begin
                addr_img_nxt = addr_img;
            end
        end
    end
    else begin
        addr_img_nxt = addr_img;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        WEB_img <= 0;
    end    
    else begin
        WEB_img <= WEB_img_nxt;
    end
end

assign WEB_img_nxt = (state == IN_IMG) ? 0 : 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_img[0] <= 0;
        DI_img[1] <= 0;
        DI_img[2] <= 0;
        DI_img[3] <= 0;
        DI_img[4] <= 0;
        DI_img[5] <= 0;
        DI_img[6] <= 0;
        DI_img[7] <= 0;
    end
    else begin
        DI_img[0] <= DI_img_nxt[0];
        DI_img[1] <= DI_img_nxt[1];
        DI_img[2] <= DI_img_nxt[2];
        DI_img[3] <= DI_img_nxt[3];
        DI_img[4] <= DI_img_nxt[4];
        DI_img[5] <= DI_img_nxt[5];
        DI_img[6] <= DI_img_nxt[6];
        DI_img[7] <= DI_img_nxt[7];
    end
end

assign DI_img_nxt[0] = (state == IN_IMG) ?  DI_img[1] : DI_img[0];
assign DI_img_nxt[1] = (state == IN_IMG) ?  DI_img[2] : DI_img[1];
assign DI_img_nxt[2] = (state == IN_IMG) ?  DI_img[3] : DI_img[2];
assign DI_img_nxt[3] = (state == IN_IMG) ?  DI_img[4] : DI_img[3];
assign DI_img_nxt[4] = (state == IN_IMG) ?  DI_img[5] : DI_img[4];
assign DI_img_nxt[5] = (state == IN_IMG) ?  DI_img[6] : DI_img[5];
assign DI_img_nxt[6] = (state == IN_IMG) ?  DI_img[7] : DI_img[6];
assign DI_img_nxt[7] = (state == IN_IMG) ? matrix_reg : DI_img[7];

mem_img m_img(  .A0(addr_img[0]), .A1(addr_img[1]), .A2(addr_img[2]), .A3(addr_img[3]), .A4(addr_img[4]), .A5(addr_img[5]),
                .A6(addr_img[6]), .A7(addr_img[7]), .A8(addr_img[8]), .A9(addr_img[9]), .A10(addr_img[10]),

                 .DO0(DO_img[0][0]),  .DO1(DO_img[0][1]),  .DO2(DO_img[0][2]),  .DO3(DO_img[0][3]),  .DO4(DO_img[0][4]),  .DO5(DO_img[0][5]),  .DO6(DO_img[0][6]),  .DO7(DO_img[0][7]),
                 .DO8(DO_img[1][0]),  .DO9(DO_img[1][1]), .DO10(DO_img[1][2]), .DO11(DO_img[1][3]), .DO12(DO_img[1][4]), .DO13(DO_img[1][5]), .DO14(DO_img[1][6]), .DO15(DO_img[1][7]),
                .DO16(DO_img[2][0]), .DO17(DO_img[2][1]), .DO18(DO_img[2][2]), .DO19(DO_img[2][3]), .DO20(DO_img[2][4]), .DO21(DO_img[2][5]), .DO22(DO_img[2][6]), .DO23(DO_img[2][7]),
                .DO24(DO_img[3][0]), .DO25(DO_img[3][1]), .DO26(DO_img[3][2]), .DO27(DO_img[3][3]), .DO28(DO_img[3][4]), .DO29(DO_img[3][5]), .DO30(DO_img[3][6]), .DO31(DO_img[3][7]),
                .DO32(DO_img[4][0]), .DO33(DO_img[4][1]), .DO34(DO_img[4][2]), .DO35(DO_img[4][3]), .DO36(DO_img[4][4]), .DO37(DO_img[4][5]), .DO38(DO_img[4][6]), .DO39(DO_img[4][7]),
                .DO40(DO_img[5][0]), .DO41(DO_img[5][1]), .DO42(DO_img[5][2]), .DO43(DO_img[5][3]), .DO44(DO_img[5][4]), .DO45(DO_img[5][5]), .DO46(DO_img[5][6]), .DO47(DO_img[5][7]),
                .DO48(DO_img[6][0]), .DO49(DO_img[6][1]), .DO50(DO_img[6][2]), .DO51(DO_img[6][3]), .DO52(DO_img[6][4]), .DO53(DO_img[6][5]), .DO54(DO_img[6][6]), .DO55(DO_img[6][7]),
                .DO56(DO_img[7][0]), .DO57(DO_img[7][1]), .DO58(DO_img[7][2]), .DO59(DO_img[7][3]), .DO60(DO_img[7][4]), .DO61(DO_img[7][5]), .DO62(DO_img[7][6]), .DO63(DO_img[7][7]),

                 .DI0(DI_img[0][0]),  .DI1(DI_img[0][1]),  .DI2(DI_img[0][2]),  .DI3(DI_img[0][3]),  .DI4(DI_img[0][4]),  .DI5(DI_img[0][5]),  .DI6(DI_img[0][6]),  .DI7(DI_img[0][7]),
                 .DI8(DI_img[1][0]),  .DI9(DI_img[1][1]), .DI10(DI_img[1][2]), .DI11(DI_img[1][3]), .DI12(DI_img[1][4]), .DI13(DI_img[1][5]), .DI14(DI_img[1][6]), .DI15(DI_img[1][7]),
                .DI16(DI_img[2][0]), .DI17(DI_img[2][1]), .DI18(DI_img[2][2]), .DI19(DI_img[2][3]), .DI20(DI_img[2][4]), .DI21(DI_img[2][5]), .DI22(DI_img[2][6]), .DI23(DI_img[2][7]),
                .DI24(DI_img[3][0]), .DI25(DI_img[3][1]), .DI26(DI_img[3][2]), .DI27(DI_img[3][3]), .DI28(DI_img[3][4]), .DI29(DI_img[3][5]), .DI30(DI_img[3][6]), .DI31(DI_img[3][7]),
                .DI32(DI_img[4][0]), .DI33(DI_img[4][1]), .DI34(DI_img[4][2]), .DI35(DI_img[4][3]), .DI36(DI_img[4][4]), .DI37(DI_img[4][5]), .DI38(DI_img[4][6]), .DI39(DI_img[4][7]),
                .DI40(DI_img[5][0]), .DI41(DI_img[5][1]), .DI42(DI_img[5][2]), .DI43(DI_img[5][3]), .DI44(DI_img[5][4]), .DI45(DI_img[5][5]), .DI46(DI_img[5][6]), .DI47(DI_img[5][7]),
                .DI48(DI_img[6][0]), .DI49(DI_img[6][1]), .DI50(DI_img[6][2]), .DI51(DI_img[6][3]), .DI52(DI_img[6][4]), .DI53(DI_img[6][5]), .DI54(DI_img[6][6]), .DI55(DI_img[6][7]),
                .DI56(DI_img[7][0]), .DI57(DI_img[7][1]), .DI58(DI_img[7][2]), .DI59(DI_img[7][3]), .DI60(DI_img[7][4]), .DI61(DI_img[7][5]), .DI62(DI_img[7][6]), .DI63(DI_img[7][7]),

                .CK(clk), .WEB(WEB_img), .OE(1'b1), .CS(1'b1));

//=======================================================
//                    SRAM OF KERNAL
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_in_5_5 <= 0;
    end    
    else begin
        cnt_in_5_5 <= cnt_in_5_5_nxt;
    end
end

assign cnt_in_5_5_nxt = cnt_in_5;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_ker <= 0;
    end    
    else begin
        addr_ker <= addr_ker_nxt;
    end
end

always @(*) begin
    if(state == IDLE) begin
        addr_ker_nxt = 0;
    end
    else if(state == IN_KER) begin
        if(cnt_in_5_5 == 4) begin
            addr_ker_nxt = addr_ker + 1;
        end
        else begin
            addr_ker_nxt = addr_ker;
        end
    end
    else if(state == IN_IDX) begin
        if(cnt_in_4 == 2) begin
            case (ker_idx)
                 0: addr_ker_nxt =  0;
                 1: addr_ker_nxt =  5;
                 2: addr_ker_nxt = 10;
                 3: addr_ker_nxt = 15;
                 4: addr_ker_nxt = 20;
                 5: addr_ker_nxt = 25;
                 6: addr_ker_nxt = 30;
                 7: addr_ker_nxt = 35;
                 8: addr_ker_nxt = 40;
                 9: addr_ker_nxt = 45;
                10: addr_ker_nxt = 50;
                11: addr_ker_nxt = 55;
                12: addr_ker_nxt = 60;
                13: addr_ker_nxt = 65;
                14: addr_ker_nxt = 70;
                15: addr_ker_nxt = 75;
                default: addr_ker_nxt = 0;
            endcase
        end
        else if((cnt_in_4 == 3) && (!mode_reg)) begin
            addr_ker_nxt = addr_ker + 1;
        end
        else begin
            addr_ker_nxt = addr_ker;
        end
    end
    else if((state == CAL_CONV) && (cnt_conv < 3)) begin
        addr_ker_nxt = addr_ker + 1;
    end
    else if(state == OUT) begin
        if(!mode_reg) begin
           if(!cnt_out_bit) begin
                case (ker_idx)
                    0: addr_ker_nxt =  0;
                    1: addr_ker_nxt =  5;
                    2: addr_ker_nxt = 10;
                    3: addr_ker_nxt = 15;
                    4: addr_ker_nxt = 20;
                    5: addr_ker_nxt = 25;
                    6: addr_ker_nxt = 30;
                    7: addr_ker_nxt = 35;
                    8: addr_ker_nxt = 40;
                    9: addr_ker_nxt = 45;
                    10: addr_ker_nxt = 50;
                    11: addr_ker_nxt = 55;
                    12: addr_ker_nxt = 60;
                    13: addr_ker_nxt = 65;
                    14: addr_ker_nxt = 70;
                    15: addr_ker_nxt = 75;
                    default: addr_ker_nxt = 0;
                endcase
            end
            else if((cnt_out_bit >= 5) && (cnt_out_bit < 13) && (cnt_out_bit[0])) begin
                addr_ker_nxt = addr_ker + 1;
            end
            else begin
                addr_ker_nxt = addr_ker;
            end 
        end
        else begin
            if(!cnt_out_bit) begin
                case (ker_idx)
                    0: addr_ker_nxt =  0;
                    1: addr_ker_nxt =  5;
                    2: addr_ker_nxt = 10;
                    3: addr_ker_nxt = 15;
                    4: addr_ker_nxt = 20;
                    5: addr_ker_nxt = 25;
                    6: addr_ker_nxt = 30;
                    7: addr_ker_nxt = 35;
                    8: addr_ker_nxt = 40;
                    9: addr_ker_nxt = 45;
                    10: addr_ker_nxt = 50;
                    11: addr_ker_nxt = 55;
                    12: addr_ker_nxt = 60;
                    13: addr_ker_nxt = 65;
                    14: addr_ker_nxt = 70;
                    15: addr_ker_nxt = 75;
                    default: addr_ker_nxt = 0;
                endcase
            end
            else if((cnt_out_bit >= 6) && (cnt_out_bit < 10)) begin
                addr_ker_nxt = addr_ker + 1;
            end
            else begin
                addr_ker_nxt = addr_ker;
            end
        end
    end
    else begin
        addr_ker_nxt = addr_ker;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        WEB_ker <= 0;
    end    
    else begin
        WEB_ker <= WEB_ker_nxt;
    end
end

assign WEB_ker_nxt = (state == IN_KER) ? 0 : 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_ker[0] <= 0;
        DI_ker[1] <= 0;
        DI_ker[2] <= 0;
        DI_ker[3] <= 0;
        DI_ker[4] <= 0;
    end
    else begin
        DI_ker[0] <= DI_ker_nxt[0];
        DI_ker[1] <= DI_ker_nxt[1];
        DI_ker[2] <= DI_ker_nxt[2];
        DI_ker[3] <= DI_ker_nxt[3];
        DI_ker[4] <= DI_ker_nxt[4];
    end
end

assign DI_ker_nxt[0] = (state == IN_KER) ?  DI_ker[1] : DI_ker[0];
assign DI_ker_nxt[1] = (state == IN_KER) ?  DI_ker[2] : DI_ker[1];
assign DI_ker_nxt[2] = (state == IN_KER) ?  DI_ker[3] : DI_ker[2];
assign DI_ker_nxt[3] = (state == IN_KER) ?  DI_ker[4] : DI_ker[3];
assign DI_ker_nxt[4] = (state == IN_KER) ? matrix_reg : DI_ker[4];

mem_ker m_ker(  .A0(addr_ker[0]), .A1(addr_ker[1]), .A2(addr_ker[2]), .A3(addr_ker[3]), .A4(addr_ker[4]), .A5(addr_ker[5]), .A6(addr_ker[6]),

                 .DO0(DO_ker[0][0]),  .DO1(DO_ker[0][1]),  .DO2(DO_ker[0][2]),  .DO3(DO_ker[0][3]),  .DO4(DO_ker[0][4]),  .DO5(DO_ker[0][5]),  .DO6(DO_ker[0][6]),  .DO7(DO_ker[0][7]),
                 .DO8(DO_ker[1][0]),  .DO9(DO_ker[1][1]), .DO10(DO_ker[1][2]), .DO11(DO_ker[1][3]), .DO12(DO_ker[1][4]), .DO13(DO_ker[1][5]), .DO14(DO_ker[1][6]), .DO15(DO_ker[1][7]),
                .DO16(DO_ker[2][0]), .DO17(DO_ker[2][1]), .DO18(DO_ker[2][2]), .DO19(DO_ker[2][3]), .DO20(DO_ker[2][4]), .DO21(DO_ker[2][5]), .DO22(DO_ker[2][6]), .DO23(DO_ker[2][7]),
                .DO24(DO_ker[3][0]), .DO25(DO_ker[3][1]), .DO26(DO_ker[3][2]), .DO27(DO_ker[3][3]), .DO28(DO_ker[3][4]), .DO29(DO_ker[3][5]), .DO30(DO_ker[3][6]), .DO31(DO_ker[3][7]),
                .DO32(DO_ker[4][0]), .DO33(DO_ker[4][1]), .DO34(DO_ker[4][2]), .DO35(DO_ker[4][3]), .DO36(DO_ker[4][4]), .DO37(DO_ker[4][5]), .DO38(DO_ker[4][6]), .DO39(DO_ker[4][7]),

                 .DI0(DI_ker[0][0]),  .DI1(DI_ker[0][1]),  .DI2(DI_ker[0][2]),  .DI3(DI_ker[0][3]),  .DI4(DI_ker[0][4]),  .DI5(DI_ker[0][5]),  .DI6(DI_ker[0][6]),  .DI7(DI_ker[0][7]),
                 .DI8(DI_ker[1][0]),  .DI9(DI_ker[1][1]), .DI10(DI_ker[1][2]), .DI11(DI_ker[1][3]), .DI12(DI_ker[1][4]), .DI13(DI_ker[1][5]), .DI14(DI_ker[1][6]), .DI15(DI_ker[1][7]),
                .DI16(DI_ker[2][0]), .DI17(DI_ker[2][1]), .DI18(DI_ker[2][2]), .DI19(DI_ker[2][3]), .DI20(DI_ker[2][4]), .DI21(DI_ker[2][5]), .DI22(DI_ker[2][6]), .DI23(DI_ker[2][7]),
                .DI24(DI_ker[3][0]), .DI25(DI_ker[3][1]), .DI26(DI_ker[3][2]), .DI27(DI_ker[3][3]), .DI28(DI_ker[3][4]), .DI29(DI_ker[3][5]), .DI30(DI_ker[3][6]), .DI31(DI_ker[3][7]),
                .DI32(DI_ker[4][0]), .DI33(DI_ker[4][1]), .DI34(DI_ker[4][2]), .DI35(DI_ker[4][3]), .DI36(DI_ker[4][4]), .DI37(DI_ker[4][5]), .DI38(DI_ker[4][6]), .DI39(DI_ker[4][7]),

                .CK(clk), .WEB(WEB_ker), .OE(1'b1), .CS(1'b1));

endmodule