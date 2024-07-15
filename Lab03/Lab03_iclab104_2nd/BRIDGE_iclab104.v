//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE          =  0,
          AR_ready      =  1,
          R_ready       =  2,
          COMMAND       =  3,
          RESPONSE      =  4,
          WAIT_24       =  5,
          SD_write      =  6,
          DATA_response =  7,
          BUSY          =  8,
          WAIT_MISO     =  9,
          SD_read       = 10,
          AW_ready      = 11,
          W_ready       = 12,
          B_valid       = 13,
          OUT           = 14;

//==============================================//
//                    FSM                       //
//==============================================//
// IDLE declaration
reg         in_valid_reg;
wire        in_valid_nxt;
reg         dir_reg;
wire        dir_nxt;

reg  [3:0]  state;
reg  [3:0]  state_nxt;
reg  [5:0]  cnt48;
wire [5:0]  cnt48_nxt;
reg  [5:0]  cnt8;
wire [5:0]  cnt8_nxt;
reg  [6:0]  cnt88;
wire [6:0]  cnt88_nxt;
reg  [6:0]  cnt80;
wire [6:0]  cnt80_nxt;
reg  [5:0]  cnt24;
wire [5:0]  cnt24_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= 0;
        cnt48 <= 0;
        cnt8 <= 0;
        cnt88 <= 0;
        cnt80 <= 0;
        cnt24 <= 0;
    end
    else begin
        state <= state_nxt;
        cnt48 <= cnt48_nxt;
        cnt8 <= cnt8_nxt;
        cnt88 <= cnt88_nxt;
        cnt80 <= cnt80_nxt;
        cnt24 <= cnt24_nxt;
    end
end

assign cnt48_nxt = (state == COMMAND)  ? (cnt48 + 1) : 0;
assign cnt8_nxt  = (((state == RESPONSE) && (MISO == 0)) || (state == DATA_response) || (state == OUT)) ? (cnt8 + 1) : 0;
assign cnt88_nxt = (state == SD_write) ? (cnt88 + 1) : 0;
assign cnt80_nxt = (state == SD_read) ? (cnt80 + 1) : 0; 
assign cnt24_nxt = (state == WAIT_24) ? (cnt24 + 1) : 0;

always @(*) begin
    case(state)
        IDLE : begin
            if(in_valid_reg) begin
                if(dir_reg == 0) begin
                    state_nxt = AR_ready;
                end
                else if(dir_reg == 1) begin
                    state_nxt = COMMAND;
                end
                else begin
                    state_nxt = IDLE;
                end
            end
            else begin
                state_nxt = IDLE;
            end
        end
        AR_ready : begin
            if(AR_READY && AR_VALID) begin
                state_nxt = R_ready;
            end
            else begin
                state_nxt = AR_ready;
            end
        end
        R_ready : begin
            if(R_READY && R_VALID) begin
                state_nxt = COMMAND;
            end
            else begin
                state_nxt = R_ready;
            end
        end
        COMMAND : begin
            if(cnt48 >= 47) begin
                state_nxt = RESPONSE;
            end
            else begin
                state_nxt = COMMAND;
            end
        end
        RESPONSE : begin
            if(cnt8 >= 7 && dir_reg == 0) begin
                state_nxt = WAIT_24;
            end
            else if(cnt8 >= 7 && dir_reg == 1) begin
                state_nxt = WAIT_MISO;
            end
            else begin
                state_nxt = RESPONSE;
            end
        end
        WAIT_24 : begin
            if(cnt24 >= 22) begin
                state_nxt = SD_write;
            end
            else begin
                state_nxt = WAIT_24;
            end
        end
        SD_write : begin
            if(cnt88 >= 87) begin
                state_nxt = DATA_response;
            end

            else begin
                state_nxt = SD_write;
            end
        end
        DATA_response : begin
            if(cnt8 >= 8) begin
                state_nxt = BUSY;
            end
            else begin
                state_nxt = DATA_response;
            end
        end
        BUSY : begin
            if(MISO == 0) begin
                state_nxt = BUSY;
            end
            else begin
                state_nxt = OUT;
            end
        end
        WAIT_MISO : begin
            if(MISO == 0) begin
                state_nxt = SD_read;
            end
            else begin
                state_nxt = WAIT_MISO;
            end
        end
        SD_read : begin
            if(cnt80 >= 79) begin
                state_nxt = AW_ready;
            end
            else begin
                state_nxt = SD_read;
            end
        end
        AW_ready : begin
            if(AW_READY && AW_VALID) begin
                state_nxt = W_ready;
            end
            else begin
                state_nxt = AW_ready;
            end
        end
        W_ready : begin
            if(W_READY && W_VALID) begin
                state_nxt = B_valid;
            end
            else begin
                state_nxt = W_ready;
            end
        end
        B_valid : begin
            if(B_VALID && B_READY) begin
                state_nxt = OUT;
            end
            else begin
                state_nxt = B_valid;
            end
        end
        OUT : begin
            if(cnt8 >= 7) begin
                state_nxt = IDLE;
            end
            else begin
                state_nxt = OUT;
            end
        end
        default : begin
            state_nxt = IDLE;
        end
    endcase
end

//==============================================//
//                     IDLE                     //
//==============================================//
reg  [31:0] addr_dram_reg;
wire [31:0] addr_dram_nxt;
reg  [31:0] addr_sd_reg;
wire [31:0] addr_sd_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_reg <= 0;
        addr_dram_reg <= 0;
        addr_sd_reg <= 0;
        dir_reg <= 0;
    end
    else begin
        in_valid_reg <= in_valid;
        addr_dram_reg <= addr_dram_nxt;
        addr_sd_reg <= addr_sd_nxt;
        dir_reg <= dir_nxt;
    end
end

assign in_valid_nxt = (in_valid) ? 1 : 0;
assign addr_dram_nxt = (in_valid) ? addr_dram : addr_dram_reg;
assign addr_sd_nxt = (in_valid) ? addr_sd : addr_sd_reg;
assign dir_nxt = (in_valid) ? direction : dir_reg;

//==============================================//
//                 DRAM read                    //
//==============================================//
reg         AR_VALID_nxt;
reg  [31:0] AR_ADDR_nxt;
reg         R_READY_nxt;
reg  [63:0] data_dram;
wire [63:0] data_dram_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AR_VALID <= 0;
        AR_ADDR <= 0;
        R_READY <= 0;
        data_dram <= 0;
    end
    else begin
        AR_VALID <= AR_VALID_nxt;
        AR_ADDR <= AR_ADDR_nxt;
        R_READY <= R_READY_nxt;
        data_dram <= data_dram_nxt;
    end
end

assign AR_VALID_nxt = (state == AR_ready) ? ((!AR_READY) ? 1 : 0) : 0;
assign AR_ADDR_nxt = (state == AR_ready) ? ((!AR_READY) ? addr_dram_reg : 0) : 0;
assign R_READY_nxt = (state == R_ready) ? 1 : 0;
assign data_dram_nxt = (R_VALID && R_READY) ? R_DATA : ((state == OUT) ? (data_dram << 8) : data_dram);

//==============================================//
//                   COMMAND                    //
//==============================================//
wire [6:0]  crc7;
wire [47:0] MOSI48_tmp;
wire [47:0] MOSI48_nxt;
reg  [47:0] MOSI48;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        MOSI48 <= 0;
    end
    else begin
        MOSI48 <= MOSI48_nxt;
    end
end

assign crc7 = (dir_reg) ? CRC7(.data({2'b01, 6'd17, addr_sd_reg})) : CRC7(.data({2'b01, 6'd24, addr_sd_reg}));
assign MOSI48_tmp = (dir_reg) ? {2'b01, 6'd17, addr_sd_reg, crc7, 1'b1} : {2'b01, 6'd24, addr_sd_reg, crc7, 1'b1};
assign MOSI48_nxt = (state == COMMAND) ? (MOSI48 << 1) : MOSI48_tmp;

//==============================================//
//                   RESPONSE                   //
//==============================================//

//==============================================//
//                   WAIT_24                    //
//==============================================//

//==============================================//
//                   SD_write                   //
//==============================================//
wire [15:0] crc16;
reg  [87:0] MOSI88;
wire [87:0] MOSI88_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        MOSI88 <= 0;
    end
    else begin
        MOSI88 <= MOSI88_nxt;
    end
end

assign crc16 = CRC16_CCITT(.data(data_dram));
assign MOSI88_nxt = (state == SD_write) ? MOSI88 << 1 : {8'hFE, data_dram, crc16};

//==============================================//
//                 DATA_response                //
//==============================================//

//==============================================//
//                     BUSY                     //
//==============================================//

//==============================================//
//                     SD_read                  //
//==============================================//
reg  [79:0] data_sd;
wire [79:0] data_sd_shift;
wire [79:0] data_sd_tmp;
wire [79:0] data_sd_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_sd <= 0;
    end
    else begin
        data_sd <= data_sd_nxt;
    end
end

assign data_sd_shift = data_sd << 1;
assign data_sd_tmp[79:1] = (state == SD_read) ? data_sd_shift[79:1] : data_sd[79:1];
assign data_sd_tmp[0] = (state == SD_read) ? MISO : data_sd[0];
assign data_sd_nxt = (state == OUT) ? (data_sd_tmp << 8) : data_sd_tmp;

//==============================================//
//                     AW_ready                 //
//==============================================//
wire        AW_VALID_nxt;
wire [31:0] AW_ADDR_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AW_VALID <= 0;
        AW_ADDR <= 0;
    end
    else begin
        AW_VALID <= AW_VALID_nxt;
        AW_ADDR <= AW_ADDR_nxt;
    end
end

assign AW_VALID_nxt = (state == AW_ready) ? (!(AW_READY) ? 1 : 0) : 0;
assign AW_ADDR_nxt = (state == AW_ready) ? (!(AW_READY) ? addr_dram_reg : 0) : 0;

//==============================================//
//                     W_ready                  //
//==============================================//
wire        W_VALID_nxt;
wire [63:0] W_DATA_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        W_VALID <= 0;
        W_DATA <= 0;
    end
    else begin
        W_VALID <= W_VALID_nxt;
        W_DATA <= W_DATA_nxt;
    end
end

assign W_VALID_nxt = (state == W_ready) ? 1 : 0;
assign W_DATA_nxt = (state == W_ready) ? data_sd[79:16] : 0;

//==============================================//
//                     B_valid                  //
//==============================================//
reg         B_READY_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        B_READY <= 0;
    end
    else begin
        B_READY <= B_READY_nxt;
    end
end

assign B_READY_nxt = ((state == W_ready) || (state == B_valid)) ? 1 : 0;

//==============================================//
//                      OUT                     //
//==============================================//
wire        out_valid_nxt;
wire [7:0]  out_data_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 0;
        out_valid <= 0;
    end
    else begin
        out_data <= out_data_nxt;
        out_valid <= out_valid_nxt;
    end
end

assign out_valid_nxt = (state == OUT) ? 1 : 0;
assign out_data_nxt = (state == OUT) ? ((dir_reg) ? data_sd[79:72] : data_dram[63:56]) : 0;

//==============================================//
//                     MOSI                     //
//==============================================//
wire        MOSI_nxt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        MOSI <= 1;
    end
    else begin
        MOSI <= MOSI_nxt;
    end
end

assign MOSI_nxt = (state == COMMAND) ? MOSI48[47] : ((state == SD_write) ? MOSI88[87] : 1);

//==============================================//
//             Example for function             //
//==============================================//
function automatic [6:0] CRC7; // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9; // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1; // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT; // Return 16-bit result
    input [63:0] data; // 64-bit data input
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021; // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1; // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction

endmodule

