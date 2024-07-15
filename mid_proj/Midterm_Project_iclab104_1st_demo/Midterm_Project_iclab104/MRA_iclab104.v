//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Midterm Proejct            : MRA  
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
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
	   rready_m_inf,
	
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
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ===============================================================
//  				   parameter & integer
// ===============================================================

// for loop
integer i, j;

// AXI
parameter 	ID_WIDTH = 4, DATA_WIDTH = 128, ADDR_WIDTH = 32;

parameter 	LOC_START = 32'h0001_0000, 
			WGT_START = 32'h0002_0000;

parameter 	FRAME_WIDTH = 2048; // 2048 = (64 * 64)(blocks in 1 frame) / 2(each address can store 2 blocks)

// FSM
parameter 	IDLE 				=  0,
			IN 				 	=  1,
			WAIT_LOC_ARREADY 	=  2,
			WRITE_LOC_SRAM 	 	=  3,
			WAIT_WGT_ARREADY 	=  4,
			WRITE_WGT_SRAM 	 	=  5,
			MAP_INIT			=  6,
			WAVE_PROPAG 		=  7,
			RETRACE_READ_SRAM  	=  8,
			RETRACE_WRITE_SRAM 	=  9,
			MAP_CLEAR			= 10,
			WAIT_LOC_AWREADY	= 11,
			WRITE_LOC_DRAM	 	= 12,
			OUT 				= 13;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ===============================================================
// 					   register & wire
// ===============================================================

/////////////////////////////
// FSM
reg  [3:0] state;
reg  [3:0] state_nxt;

/////////////////////////////
// INPUT

// counter for src, target
reg  cnt_in_2;
wire cnt_in_2_nxt;

// counter for number of nets
reg  [3:0] cnt_in;
wire [3:0] cnt_in_nxt;

reg  [3:0] net		[0:14];
reg  [3:0] net_nxt  [0:14];

reg  [5:0] src_x	[0:14];
reg  [5:0] src_y	[0:14];
reg  [5:0] src_x_nxt[0:14];
reg  [5:0] src_y_nxt[0:14];

reg  [5:0] trg_x	[0:14];
reg  [5:0] trg_y	[0:14];
reg  [5:0] trg_x_nxt[0:14];
reg  [5:0] trg_y_nxt[0:14];

reg  [4:0] frame;
wire [4:0] frame_nxt;

/////////////////////////////
// WAVE_PROPAG + MAP

// actually this counter should be bigger ^_^
reg  [1:0] cnt_wp;
reg  [1:0] cnt_wp_nxt;

reg  [1:0] wave;
reg  [1:0] wave_nxt;

// 0: empty
// 1: obstacle {exits initially or other net already routed}
// 2 & 3: propagation sequence {2, 2, 3, 3}
reg  [1:0] map 		[0:63][0:63];
reg  [1:0] map_nxt 	[0:63][0:63];

/////////////////////////////
// RETRACE
reg  first_retrace;
wire first_retrace_nxt;

reg  [5:0] cur_x;
reg  [5:0] cur_x_nxt;
reg  [5:0] cur_y;
reg  [5:0] cur_y_nxt;

wire [3:0] wgt_sram	[16];
wire [3:0] loc_sram	[16];
reg  [3:0] loc_reg	[16];

/////////////////////////////
// OUTPUT
reg  [13:0] cost_nxt;

/////////////////////////////
// SRAM
reg  [6:0] cnt_128;
wire [6:0] cnt_128_nxt;

reg  [7:0] addr_s_1;
reg  [(DATA_WIDTH/2)-1:0] DI_s_1;
wire [(DATA_WIDTH/2)-1:0] DO_s_1;
reg  WEB_s_1;

reg  [7:0] addr_s_2;
reg  [(DATA_WIDTH/2)-1:0] DI_s_2;
wire [(DATA_WIDTH/2)-1:0] DO_s_2;
reg  WEB_s_2;

// ===============================================================
//  					       FSM
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
		IDLE: begin
			state_nxt = (in_valid) ? IN : IDLE;
		end
		IN: begin
			state_nxt = (in_valid) ? IN : WAIT_LOC_ARREADY;
		end
		WAIT_LOC_ARREADY: begin
			state_nxt = (arready_m_inf) ? WRITE_LOC_SRAM : WAIT_LOC_ARREADY;
		end
		WRITE_LOC_SRAM: begin
			state_nxt = (rlast_m_inf) ? WAIT_WGT_ARREADY : WRITE_LOC_SRAM;
		end
		WAIT_WGT_ARREADY: begin
			state_nxt = (arready_m_inf) ? WRITE_WGT_SRAM : WAIT_WGT_ARREADY;
		end
		WRITE_WGT_SRAM: begin
			state_nxt = (rlast_m_inf) ? MAP_INIT : WRITE_WGT_SRAM;
		end
		MAP_INIT: begin
			state_nxt = WAVE_PROPAG;
		end
		WAVE_PROPAG: begin
			state_nxt = (((map[trg_y[0] - 1][trg_x[0] + 0][1]) || (map[trg_y[0] + 1][trg_x[0] + 0][1])) || ((map[trg_y[0] + 0][trg_x[0] - 1][1]) || (map[trg_y[0] + 0][trg_x[0] + 1][1]))) ? RETRACE_READ_SRAM : WAVE_PROPAG;
		end
		RETRACE_READ_SRAM: begin
			state_nxt = RETRACE_WRITE_SRAM;
		end
		RETRACE_WRITE_SRAM: begin
			state_nxt = ((cur_y == src_y[0]) && (cur_x == src_x[0])) ? MAP_CLEAR : RETRACE_READ_SRAM;
		end
		MAP_CLEAR: begin
			state_nxt = (net[1]) ? MAP_INIT : WAIT_LOC_AWREADY;
		end
		WAIT_LOC_AWREADY: begin
			state_nxt = (awready_m_inf) ? WRITE_LOC_DRAM : WAIT_LOC_AWREADY;
		end
		WRITE_LOC_DRAM: begin
			state_nxt = (wlast_m_inf) ? OUT : WRITE_LOC_DRAM;
		end
		OUT: begin
			state_nxt = (bvalid_m_inf) ? IDLE : OUT;
		end
		default: begin
			state_nxt = state;
		end
	endcase
end

// ===============================================================
//  					      INPUT
// ===============================================================

// DFF of cnt_in_2 & cnt_in
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_in_2 <= 0;
		cnt_in <= 0;
	end
	else begin
		cnt_in_2 <= cnt_in_2_nxt;
		cnt_in <= cnt_in_nxt;
	end
end

// comb of cnt_in_2 & cnt_in
assign cnt_in_2_nxt = (in_valid) ? (cnt_in_2 + 1) : (cnt_in_2);
assign cnt_in_nxt = ((in_valid) && (cnt_in_2)) ? (cnt_in + 1) : ((state == IDLE) ? 0 : cnt_in);

// DFF of net
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 15; i = i + 1) begin
			net[i] <= 0;
		end
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			net[i] <= net_nxt[i];
		end
	end
end

// comb of net
always @(*) begin
	if((in_valid) && (!cnt_in_2)) begin
		for(i = 0; i < 15; i = i + 1) begin
			net_nxt[i] = (cnt_in == i[3:0]) ? net_id : net[i];
		end
	end
	else if(state == MAP_CLEAR) begin
		for(i = 0; i < 14; i = i + 1) begin
			net_nxt[i] = net[i + 1];
		end
		net_nxt[14] = 0;
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			net_nxt[i] = net[i];
		end
	end
end

// DFF of src
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 15; i = i + 1) begin
			src_x[i] <= 0;
			src_y[i] <= 0;
		end
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			src_x[i] <= src_x_nxt[i];
			src_y[i] <= src_y_nxt[i];
		end
	end
end

// comb of src
always @(*) begin
	if((in_valid) && !(cnt_in_2)) begin
		for(i = 0; i < 15; i = i + 1) begin
			src_x_nxt[i] = (cnt_in == i[3:0]) ? loc_x : src_x[i];
			src_y_nxt[i] = (cnt_in == i[3:0]) ? loc_y : src_y[i];
		end
	end
	else if(state == MAP_CLEAR) begin
		for(i = 0; i < 14; i = i + 1) begin
			src_x_nxt[i] = src_x[i + 1];
			src_y_nxt[i] = src_y[i + 1];
		end
		src_x_nxt[14] = 0;
		src_y_nxt[14] = 0;
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			src_x_nxt[i] = src_x[i];
			src_y_nxt[i] = src_y[i];
		end
	end
end

// DFF of trg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 15; i = i + 1) begin
			trg_x[i] <= 0;
			trg_y[i] <= 0;
		end
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			trg_x[i] <= trg_x_nxt[i];
			trg_y[i] <= trg_y_nxt[i];
		end
	end
end

// comb of trg
always @(*) begin
	if((in_valid) && (cnt_in_2)) begin
		for(i = 0; i < 15; i = i + 1) begin
			trg_x_nxt[i] = (cnt_in == i[3:0]) ? loc_x : trg_x[i];
			trg_y_nxt[i] = (cnt_in == i[3:0]) ? loc_y : trg_y[i];
		end
	end
	else if(state == MAP_CLEAR) begin
		for(i = 0; i < 14; i = i + 1) begin
			trg_x_nxt[i] = trg_x[i + 1];
			trg_y_nxt[i] = trg_y[i + 1];
		end
		trg_x_nxt[14] = 0;
		trg_y_nxt[14] = 0;
	end
	else begin
		for(i = 0; i < 15; i = i + 1) begin
			trg_x_nxt[i] = trg_x[i];
			trg_y_nxt[i] = trg_y[i];
		end
	end
end

// DFF of frame
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		frame <= 0;
	end
	else begin
		frame <= frame_nxt;
	end
end

// comb of frame
assign frame_nxt = ((in_valid) && !(cnt_in)) ? (frame_id) : (frame);

// ===============================================================
//  				           MAP
// ===============================================================

// DFF of cnt_wp
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_wp <= 0;
	end
	else begin
		cnt_wp <= cnt_wp_nxt;
	end
end

// comb of cnt_wp
always @(*) begin
	case (state)
		MAP_INIT: begin
			cnt_wp_nxt = 0;
		end
		WAVE_PROPAG: begin
			if((map[trg_y[0] - 1][trg_x[0] + 0][1]) || (map[trg_y[0] + 1][trg_x[0] + 0][1]) || (map[trg_y[0] + 0][trg_x[0] - 1][1]) || (map[trg_y[0] + 0][trg_x[0] + 1][1])) begin
				cnt_wp_nxt = cnt_wp;
			end
			else begin
				cnt_wp_nxt = cnt_wp + 1;
			end
		end 
		RETRACE_READ_SRAM: begin
			cnt_wp_nxt = cnt_wp - 1;
		end
		default: begin
			cnt_wp_nxt = cnt_wp;
		end
	endcase
end

// DFF of wave
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wave <= 0;
	end
	else begin
		wave <= wave_nxt;
	end
end

// comb of wave
always @(*) begin
	if(state == MAP_INIT) begin // src is set 3 should be detected in propagation in first cycle
		wave_nxt = 2'b11;
	end
	else begin // cnt{0, 1, 2, 3} <-> wave{2, 2, 3, 3}
		wave_nxt = {1'b1, cnt_wp[1]};
	end
end

// DFF of map
always @(posedge clk) begin
	for(i = 0; i < 64; i = i + 1) begin
		for(j = 0; j < 64; j = j + 1) begin
			map[i][j] <= map_nxt[i][j];
		end
	end
end

// comb of map
always @(*) begin
	case (state)
		WRITE_LOC_SRAM: begin // initialize map in register
			for(i = 0; i < 63; i = i + 1) begin
				for(j = 0; j < 32; j = j + 1) begin
					map_nxt[i][j] = map[i][j + 32];
				end
				for(j = 32; j < 64; j = j + 1) begin
					map_nxt[i][j] = map[i + 1][j - 32];
				end
			end
			for(j = 0; j < 32; j = j + 1) begin
				map_nxt[63][j] = map[63][j + 32];
			end
			map_nxt[63][32] = (rdata_m_inf[  3:  0]) ? 1 : 0;
			map_nxt[63][33] = (rdata_m_inf[  7:  4]) ? 1 : 0;
			map_nxt[63][34] = (rdata_m_inf[ 11:  8]) ? 1 : 0;
			map_nxt[63][35] = (rdata_m_inf[ 15: 12]) ? 1 : 0;
			map_nxt[63][36] = (rdata_m_inf[ 19: 16]) ? 1 : 0;
			map_nxt[63][37] = (rdata_m_inf[ 23: 20]) ? 1 : 0;
			map_nxt[63][38] = (rdata_m_inf[ 27: 24]) ? 1 : 0;
			map_nxt[63][39] = (rdata_m_inf[ 31: 28]) ? 1 : 0;
			map_nxt[63][40] = (rdata_m_inf[ 35: 32]) ? 1 : 0;
			map_nxt[63][41] = (rdata_m_inf[ 39: 36]) ? 1 : 0;
			map_nxt[63][42] = (rdata_m_inf[ 43: 40]) ? 1 : 0;
			map_nxt[63][43] = (rdata_m_inf[ 47: 44]) ? 1 : 0;
			map_nxt[63][44] = (rdata_m_inf[ 51: 48]) ? 1 : 0;
			map_nxt[63][45] = (rdata_m_inf[ 55: 52]) ? 1 : 0;
			map_nxt[63][46] = (rdata_m_inf[ 59: 56]) ? 1 : 0;
			map_nxt[63][47] = (rdata_m_inf[ 63: 60]) ? 1 : 0;
			map_nxt[63][48] = (rdata_m_inf[ 67: 64]) ? 1 : 0;
			map_nxt[63][49] = (rdata_m_inf[ 71: 68]) ? 1 : 0;
			map_nxt[63][50] = (rdata_m_inf[ 75: 72]) ? 1 : 0;
			map_nxt[63][51] = (rdata_m_inf[ 79: 76]) ? 1 : 0;
			map_nxt[63][52] = (rdata_m_inf[ 83: 80]) ? 1 : 0;
			map_nxt[63][53] = (rdata_m_inf[ 87: 84]) ? 1 : 0;
			map_nxt[63][54] = (rdata_m_inf[ 91: 88]) ? 1 : 0;
			map_nxt[63][55] = (rdata_m_inf[ 95: 92]) ? 1 : 0;
			map_nxt[63][56] = (rdata_m_inf[ 99: 96]) ? 1 : 0;
			map_nxt[63][57] = (rdata_m_inf[103:100]) ? 1 : 0;
			map_nxt[63][58] = (rdata_m_inf[107:104]) ? 1 : 0;
			map_nxt[63][59] = (rdata_m_inf[111:108]) ? 1 : 0;
			map_nxt[63][60] = (rdata_m_inf[115:112]) ? 1 : 0;
			map_nxt[63][61] = (rdata_m_inf[119:116]) ? 1 : 0;
			map_nxt[63][62] = (rdata_m_inf[123:120]) ? 1 : 0;
			map_nxt[63][63] = (rdata_m_inf[127:124]) ? 1 : 0;
		end 
		MAP_INIT: begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0 ; j < 64; j = j + 1) begin
					map_nxt[i][j] = map[i][j];
				end
			end
			map_nxt[src_y[0]][src_x[0]] = 2'b11; // set source
			map_nxt[trg_y[0]][trg_x[0]] = 2'b00; // set sink
		end
		WAVE_PROPAG: begin ////////////////////////////////////////////////////////////////////////////////////////////////////////////////// notice!
			// 2 conditions:
			// 1. it should be 0 (empty)
			// 2. there is at least one wave beside

			// corner
			map_nxt[ 0][ 0] = ((!map[ 0][ 0]) && ((map[ 0][ 1][1]) || (map[ 1][ 0][1]))) ? wave_nxt : map[ 0][ 0]; // left-up
			map_nxt[ 0][63] = ((!map[ 0][63]) && ((map[ 0][62][1]) || (map[ 1][63][1]))) ? wave_nxt : map[ 0][63]; // right-up
			map_nxt[63][ 0] = ((!map[63][ 0]) && ((map[62][ 0][1]) || (map[63][ 1][1]))) ? wave_nxt : map[63][ 0]; // left-down
			map_nxt[63][63] = ((!map[63][63]) && ((map[62][63][1]) || (map[63][62][1]))) ? wave_nxt : map[63][63]; // right-down

			// side
			for(i = 1; i < 63; i = i + 1) begin // y-axis
				map_nxt[i][ 0] = ((!map[i][ 0]) && ((map[i - 1][ 0][1]) || (map[i + 1][ 0][1]) || (map[i + 0][ 1][1]))) ? wave_nxt : map[ i][ 0]; // left
				map_nxt[i][63] = ((!map[i][63]) && ((map[i - 1][63][1]) || (map[i + 1][63][1]) || (map[i + 0][62][1]))) ? wave_nxt : map[ i][63]; // right
			end
			for(j = 1; j < 63; j = j + 1) begin // x-axis
				map_nxt[ 0][j] = ((!map[ 0][j]) && ((map[ 1][j + 0][1]) || (map[ 0][j - 1][1]) || (map[ 0][j + 1][1]))) ? wave_nxt : map[ 0][ j]; // up
				map_nxt[63][j] = ((!map[63][j]) && ((map[62][j + 0][1]) || (map[63][j - 1][1]) || (map[63][j + 1][1]))) ? wave_nxt : map[63][ j]; // down
			end // 

			// internal
			for(i = 1; i < 63; i = i + 1) begin
				for(j = 1; j < 63; j = j + 1) begin
					map_nxt[i][j] = ((!map[i][j]) && (((map[i - 1][j + 0][1]) || (map[i + 1][j + 0][1])) || ((map[i + 0][j - 1][1]) || (map[i + 0][j + 1][1])))) ? wave_nxt : map[ i][ j];
				end
			end
		end
		RETRACE_WRITE_SRAM: begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0 ; j < 64; j = j + 1) begin
					map_nxt[i][j] = map[i][j];
				end
			end
			map_nxt[cur_y][cur_x] = 2'b01; // fill 1 to the path
		end
		MAP_CLEAR: begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0 ; j < 64; j = j + 1) begin
					map_nxt[i][j] = (map[i][j][1]) ? 0 : map[i][j]; // clear wave
				end
			end
		end
		default: begin
			for(i = 0; i < 64; i = i + 1) begin
				for(j = 0; j < 64; j = j + 1) begin
					map_nxt[i][j] = map[i][j];
				end
			end
		end
	endcase
end

// ===============================================================
//  				  		RETRACE
// ===============================================================

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		first_retrace <= 0;
	end
	else begin
		first_retrace <= first_retrace_nxt;
	end
end

assign first_retrace_nxt = (state == RETRACE_WRITE_SRAM) ? 0 : ((state == MAP_INIT) ? 1 : first_retrace);

// DFF of cur
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cur_x <= 0;
		cur_y <= 0;
	end
	else begin
		cur_x <= cur_x_nxt;
		cur_y <= cur_y_nxt;
	end
end

// comb of cur
always @(*) begin
	case (state)
		MAP_INIT: begin
			cur_x_nxt = trg_x[0];
			cur_y_nxt = trg_y[0];
		end 
		RETRACE_READ_SRAM: begin // notice the priority! 
			if(first_retrace) begin
				cur_x_nxt = cur_x;
				cur_y_nxt = cur_y;
			end
			else if((map[cur_y + 1][cur_x + 0] == wave) && (~cur_y)) begin // down
				cur_x_nxt = cur_x;
				cur_y_nxt = cur_y + 1;
			end
			else if((map[cur_y - 1][cur_x + 0] == wave) && (cur_y)) begin // up
				cur_x_nxt = cur_x;
				cur_y_nxt = cur_y - 1;
			end
			else if((map[cur_y + 0][cur_x + 1] == wave) && (~cur_x)) begin // right
				cur_x_nxt = cur_x + 1;
				cur_y_nxt = cur_y;
			end
			else if((map[cur_y + 0][cur_x - 1] == wave) && (cur_x)) begin // left
				cur_x_nxt = cur_x - 1;
				cur_y_nxt = cur_y;
			end
			else begin
				cur_x_nxt = cur_x;
				cur_y_nxt = cur_y;
			end
		end
		default: begin
			cur_x_nxt = cur_x;
			cur_y_nxt = cur_y;
		end
	endcase
end

// comb of wgt_sram
assign wgt_sram[ 0] = (cur_x[4]) ? DO_s_1[ 3: 0] : DO_s_2[ 3: 0];
assign wgt_sram[ 1] = (cur_x[4]) ? DO_s_1[ 7: 4] : DO_s_2[ 7: 4];
assign wgt_sram[ 2] = (cur_x[4]) ? DO_s_1[11: 8] : DO_s_2[11: 8];
assign wgt_sram[ 3] = (cur_x[4]) ? DO_s_1[15:12] : DO_s_2[15:12];
assign wgt_sram[ 4] = (cur_x[4]) ? DO_s_1[19:16] : DO_s_2[19:16];
assign wgt_sram[ 5] = (cur_x[4]) ? DO_s_1[23:20] : DO_s_2[23:20];
assign wgt_sram[ 6] = (cur_x[4]) ? DO_s_1[27:24] : DO_s_2[27:24];
assign wgt_sram[ 7] = (cur_x[4]) ? DO_s_1[31:28] : DO_s_2[31:28];
assign wgt_sram[ 8] = (cur_x[4]) ? DO_s_1[35:32] : DO_s_2[35:32];
assign wgt_sram[ 9] = (cur_x[4]) ? DO_s_1[39:36] : DO_s_2[39:36];
assign wgt_sram[10] = (cur_x[4]) ? DO_s_1[43:40] : DO_s_2[43:40];
assign wgt_sram[11] = (cur_x[4]) ? DO_s_1[47:44] : DO_s_2[47:44];
assign wgt_sram[12] = (cur_x[4]) ? DO_s_1[51:48] : DO_s_2[51:48];
assign wgt_sram[13] = (cur_x[4]) ? DO_s_1[55:52] : DO_s_2[55:52];
assign wgt_sram[14] = (cur_x[4]) ? DO_s_1[59:56] : DO_s_2[59:56];
assign wgt_sram[15] = (cur_x[4]) ? DO_s_1[63:60] : DO_s_2[63:60];

// comb of loc_sram
assign loc_sram[ 0] = (cur_x[4]) ? DO_s_2[ 3: 0] : DO_s_1[ 3: 0];
assign loc_sram[ 1] = (cur_x[4]) ? DO_s_2[ 7: 4] : DO_s_1[ 7: 4];
assign loc_sram[ 2] = (cur_x[4]) ? DO_s_2[11: 8] : DO_s_1[11: 8];
assign loc_sram[ 3] = (cur_x[4]) ? DO_s_2[15:12] : DO_s_1[15:12];
assign loc_sram[ 4] = (cur_x[4]) ? DO_s_2[19:16] : DO_s_1[19:16];
assign loc_sram[ 5] = (cur_x[4]) ? DO_s_2[23:20] : DO_s_1[23:20];
assign loc_sram[ 6] = (cur_x[4]) ? DO_s_2[27:24] : DO_s_1[27:24];
assign loc_sram[ 7] = (cur_x[4]) ? DO_s_2[31:28] : DO_s_1[31:28];
assign loc_sram[ 8] = (cur_x[4]) ? DO_s_2[35:32] : DO_s_1[35:32];
assign loc_sram[ 9] = (cur_x[4]) ? DO_s_2[39:36] : DO_s_1[39:36];
assign loc_sram[10] = (cur_x[4]) ? DO_s_2[43:40] : DO_s_1[43:40];
assign loc_sram[11] = (cur_x[4]) ? DO_s_2[47:44] : DO_s_1[47:44];
assign loc_sram[12] = (cur_x[4]) ? DO_s_2[51:48] : DO_s_1[51:48];
assign loc_sram[13] = (cur_x[4]) ? DO_s_2[55:52] : DO_s_1[55:52];
assign loc_sram[14] = (cur_x[4]) ? DO_s_2[59:56] : DO_s_1[59:56];
assign loc_sram[15] = (cur_x[4]) ? DO_s_2[63:60] : DO_s_1[63:60];

// comb of loc_reg
always @(*) begin
	for(i = 0; i < 16; i = i + 1) begin
		loc_reg[i] = loc_sram[i];
	end
	loc_reg[cur_x[3:0]] = net[0];
end


// ===============================================================
//  					     OUTPUT
// ===============================================================

// DFF of cost
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cost <= 0;
	end
	else begin
		cost <= cost_nxt;
	end
end

// comb of cost
always @(*) begin
	case (state)
		IDLE: begin
			cost_nxt = 0;
		end
		RETRACE_WRITE_SRAM: begin
			if((first_retrace) || ((cur_x == src_x[0]) && (cur_y == src_y[0]))) begin
				cost_nxt = cost;
			end
			else begin
				cost_nxt = cost + wgt_sram[cur_x[3:0]];
			end
		end
		default: begin
			cost_nxt = cost;
		end
	endcase
end

// comb of busy
assign busy = ((state == IDLE) || (state == IN) || (state == OUT)) ? 0 : 1;

// ===============================================================
//  					     SRAM_1
// ===============================================================

// DFF of cnt_128
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_128 <= 0;
	end
	else begin
		cnt_128 <= cnt_128_nxt;
	end
end

// comb of cnt_128
assign cnt_128_nxt = ((((state == WRITE_LOC_SRAM) || (state == WRITE_WGT_SRAM)) && (rvalid_m_inf)) || ((state == WRITE_LOC_DRAM) && (wready_m_inf))) ? (cnt_128 + 1) : 0;

// address of SRAM_1
always @(*) begin
	case (state)
		WRITE_LOC_SRAM: begin
			addr_s_1 = {cnt_128, 1'b0};
		end 
		WRITE_WGT_SRAM: begin
			addr_s_1 = {cnt_128, 1'b1};
		end
		RETRACE_READ_SRAM: begin
			addr_s_1 = {cur_y_nxt, cur_x_nxt[5:4]};
		end
		RETRACE_WRITE_SRAM: begin
			addr_s_1 = {cur_y, cur_x[5:4]};
		end
		WRITE_LOC_DRAM: begin
			addr_s_1 = {cnt_128_nxt, 1'b0};
		end
		default: begin
			addr_s_1 = 0;
		end
	endcase
end

// DI of SRAM_1
always @(*) begin
	case (state)
		WRITE_LOC_SRAM: begin
			DI_s_1 = rdata_m_inf[ 63: 0];
		end
		WRITE_WGT_SRAM: begin
			DI_s_1 = rdata_m_inf[127:64];
		end
		RETRACE_WRITE_SRAM: begin
			if((first_retrace) || ((cur_x == src_x[0]) && (cur_y == src_y[0]))) begin
				DI_s_1 = {loc_sram[15], loc_sram[14], loc_sram[13], loc_sram[12], loc_sram[11], loc_sram[10], loc_sram[9], loc_sram[8], loc_sram[7], loc_sram[6], loc_sram[5], loc_sram[4], loc_sram[3], loc_sram[2], loc_sram[1], loc_sram[0]};
			end
			else begin
				DI_s_1 = {loc_reg[15], loc_reg[14], loc_reg[13], loc_reg[12], loc_reg[11], loc_reg[10], loc_reg[9], loc_reg[8], loc_reg[7], loc_reg[6], loc_reg[5], loc_reg[4], loc_reg[3], loc_reg[2], loc_reg[1], loc_reg[0]};
			end
		end
		default: begin
			DI_s_1 = 0;
		end
	endcase
end

// WEB of SRAM_1
always @(*) begin
	case (state)
		WRITE_LOC_SRAM, WRITE_WGT_SRAM: begin
			if(rvalid_m_inf) begin
				WEB_s_1 = 0;
			end
			else begin
				WEB_s_1 = 1;
			end
		end
		RETRACE_WRITE_SRAM: begin
			if(!cur_x[4]) begin // 0 ~ 15, 32 ~ 47
				WEB_s_1 = 0;
			end
			else begin // 16 ~ 31, 48 ~ 63
				WEB_s_1 = 1;
			end
		end
		default: begin
			WEB_s_1 = 1;
		end
	endcase
end

sram_1 s_1	(	. A0(addr_s_1[ 0]), . A1(addr_s_1[ 1]), . A2(addr_s_1[ 2]), . A3(addr_s_1[ 3]), . A4(addr_s_1[ 4]), . A5(addr_s_1[ 5]), . A6(addr_s_1[ 6]), . A7(addr_s_1[ 7]),

				.  DO0(DO_s_1[ 0]), .  DO1(DO_s_1[ 1]), .  DO2(DO_s_1[ 2]), .  DO3(DO_s_1[ 3]), .  DO4(DO_s_1[ 4]), .  DO5(DO_s_1[ 5]), .  DO6(DO_s_1[ 6]), .  DO7(DO_s_1[ 7]),
				.  DO8(DO_s_1[ 8]), .  DO9(DO_s_1[ 9]), . DO10(DO_s_1[10]), . DO11(DO_s_1[11]), . DO12(DO_s_1[12]), . DO13(DO_s_1[13]), . DO14(DO_s_1[14]), . DO15(DO_s_1[15]),
				. DO16(DO_s_1[16]), . DO17(DO_s_1[17]), . DO18(DO_s_1[18]), . DO19(DO_s_1[19]), . DO20(DO_s_1[20]), . DO21(DO_s_1[21]), . DO22(DO_s_1[22]), . DO23(DO_s_1[23]),
				. DO24(DO_s_1[24]), . DO25(DO_s_1[25]), . DO26(DO_s_1[26]), . DO27(DO_s_1[27]), . DO28(DO_s_1[28]), . DO29(DO_s_1[29]), . DO30(DO_s_1[30]), . DO31(DO_s_1[31]),
				. DO32(DO_s_1[32]), . DO33(DO_s_1[33]), . DO34(DO_s_1[34]), . DO35(DO_s_1[35]), . DO36(DO_s_1[36]), . DO37(DO_s_1[37]), . DO38(DO_s_1[38]), . DO39(DO_s_1[39]),
				. DO40(DO_s_1[40]), . DO41(DO_s_1[41]), . DO42(DO_s_1[42]), . DO43(DO_s_1[43]), . DO44(DO_s_1[44]), . DO45(DO_s_1[45]), . DO46(DO_s_1[46]), . DO47(DO_s_1[47]),
				. DO48(DO_s_1[48]), . DO49(DO_s_1[49]), . DO50(DO_s_1[50]), . DO51(DO_s_1[51]), . DO52(DO_s_1[52]), . DO53(DO_s_1[53]), . DO54(DO_s_1[54]), . DO55(DO_s_1[55]),
				. DO56(DO_s_1[56]), . DO57(DO_s_1[57]), . DO58(DO_s_1[58]), . DO59(DO_s_1[59]), . DO60(DO_s_1[60]), . DO61(DO_s_1[61]), . DO62(DO_s_1[62]), . DO63(DO_s_1[63]),

				.  DI0(DI_s_1[ 0]), .  DI1(DI_s_1[ 1]), .  DI2(DI_s_1[ 2]), .  DI3(DI_s_1[ 3]), .  DI4(DI_s_1[ 4]), .  DI5(DI_s_1[ 5]), .  DI6(DI_s_1[ 6]), .  DI7(DI_s_1[ 7]),
				.  DI8(DI_s_1[ 8]), .  DI9(DI_s_1[ 9]), . DI10(DI_s_1[10]), . DI11(DI_s_1[11]), . DI12(DI_s_1[12]), . DI13(DI_s_1[13]), . DI14(DI_s_1[14]), . DI15(DI_s_1[15]),
				. DI16(DI_s_1[16]), . DI17(DI_s_1[17]), . DI18(DI_s_1[18]), . DI19(DI_s_1[19]), . DI20(DI_s_1[20]), . DI21(DI_s_1[21]), . DI22(DI_s_1[22]), . DI23(DI_s_1[23]),
				. DI24(DI_s_1[24]), . DI25(DI_s_1[25]), . DI26(DI_s_1[26]), . DI27(DI_s_1[27]), . DI28(DI_s_1[28]), . DI29(DI_s_1[29]), . DI30(DI_s_1[30]), . DI31(DI_s_1[31]),
				. DI32(DI_s_1[32]), . DI33(DI_s_1[33]), . DI34(DI_s_1[34]), . DI35(DI_s_1[35]), . DI36(DI_s_1[36]), . DI37(DI_s_1[37]), . DI38(DI_s_1[38]), . DI39(DI_s_1[39]),
				. DI40(DI_s_1[40]), . DI41(DI_s_1[41]), . DI42(DI_s_1[42]), . DI43(DI_s_1[43]), . DI44(DI_s_1[44]), . DI45(DI_s_1[45]), . DI46(DI_s_1[46]), . DI47(DI_s_1[47]),
				. DI48(DI_s_1[48]), . DI49(DI_s_1[49]), . DI50(DI_s_1[50]), . DI51(DI_s_1[51]), . DI52(DI_s_1[52]), . DI53(DI_s_1[53]), . DI54(DI_s_1[54]), . DI55(DI_s_1[55]),
				. DI56(DI_s_1[56]), . DI57(DI_s_1[57]), . DI58(DI_s_1[58]), . DI59(DI_s_1[59]), . DI60(DI_s_1[60]), . DI61(DI_s_1[61]), . DI62(DI_s_1[62]), . DI63(DI_s_1[63]),

				.CK(clk), .WEB(WEB_s_1), .OE(1'b1), .CS(1'b1));

// ===============================================================
//  					     SRAM_2
// ===============================================================

// address of SRAM_2
always @(*) begin
	case (state)
		WRITE_LOC_SRAM: begin
			addr_s_2 = {cnt_128, 1'b0};
		end 
		WRITE_WGT_SRAM: begin
			addr_s_2 = {cnt_128, 1'b1};
		end
		RETRACE_READ_SRAM: begin
			addr_s_2 = {cur_y_nxt, cur_x_nxt[5], !cur_x_nxt[4]};
		end
		RETRACE_WRITE_SRAM: begin
			addr_s_2 = {cur_y, cur_x[5], !cur_x[4]};
		end
		WRITE_LOC_DRAM: begin
			addr_s_2 = {cnt_128_nxt, 1'b0};
		end
		default: begin
			addr_s_2 = 0;
		end
	endcase
end

// DI of SRAM_2
always @(*) begin
	case (state)
		WRITE_LOC_SRAM: begin
			DI_s_2 = rdata_m_inf[127:64];
		end
		WRITE_WGT_SRAM: begin
			DI_s_2 = rdata_m_inf[ 63: 0];
		end
		RETRACE_WRITE_SRAM: begin
			if((first_retrace) || ((cur_x == src_x[0]) && (cur_y == src_y[0]))) begin
				DI_s_2 = {loc_sram[15], loc_sram[14], loc_sram[13], loc_sram[12], loc_sram[11], loc_sram[10], loc_sram[9], loc_sram[8], loc_sram[7], loc_sram[6], loc_sram[5], loc_sram[4], loc_sram[3], loc_sram[2], loc_sram[1], loc_sram[0]};
			end
			else begin
				DI_s_2 = {loc_reg[15], loc_reg[14], loc_reg[13], loc_reg[12], loc_reg[11], loc_reg[10], loc_reg[9], loc_reg[8], loc_reg[7], loc_reg[6], loc_reg[5], loc_reg[4], loc_reg[3], loc_reg[2], loc_reg[1], loc_reg[0]};
			end
		end
		default: begin
			DI_s_2 = 0;
		end
	endcase
end

// WEB of SRAM_2
always @(*) begin
	case (state)
		WRITE_LOC_SRAM, WRITE_WGT_SRAM: begin
			if(rvalid_m_inf) begin
				WEB_s_2 = 0;
			end
			else begin
				WEB_s_2 = 1;
			end
		end
		RETRACE_WRITE_SRAM: begin
			if(cur_x[4]) begin // 16 ~ 31, 48 ~ 63
				WEB_s_2 = 0;
			end
			else begin // 0 ~ 15, 32 ~ 47
				WEB_s_2 = 1;
			end
		end
		default: begin
			WEB_s_2 = 1;
		end
	endcase
end

sram_2 s_2	(	. A0(addr_s_2[ 0]), . A1(addr_s_2[ 1]), . A2(addr_s_2[ 2]), . A3(addr_s_2[ 3]), . A4(addr_s_2[ 4]), . A5(addr_s_2[ 5]), . A6(addr_s_2[ 6]), . A7(addr_s_2[ 7]),

				.  DO0(DO_s_2[ 0]), .  DO1(DO_s_2[ 1]), .  DO2(DO_s_2[ 2]), .  DO3(DO_s_2[ 3]), .  DO4(DO_s_2[ 4]), .  DO5(DO_s_2[ 5]), .  DO6(DO_s_2[ 6]), .  DO7(DO_s_2[ 7]),
				.  DO8(DO_s_2[ 8]), .  DO9(DO_s_2[ 9]), . DO10(DO_s_2[10]), . DO11(DO_s_2[11]), . DO12(DO_s_2[12]), . DO13(DO_s_2[13]), . DO14(DO_s_2[14]), . DO15(DO_s_2[15]),
				. DO16(DO_s_2[16]), . DO17(DO_s_2[17]), . DO18(DO_s_2[18]), . DO19(DO_s_2[19]), . DO20(DO_s_2[20]), . DO21(DO_s_2[21]), . DO22(DO_s_2[22]), . DO23(DO_s_2[23]),
				. DO24(DO_s_2[24]), . DO25(DO_s_2[25]), . DO26(DO_s_2[26]), . DO27(DO_s_2[27]), . DO28(DO_s_2[28]), . DO29(DO_s_2[29]), . DO30(DO_s_2[30]), . DO31(DO_s_2[31]),
				. DO32(DO_s_2[32]), . DO33(DO_s_2[33]), . DO34(DO_s_2[34]), . DO35(DO_s_2[35]), . DO36(DO_s_2[36]), . DO37(DO_s_2[37]), . DO38(DO_s_2[38]), . DO39(DO_s_2[39]),
				. DO40(DO_s_2[40]), . DO41(DO_s_2[41]), . DO42(DO_s_2[42]), . DO43(DO_s_2[43]), . DO44(DO_s_2[44]), . DO45(DO_s_2[45]), . DO46(DO_s_2[46]), . DO47(DO_s_2[47]),
				. DO48(DO_s_2[48]), . DO49(DO_s_2[49]), . DO50(DO_s_2[50]), . DO51(DO_s_2[51]), . DO52(DO_s_2[52]), . DO53(DO_s_2[53]), . DO54(DO_s_2[54]), . DO55(DO_s_2[55]),
				. DO56(DO_s_2[56]), . DO57(DO_s_2[57]), . DO58(DO_s_2[58]), . DO59(DO_s_2[59]), . DO60(DO_s_2[60]), . DO61(DO_s_2[61]), . DO62(DO_s_2[62]), . DO63(DO_s_2[63]),

				.  DI0(DI_s_2[ 0]), .  DI1(DI_s_2[ 1]), .  DI2(DI_s_2[ 2]), .  DI3(DI_s_2[ 3]), .  DI4(DI_s_2[ 4]), .  DI5(DI_s_2[ 5]), .  DI6(DI_s_2[ 6]), .  DI7(DI_s_2[ 7]),
				.  DI8(DI_s_2[ 8]), .  DI9(DI_s_2[ 9]), . DI10(DI_s_2[10]), . DI11(DI_s_2[11]), . DI12(DI_s_2[12]), . DI13(DI_s_2[13]), . DI14(DI_s_2[14]), . DI15(DI_s_2[15]),
				. DI16(DI_s_2[16]), . DI17(DI_s_2[17]), . DI18(DI_s_2[18]), . DI19(DI_s_2[19]), . DI20(DI_s_2[20]), . DI21(DI_s_2[21]), . DI22(DI_s_2[22]), . DI23(DI_s_2[23]),
				. DI24(DI_s_2[24]), . DI25(DI_s_2[25]), . DI26(DI_s_2[26]), . DI27(DI_s_2[27]), . DI28(DI_s_2[28]), . DI29(DI_s_2[29]), . DI30(DI_s_2[30]), . DI31(DI_s_2[31]),
				. DI32(DI_s_2[32]), . DI33(DI_s_2[33]), . DI34(DI_s_2[34]), . DI35(DI_s_2[35]), . DI36(DI_s_2[36]), . DI37(DI_s_2[37]), . DI38(DI_s_2[38]), . DI39(DI_s_2[39]),
				. DI40(DI_s_2[40]), . DI41(DI_s_2[41]), . DI42(DI_s_2[42]), . DI43(DI_s_2[43]), . DI44(DI_s_2[44]), . DI45(DI_s_2[45]), . DI46(DI_s_2[46]), . DI47(DI_s_2[47]),
				. DI48(DI_s_2[48]), . DI49(DI_s_2[49]), . DI50(DI_s_2[50]), . DI51(DI_s_2[51]), . DI52(DI_s_2[52]), . DI53(DI_s_2[53]), . DI54(DI_s_2[54]), . DI55(DI_s_2[55]),
				. DI56(DI_s_2[56]), . DI57(DI_s_2[57]), . DI58(DI_s_2[58]), . DI59(DI_s_2[59]), . DI60(DI_s_2[60]), . DI61(DI_s_2[61]), . DI62(DI_s_2[62]), . DI63(DI_s_2[63]),
				
				.CK(clk), .WEB(WEB_s_2), . OE(1'b1), .CS(1'b1));

// ===============================================================
//  					      DRAM
// ===============================================================

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 

assign arid_m_inf = 0; 		// read address ID
							// only recognize master(4'b0000) in this project

assign arburst_m_inf = 1; 	// burst type
							// only support 2'b01 in this project

assign arsize_m_inf = 4; 	// burst size
							// only support 3'b100 (16 bytes = 128 bits) in this project

assign arlen_m_inf = 127; 	// burst length
							// determine number of data transfered with the associated address
							// in my design, it should be 64(row) * 2(col), because 1 data containing 32 cols (32 (block) * 4 (bit))

assign arvalid_m_inf = ((state == WAIT_LOC_ARREADY) || (state == WAIT_WGT_ARREADY)) ? 1 : 0; // keep arvalid high until arready goes high

assign araddr_m_inf = (state == WAIT_LOC_ARREADY) ? (LOC_START + frame * FRAME_WIDTH) : (WGT_START + frame * FRAME_WIDTH);

// ------------------------
// (2)	axi read data channel 

assign rready_m_inf = ((state == WRITE_LOC_SRAM) || (state == WRITE_WGT_SRAM)) ? 1 : 0;

// ------------------------

// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 

assign awid_m_inf = 0;		// write address ID
							// only recognize master(4'b0000) in this project

assign awburst_m_inf = 1;	// burst type
							// only support 2'b01 in this project

assign awsize_m_inf = 4;	// burst size
							// only support 3'b100 (16 bytes = 128 bits) in this project

assign awlen_m_inf = 127;	// burst length
							// determine number of data transfered with the associated address
							// in my design, it should be 64(row) * 2(col), because 1 data containing 32 cols (32 (block) * 4 (bit))

assign awvalid_m_inf = (state == WAIT_LOC_AWREADY) ? 1 : 0;

assign awaddr_m_inf = (state == WAIT_LOC_AWREADY) ? (LOC_START + frame * FRAME_WIDTH) : 0;

// -------------------------
// (2)	axi write data channel 

assign  wvalid_m_inf = (state == WRITE_LOC_DRAM) ? 1 : 0;

assign  wdata_m_inf = (state == WRITE_LOC_DRAM) ? {DO_s_2, DO_s_1} : 0;

assign  wlast_m_inf = ((state == WRITE_LOC_DRAM) && !(~cnt_128)) ? 1 : 0;

// -------------------------
// (3)	axi write response channel

assign bready_m_inf = ((state == WRITE_LOC_DRAM) || (state == OUT)) ? 1 : 0; 

// -------------------------

endmodule
