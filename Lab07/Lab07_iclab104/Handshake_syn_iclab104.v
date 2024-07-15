module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1; // handshake response
input flag_clk1_to_handshake;

output flag_handshake_to_clk2; // last cycle of dvalid
input flag_clk2_to_handshake;

//============================================
//              PARAMETER
//============================================

parameter   IDLE        = 0,
            INPUT       = 1,
            WAIT_SACK   = 2,
            OUTPUT      = 3;

//============================================
//              DECLARATION
//============================================

// Remember:
//   Don't modify the signal name (sreq, sack, dreq, dack)

// SRC CTRL
reg  [1:0] s_state;
reg  [1:0] s_state_nxt;

reg  sreq;
wire sreq_nxt;

wire sack;
wire flag_handshake_to_clk1_nxt;

reg  [7:0] data;
wire [7:0] data_nxt;

// DEST CTRL

wire dreq;

reg  dack;
wire dack_nxt;

wire [7:0] dout_nxt;

wire dvalid_nxt;

//============================================
//              SRC CTRL
//============================================

// DFF of s_state
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        s_state <= IDLE;
    end
    else begin
        s_state <= s_state_nxt;
    end
end

// comb of s_state
always @(*) begin
    case (s_state)
        IDLE: s_state_nxt = (sready) ? INPUT : IDLE;
        INPUT: s_state_nxt = (sack) ? WAIT_SACK : INPUT;
        WAIT_SACK: s_state_nxt = (flag_handshake_to_clk1) ? IDLE : WAIT_SACK;
        default: s_state_nxt = s_state;
    endcase
end

// comb of sidle
assign sidle = (s_state == IDLE) ? 1 : 0;

// DFF of sreq
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        sreq <= 0;
    end
    else begin
        sreq <= sreq_nxt;
    end
end

// comb of sreq
//   raise up sreq until request is acknowledged
assign sreq_nxt = ((s_state == IDLE) && (sready)) ? 1 : ((sack) ? 0 : sreq);

// DFF of flag_handshake_to_clk1
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        flag_handshake_to_clk1 <= 0;
    end
    else begin
        flag_handshake_to_clk1 <= flag_handshake_to_clk1_nxt;
    end
end

// comb of flag_handshake_to_clk1
assign flag_handshake_to_clk1_nxt = ((s_state == WAIT_SACK) && (!flag_handshake_to_clk1) && !(sack)) ? 1 : 0;

// DFF of data
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        data <= 0;
    end
    else begin
        data <= data_nxt;
    end
end

// comb of data
assign data_nxt = ((s_state == IDLE) && (sready)) ? din : data;

//============================================
//              DEST CTRL
//============================================

// DFF of dack
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin
        dack <= 0;
    end
    else begin
        dack <= dack_nxt;
    end
end

// comb of dack
assign dack_nxt = (dreq) ? 1 : 0;


// comb of flag_handshake_to_clk2
assign flag_handshake_to_clk2 = ((dvalid) && !(dvalid_nxt)) ? 1 : 0;

// DFF of dout
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin
        dout <= 0;
    end
    else begin
        dout <= dout_nxt;
    end
end

// comb of dout
assign dout_nxt = (dreq) ? data : dout;

// DFF of dvalid
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin
        dvalid <= 0;
    end
    else begin
        dvalid <= dvalid_nxt;
    end
end

// comb of dvalid
assign dvalid_nxt = (dreq) ? 1 : 0;

//============================================
//              NDFF BUS
//============================================

// sync_s2d
NDFF_syn sync_s2d (.D(sreq), .Q(dreq), .rst_n(rst_n), .clk(dclk));

// sync_d2s
NDFF_syn sync_d2s (.D(dack), .Q(sack), .rst_n(rst_n), .clk(sclk));

endmodule