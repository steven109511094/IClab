// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input cg_en;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//

parameter 	IDLE 	= 0,	// Initial
			INPUT 	= 1,	// Input signals
			CONV 	= 2, 	// Convolution
			QNT_MAP = 3,	// Quantization of feature map
			MAXPOOL = 4,	// Maxpooling
			FC		= 5,	// Fully connected
			QNT_ENV = 6,	// Quantization of encoded vector
			WAIT	= 7,	// For state_1, wait calculation of state_2
			L1_DIST = 7,	// L1_distance
			ACT		= 8,	// Activation function
			OUTPUT	= 9;	// Output signals

parameter 	scale_map = 2295,
			scale_env = 510;

integer i;
genvar i_gen;

//==============================================//
//           reg & wire declaration             //
//==============================================//

// CLOCK GATED
reg 	  clk_sleep_img_1	[36];
reg 	  clk_gated_img_1	[36];

reg 	  clk_sleep_img_2	[36];
reg 	  clk_gated_img_2	[36];

reg 	  clk_sleep_ker		[9];
reg 	  clk_gated_ker		[9];

reg 	  clk_sleep_wgt		[4];
reg 	  clk_gated_wgt		[4];

reg 	  clk_sleep_map_1	[16];
reg 	  clk_gated_map_1	[16];

reg 	  clk_sleep_map_2	[16];
reg 	  clk_gated_map_2	[16];

reg 	  clk_sleep_q_map_1	[16];
reg 	  clk_gated_q_map_1	[16];

reg 	  clk_sleep_q_map_2	[16];
reg 	  clk_gated_q_map_2	[16];

reg 	  clk_sleep_pool_1	[4];
reg 	  clk_gated_pool_1	[4];

reg 	  clk_sleep_pool_2	[4];
reg 	  clk_gated_pool_2	[4];

reg 	  clk_sleep_env_1	[4];
reg 	  clk_gated_env_1	[4];

reg 	  clk_sleep_env_2	[4];
reg 	  clk_gated_env_2	[4];

reg 	  clk_sleep_q_env_1	[4];
reg 	  clk_gated_q_env_1	[4];

reg 	  clk_sleep_q_env_2	[4];
reg 	  clk_gated_q_env_2	[4];

// COUNTER
reg [ 6:0] cnt;
reg [ 6:0] cnt_nxt;

// INPUT
reg [ 7:0] img_1_reg	[36];
reg [ 7:0] img_1_nxt	[36];

reg [ 7:0] img_2_reg	[36];
reg [ 7:0] img_2_nxt	[36];

reg [ 7:0] ker_reg		[9];
reg [ 7:0] ker_nxt		[9];

reg [ 7:0] wgt_reg		[4];
reg [ 7:0] wgt_nxt		[4];

// CONVOLUTION
reg [ 3:0] offset_conv_1; 
reg [ 3:0] offset_conv_2; 

reg [ 7:0] mul_a		[9];
reg [ 7:0] mul_b		[9];
reg [15:0] mul_z		[9];

reg [19:0] add_a 		[8];
reg [19:0] add_b 		[8];
reg [19:0] add_z 		[8];

reg [19:0] map_1		[16];
reg [19:0] map_1_nxt	[16];

reg [19:0] map_2		[16];
reg [19:0] map_2_nxt	[16];

// QUATIZATION OF FEATURE MAP
reg [ 3:0] offset_q_map_1; 
reg [ 3:0] offset_q_map_2; 

reg [19:0] div_a;
reg [12:0] div_b;
reg [ 7:0] div_z;

reg [ 7:0] q_map_1		[16];
reg [ 7:0] q_map_1_nxt	[16];

reg [ 7:0] q_map_2		[16];
reg [ 7:0] q_map_2_nxt	[16];

// MAXPOOLING
reg [ 7:0] cmp_a		[3];
reg [ 7:0] cmp_b		[3];
reg [ 7:0] cmp_z		[3];

reg [ 7:0] pool_1		[4];
reg [ 7:0] pool_1_nxt	[4];

reg [ 7:0] pool_2		[4];
reg [ 7:0] pool_2_nxt	[4];

// FULLY CONNECTED
reg [17:0] env_1		[4];
reg [17:0] env_1_nxt	[4];

reg [17:0] env_2		[4];
reg [17:0] env_2_nxt	[4];

// QUATIZATION OF ENCODED VECTOR
reg [ 1:0] offset_q_env_1; 
reg [ 1:0] offset_q_env_2; 

reg [ 7:0] q_env_1		[4];
reg [ 7:0] q_env_1_nxt	[4];

reg [ 7:0] q_env_2		[4];
reg [ 7:0] q_env_2_nxt	[4];

// L1 DISTANCE
reg [ 1:0] offset_dist; 

reg [ 9:0] d;
reg [ 9:0] d_nxt;

// ACTIVATION + OUTPUT
reg 	   out_valid_nxt;
reg [ 9:0] out_data_nxt;

//==============================================//
//                  design                      //
//==============================================//

//================================================
// CLOCK GATED
//================================================

// clk for img_1
generate
	for(i_gen = 0; i_gen < 36; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen) && (cg_en)) begin
				clk_sleep_img_1[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_img_1[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_IMG_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_img_1[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_img_1[i_gen]));
	end
endgenerate

// clk for img_2
generate
	for(i_gen = 0; i_gen < 36; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 36) && (cg_en)) begin
				clk_sleep_img_2[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_img_2[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_IMG_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_img_2[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_img_2[i_gen]));
	end
endgenerate

// clk for ker
generate
	for(i_gen = 0; i_gen < 9; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen) && (cg_en)) begin
				clk_sleep_ker[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_ker[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_KER (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_ker[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_ker[i_gen]));
	end
endgenerate

// clk for wgt
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen) && (cg_en)) begin
				clk_sleep_wgt[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_wgt[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_WGT (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_wgt[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_wgt[i_gen]));
	end
endgenerate

// clk for map_1
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 21) && (cg_en)) begin
				clk_sleep_map_1[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_map_1[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_MAP_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_map_1[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_map_1[i_gen]));
	end
endgenerate

// clk for map_2
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 57) && (cg_en)) begin
				clk_sleep_map_2[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_map_2[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_MAP_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_map_2[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_map_2[i_gen]));
	end
endgenerate

// clk for q_map_1
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 22) && (cg_en)) begin
				clk_sleep_q_map_1[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_q_map_1[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_Q_MAP_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_q_map_1[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_q_map_1[i_gen]));
	end
endgenerate

// clk for q_map_2
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 58) && (cg_en)) begin
				clk_sleep_q_map_2[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_q_map_2[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_Q_MAP_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_q_map_2[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_q_map_2[i_gen]));
	end
endgenerate

// clk for pool_1
generate
	always @(*) begin
		if((cnt != 28) && (cg_en)) begin
			clk_sleep_pool_1[0] = 1; // sleep
		end
		else begin
			clk_sleep_pool_1[0] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_1_0 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_1[0]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_1[0]));

	always @(*) begin
		if((cnt != 30) && (cg_en)) begin
			clk_sleep_pool_1[1] = 1; // sleep
		end
		else begin
			clk_sleep_pool_1[1] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_1_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_1[1]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_1[1]));

	always @(*) begin
		if((cnt != 36) && (cg_en)) begin
			clk_sleep_pool_1[2] = 1; // sleep
		end
		else begin
			clk_sleep_pool_1[2] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_1_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_1[2]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_1[2]));

	always @(*) begin
		if((cnt != 38) && (cg_en)) begin
			clk_sleep_pool_1[3] = 1; // sleep
		end
		else begin
			clk_sleep_pool_1[3] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_1_3 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_1[3]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_1[3]));
endgenerate

// clk for pool_2
generate
	always @(*) begin
		if((cnt != 64) && (cg_en)) begin
			clk_sleep_pool_2[0] = 1; // sleep
		end
		else begin
			clk_sleep_pool_2[0] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_2_0 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_2[0]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_2[0]));

	always @(*) begin
		if((cnt != 66) && (cg_en)) begin
			clk_sleep_pool_2[1] = 1; // sleep
		end
		else begin
			clk_sleep_pool_2[1] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_2_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_2[1]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_2[1]));

	always @(*) begin
		if((cnt != 72) && (cg_en)) begin
			clk_sleep_pool_2[2] = 1; // sleep
		end
		else begin
			clk_sleep_pool_2[2] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_2_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_2[2]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_2[2]));

	always @(*) begin
		if((cnt != 74) && (cg_en)) begin
			clk_sleep_pool_2[3] = 1; // sleep
		end
		else begin
			clk_sleep_pool_2[3] = 0; // awake
		end
	end
	GATED_OR GATED_POOL_2_3 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_pool_2[3]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_pool_2[3]));
endgenerate

// clk for env_1
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != 37) && (cnt != 39) && (cg_en)) begin
				clk_sleep_env_1[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_env_1[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_ENV_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_env_1[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_env_1[i_gen]));
	end
endgenerate

// clk for env_2
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != 73) && (cnt != 75) && (cg_en)) begin
				clk_sleep_env_2[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_env_2[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_ENV_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_env_2[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_env_2[i_gen]));
	end
endgenerate

// clk for q_env_1
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 38) && (cg_en)) begin
				clk_sleep_q_env_1[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_q_env_1[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_Q_ENV_1 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_q_env_1[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_q_env_1[i_gen]));
	end
endgenerate

// clk for q_env_2
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1)begin
		always @(*) begin
			if((cnt != i_gen + 74) && (cg_en)) begin
				clk_sleep_q_env_2[i_gen] = 1; // sleep
			end
			else begin
				clk_sleep_q_env_2[i_gen] = 0; // awake
			end
		end
		GATED_OR GATED_Q_ENV_2 (.CLOCK(clk),.SLEEP_CTRL(clk_sleep_q_env_2[i_gen]),.RST_N(rst_n),.CLOCK_GATED(clk_gated_q_env_2[i_gen]));
	end
endgenerate

//================================================
// COUNTER
//================================================

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else begin
		cnt <= cnt_nxt;
	end
end

always @(*) begin
	if(in_valid) begin
		cnt_nxt = cnt + 1;
	end
	else begin
		if((cnt > 0) && (!out_valid)) begin
			cnt_nxt = cnt + 1;
		end
		else begin
			cnt_nxt = 0;
		end
	end
end

//================================================
// INPUT
//================================================

// img_1
generate
	for(i_gen = 0; i_gen < 36; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_img_1[i_gen]) begin
			img_1_reg[i_gen] <= img_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((in_valid) && (cnt < 36)) begin
		for(i = 0; i < 36; i = i + 1) begin
			if(i == cnt) begin
				img_1_nxt[i] = img;
			end
			else begin
				img_1_nxt[i] = img_1_reg[i];
			end
		end
	end
	else begin
		for(i = 0; i < 36; i = i + 1) begin
			img_1_nxt[i] = img_1_reg[i];
		end
	end
end

// img_2
generate
	for(i_gen = 0; i_gen < 36; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_img_2[i_gen]) begin
			img_2_reg[i_gen] <= img_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((in_valid) && (cnt > 35) && (cnt < 72)) begin
		for(i = 0; i < 36; i = i + 1) begin
			if(i == (cnt - 36)) begin
				img_2_nxt[i] = img;
			end
			else begin
				img_2_nxt[i] = img_2_reg[i];
			end
		end
	end
	else begin
		for(i = 0; i < 36; i = i + 1) begin
			img_2_nxt[i] = img_2_reg[i];
		end
	end
end

// ker
generate
	for(i_gen = 0; i_gen < 9; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_ker[i_gen]) begin
			ker_reg[i_gen] <= ker_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((in_valid) && (cnt < 9)) begin
		for(i = 0; i < 9; i = i + 1) begin
			if(i == cnt) begin
				ker_nxt[i] = ker;
			end
			else begin
				ker_nxt[i] = ker_reg[i];
			end
		end
	end
	else begin
		for(i = 0; i < 9; i = i + 1) begin
			ker_nxt[i] = ker_reg[i];
		end
	end
end

// wgt
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_wgt[i_gen]) begin
			wgt_reg[i_gen] <= wgt_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((in_valid) && (cnt < 4)) begin
		for(i = 0; i < 4; i = i + 1) begin
			if(i == cnt) begin
				wgt_nxt[i] = weight;
			end
			else begin
				wgt_nxt[i] = wgt_reg[i];
			end
		end
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			wgt_nxt[i] = wgt_reg[i];
		end
	end
end

//================================================
// CONVOLUTION
//================================================

always @(*) begin
	offset_conv_1 = cnt - 21;
end

always @(*) begin
	offset_conv_2 = cnt - 57;
end

// multiplier
always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[0] = img_1_reg[ 0];
			 1: mul_a[0] = img_1_reg[ 1];
			 2: mul_a[0] = img_1_reg[ 2];
			 3: mul_a[0] = img_1_reg[ 3];
			 4: mul_a[0] = img_1_reg[ 6];
			 5: mul_a[0] = img_1_reg[ 7];
			 6: mul_a[0] = img_1_reg[ 8];
			 7: mul_a[0] = img_1_reg[ 9];
			 8: mul_a[0] = img_1_reg[12];
			 9: mul_a[0] = img_1_reg[13];
			10: mul_a[0] = img_1_reg[14];
			11: mul_a[0] = img_1_reg[15];
			12: mul_a[0] = img_1_reg[18];
			13: mul_a[0] = img_1_reg[19];
			14: mul_a[0] = img_1_reg[20];
			15: mul_a[0] = img_1_reg[21];
		endcase
	end
	else if(cnt == 37) begin
		mul_a[0] = pool_1[0];
	end
	else if(cnt == 39) begin
		mul_a[0] = pool_1[2];
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[0] = img_2_reg[ 0];
			 1: mul_a[0] = img_2_reg[ 1];
			 2: mul_a[0] = img_2_reg[ 2];
			 3: mul_a[0] = img_2_reg[ 3];
			 4: mul_a[0] = img_2_reg[ 6];
			 5: mul_a[0] = img_2_reg[ 7];
			 6: mul_a[0] = img_2_reg[ 8];
			 7: mul_a[0] = img_2_reg[ 9];
			 8: mul_a[0] = img_2_reg[12];
			 9: mul_a[0] = img_2_reg[13];
			10: mul_a[0] = img_2_reg[14];
			11: mul_a[0] = img_2_reg[15];
			12: mul_a[0] = img_2_reg[18];
			13: mul_a[0] = img_2_reg[19];
			14: mul_a[0] = img_2_reg[20];
			15: mul_a[0] = img_2_reg[21];
		endcase
	end
	else if(cnt == 73) begin
		mul_a[0] = pool_2[0];
	end
	else if(cnt == 75) begin
		mul_a[0] = pool_2[2];
	end
	else begin
		mul_a[0] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[1] = img_1_reg[ 1];
			 1: mul_a[1] = img_1_reg[ 2];
			 2: mul_a[1] = img_1_reg[ 3];
			 3: mul_a[1] = img_1_reg[ 4];
			 4: mul_a[1] = img_1_reg[ 7];
			 5: mul_a[1] = img_1_reg[ 8];
			 6: mul_a[1] = img_1_reg[ 9];
			 7: mul_a[1] = img_1_reg[10];
			 8: mul_a[1] = img_1_reg[13];
			 9: mul_a[1] = img_1_reg[14];
			10: mul_a[1] = img_1_reg[15];
			11: mul_a[1] = img_1_reg[16];
			12: mul_a[1] = img_1_reg[19];
			13: mul_a[1] = img_1_reg[20];
			14: mul_a[1] = img_1_reg[21];
			15: mul_a[1] = img_1_reg[22];
		endcase
	end
	else if(cnt == 37) begin
		mul_a[1] = pool_1[1];
	end
	else if(cnt == 39) begin
		mul_a[1] = pool_1[3];
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[1] = img_2_reg[ 1];
			 1: mul_a[1] = img_2_reg[ 2];
			 2: mul_a[1] = img_2_reg[ 3];
			 3: mul_a[1] = img_2_reg[ 4];
			 4: mul_a[1] = img_2_reg[ 7];
			 5: mul_a[1] = img_2_reg[ 8];
			 6: mul_a[1] = img_2_reg[ 9];
			 7: mul_a[1] = img_2_reg[10];
			 8: mul_a[1] = img_2_reg[13];
			 9: mul_a[1] = img_2_reg[14];
			10: mul_a[1] = img_2_reg[15];
			11: mul_a[1] = img_2_reg[16];
			12: mul_a[1] = img_2_reg[19];
			13: mul_a[1] = img_2_reg[20];
			14: mul_a[1] = img_2_reg[21];
			15: mul_a[1] = img_2_reg[22];
		endcase
	end
	else if(cnt == 73) begin
		mul_a[1] = pool_2[1];
	end
	else if(cnt == 75) begin
		mul_a[1] = pool_2[3];
	end
	else begin
		mul_a[1] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[2] = img_1_reg[ 2];
			 1: mul_a[2] = img_1_reg[ 3];
			 2: mul_a[2] = img_1_reg[ 4];
			 3: mul_a[2] = img_1_reg[ 5];
			 4: mul_a[2] = img_1_reg[ 8];
			 5: mul_a[2] = img_1_reg[ 9];
			 6: mul_a[2] = img_1_reg[10];
			 7: mul_a[2] = img_1_reg[11];
			 8: mul_a[2] = img_1_reg[14];
			 9: mul_a[2] = img_1_reg[15];
			10: mul_a[2] = img_1_reg[16];
			11: mul_a[2] = img_1_reg[17];
			12: mul_a[2] = img_1_reg[20];
			13: mul_a[2] = img_1_reg[21];
			14: mul_a[2] = img_1_reg[22];
			15: mul_a[2] = img_1_reg[23];
		endcase
	end
	else if(cnt == 37) begin
		mul_a[2] = pool_1[0];
	end
	else if(cnt == 39) begin
		mul_a[2] = pool_1[2];
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[2] = img_2_reg[ 2];
			 1: mul_a[2] = img_2_reg[ 3];
			 2: mul_a[2] = img_2_reg[ 4];
			 3: mul_a[2] = img_2_reg[ 5];
			 4: mul_a[2] = img_2_reg[ 8];
			 5: mul_a[2] = img_2_reg[ 9];
			 6: mul_a[2] = img_2_reg[10];
			 7: mul_a[2] = img_2_reg[11];
			 8: mul_a[2] = img_2_reg[14];
			 9: mul_a[2] = img_2_reg[15];
			10: mul_a[2] = img_2_reg[16];
			11: mul_a[2] = img_2_reg[17];
			12: mul_a[2] = img_2_reg[20];
			13: mul_a[2] = img_2_reg[21];
			14: mul_a[2] = img_2_reg[22];
			15: mul_a[2] = img_2_reg[23];
		endcase
	end
	else if(cnt == 73) begin
		mul_a[2] = pool_2[0];
	end
	else if(cnt == 75) begin
		mul_a[2] = pool_2[2];
	end
	else begin
		mul_a[2] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[3] = img_1_reg[ 6];
			 1: mul_a[3] = img_1_reg[ 7];
			 2: mul_a[3] = img_1_reg[ 8];
			 3: mul_a[3] = img_1_reg[ 9];
			 4: mul_a[3] = img_1_reg[12];
			 5: mul_a[3] = img_1_reg[13];
			 6: mul_a[3] = img_1_reg[14];
			 7: mul_a[3] = img_1_reg[15];
			 8: mul_a[3] = img_1_reg[18];
			 9: mul_a[3] = img_1_reg[19];
			10: mul_a[3] = img_1_reg[20];
			11: mul_a[3] = img_1_reg[21];
			12: mul_a[3] = img_1_reg[24];
			13: mul_a[3] = img_1_reg[25];
			14: mul_a[3] = img_1_reg[26];
			15: mul_a[3] = img_1_reg[27];
		endcase
	end
	else if(cnt == 37) begin
		mul_a[3] = pool_1[1];
	end
	else if(cnt == 39) begin
		mul_a[3] = pool_1[3];
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[3] = img_2_reg[ 6];
			 1: mul_a[3] = img_2_reg[ 7];
			 2: mul_a[3] = img_2_reg[ 8];
			 3: mul_a[3] = img_2_reg[ 9];
			 4: mul_a[3] = img_2_reg[12];
			 5: mul_a[3] = img_2_reg[13];
			 6: mul_a[3] = img_2_reg[14];
			 7: mul_a[3] = img_2_reg[15];
			 8: mul_a[3] = img_2_reg[18];
			 9: mul_a[3] = img_2_reg[19];
			10: mul_a[3] = img_2_reg[20];
			11: mul_a[3] = img_2_reg[21];
			12: mul_a[3] = img_2_reg[24];
			13: mul_a[3] = img_2_reg[25];
			14: mul_a[3] = img_2_reg[26];
			15: mul_a[3] = img_2_reg[27];
		endcase
	end
	else if(cnt == 73) begin
		mul_a[3] = pool_2[1];
	end
	else if(cnt == 75) begin
		mul_a[3] = pool_2[3];
	end
	else begin
		mul_a[3] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[4] = img_1_reg[ 7];
			 1: mul_a[4] = img_1_reg[ 8];
			 2: mul_a[4] = img_1_reg[ 9];
			 3: mul_a[4] = img_1_reg[10];
			 4: mul_a[4] = img_1_reg[13];
			 5: mul_a[4] = img_1_reg[14];
			 6: mul_a[4] = img_1_reg[15];
			 7: mul_a[4] = img_1_reg[16];
			 8: mul_a[4] = img_1_reg[19];
			 9: mul_a[4] = img_1_reg[20];
			10: mul_a[4] = img_1_reg[21];
			11: mul_a[4] = img_1_reg[22];
			12: mul_a[4] = img_1_reg[25];
			13: mul_a[4] = img_1_reg[26];
			14: mul_a[4] = img_1_reg[27];
			15: mul_a[4] = img_1_reg[28];
		endcase
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[4] = img_2_reg[ 7];
			 1: mul_a[4] = img_2_reg[ 8];
			 2: mul_a[4] = img_2_reg[ 9];
			 3: mul_a[4] = img_2_reg[10];
			 4: mul_a[4] = img_2_reg[13];
			 5: mul_a[4] = img_2_reg[14];
			 6: mul_a[4] = img_2_reg[15];
			 7: mul_a[4] = img_2_reg[16];
			 8: mul_a[4] = img_2_reg[19];
			 9: mul_a[4] = img_2_reg[20];
			10: mul_a[4] = img_2_reg[21];
			11: mul_a[4] = img_2_reg[22];
			12: mul_a[4] = img_2_reg[25];
			13: mul_a[4] = img_2_reg[26];
			14: mul_a[4] = img_2_reg[27];
			15: mul_a[4] = img_2_reg[28];
		endcase
	end
	else begin
		mul_a[4] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[5] = img_1_reg[ 8];
			 1: mul_a[5] = img_1_reg[ 9];
			 2: mul_a[5] = img_1_reg[10];
			 3: mul_a[5] = img_1_reg[11];
			 4: mul_a[5] = img_1_reg[14];
			 5: mul_a[5] = img_1_reg[15];
			 6: mul_a[5] = img_1_reg[16];
			 7: mul_a[5] = img_1_reg[17];
			 8: mul_a[5] = img_1_reg[20];
			 9: mul_a[5] = img_1_reg[21];
			10: mul_a[5] = img_1_reg[22];
			11: mul_a[5] = img_1_reg[23];
			12: mul_a[5] = img_1_reg[26];
			13: mul_a[5] = img_1_reg[27];
			14: mul_a[5] = img_1_reg[28];
			15: mul_a[5] = img_1_reg[29];
		endcase
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[5] = img_2_reg[ 8];
			 1: mul_a[5] = img_2_reg[ 9];
			 2: mul_a[5] = img_2_reg[10];
			 3: mul_a[5] = img_2_reg[11];
			 4: mul_a[5] = img_2_reg[14];
			 5: mul_a[5] = img_2_reg[15];
			 6: mul_a[5] = img_2_reg[16];
			 7: mul_a[5] = img_2_reg[17];
			 8: mul_a[5] = img_2_reg[20];
			 9: mul_a[5] = img_2_reg[21];
			10: mul_a[5] = img_2_reg[22];
			11: mul_a[5] = img_2_reg[23];
			12: mul_a[5] = img_2_reg[26];
			13: mul_a[5] = img_2_reg[27];
			14: mul_a[5] = img_2_reg[28];
			15: mul_a[5] = img_2_reg[29];
		endcase
	end
	else begin
		mul_a[5] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[6] = img_1_reg[12];
			 1: mul_a[6] = img_1_reg[13];
			 2: mul_a[6] = img_1_reg[14];
			 3: mul_a[6] = img_1_reg[15];
			 4: mul_a[6] = img_1_reg[18];
			 5: mul_a[6] = img_1_reg[19];
			 6: mul_a[6] = img_1_reg[20];
			 7: mul_a[6] = img_1_reg[21];
			 8: mul_a[6] = img_1_reg[24];
			 9: mul_a[6] = img_1_reg[25];
			10: mul_a[6] = img_1_reg[26];
			11: mul_a[6] = img_1_reg[27];
			12: mul_a[6] = img_1_reg[30];
			13: mul_a[6] = img_1_reg[31];
			14: mul_a[6] = img_1_reg[32];
			15: mul_a[6] = img_1_reg[33];
		endcase
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[6] = img_2_reg[12];
			 1: mul_a[6] = img_2_reg[13];
			 2: mul_a[6] = img_2_reg[14];
			 3: mul_a[6] = img_2_reg[15];
			 4: mul_a[6] = img_2_reg[18];
			 5: mul_a[6] = img_2_reg[19];
			 6: mul_a[6] = img_2_reg[20];
			 7: mul_a[6] = img_2_reg[21];
			 8: mul_a[6] = img_2_reg[24];
			 9: mul_a[6] = img_2_reg[25];
			10: mul_a[6] = img_2_reg[26];
			11: mul_a[6] = img_2_reg[27];
			12: mul_a[6] = img_2_reg[30];
			13: mul_a[6] = img_2_reg[31];
			14: mul_a[6] = img_2_reg[32];
			15: mul_a[6] = img_2_reg[33];
		endcase
	end
	else begin
		mul_a[6] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[7] = img_1_reg[13];
			 1: mul_a[7] = img_1_reg[14];
			 2: mul_a[7] = img_1_reg[15];
			 3: mul_a[7] = img_1_reg[16];
			 4: mul_a[7] = img_1_reg[19];
			 5: mul_a[7] = img_1_reg[20];
			 6: mul_a[7] = img_1_reg[21];
			 7: mul_a[7] = img_1_reg[22];
			 8: mul_a[7] = img_1_reg[25];
			 9: mul_a[7] = img_1_reg[26];
			10: mul_a[7] = img_1_reg[27];
			11: mul_a[7] = img_1_reg[28];
			12: mul_a[7] = img_1_reg[31];
			13: mul_a[7] = img_1_reg[32];
			14: mul_a[7] = img_1_reg[33];
			15: mul_a[7] = img_1_reg[34];
		endcase
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[7] = img_2_reg[13];
			 1: mul_a[7] = img_2_reg[14];
			 2: mul_a[7] = img_2_reg[15];
			 3: mul_a[7] = img_2_reg[16];
			 4: mul_a[7] = img_2_reg[19];
			 5: mul_a[7] = img_2_reg[20];
			 6: mul_a[7] = img_2_reg[21];
			 7: mul_a[7] = img_2_reg[22];
			 8: mul_a[7] = img_2_reg[25];
			 9: mul_a[7] = img_2_reg[26];
			10: mul_a[7] = img_2_reg[27];
			11: mul_a[7] = img_2_reg[28];
			12: mul_a[7] = img_2_reg[31];
			13: mul_a[7] = img_2_reg[32];
			14: mul_a[7] = img_2_reg[33];
			15: mul_a[7] = img_2_reg[34];
		endcase
	end
	else begin
		mul_a[7] = 0;
	end
end

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		case (offset_conv_1)
			 0: mul_a[8] = img_1_reg[14];
			 1: mul_a[8] = img_1_reg[15];
			 2: mul_a[8] = img_1_reg[16];
			 3: mul_a[8] = img_1_reg[17];
			 4: mul_a[8] = img_1_reg[20];
			 5: mul_a[8] = img_1_reg[21];
			 6: mul_a[8] = img_1_reg[22];
			 7: mul_a[8] = img_1_reg[23];
			 8: mul_a[8] = img_1_reg[26];
			 9: mul_a[8] = img_1_reg[27];
			10: mul_a[8] = img_1_reg[28];
			11: mul_a[8] = img_1_reg[29];
			12: mul_a[8] = img_1_reg[32];
			13: mul_a[8] = img_1_reg[33];
			14: mul_a[8] = img_1_reg[34];
			15: mul_a[8] = img_1_reg[35];
		endcase
	end
	else if((cnt > 56) && (cnt < 73)) begin
		case (offset_conv_2)
			 0: mul_a[8] = img_2_reg[14];
			 1: mul_a[8] = img_2_reg[15];
			 2: mul_a[8] = img_2_reg[16];
			 3: mul_a[8] = img_2_reg[17];
			 4: mul_a[8] = img_2_reg[20];
			 5: mul_a[8] = img_2_reg[21];
			 6: mul_a[8] = img_2_reg[22];
			 7: mul_a[8] = img_2_reg[23];
			 8: mul_a[8] = img_2_reg[26];
			 9: mul_a[8] = img_2_reg[27];
			10: mul_a[8] = img_2_reg[28];
			11: mul_a[8] = img_2_reg[29];
			12: mul_a[8] = img_2_reg[32];
			13: mul_a[8] = img_2_reg[33];
			14: mul_a[8] = img_2_reg[34];
			15: mul_a[8] = img_2_reg[35];
		endcase
	end
	else begin
		mul_a[8] = 0;
	end
end

always @(*) begin
	if(((cnt > 20) && (cnt < 37)) || ((cnt > 56) && (cnt < 73))) begin
		for(i = 0; i < 9; i = i + 1) begin
			mul_b[i] = ker_reg[i];
		end
	end
	else if(((cnt == 37) || (cnt == 39)) || ((cnt == 73) || (cnt == 75))) begin
		mul_b[0] = wgt_reg[0];
		mul_b[1] = wgt_reg[2];
		mul_b[2] = wgt_reg[1];
		mul_b[3] = wgt_reg[3];
		mul_b[4] = 0;
		mul_b[5] = 0;
		mul_b[6] = 0;
		mul_b[7] = 0;
		mul_b[8] = 0;
	end
	else begin
		for(i = 0; i < 9; i = i + 1) begin
			mul_b[i] = 0;
		end
	end
end

always @(*) begin
	for(i = 0; i < 9; i = i + 1) begin
		mul_z[i] = mul_a[i] * mul_b[i];
	end
end

// adder
always @(*) begin
	if(((cnt > 20) && (cnt < 37)) || ((cnt > 56) && (cnt < 73))) begin
		add_a[0] = mul_z[0];
		add_a[1] = mul_z[2];
		add_a[2] = mul_z[4];
		add_a[3] = mul_z[6];
		add_a[4] = add_z[0];
		add_a[5] = add_z[2];
		add_a[6] = add_z[4];
		add_a[7] = add_z[6];
	end
	else if(((cnt == 37) || (cnt == 39)) || ((cnt == 73) || (cnt == 75))) begin
		add_a[0] = mul_z[0];
		add_a[1] = mul_z[2];
		add_a[2] = 0;
		add_a[3] = 0;
		add_a[4] = 0;
		add_a[5] = 0;
		add_a[6] = 0;
		add_a[7] = 0;
	end
	else begin
		add_a[0] = 0;
		add_a[1] = 0;
		add_a[2] = 0;
		add_a[3] = 0;
		add_a[4] = 0;
		add_a[5] = 0;
		add_a[6] = 0;
		add_a[7] = 0;
	end
end

always @(*) begin
	if(((cnt > 20) && (cnt < 37)) || ((cnt > 56) && (cnt < 73))) begin
		add_b[0] = mul_z[1];
		add_b[1] = mul_z[3];
		add_b[2] = mul_z[5];
		add_b[3] = mul_z[7];
		add_b[4] = add_z[1];
		add_b[5] = add_z[3];
		add_b[6] = add_z[5];
		add_b[7] = mul_z[8];
	end
	else if(((cnt == 37) || (cnt == 39)) || ((cnt == 73) || (cnt == 75))) begin
		add_b[0] = mul_z[1];
		add_b[1] = mul_z[3];
		add_b[2] = 0;
		add_b[3] = 0;
		add_b[4] = 0;
		add_b[5] = 0;
		add_b[6] = 0;
		add_b[7] = 0;
	end
	else begin
		add_b[0] = 0;
		add_b[1] = 0;
		add_b[2] = 0;
		add_b[3] = 0;
		add_b[4] = 0;
		add_b[5] = 0;
		add_b[6] = 0;
		add_b[7] = 0;
	end
end

always @(*) begin
	for(i = 0; i < 8; i = i + 1) begin
		add_z[i] = add_a[i] + add_b[i];
	end
end

// map_1
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_map_1[i_gen]) begin
			map_1[i_gen] <= map_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 20) && (cnt < 37)) begin
		for(i = 0; i < 16; i = i + 1) begin
			if(i == offset_conv_1) begin
				map_1_nxt[i] = add_z[7];
			end
			else begin
				map_1_nxt[i] = map_1[i];
			end
		end
	end
	else begin
		for(i = 0; i < 16; i = i + 1) begin
			map_1_nxt[i] = map_1[i];
		end
	end
end

// map_2
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_map_2[i_gen]) begin
			map_2[i_gen] <= map_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 56) && (cnt < 73)) begin
		for(i = 0; i < 16; i = i + 1) begin
			if(i == offset_conv_2) begin
				map_2_nxt[i] = add_z[7];
			end
			else begin
				map_2_nxt[i] = map_2[i];
			end
		end
	end
	else begin
		for(i = 0; i < 16; i = i + 1) begin
			map_2_nxt[i] = map_2[i];
		end
	end
end

//================================================
// QUANTIZATION OF FEATURE MAP
//================================================

always @(*) begin
	offset_q_map_1 = cnt - 22;
end

always @(*) begin
	offset_q_map_2 = cnt - 58;
end

// divider
always @(*) begin
	if(((cnt > 21) && (cnt < 38)) || ((cnt > 57) && (cnt < 74))) begin
		if((cnt > 21) && (cnt < 38)) begin
			case (offset_q_map_1)
				 0: div_a = map_1[ 0];
				 1: div_a = map_1[ 1];
				 2: div_a = map_1[ 2];
				 3: div_a = map_1[ 3];
				 4: div_a = map_1[ 4];
				 5: div_a = map_1[ 5];
				 6: div_a = map_1[ 6];
				 7: div_a = map_1[ 7];
				 8: div_a = map_1[ 8];
				 9: div_a = map_1[ 9];
				10: div_a = map_1[10];
				11: div_a = map_1[11];
				12: div_a = map_1[12];
				13: div_a = map_1[13];
				14: div_a = map_1[14];
				15: div_a = map_1[15];
			endcase
		end
		else if((cnt > 57) && (cnt < 74)) begin
			case (offset_q_map_2)
				 0: div_a = map_2[ 0];
				 1: div_a = map_2[ 1];
				 2: div_a = map_2[ 2];
				 3: div_a = map_2[ 3];
				 4: div_a = map_2[ 4];
				 5: div_a = map_2[ 5];
				 6: div_a = map_2[ 6];
				 7: div_a = map_2[ 7];
				 8: div_a = map_2[ 8];
				 9: div_a = map_2[ 9];
				10: div_a = map_2[10];
				11: div_a = map_2[11];
				12: div_a = map_2[12];
				13: div_a = map_2[13];
				14: div_a = map_2[14];
				15: div_a = map_2[15];
			endcase
		end
		else begin
			div_a = 0;
		end
	end
	else if(((cnt > 37) && (cnt < 42)) || ((cnt > 73) && (cnt < 78))) begin
		if(((cnt > 37) && (cnt < 42))) begin
			case (offset_q_env_1)
				0: div_a = env_1[offset_q_env_1];
				1: div_a = env_1[offset_q_env_1];
				2: div_a = env_1[offset_q_env_1];
				3: div_a = env_1[offset_q_env_1];
			endcase
		end
		else if((cnt > 73) && (cnt < 78)) begin
			case (offset_q_env_2)
				0: div_a = env_2[offset_q_env_2];
				1: div_a = env_2[offset_q_env_2];
				2: div_a = env_2[offset_q_env_2];
				3: div_a = env_2[offset_q_env_2];
			endcase
		end
		else begin
			div_a = 0;
		end
	end
	else begin
		div_a = 0;
	end
end

always @(*) begin
	if(((cnt > 21) && (cnt < 38)) || ((cnt > 57) && (cnt < 74))) begin
		div_b = scale_map;
	end
	else if(((cnt > 37) && (cnt < 42)) || ((cnt > 73) && (cnt < 78))) begin
		div_b = scale_env;
	end
	else begin
		div_b = 1;
	end
end

always @(*) begin
	div_z = div_a / div_b;
end

// q_map_1
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_q_map_1[i_gen]) begin
			q_map_1[i_gen] <= q_map_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 21) && (cnt < 38)) begin
		for(i = 0; i < 16; i = i + 1) begin
			if(i == offset_q_map_1) begin
				q_map_1_nxt[i] = div_z;
			end
			else begin
				q_map_1_nxt[i] = q_map_1[i];
			end
		end
	end
	else begin
		for(i = 0; i < 16; i = i + 1) begin
			q_map_1_nxt[i] = q_map_1[i];
		end
	end
end

// q_map_2
generate
	for(i_gen = 0; i_gen < 16; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_q_map_2[i_gen]) begin
			q_map_2[i_gen] <= q_map_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 57) && (cnt < 74)) begin
		for(i = 0; i < 16; i = i + 1) begin
			if(i == offset_q_map_2) begin
				q_map_2_nxt[i] = div_z;
			end
			else begin
				q_map_2_nxt[i] = q_map_2[i];
			end
		end
	end
	else begin
		for(i = 0; i < 16; i = i + 1) begin
			q_map_2_nxt[i] = q_map_2[i];
		end
	end
end

//================================================
// MAXPOOLING
//================================================

// comparator
always @(*) begin
	if(cnt < 39) begin
		if(cnt == 28) begin
			cmp_a[0] = q_map_1[0];
			cmp_a[1] = q_map_1[1];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 30) begin
			cmp_a[0] = q_map_1[2];
			cmp_a[1] = q_map_1[3];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 36) begin
			cmp_a[0] = q_map_1[8];
			cmp_a[1] = q_map_1[9];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 38) begin
			cmp_a[0] = q_map_1[10];
			cmp_a[1] = q_map_1[11];
			cmp_a[2] = cmp_z[0];
		end
		else begin
			cmp_a[0] = 0;
			cmp_a[1] = 0;
			cmp_a[2] = 0;
		end
	end
	else if(cnt < 75) begin
		if(cnt == 64) begin
			cmp_a[0] = q_map_2[0];
			cmp_a[1] = q_map_2[1];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 66) begin
			cmp_a[0] = q_map_2[2];
			cmp_a[1] = q_map_2[3];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 72) begin
			cmp_a[0] = q_map_2[8];
			cmp_a[1] = q_map_2[9];
			cmp_a[2] = cmp_z[0];
		end
		else if(cnt == 74) begin
			cmp_a[0] = q_map_2[10];
			cmp_a[1] = q_map_2[11];
			cmp_a[2] = cmp_z[0];
		end
		else begin
			cmp_a[0] = 0;
			cmp_a[1] = 0;
			cmp_a[2] = 0;
		end
	end
	else begin
		cmp_a[0] = 0;
		cmp_a[1] = 0;
		cmp_a[2] = 0;
	end
end

always @(*) begin
	if(cnt < 39) begin
		if(cnt == 28) begin
			cmp_b[0] = q_map_1[4];
			cmp_b[1] = q_map_1[5];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 30) begin
			cmp_b[0] = q_map_1[6];
			cmp_b[1] = q_map_1[7];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 36) begin
			cmp_b[0] = q_map_1[12];
			cmp_b[1] = q_map_1[13];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 38) begin
			cmp_b[0] = q_map_1[14];
			cmp_b[1] = q_map_1[15];
			cmp_b[2] = cmp_z[1];
		end
		else begin
			cmp_b[0] = 0;
			cmp_b[1] = 0;
			cmp_b[2] = 0;
		end
	end
	else if(cnt < 75) begin
		if(cnt == 64) begin
			cmp_b[0] = q_map_2[4];
			cmp_b[1] = q_map_2[5];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 66) begin
			cmp_b[0] = q_map_2[6];
			cmp_b[1] = q_map_2[7];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 72) begin
			cmp_b[0] = q_map_2[12];
			cmp_b[1] = q_map_2[13];
			cmp_b[2] = cmp_z[1];
		end
		else if(cnt == 74) begin
			cmp_b[0] = q_map_2[14];
			cmp_b[1] = q_map_2[15];
			cmp_b[2] = cmp_z[1];
		end
		else begin
			cmp_b[0] = 0;
			cmp_b[1] = 0;
			cmp_b[2] = 0;
		end
	end
	else begin
		cmp_b[0] = 0;
		cmp_b[1] = 0;
		cmp_b[2] = 0;
	end
end

always @(*) begin
	for(i = 0; i < 3; i = i + 1) begin
		cmp_z[i] = (cmp_a[i] > cmp_b[i]) ? cmp_a[i] : cmp_b[i];
	end
end

// pool_1
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_pool_1[i_gen]) begin
			pool_1[i_gen] <= pool_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if(cnt == 28) begin
		pool_1_nxt[0] = cmp_z[2];
	end
	else begin
		pool_1_nxt[0] = pool_1[0];
	end
end

always @(*) begin
	if(cnt == 30) begin
		pool_1_nxt[1] = cmp_z[2];
	end
	else begin
		pool_1_nxt[1] = pool_1[1];
	end
end

always @(*) begin
	if(cnt == 36) begin
		pool_1_nxt[2] = cmp_z[2];
	end
	else begin
		pool_1_nxt[2] = pool_1[2];
	end
end

always @(*) begin
	if(cnt == 38) begin
		pool_1_nxt[3] = cmp_z[2];
	end
	else begin
		pool_1_nxt[3] = pool_1[3];
	end
end

// pool_2
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_pool_2[i_gen]) begin
			pool_2[i_gen] <= pool_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if(cnt == 64) begin
		pool_2_nxt[0] = cmp_z[2];
	end
	else begin
		pool_2_nxt[0] = pool_2[0];
	end
end

always @(*) begin
	if(cnt == 66) begin
		pool_2_nxt[1] = cmp_z[2];
	end
	else begin
		pool_2_nxt[1] = pool_2[1];
	end
end

always @(*) begin
	if(cnt == 72) begin
		pool_2_nxt[2] = cmp_z[2];
	end
	else begin
		pool_2_nxt[2] = pool_2[2];
	end
end

always @(*) begin
	if(cnt == 74) begin
		pool_2_nxt[3] = cmp_z[2];
	end
	else begin
		pool_2_nxt[3] = pool_2[3];
	end
end

//================================================
// FULLY CONNECTED
//================================================

// env_1
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_env_1[i_gen]) begin
			env_1[i_gen] <= env_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if(cnt == 37) begin
		env_1_nxt[0] = add_z[0];
		env_1_nxt[1] = add_z[1];
		env_1_nxt[2] = env_1[2];
		env_1_nxt[3] = env_1[3];
	end
	else if(cnt == 39) begin
		env_1_nxt[0] = env_1[0];
		env_1_nxt[1] = env_1[1];
		env_1_nxt[2] = add_z[0];
		env_1_nxt[3] = add_z[1];
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			env_1_nxt[i] = env_1[i];
		end
	end
end

// env_2
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_env_2[i_gen]) begin
			env_2[i_gen] <= env_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if(cnt == 73) begin
		env_2_nxt[0] = add_z[0];
		env_2_nxt[1] = add_z[1];
		env_2_nxt[2] = env_2[2];
		env_2_nxt[3] = env_2[3];
	end
	else if(cnt == 75) begin
		env_2_nxt[0] = env_2[0];
		env_2_nxt[1] = env_2[1];
		env_2_nxt[2] = add_z[0];
		env_2_nxt[3] = add_z[1];
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			env_2_nxt[i] = env_2[i];
		end
	end
end

//================================================
// QUATIZATION OF ENCODED VECTOR
//================================================

always @(*) begin
	offset_q_env_1 = cnt - 38;
end

always @(*) begin
	offset_q_env_2 = cnt - 74;
end

// q_env_1
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_q_env_1[i_gen]) begin
			q_env_1[i_gen] <= q_env_1_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 37) && (cnt < 42)) begin
		for(i = 0; i < 4; i = i + 1) begin
			if(i == offset_q_env_1) begin
				q_env_1_nxt[i] = div_z;
			end
			else begin
				q_env_1_nxt[i] = q_env_1[i];
			end
		end
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			q_env_1_nxt[i] = q_env_1[i];
		end
	end
end

// q_env_2
generate
	for(i_gen = 0; i_gen < 4; i_gen = i_gen + 1) begin
		always @(posedge clk_gated_q_env_2[i_gen]) begin
			q_env_2[i_gen] <= q_env_2_nxt[i_gen];
		end
	end
endgenerate

always @(*) begin
	if((cnt > 73) && (cnt < 78)) begin
		for(i = 0; i < 4; i = i + 1) begin
			if(i == offset_q_env_2) begin
				q_env_2_nxt[i] = div_z;
			end
			else begin
				q_env_2_nxt[i] = q_env_2[i];
			end
		end
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			q_env_2_nxt[i] = q_env_2[i];
		end
	end
end

//================================================
// L1 DISTANCE
//================================================

always @(*) begin
	offset_dist = cnt - 75;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		d <= 0;
	end
	else begin
		d <= d_nxt;
	end
end

always @(*) begin
	if(cnt > 74 && cnt < 79) begin
		d_nxt = d + ((q_env_1[offset_dist] > q_env_2[offset_dist]) ? (q_env_1[offset_dist] - q_env_2[offset_dist]) : (q_env_2[offset_dist] - q_env_1[offset_dist]));
	end
	else begin
		d_nxt = 0;
	end
end

//================================================
// OUTPUT
//================================================

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		out_valid <= out_valid_nxt;
	end
end

always @(*) begin
	if(cnt == 79) begin
		out_valid_nxt = 1;
	end
	else begin
		out_valid_nxt = 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_data <= 0;
	end
	else begin
		out_data <= out_data_nxt;
	end
end

always @(*) begin
	if(cnt == 79) begin
		out_data_nxt = (d < 16) ? 0 : d;
	end
	else begin
		out_data_nxt = 0;
	end
end

endmodule