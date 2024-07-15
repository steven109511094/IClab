module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input   flag_clk2_to_fifo;

output  flag_fifo_to_clk1;
input   flag_clk1_to_fifo;

//============================================
//              DECLARATION
//============================================

// READ CTRL
reg  [6:0] addr_read;
wire [6:0] addr_read_nxt;

reg  [$clog2(WORDS):0] rptr;
wire [$clog2(WORDS):0] rptr_nxt;

reg  [$clog2(WORDS):0] wq2_rptr;

wire rempty_nxt;

wire [WIDTH-1:0] rdata_q;
wire [WIDTH-1:0] rdata_nxt;

// WRITE CTRL
reg  [6:0] addr_write;
wire [6:0] addr_write_nxt;

reg  [$clog2(WORDS):0] wptr;
wire [$clog2(WORDS):0] wptr_nxt;

reg  [$clog2(WORDS):0] rq2_wptr;

wire wfull_nxt;

// FIFO SRAM
wire web_a;

//============================================
//              READ CTRL
//============================================

// DFF of addr_read
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n)
        addr_read <= 0;
    else
        addr_read <= addr_read_nxt;
end

// comb of addr_read
//   act as normal counter
assign addr_read_nxt = (rinc & ~rempty) ? (addr_read + 1) : addr_read;

// DFF of rptr
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n)
        rptr <= 0;
    else
        rptr <= rptr_nxt;
end

// comb of rptr
//   gray code
assign rptr_nxt = (addr_read_nxt >> 1) ^ addr_read_nxt;

// DFF of rempty
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n)
        rempty <= 1;
    else
        rempty <= rempty_nxt;
end

// comb of rempty
//   if(waddr == raddr) -> empty
assign rempty_nxt = (rq2_wptr == rptr_nxt) ? 1 : 0;

// DFF of rdata
always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
        rdata <= rdata_nxt;
    end
end

// comb of rdata
assign rdata_nxt = rdata_q;

//============================================
//              WRITE CTRL
//============================================

// DFF of addr_write
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)
        addr_write <= 0;
    else
        addr_write <= addr_write_nxt;
end

// comb of addr_write
//   act as normal counter
assign addr_write_nxt = (winc & ~wfull) ? (addr_write + 1) : addr_write;

// DFF of wptr
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)
        wptr <= 0;
    else
        wptr <= wptr_nxt;
end

// comb of wptr
//   gray code
assign wptr_nxt = (addr_write_nxt >> 1) ^ addr_write_nxt;

// DFF of wfull
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)
        wfull <= 0;
    else
        wfull <= wfull_nxt;
end

// comb of wfull
//   if({~waddr[...], waddr[...]} == raddr) -> full
assign wfull_nxt = ({~wptr_nxt[$clog2(WORDS):$clog2(WORDS)-1], wptr_nxt[$clog2(WORDS)-2:0]} == wq2_rptr) ? 1 : 0;

// comb of flag_fifo_to_clk2
assign flag_fifo_to_clk2 = !wfull_nxt;

//============================================
//              FIFO NDFF BUS
//============================================

// sync_r2w
NDFF_BUS_syn #(.WIDTH(7)) sync_r2w (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n));

// sync_w2r
NDFF_BUS_syn #(.WIDTH(7)) sync_w2r (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n));

//============================================
//              FIFO SRAM
//============================================

assign web_a = (winc & ~wfull) ? 0 : 1;

// A: write
// B: read
DUAL_64X8X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(web_a),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(addr_write[0]),
    .A1(addr_write[1]),
    .A2(addr_write[2]),
    .A3(addr_write[3]),
    .A4(addr_write[4]),
    .A5(addr_write[5]),
    .B0(addr_read[0]),
    .B1(addr_read[1]),
    .B2(addr_read[2]),
    .B3(addr_read[3]),
    .B4(addr_read[4]),
    .B5(addr_read[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7])
);

endmodule
