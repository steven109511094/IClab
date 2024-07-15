module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_matrix_A,
    in_matrix_B,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_matrix,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);

input clk;
input rst_n;
input in_valid;
input [3:0] in_matrix_A;
input [3:0] in_matrix_B;

input out_idle;
output reg handshake_sready;
output reg [7:0] handshake_din;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1; // handshake response
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;

output reg out_valid;
output reg [7:0] out_matrix;

// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//=======================================================
//                  PARAMETER
//=======================================================

integer i;

parameter   IDLE        = 0,
            INPUT       = 1,
            HANDSHAKE   = 2,
            OUTPUT      = 3;

//=======================================================
//                  DECLARATION
//=======================================================

// FSM
reg  [1:0] state;
reg  [1:0] state_nxt;

// INPUT
reg  [3:0] in_matrix_A_reg;
wire [3:0] in_matrix_A_nxt;

reg  [3:0] matrix_A    [0:15];
reg  [3:0] matrix_A_nxt[0:15];

reg  [3:0] in_matrix_B_reg;
wire [3:0] in_matrix_B_nxt;

reg  [3:0] matrix_B    [0:15];
reg  [3:0] matrix_B_nxt[0:15];

reg  [3:0] cnt_16_1;
reg  [3:0] cnt_16_1_nxt;

// HANDSHAKE
reg  [3:0] cnt_16_2;
reg  [3:0] cnt_16_2_nxt;

reg  handshake_sready_nxt;

reg  [7:0] handshake_din_nxt; // {B[3:0], A[3:0]}

// OUTPUT
wire out_valid_nxt;
wire [7:0] out_matrix_nxt;

reg  fifo_empty_reg_1;
wire fifo_empty_nxt_1;

reg  fifo_empty_reg_2;
wire fifo_empty_nxt_2;

//=======================================================
//                  FSM
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
        IDLE: state_nxt = (in_valid) ? INPUT : IDLE;
        INPUT: state_nxt = !(~cnt_16_1) ? HANDSHAKE : INPUT;
        HANDSHAKE: state_nxt = (!(~cnt_16_2) && (flag_handshake_to_clk1)) ? OUTPUT : HANDSHAKE;
        OUTPUT: state_nxt = ((!(~cnt_16_1) && !(~cnt_16_2)) && (!fifo_empty_reg_2)) ? IDLE : OUTPUT;
    endcase
end

//=======================================================
//                  INPUT
//=======================================================

// DFF of in_matrix_A_reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_matrix_A_reg <= 0;
    end
    else begin
        in_matrix_A_reg <= in_matrix_A_nxt;
    end
end

// comb of in_matrix_A_reg
assign in_matrix_A_nxt = in_matrix_A;

// DFF of matrix_A
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= matrix_A_nxt[i];
        end
    end
end

// comb of matrix_A
always @(*) begin
    case (state)
        INPUT: begin
            for(i = 0; i < 15; i = i + 1) begin
                matrix_A_nxt[i] = matrix_A[i + 1];
            end
            matrix_A_nxt[15] = in_matrix_A_reg;
        end
        HANDSHAKE: begin
            if((handshake_sready) && !(handshake_sready_nxt)) begin
                for(i = 0; i < 15; i = i + 1) begin
                    matrix_A_nxt[i] = matrix_A[i + 1];
                end
                matrix_A_nxt[15] = 0;
            end
            else begin
                for(i = 0; i < 16; i = i + 1) begin
                    matrix_A_nxt[i] = matrix_A[i];
                end
            end
        end
        default: begin
            for(i = 0; i < 16; i = i + 1) begin
                matrix_A_nxt[i] = matrix_A[i];
            end
        end
    endcase
end

// DFF of in_matrix_B_reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_matrix_B_reg <= 0;
    end
    else begin
        in_matrix_B_reg <= in_matrix_B_nxt;
    end
end

// comb of in_matrix_B_reg
assign in_matrix_B_nxt = in_matrix_B;

// DFF of matrix_B
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= matrix_B_nxt[i];
        end
    end
end

// comb of matrix_B
always @(*) begin
    case (state)
        INPUT: begin
            for(i = 0; i < 15; i = i + 1) begin
                matrix_B_nxt[i] = matrix_B[i + 1];
            end
            matrix_B_nxt[15] = in_matrix_B_reg;
        end
        HANDSHAKE: begin
            if((handshake_sready) && !(handshake_sready_nxt)) begin
                for(i = 0; i < 15; i = i + 1) begin
                    matrix_B_nxt[i] = matrix_B[i + 1];
                end
                matrix_B_nxt[15] = 0;
            end
            else begin
                for(i = 0; i < 16; i = i + 1) begin
                    matrix_B_nxt[i] = matrix_B[i];
                end
            end
        end
        default: begin
            for(i = 0; i < 16; i = i + 1) begin
                matrix_B_nxt[i] = matrix_B[i];
            end
        end
    endcase
end

// DFF of cnt_16_1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_16_1 <= 0;
    end
    else begin
        cnt_16_1 <= cnt_16_1_nxt;
    end
end

// comb of cnt_16_1
always @(*) begin
    case (state)
        INPUT: begin
            cnt_16_1_nxt = cnt_16_1 + 1;
        end
        OUTPUT: begin
            if((!fifo_empty_reg_2)) begin
                cnt_16_1_nxt = cnt_16_1 + 1;
            end
            else begin
                cnt_16_1_nxt = cnt_16_1;
            end
        end
        default: begin
            cnt_16_1_nxt = cnt_16_1;
        end
    endcase
end

//=======================================================
//                  HANDSHAKE
//=======================================================

// DFF of cnt_16_2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_16_2 <= 0;
    end
    else begin
        cnt_16_2 <= cnt_16_2_nxt;
    end
end

// comb of cnt_16_2
always @(*) begin
    case (state)
        IDLE: begin
            cnt_16_2_nxt = 0;
        end
        HANDSHAKE: begin
            if((handshake_sready) && !(handshake_sready_nxt)) begin
                cnt_16_2_nxt = cnt_16_2 + 1;
            end
            else begin
                cnt_16_2_nxt = cnt_16_2;
            end
        end
        OUTPUT: begin
            if((!fifo_empty_reg_2) && !(~cnt_16_1)) begin
                cnt_16_2_nxt = cnt_16_2 + 1;
            end
            else begin
                cnt_16_2_nxt = cnt_16_2;
            end
        end
        default: begin
            cnt_16_2_nxt = cnt_16_2;
        end
    endcase
end

// DFF of handshake_sready
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_sready <= 0;
    end
    else begin
        handshake_sready <= handshake_sready_nxt;
    end
end

// comb of handshake_sready
always @(*) begin
    case (state)
        HANDSHAKE: begin
            if(flag_handshake_to_clk1) begin
                handshake_sready_nxt = 0; // pull down sready when handshake output
            end
            else begin
                handshake_sready_nxt = 1; // raise up sready until handshake output
            end
        end
        default: begin
            handshake_sready_nxt = 0;
        end
    endcase
end

// DFF of handshake_din
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_din <= 0;
    end
    else begin
        handshake_din <= handshake_din_nxt;
    end
end

// comb of handshake_din
always @(*) begin
    case (state)
        HANDSHAKE: begin
            if(flag_handshake_to_clk1) begin
                handshake_din_nxt = 0; // pull down sready when handshake output
            end
            else begin
                handshake_din_nxt = {matrix_B[0], matrix_A[0]}; // raise up sready until handshake output
            end
        end
        default: begin
            handshake_din_nxt = handshake_din;
        end
    endcase
end

//=======================================================
//                  OUTPUT
//=======================================================

assign fifo_rinc = !fifo_empty;

// DFF of fifo_empty_reg_1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_empty_reg_1 <= 1;
    end
    else begin
        fifo_empty_reg_1 <= fifo_empty_nxt_1;
    end
end

// DFF of fifo_empty_nxt_1
assign fifo_empty_nxt_1 = fifo_empty;

// DFF of fifo_empty_reg_2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_empty_reg_2 <= 1;
    end
    else begin
        fifo_empty_reg_2 <= fifo_empty_nxt_2;
    end
end

// DFF of fifo_empty_nxt_2
assign fifo_empty_nxt_2 = fifo_empty_reg_1;

// DFF of out_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
    end
end

// comb of out_valid
assign out_valid_nxt = (!fifo_empty_reg_2) ? 1 : 0;

// DFF of out_matrix
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_matrix <= 0;
    end
    else begin
        out_matrix <= out_matrix_nxt;
    end
end

// comb of out_matrix
assign out_matrix_nxt = (!fifo_empty_reg_2) ? fifo_rdata : 0;

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_matrix,
    out_valid,
    out_matrix,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [7:0] in_matrix;
output reg out_valid;
output reg [7:0] out_matrix;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2; // !wfull_nxt
output flag_clk2_to_fifo;

//============================================
//              PARAMETER
//============================================

integer i;

parameter   IDLE    = 0,
            INPUT   = 1,
            CAL     = 2,
            OUTPUT  = 3;

//============================================
//              DECLARATION
//============================================

// FSM
reg  [1:0] state;
reg  [1:0] state_nxt;

// INPUT
reg  [3:0] matrix_A     [0:15];
reg  [3:0] matrix_A_nxt [0:15];

reg  [3:0] matrix_B     [0:15];
reg  [3:0] matrix_B_nxt [0:15];

reg  [3:0] cnt_in;
wire [3:0] cnt_in_nxt;

// CAL
reg  [7:0] cnt_256;
wire [7:0] cnt_256_nxt;

reg  [7:0] out;
wire [7:0] out_nxt;

// OUTPUT

wire out_valid_nxt;

wire [7:0] out_matrix_nxt;

//============================================
//              FSM
//============================================

// DFF of FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= 0;
    end
    else begin
        state <= state_nxt;
    end
end

// comb of FSM
always @(*) begin
    case (state)
        IDLE: state_nxt = (in_valid) ? INPUT : IDLE;
        INPUT: state_nxt = ((flag_handshake_to_clk2) && !(~cnt_in)) ? CAL : INPUT;
        CAL: state_nxt = OUTPUT;
        OUTPUT: state_nxt = (flag_fifo_to_clk2) ? (!(~cnt_256) ? IDLE : CAL) : OUTPUT;
    endcase
end

//============================================
//              INPUT
//============================================

// DFF of matrix_A
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_A[i] <= matrix_A_nxt[i];
        end
    end
end

// comb of matrix_A
always @(*) begin
    if((state == INPUT) && (flag_handshake_to_clk2)) begin
        for(i = 0; i < 15; i = i + 1) begin
            matrix_A_nxt[i] = matrix_A[i + 1];
        end
        matrix_A_nxt[15] = in_matrix[3:0];
    end
    else if((state == OUTPUT) && (flag_fifo_to_clk2) && !(~(cnt_256[3:0]))) begin
        for(i = 0; i < 15; i = i + 1) begin
            matrix_A_nxt[i] = matrix_A[i + 1];
        end
        matrix_A_nxt[15] = matrix_A[0];
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_A_nxt[i] = matrix_A[i];
        end
    end
end

// DFF of matrix_B
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_B[i] <= matrix_B_nxt[i];
        end
    end
end

// comb of matrix_B
always @(*) begin
    if((state == INPUT) && (flag_handshake_to_clk2)) begin
        for(i = 0; i < 15; i = i + 1) begin
            matrix_B_nxt[i] = matrix_B[i + 1];
        end
        matrix_B_nxt[15] = in_matrix[7:4];
    end
    else if((state == OUTPUT) && (flag_fifo_to_clk2)) begin
        for(i = 0; i < 15; i = i + 1) begin
            matrix_B_nxt[i] = matrix_B[i + 1];
        end
        matrix_B_nxt[15] = matrix_B[0];
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            matrix_B_nxt[i] = matrix_B[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_in <= 0;
    end
    else begin
        cnt_in <= cnt_in_nxt;
    end
end

assign cnt_in_nxt = ((state == INPUT) && (flag_handshake_to_clk2)) ? (cnt_in + 1) : cnt_in;

//============================================
//              CAL
//============================================

// DFF of out
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else begin
        out <= out_nxt;
    end
end

// comb of out
assign out_nxt = (state == CAL) ? (matrix_A[0] * matrix_B[0]) : out;

//============================================
//              OUTPUT
//============================================

// DFF of cnt_256
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_256 <= 0;
    end
    else begin
        cnt_256 <= cnt_256_nxt;
    end
end

// comb of cnt_256
assign cnt_256_nxt = ((state == OUTPUT) && (flag_fifo_to_clk2)) ? (cnt_256 + 1) : cnt_256;

// DFF of out_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
    end
end

// comb of out_valid
assign out_valid_nxt = ((state == OUTPUT) && (flag_fifo_to_clk2)) ? 1 : 0;

// DFF of out_matrix
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_matrix <= 0;
    end
    else begin
        out_matrix <= out_matrix_nxt;
    end
end

// comb of out_matrix
assign out_matrix_nxt = ((state == OUTPUT) && (flag_fifo_to_clk2)) ? out : 0;

endmodule












