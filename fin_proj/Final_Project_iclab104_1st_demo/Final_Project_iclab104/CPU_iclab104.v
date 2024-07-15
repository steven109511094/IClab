//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER = 2, WRIT_NUMBER = 1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//====================================================
//                integer & parameter
//====================================================

parameter   IF                =  0,
            ID                =  1,
            EXE               =  2,
            MEM               =  3,
            WB                =  4,
            INST_WAIT_ARREADY =  5,
            INST_WAIT_RLAST   =  6,
            DATA_WAIT_ARREADY =  7,
            DATA_WAIT_RLAST   =  8,
            DATA_WAIT_AWREADY =  9,
            DATA_WAIT_WREADY  = 10,
            DATA_WAIT_BVALID  = 11,
            CAL_DET           = 12;

parameter signed offset = 16'h1000;

integer i;

//====================================================
//                reg & wire
//====================================================

// FSM
reg  [ 3:0] state;
reg  [ 3:0] state_nxt;

// IF
reg  [15:0] inst;
reg  [15:0] inst_nxt;

wire [ 2:0] opcode;             // details in instruction
wire [ 3:0] rs;
wire [ 3:0] rt;
wire [ 3:0] rd;
wire        func;
wire signed [ 4:0] imm;
wire [ 3:0] coeff_a;
wire [ 8:0] coeff_b;

reg  [ 1:0] cnt_3;              // delay for sram 
reg  [ 1:0] cnt_3_nxt;

reg  [ 4:0] range_s_inst;       // Since address of DRAM_inst: 1000 ~ 1FFF
reg  [ 4:0] range_s_inst_nxt;   // And arlen_inst = 127, arsize = 3'b001 (16 bits = 2 address of dram)
                                // Store pc[12:8] for range judgement


// ID
reg  signed [15:0] rs_data;
reg  signed [15:0] rs_data_nxt;

reg  signed [15:0] rt_data;
reg  signed [15:0] rt_data_nxt;

// EXE
reg         [15:0] addr_data;
reg         [15:0] addr_data_nxt;

reg  signed [15:0] pc;
reg  signed [15:0] pc_nxt;

reg         [ 4:0] cnt_25;      // delay for det(M)
reg         [ 4:0] cnt_25_nxt;

reg  signed [69:0] tmp;

wire        [69:0] shift;
reg  signed [69:0] temp;

// multiplier
reg  signed [16:0] mul_a[2];
reg  signed [16:0] mul_b[2];
wire signed [32:0] mul_z[2];
wire signed [69:0] fuck;

// WB
reg  [ 3:0] addr_WB;
reg  [ 3:0] addr_WB_nxt;

reg  signed [69:0] result;
reg  signed [69:0] result_nxt;

reg  signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;   // Register in each core:
reg  signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;   // There are sixteen registers in your CPU. You should not change the name of those registers.
reg  signed [15:0] core_r8 , core_r9 , core_r10, core_r11;   // TA will check the value in each register when your core is not busy.
reg  signed [15:0] core_r12, core_r13, core_r14, core_r15;   // If you change the name of registers below, you must get the fail in this lab.

reg  signed [15:0] core_r0_nxt , core_r1_nxt , core_r2_nxt , core_r3_nxt;
reg  signed [15:0] core_r4_nxt , core_r5_nxt , core_r6_nxt , core_r7_nxt;
reg  signed [15:0] core_r8_nxt , core_r9_nxt , core_r10_nxt, core_r11_nxt;
reg  signed [15:0] core_r12_nxt, core_r13_nxt, core_r14_nxt, core_r15_nxt;

// SRAM
reg  [ 6:0] cnt_128;
reg  [ 6:0] cnt_128_nxt;

reg  [ 6:0] addr_s_inst;
reg  [ 6:0] addr_s_inst_nxt;

reg  [15:0] DO_s_inst;
reg  [15:0] DO_s_inst_nxt;

reg  [15:0] DI_s_inst;
reg  [15:0] DI_s_inst_nxt;

reg         WEB_s_inst;
reg         WEB_s_inst_nxt;

// DRAM
wire [ 3:0] arid_inst;
wire [ 1:0] arburst_inst;
wire [ 2:0] arsize_inst;
wire [ 6:0] arlen_inst;

wire [31:0] araddr_inst;
wire        arvalid_inst;
wire        arready_inst;  

wire [15:0] rdata_inst;
wire        rvalid_inst;
wire        rlast_inst;
wire        rready_inst;

wire [ 3:0] arid_data;
wire [ 1:0] arburst_data;
wire [ 2:0] arsize_data;
wire [ 6:0] arlen_data;

wire [31:0] araddr_data;
wire        arvalid_data;
wire        arready_data;  

wire [15:0] rdata_data;
wire        rvalid_data;
wire        rlast_data;
wire        rready_data;

// OUTPUT
reg         IO_stall_nxt;       

//====================================================
//                FSM
//====================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IF;
    end
    else begin
        state <= state_nxt;
    end
end

always @(*) begin
    case (state)
        IF: begin
            if(pc[12:8] != range_s_inst) begin
                state_nxt = INST_WAIT_ARREADY;
            end
            else if(cnt_3 == 2) begin
                state_nxt = ID;
            end
            else begin
                state_nxt = IF;
            end
        end
        ID: begin
            state_nxt = EXE;
        end
        EXE: begin
            case (opcode)
                // load
                2: begin
                    state_nxt = DATA_WAIT_ARREADY;
                end 
                // store
                3: begin
                    state_nxt = DATA_WAIT_AWREADY;
                end
                // beq
                4: begin
                    state_nxt = IF;
                end
                7: begin
                    state_nxt = CAL_DET;
                end
                default: begin
                    state_nxt = WB;
                end
            endcase
        end
        WB: begin
            state_nxt = IF;
        end
        INST_WAIT_ARREADY: begin
            state_nxt = (arready_inst) ? INST_WAIT_RLAST : INST_WAIT_ARREADY;
        end
        INST_WAIT_RLAST: begin
            state_nxt = (rlast_inst) ? IF : INST_WAIT_RLAST;
        end
        DATA_WAIT_ARREADY: begin
            state_nxt = (arready_data) ? DATA_WAIT_RLAST : DATA_WAIT_ARREADY;
        end
        DATA_WAIT_RLAST: begin
            state_nxt = (rlast_data) ? WB : DATA_WAIT_RLAST;
        end
        DATA_WAIT_AWREADY: begin
            state_nxt = (awready_m_inf) ? DATA_WAIT_WREADY : DATA_WAIT_AWREADY;
        end
        DATA_WAIT_WREADY: begin
            state_nxt = (wready_m_inf) ? DATA_WAIT_BVALID : DATA_WAIT_WREADY;
        end
        DATA_WAIT_BVALID: begin
            state_nxt = (bvalid_m_inf) ? IF : DATA_WAIT_BVALID;
        end
        CAL_DET: begin
            state_nxt = (cnt_25 == 24) ? WB : CAL_DET;
        end
        default: begin
            state_nxt = state;
        end
    endcase
end

//====================================================
//                FETCH
//====================================================

// inst
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        inst <= 0;
    end
    else begin
        inst <= inst_nxt;
    end
end

always @(*) begin
    if(state == IF) begin
        inst_nxt = DO_s_inst;
    end
    else begin
        inst_nxt = inst;
    end
end

// opcode
assign opcode = inst[15:13];

// rs
assign rs = inst[12:9];

// rt
assign rt = inst[8:5];

// rd
assign rd = inst[4:1];

// func
assign func = inst[0];

// imm
assign imm = inst[4:0];

// coeff_a
assign coeff_a = inst[12:9];

// coeff_b
assign coeff_b = inst[8:0];

// cnt_3
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_3 <= 0;
    end
    else begin
        cnt_3 <= cnt_3_nxt;
    end
end

always @(*) begin
    if(state == IF) begin
        cnt_3_nxt = cnt_3 + 1;
    end
    else begin
        cnt_3_nxt = 0;
    end
end

// range_s_inst
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        range_s_inst <= 0;
    end
    else begin
        range_s_inst <= range_s_inst_nxt;
    end
end

always @(*) begin
    if(state == INST_WAIT_ARREADY) begin
        range_s_inst_nxt = pc[12:8];
    end
    else begin
        range_s_inst_nxt = range_s_inst;
    end
end

//====================================================
//                DECODE
//====================================================

// rs_data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rs_data <= 0;
    end
    else begin
        rs_data <= rs_data_nxt;
    end
end

always @(*) begin
    if(state == ID) begin
        case (rs)
             0: rs_data_nxt = core_r0; 
             1: rs_data_nxt = core_r1; 
             2: rs_data_nxt = core_r2; 
             3: rs_data_nxt = core_r3; 
             4: rs_data_nxt = core_r4; 
             5: rs_data_nxt = core_r5; 
             6: rs_data_nxt = core_r6; 
             7: rs_data_nxt = core_r7;
             8: rs_data_nxt = core_r8; 
             9: rs_data_nxt = core_r9; 
            10: rs_data_nxt = core_r10; 
            11: rs_data_nxt = core_r11;
            12: rs_data_nxt = core_r12; 
            13: rs_data_nxt = core_r13; 
            14: rs_data_nxt = core_r14; 
            15: rs_data_nxt = core_r15;
        endcase
    end
    else begin
        rs_data_nxt = rs_data;
    end
end

// rt_data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rt_data <= 0;
    end
    else begin
        rt_data <= rt_data_nxt;
    end
end

always @(*) begin
    if(state == ID) begin
        case (rt)
             0: rt_data_nxt = core_r0; 
             1: rt_data_nxt = core_r1; 
             2: rt_data_nxt = core_r2; 
             3: rt_data_nxt = core_r3; 
             4: rt_data_nxt = core_r4; 
             5: rt_data_nxt = core_r5; 
             6: rt_data_nxt = core_r6; 
             7: rt_data_nxt = core_r7;
             8: rt_data_nxt = core_r8; 
             9: rt_data_nxt = core_r9; 
            10: rt_data_nxt = core_r10; 
            11: rt_data_nxt = core_r11;
            12: rt_data_nxt = core_r12; 
            13: rt_data_nxt = core_r13; 
            14: rt_data_nxt = core_r14; 
            15: rt_data_nxt = core_r15;
        endcase
    end
    else begin
        rt_data_nxt = rt_data;
    end
end

//====================================================
//                EXE
//====================================================

// addr_data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_data <= offset;
    end
    else begin
        addr_data <= addr_data_nxt;
    end
end

always @(*) begin
    if((state == EXE) && ((opcode == 2) || (opcode == 3))) begin
        addr_data_nxt = ((rs_data + imm) << 1) + offset;
    end
    else begin
        addr_data_nxt = addr_data;
    end
end

// pc
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc <= offset;
    end
    else begin
        pc <= pc_nxt;
    end
end

always @(*) begin
    if(state == EXE) begin
        if((opcode == 4) && (rs_data == rt_data)) begin
            pc_nxt = pc + 2 + imm * 2;
        end
        else begin
            pc_nxt = pc + 2;
        end
    end
    else begin
        pc_nxt = pc;
    end
end

// cnt_25
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_25 <= 0;
    end
    else begin
        cnt_25 <= cnt_25_nxt;
    end
end

always @(*) begin
    if(state == CAL_DET) begin
        cnt_25_nxt = cnt_25 + 1;
    end
    else begin
        cnt_25_nxt = 0;
    end
end

// tmp
always @(*) begin
    if(state == EXE) begin
        case (opcode)
            0: begin
                // SUB
                if(func) begin
                    tmp = rs_data - rt_data;
                end
                // ADD
                else begin
                    tmp = rs_data + rt_data;
                end
            end
            1: begin
                // MUL
                if(func) begin
                    tmp = rs_data * rt_data;
                end
                // SLT
                else begin
                    tmp = (rs_data < rt_data) ? 1 : 0;
                end
            end
            default: begin
                tmp = 0;
            end
        endcase
    end
    else begin
        tmp = 0;
    end
end

// shift
assign shift = result >>> (coeff_a * 2);

// temp
assign temp = shift + coeff_b;

//====================================================
//                MULTIPLIER
//====================================================

// mul_a
always @(*) begin
    if(state == CAL_DET) begin
        case (cnt_25)
             0: mul_a[0] = core_r0;
             1: mul_a[0] = core_r0;
             2: mul_a[0] = core_r0;
             3: mul_a[0] = core_r0;
             4: mul_a[0] = core_r0;
             5: mul_a[0] = core_r0;
             6: mul_a[0] = core_r1;
             7: mul_a[0] = core_r2;
             8: mul_a[0] = core_r3;
             9: mul_a[0] = core_r3;
            10: mul_a[0] = core_r2;
            11: mul_a[0] = core_r1;
            12: mul_a[0] = core_r1;
            13: mul_a[0] = core_r2;
            14: mul_a[0] = core_r3;
            15: mul_a[0] = core_r3;
            16: mul_a[0] = core_r2;
            17: mul_a[0] = core_r1;
            18: mul_a[0] = core_r1;
            19: mul_a[0] = core_r2;
            20: mul_a[0] = core_r3;
            21: mul_a[0] = core_r3;
            22: mul_a[0] = core_r2;
            23: mul_a[0] = core_r1;
            default: mul_a[0] = 0;
        endcase
    end
    else begin
        mul_a[0] = 0;
    end
end

always @(*) begin
    if(state == CAL_DET) begin
        case (cnt_25)
             0: mul_a[1] = core_r5;
             1: mul_a[1] = core_r6;
             2: mul_a[1] = core_r7;
             3: mul_a[1] = core_r7;
             4: mul_a[1] = core_r6;
             5: mul_a[1] = core_r5;
             6: mul_a[1] = core_r4;
             7: mul_a[1] = core_r4;
             8: mul_a[1] = core_r4;
             9: mul_a[1] = core_r4;
            10: mul_a[1] = core_r4;
            11: mul_a[1] = core_r4;
            12: mul_a[1] = core_r6;
            13: mul_a[1] = core_r7;
            14: mul_a[1] = core_r5;
            15: mul_a[1] = core_r6;
            16: mul_a[1] = core_r5;
            17: mul_a[1] = core_r7;
            18: mul_a[1] = core_r6;
            19: mul_a[1] = core_r7;
            20: mul_a[1] = core_r5;
            21: mul_a[1] = core_r6;
            22: mul_a[1] = core_r5;
            23: mul_a[1] = core_r7;
            default: mul_a[1] = 0;
        endcase
    end
    else begin
        mul_a[1] = 0;
    end
end

// mul_b
always @(*) begin
    if(state == CAL_DET) begin
        case (cnt_25)
             0: mul_b[0] = core_r10;
             1: mul_b[0] = core_r11;
             2: mul_b[0] = core_r9;
             3: mul_b[0] = core_r10;
             4: mul_b[0] = core_r9;
             5: mul_b[0] = core_r11;
             6: mul_b[0] = core_r10;
             7: mul_b[0] = core_r11;
             8: mul_b[0] = core_r9;
             9: mul_b[0] = core_r10;
            10: mul_b[0] = core_r9;
            11: mul_b[0] = core_r11;
            12: mul_b[0] = core_r8;
            13: mul_b[0] = core_r8;
            14: mul_b[0] = core_r8;
            15: mul_b[0] = core_r8;
            16: mul_b[0] = core_r8;
            17: mul_b[0] = core_r8;
            18: mul_b[0] = core_r11;
            19: mul_b[0] = core_r9;
            20: mul_b[0] = core_r10;
            21: mul_b[0] = core_r9;
            22: mul_b[0] = core_r11;
            23: mul_b[0] = core_r10;
            default: mul_b[0] = 0;
        endcase
    end
    else begin
        mul_b[0] = 0;
    end
end

always @(*) begin
    if(state == CAL_DET) begin
        case (cnt_25)
             0: mul_b[1] = core_r15;
             1: mul_b[1] = core_r13;
             2: mul_b[1] = core_r14;
             3: mul_b[1] = core_r13;
             4: mul_b[1] = core_r15;
             5: mul_b[1] = core_r14;
             6: mul_b[1] = core_r15;
             7: mul_b[1] = core_r13;
             8: mul_b[1] = core_r14;
             9: mul_b[1] = core_r13;
            10: mul_b[1] = core_r15;
            11: mul_b[1] = core_r14;
            12: mul_b[1] = core_r15;
            13: mul_b[1] = core_r13;
            14: mul_b[1] = core_r14;
            15: mul_b[1] = core_r13;
            16: mul_b[1] = core_r15;
            17: mul_b[1] = core_r14;
            18: mul_b[1] = core_r12;
            19: mul_b[1] = core_r12;
            20: mul_b[1] = core_r12;
            21: mul_b[1] = core_r12;
            22: mul_b[1] = core_r12;
            23: mul_b[1] = core_r12;
            default: mul_b[1] = 0;
        endcase
    end
    else begin
        mul_b[1] = 0;
    end
end

// mul_z
assign mul_z[0] = mul_a[0] * mul_b[0];
assign mul_z[1] = mul_a[1] * mul_b[1];
assign fuck = mul_z[0] * mul_z[1];

//====================================================
//                WB
//====================================================

// addr_WB
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_WB <= 0;
    end
    else begin
        addr_WB <= addr_WB_nxt;
    end
end

always @(*) begin
    if(state == EXE) begin
        case (opcode)
            2: begin
                addr_WB_nxt = rt;
            end
            7: begin
                addr_WB_nxt = 0;
            end
            default: begin
                addr_WB_nxt = rd;
            end
        endcase
    end
    else begin
        addr_WB_nxt = addr_WB;
    end
end

// result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result <= 0;
    end
    else begin
        result <= result_nxt;
    end
end

always @(*) begin
    case (state)
        EXE: begin
            result_nxt = tmp;
        end
        DATA_WAIT_RLAST: begin
            if(rlast_data) begin
                result_nxt = rdata_data;
            end
            else begin
                result_nxt = result;
            end
        end
        CAL_DET: begin
            if(cnt_25 < 24) begin
                case (cnt_25)
                     0: result_nxt = result + fuck;
                     1: result_nxt = result + fuck;
                     2: result_nxt = result + fuck;
                     3: result_nxt = result - fuck;
                     4: result_nxt = result - fuck;
                     5: result_nxt = result - fuck;
                     6: result_nxt = result - fuck;
                     7: result_nxt = result - fuck;
                     8: result_nxt = result - fuck;
                     9: result_nxt = result + fuck;
                    10: result_nxt = result + fuck;
                    11: result_nxt = result + fuck;
                    12: result_nxt = result + fuck;
                    13: result_nxt = result + fuck;
                    14: result_nxt = result + fuck;
                    15: result_nxt = result - fuck;
                    16: result_nxt = result - fuck;
                    17: result_nxt = result - fuck;
                    18: result_nxt = result - fuck;
                    19: result_nxt = result - fuck;
                    20: result_nxt = result - fuck;
                    21: result_nxt = result + fuck;
                    22: result_nxt = result + fuck;
                    23: result_nxt = result + fuck;
                    default: begin
                        result_nxt = result;
                    end
                endcase
            end
            else begin
                if(temp > 32767) begin
                    result_nxt = 32767;
                end
                else if(temp < -32768) begin
                    result_nxt = -32768;
                end
                else begin
                    result_nxt = temp;
                end
            end
        end
        default: begin
            result_nxt = result;
        end
    endcase
end

// core_reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r0 <= 0;
    end
    else begin
        core_r0 <= core_r0_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 0)) begin
        core_r0_nxt = result;
    end
    else begin
        core_r0_nxt = core_r0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r1 <= 0;
    end
    else begin
        core_r1 <= core_r1_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 1)) begin
        core_r1_nxt = result;
    end
    else begin
        core_r1_nxt = core_r1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r2 <= 0;
    end
    else begin
        core_r2 <= core_r2_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 2)) begin
        core_r2_nxt = result;
    end
    else begin
        core_r2_nxt = core_r2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r3 <= 0;
    end
    else begin
        core_r3 <= core_r3_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 3)) begin
        core_r3_nxt = result;
    end
    else begin
        core_r3_nxt = core_r3;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r4 <= 0;
    end
    else begin
        core_r4 <= core_r4_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 4)) begin
        core_r4_nxt = result;
    end
    else begin
        core_r4_nxt = core_r4;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r5 <= 0;
    end
    else begin
        core_r5 <= core_r5_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 5)) begin
        core_r5_nxt = result;
    end
    else begin
        core_r5_nxt = core_r5;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r6 <= 0;
    end
    else begin
        core_r6 <= core_r6_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 6)) begin
        core_r6_nxt = result;
    end
    else begin
        core_r6_nxt = core_r6;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r7 <= 0;
    end
    else begin
        core_r7 <= core_r7_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 7)) begin
        core_r7_nxt = result;
    end
    else begin
        core_r7_nxt = core_r7;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r8 <= 0;
    end
    else begin
        core_r8 <= core_r8_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 8)) begin
        core_r8_nxt = result;
    end
    else begin
        core_r8_nxt = core_r8;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r9 <= 0;
    end
    else begin
        core_r9 <= core_r9_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 9)) begin
        core_r9_nxt = result;
    end
    else begin
        core_r9_nxt = core_r9;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r10 <= 0;
    end
    else begin
        core_r10 <= core_r10_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 10)) begin
        core_r10_nxt = result;
    end
    else begin
        core_r10_nxt = core_r10;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r11 <= 0;
    end
    else begin
        core_r11 <= core_r11_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 11)) begin
        core_r11_nxt = result;
    end
    else begin
        core_r11_nxt = core_r11;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r12 <= 0;
    end
    else begin
        core_r12 <= core_r12_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 12)) begin
        core_r12_nxt = result;
    end
    else begin
        core_r12_nxt = core_r12;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r13 <= 0;
    end
    else begin
        core_r13 <= core_r13_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 13)) begin
        core_r13_nxt = result;
    end
    else begin
        core_r13_nxt = core_r13;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r14 <= 0;
    end
    else begin
        core_r14 <= core_r14_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 14)) begin
        core_r14_nxt = result;
    end
    else begin
        core_r14_nxt = core_r14;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r15 <= 0;
    end
    else begin
        core_r15 <= core_r15_nxt;
    end
end

always @(*) begin
    if((state == WB) && (addr_WB == 15)) begin
        core_r15_nxt = result;
    end
    else begin
        core_r15_nxt = core_r15;
    end
end

//====================================================
//                SRAM
//====================================================

// cnt_128
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_128 <= 0;
    end
    else begin
        cnt_128 <= cnt_128_nxt;
    end
end

always @(*) begin
    if((state == INST_WAIT_RLAST) && (rvalid_inst)) begin
        cnt_128_nxt = cnt_128 + 1;
    end
    else begin
        cnt_128_nxt = 0;
    end
end

// addr_s_inst
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_s_inst <= 0;
    end
    else begin
        addr_s_inst <= addr_s_inst_nxt;
    end
end

always @(*) begin
    if((state == INST_WAIT_RLAST) && (rvalid_inst)) begin
        addr_s_inst_nxt = cnt_128;
    end
    else if (state == IF) begin
        addr_s_inst_nxt = pc[7:1];
    end
    else begin
        addr_s_inst_nxt = 0;
    end
end

// DI_s_inst
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_s_inst <= 0;
    end
    else begin
        DI_s_inst <= DI_s_inst_nxt;
    end
end

always @(*) begin
    if((state == INST_WAIT_RLAST) && (rvalid_inst)) begin
        DI_s_inst_nxt = rdata_inst;
    end
    else begin
        DI_s_inst_nxt = 0;
    end
end

// WEB_s_inst
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WEB_s_inst <= 0;
    end
    else begin
        WEB_s_inst <= WEB_s_inst_nxt;
    end
end

always @(*) begin
    if((state == INST_WAIT_RLAST) && (rvalid_inst)) begin
        WEB_s_inst_nxt = 0;
    end
    else begin
        WEB_s_inst_nxt = 1;
    end
end

SRAM_inst s_inst (  .A0(addr_s_inst[0]), .A1(addr_s_inst[1]), .A2(addr_s_inst[2]), .A3(addr_s_inst[3]), .A4(addr_s_inst[4]), .A5(addr_s_inst[5]), .A6(addr_s_inst[6]),
 
                    .DO0(DO_s_inst[0]), .DO1(DO_s_inst[1]), . DO2(DO_s_inst[ 2]), . DO3(DO_s_inst[ 3]), . DO4(DO_s_inst[ 4]), . DO5(DO_s_inst[ 5]), . DO6(DO_s_inst[ 6]), . DO7(DO_s_inst[ 7]),  
                    .DO8(DO_s_inst[8]), .DO9(DO_s_inst[9]), .DO10(DO_s_inst[10]), .DO11(DO_s_inst[11]), .DO12(DO_s_inst[12]), .DO13(DO_s_inst[13]), .DO14(DO_s_inst[14]), .DO15(DO_s_inst[15]),

                    .DI0(DI_s_inst[0]), .DI1(DI_s_inst[1]), . DI2(DI_s_inst[ 2]), . DI3(DI_s_inst[ 3]), . DI4(DI_s_inst[ 4]), . DI5(DI_s_inst[ 5]), . DI6(DI_s_inst[ 6]), . DI7(DI_s_inst[ 7]),
                    .DI8(DI_s_inst[8]), .DI9(DI_s_inst[9]), .DI10(DI_s_inst[10]), .DI11(DI_s_inst[11]), .DI12(DI_s_inst[12]), .DI13(DI_s_inst[13]), .DI14(DI_s_inst[14]), .DI15(DI_s_inst[15]),

                    .CK(clk), .WEB(WEB_s_inst), .OE(1'b1), .CS(1'b1));
//====================================================
//                DRAM
//====================================================

//////////////////////////////////////////////////////
// INST

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 

assign arid_inst = 0;       // read address ID
							// only recognize master(4'b0000) in this project

assign arburst_inst = 1;    // burst type
							// only support INCR(2'b01) in this project

assign arsize_inst = 1; 	// burst size
							// only support 3'b001 (2 bytes = 16 bits) in this project

assign arlen_inst = 127; 	// burst length
							// determine number of data transfered with the associated address
							// in my design, it should be as large as possible(=127)

// ------------------------
// (2)	axi read data channel 

assign arvalid_inst = (state == INST_WAIT_ARREADY) ? 1 : 0;

assign araddr_inst = (state == INST_WAIT_ARREADY) ? {19'b0, pc[12:8], 8'b0} : 0;

assign rready_inst = (state == INST_WAIT_RLAST) ? 1 : 0;

// ------------------------

//////////////////////////////////////////////////////
// DATA

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 

assign arid_data = 0;       // read address ID
							// only recognize master(4'b0000) in this project

assign arburst_data = 1;    // burst type
							// only support INCR(2'b01) in this project

assign arsize_data = 1; 	// burst size
							// only support 3'b001 (2 bytes = 16 bits) in this project

assign arlen_data = 0; 	    // burst length
							// determine number of data transfered with the associated address
							// in my design, it should be 0 for only one data to load

// ------------------------
// (2)	axi read data channel 

assign arvalid_data = (state == DATA_WAIT_ARREADY) ? 1 : 0;

assign araddr_data = (state == DATA_WAIT_ARREADY) ? addr_data : 0;

assign rready_data = (state == DATA_WAIT_RLAST) ? 1 : 0;

// ------------------------

// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 

assign awid_m_inf = 0;		// write address ID
							// only recognize master(4'b0000) in this project

assign awburst_m_inf = 1;	// burst type
							// only support INCR(2'b01) in this project

assign awsize_m_inf = 1;	// burst size
							// only support 3'b001 (2 bytes = 16 bits) in this project

assign awlen_m_inf = 0;	    // burst length
							// determine number of data transfered with the associated address
							// in my design, it should be 0 for only one address to store

// ------------------------
// (2)	axi read data channel 

assign awvalid_m_inf = (state == DATA_WAIT_AWREADY) ? 1 : 0;

assign awaddr_m_inf = (state == DATA_WAIT_AWREADY) ? addr_data : 0;

assign wvalid_m_inf = (state == DATA_WAIT_WREADY) ? 1 : 0;

assign wdata_m_inf = (state == DATA_WAIT_WREADY) ? rt_data : 0;

assign wlast_m_inf = ((state == DATA_WAIT_WREADY)) ? 1 : 0;

assign bready_m_inf = ((state == DATA_WAIT_WREADY) || (state == DATA_WAIT_BVALID)) ? 1 : 0; 

// ------------------------

//////////////////////////////////////////////////////
// SUM

assign arid_m_inf = {arid_inst, arid_data};

assign arburst_m_inf = {arburst_inst, arburst_data};

assign arsize_m_inf = {arsize_inst, arsize_data};

assign arlen_m_inf = {arlen_inst, arlen_data};

assign arvalid_m_inf = {arvalid_inst, arvalid_data};

assign araddr_m_inf = {araddr_inst, araddr_data};

assign {arready_inst, arready_data} = arready_m_inf;

assign {rdata_inst, rdata_data} = rdata_m_inf;

assign {rvalid_inst, rvalid_data} = rvalid_m_inf;

assign {rlast_inst, rlast_data} = rlast_m_inf;

assign rready_m_inf = {rready_inst, rready_data};

//====================================================
//                IO_STALL
//====================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        IO_stall <= 1;
    end
    else begin
        IO_stall <= IO_stall_nxt;
    end
end

always @(*) begin
    if((state == WB || state == DATA_WAIT_BVALID || state == EXE) && (state_nxt == IF)) begin
        IO_stall_nxt = 0;
    end
    else begin
        IO_stall_nxt = 1;
    end
end

endmodule












