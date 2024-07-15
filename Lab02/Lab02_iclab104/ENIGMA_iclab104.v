//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 
module ENIGMA(
	// Input Ports
	clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 

	// Output Ports
	out_code, 
	out_valid
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk;              // clock input
input rst_n;            // asynchronous reset (active low)
input in_valid;         // code_in valid signal for rotor (level sensitive). 0/1: inactive/active
input in_valid_2;       // code_in valid signal for code  (level sensitive). 0/1: inactive/active
input crypt_mode;       // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

input [6-1:0] code_in;	// When in_valid   is active, then code_in is input of rotors. 
						// When in_valid_2 is active, then code_in is input of code words.
							
output reg out_valid;       	// 0: out_code is not valid; 1: out_code is valid
output reg [6-1:0] out_code;	// encrypted/decrypted code word

// ===============================================================
// Other Declaration
// ===============================================================
reg in_valid_reg;
reg in_valid_2_reg;
reg crypt_mode_reg;
reg crypt_mode_nxt;
reg out_valid_nxt;
reg [5:0] out_code_nxt;
reg [5:0] code_in_reg;
reg [5:0] rotor_A [63:0];
reg [5:0] rotor_A_nxt [63:0];
reg [5:0] rotor_B [63:0];
reg [5:0] rotor_B_nxt [63:0];
reg [5:0] cnt, cnt_nxt;
reg flag_A, flag_A_nxt;
reg [5:0] rotor_A_out;
reg [5:0] rotor_B_out;
reg [5:0] reflector_out;
reg [5:0] rotor_B_inv;
reg [5:0] rotor_A_inv;

integer idx;

// ===============================================================
// Design
// ===============================================================
// ff of input
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid_reg <= 0;
		in_valid_2_reg <= 0;
		crypt_mode_reg <= 0;
		code_in_reg <= 0;
	end
	else begin
		in_valid_reg <= in_valid;
		in_valid_2_reg <= in_valid_2;
		crypt_mode_reg <= crypt_mode_nxt;
		code_in_reg <= code_in;
	end
end

assign crypt_mode_nxt = (in_valid && !in_valid_reg) ? crypt_mode : crypt_mode_reg;

// ff of cnt
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else begin
		cnt <= cnt_nxt;
	end
end

assign cnt_nxt = (in_valid_reg) ? cnt + 1 : 0;

// ff of flag_A
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag_A <= 1;
	end
	else begin
		flag_A <= flag_A_nxt;
	end
end

assign flag_A_nxt = in_valid_reg ? ((cnt == 63) ? 0 : flag_A) : 1;

// ff of rotor_A
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_A[idx] <= 0;
		end
	end
	else begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_A[idx] <= rotor_A_nxt[idx];
		end
	end
end

// comb of rotor_A
always @(*) begin
	if (in_valid_reg & flag_A) begin
		for(idx=0; idx<63; idx=idx+1) begin
			rotor_A_nxt[idx] = rotor_A[idx+1];
		end
		rotor_A_nxt[63] = code_in_reg;
	end
	else if(in_valid_2_reg && !crypt_mode_reg) begin
		case (rotor_A_out[1:0])
			2'b00: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx];
				end
			end
			2'b01: begin
				rotor_A_nxt[0] = rotor_A[63];
				for(idx=1; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-1];
				end
			end
			2'b10: begin
				rotor_A_nxt[0] = rotor_A[62];
				rotor_A_nxt[1] = rotor_A[63];
				for(idx=2; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-2];
				end
			end
			2'b11: begin
				rotor_A_nxt[0] = rotor_A[61];
				rotor_A_nxt[1] = rotor_A[62];
				rotor_A_nxt[2] = rotor_A[63];
				for(idx=3; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-3];
				end
			end
			default: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx];
				end
			end
		endcase
	end
	else if(in_valid_2_reg && crypt_mode_reg) begin
		case (rotor_B_inv[1:0])
			2'b00: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx];
				end
			end
			2'b01: begin
				rotor_A_nxt[0] = rotor_A[63];
				for(idx=1; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-1];
				end
			end
			2'b10: begin
				rotor_A_nxt[0] = rotor_A[62];
				rotor_A_nxt[1] = rotor_A[63];
				for(idx=2; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-2];
				end
			end
			2'b11: begin
				rotor_A_nxt[0] = rotor_A[61];
				rotor_A_nxt[1] = rotor_A[62];
				rotor_A_nxt[2] = rotor_A[63];
				for(idx=3; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx-3];
				end
			end
			default: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_A_nxt[idx] = rotor_A[idx];
				end
			end
		endcase
	end
	else begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_A_nxt[idx] = rotor_A[idx];
		end
	end
end

// ff of rotor_B
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_B[idx] <= 0;
		end
	end
	else begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_B[idx] <= rotor_B_nxt[idx];
		end
	end
end

// comb of rotor_B
always @(*) begin
	if (in_valid_reg & (!flag_A)) begin
		for(idx=0; idx<63; idx=idx+1) begin
			rotor_B_nxt[idx] = rotor_B[idx+1];
		end
		rotor_B_nxt[63] = code_in_reg;
	end
	else if(in_valid_2_reg && !crypt_mode_reg) begin
		case (rotor_B_out[2:0])
			3'b000: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_B_nxt[idx] = rotor_B[idx];
				end
			end 
			3'b001: begin
				for(idx=0; idx<32; idx=idx+1) begin
					rotor_B_nxt[2*idx+0] = rotor_B[2*idx+1];
					rotor_B_nxt[2*idx+1] = rotor_B[2*idx+0];
				end
			end
			3'b010: begin
				for(idx=0; idx<16; idx=idx+1) begin
					rotor_B_nxt[4*idx+0] = rotor_B[4*idx+2];
					rotor_B_nxt[4*idx+1] = rotor_B[4*idx+3];
					rotor_B_nxt[4*idx+2] = rotor_B[4*idx+0];
					rotor_B_nxt[4*idx+3] = rotor_B[4*idx+1];
				end
			end
			3'b011: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+7];
				end
			end
			3'b100: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+3];
				end
			end
			3'b101: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+2];
				end
			end
			3'b110: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+1];
				end
			end
			3'b111: begin
				for(idx=0; idx<8 ; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+0];
				end
			end
			default: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_B_nxt[idx] = rotor_B[idx];
				end
			end
		endcase
	end
	else if(in_valid_2_reg && crypt_mode_reg) begin
		case (reflector_out[2:0])
			3'b000: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_B_nxt[idx] = rotor_B[idx];
				end
			end 
			3'b001: begin
				for(idx=0; idx<32; idx=idx+1) begin
					rotor_B_nxt[2*idx+0] = rotor_B[2*idx+1];
					rotor_B_nxt[2*idx+1] = rotor_B[2*idx+0];
				end
			end
			3'b010: begin
				for(idx=0; idx<16; idx=idx+1) begin
					rotor_B_nxt[4*idx+0] = rotor_B[4*idx+2];
					rotor_B_nxt[4*idx+1] = rotor_B[4*idx+3];
					rotor_B_nxt[4*idx+2] = rotor_B[4*idx+0];
					rotor_B_nxt[4*idx+3] = rotor_B[4*idx+1];
				end
			end
			3'b011: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+7];
				end
			end
			3'b100: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+3];
				end
			end
			3'b101: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+2];
				end
			end
			3'b110: begin
				for(idx=0; idx<8; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+0];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+1];
				end
			end
			3'b111: begin
				for(idx=0; idx<8 ; idx=idx+1) begin
					rotor_B_nxt[8*idx+0] = rotor_B[8*idx+7];
					rotor_B_nxt[8*idx+1] = rotor_B[8*idx+6];
					rotor_B_nxt[8*idx+2] = rotor_B[8*idx+5];
					rotor_B_nxt[8*idx+3] = rotor_B[8*idx+4];
					rotor_B_nxt[8*idx+4] = rotor_B[8*idx+3];
					rotor_B_nxt[8*idx+5] = rotor_B[8*idx+2];
					rotor_B_nxt[8*idx+6] = rotor_B[8*idx+1];
					rotor_B_nxt[8*idx+7] = rotor_B[8*idx+0];
				end
			end
			default: begin
				for(idx=0; idx<64; idx=idx+1) begin
					rotor_B_nxt[idx] = rotor_B[idx];
				end
			end
		endcase
	end
	else begin
		for(idx=0; idx<64; idx=idx+1) begin
			rotor_B_nxt[idx] = rotor_B[idx];
		end
	end
end

// rotor_A_out
always @(*) begin
	if(in_valid_2_reg) begin
		case (code_in_reg)
			8'h00: rotor_A_out = rotor_A[0];
			8'h01: rotor_A_out = rotor_A[1];
			8'h02: rotor_A_out = rotor_A[2];
			8'h03: rotor_A_out = rotor_A[3];
			8'h04: rotor_A_out = rotor_A[4];
			8'h05: rotor_A_out = rotor_A[5];
			8'h06: rotor_A_out = rotor_A[6];
			8'h07: rotor_A_out = rotor_A[7];
			8'h08: rotor_A_out = rotor_A[8];
			8'h09: rotor_A_out = rotor_A[9];
			8'h0a: rotor_A_out = rotor_A[10];
			8'h0b: rotor_A_out = rotor_A[11];
			8'h0c: rotor_A_out = rotor_A[12];
			8'h0d: rotor_A_out = rotor_A[13];
			8'h0e: rotor_A_out = rotor_A[14];
			8'h0f: rotor_A_out = rotor_A[15];
			8'h10: rotor_A_out = rotor_A[16];
			8'h11: rotor_A_out = rotor_A[17];
			8'h12: rotor_A_out = rotor_A[18];
			8'h13: rotor_A_out = rotor_A[19];
			8'h14: rotor_A_out = rotor_A[20];
			8'h15: rotor_A_out = rotor_A[21];
			8'h16: rotor_A_out = rotor_A[22];
			8'h17: rotor_A_out = rotor_A[23];
			8'h18: rotor_A_out = rotor_A[24];
			8'h19: rotor_A_out = rotor_A[25];
			8'h1a: rotor_A_out = rotor_A[26];
			8'h1b: rotor_A_out = rotor_A[27];
			8'h1c: rotor_A_out = rotor_A[28];
			8'h1d: rotor_A_out = rotor_A[29];
			8'h1e: rotor_A_out = rotor_A[30];
			8'h1f: rotor_A_out = rotor_A[31];
			8'h20: rotor_A_out = rotor_A[32];
			8'h21: rotor_A_out = rotor_A[33];
			8'h22: rotor_A_out = rotor_A[34];
			8'h23: rotor_A_out = rotor_A[35];
			8'h24: rotor_A_out = rotor_A[36];
			8'h25: rotor_A_out = rotor_A[37];
			8'h26: rotor_A_out = rotor_A[38];
			8'h27: rotor_A_out = rotor_A[39];
			8'h28: rotor_A_out = rotor_A[40];
			8'h29: rotor_A_out = rotor_A[41];
			8'h2a: rotor_A_out = rotor_A[42];
			8'h2b: rotor_A_out = rotor_A[43];
			8'h2c: rotor_A_out = rotor_A[44];
			8'h2d: rotor_A_out = rotor_A[45];
			8'h2e: rotor_A_out = rotor_A[46];
			8'h2f: rotor_A_out = rotor_A[47];
			8'h30: rotor_A_out = rotor_A[48];
			8'h31: rotor_A_out = rotor_A[49];
			8'h32: rotor_A_out = rotor_A[50];
			8'h33: rotor_A_out = rotor_A[51];
			8'h34: rotor_A_out = rotor_A[52];
			8'h35: rotor_A_out = rotor_A[53];
			8'h36: rotor_A_out = rotor_A[54];
			8'h37: rotor_A_out = rotor_A[55];
			8'h38: rotor_A_out = rotor_A[56];
			8'h39: rotor_A_out = rotor_A[57];
			8'h3a: rotor_A_out = rotor_A[58];
			8'h3b: rotor_A_out = rotor_A[59];
			8'h3c: rotor_A_out = rotor_A[60];
			8'h3d: rotor_A_out = rotor_A[61];
			8'h3e: rotor_A_out = rotor_A[62];
			8'h3f: rotor_A_out = rotor_A[63];
			default: rotor_A_out = 0;
		endcase
	end
	else begin
		rotor_A_out = 0;
	end
end

// rotor_B_out
always @(*) begin
	if(in_valid_2_reg) begin
		case (rotor_A_out)
			8'h00: rotor_B_out = rotor_B[0];
			8'h01: rotor_B_out = rotor_B[1];
			8'h02: rotor_B_out = rotor_B[2];
			8'h03: rotor_B_out = rotor_B[3];
			8'h04: rotor_B_out = rotor_B[4];
			8'h05: rotor_B_out = rotor_B[5];
			8'h06: rotor_B_out = rotor_B[6];
			8'h07: rotor_B_out = rotor_B[7];
			8'h08: rotor_B_out = rotor_B[8];
			8'h09: rotor_B_out = rotor_B[9];
			8'h0a: rotor_B_out = rotor_B[10];
			8'h0b: rotor_B_out = rotor_B[11];
			8'h0c: rotor_B_out = rotor_B[12];
			8'h0d: rotor_B_out = rotor_B[13];
			8'h0e: rotor_B_out = rotor_B[14];
			8'h0f: rotor_B_out = rotor_B[15];
			8'h10: rotor_B_out = rotor_B[16];
			8'h11: rotor_B_out = rotor_B[17];
			8'h12: rotor_B_out = rotor_B[18];
			8'h13: rotor_B_out = rotor_B[19];
			8'h14: rotor_B_out = rotor_B[20];
			8'h15: rotor_B_out = rotor_B[21];
			8'h16: rotor_B_out = rotor_B[22];
			8'h17: rotor_B_out = rotor_B[23];
			8'h18: rotor_B_out = rotor_B[24];
			8'h19: rotor_B_out = rotor_B[25];
			8'h1a: rotor_B_out = rotor_B[26];
			8'h1b: rotor_B_out = rotor_B[27];
			8'h1c: rotor_B_out = rotor_B[28];
			8'h1d: rotor_B_out = rotor_B[29];
			8'h1e: rotor_B_out = rotor_B[30];
			8'h1f: rotor_B_out = rotor_B[31];
			8'h20: rotor_B_out = rotor_B[32];
			8'h21: rotor_B_out = rotor_B[33];
			8'h22: rotor_B_out = rotor_B[34];
			8'h23: rotor_B_out = rotor_B[35];
			8'h24: rotor_B_out = rotor_B[36];
			8'h25: rotor_B_out = rotor_B[37];
			8'h26: rotor_B_out = rotor_B[38];
			8'h27: rotor_B_out = rotor_B[39];
			8'h28: rotor_B_out = rotor_B[40];
			8'h29: rotor_B_out = rotor_B[41];
			8'h2a: rotor_B_out = rotor_B[42];
			8'h2b: rotor_B_out = rotor_B[43];
			8'h2c: rotor_B_out = rotor_B[44];
			8'h2d: rotor_B_out = rotor_B[45];
			8'h2e: rotor_B_out = rotor_B[46];
			8'h2f: rotor_B_out = rotor_B[47];
			8'h30: rotor_B_out = rotor_B[48];
			8'h31: rotor_B_out = rotor_B[49];
			8'h32: rotor_B_out = rotor_B[50];
			8'h33: rotor_B_out = rotor_B[51];
			8'h34: rotor_B_out = rotor_B[52];
			8'h35: rotor_B_out = rotor_B[53];
			8'h36: rotor_B_out = rotor_B[54];
			8'h37: rotor_B_out = rotor_B[55];
			8'h38: rotor_B_out = rotor_B[56];
			8'h39: rotor_B_out = rotor_B[57];
			8'h3a: rotor_B_out = rotor_B[58];
			8'h3b: rotor_B_out = rotor_B[59];
			8'h3c: rotor_B_out = rotor_B[60];
			8'h3d: rotor_B_out = rotor_B[61];
			8'h3e: rotor_B_out = rotor_B[62];
			8'h3f: rotor_B_out = rotor_B[63];
			default: rotor_B_out = 0;
		endcase
	end
	else begin
		rotor_B_out = 0;
	end
end

// reflector_out
assign reflector_out = ~rotor_B_out;

// rotor_B_inv
always @(*) begin
	rotor_B_inv = 0;
	for(idx=0; idx<64; idx=idx+1) begin
		if(in_valid_2_reg && rotor_B[idx] == reflector_out) begin
			rotor_B_inv = idx;
		end
	end
end

// rotor_A_inv
always @(*) begin
	rotor_A_inv = 0;
	for(idx=0; idx<64; idx=idx+1) begin
		if(in_valid_2_reg && rotor_A[idx] == rotor_B_inv) begin
			rotor_A_inv = idx;
		end
	end
end

// ff of output
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

// comb of output
always @(*) begin
	if(in_valid_2_reg) begin
		out_valid_nxt = 1;
		out_code_nxt = rotor_A_inv;
	end
	else begin
		out_valid_nxt = 0;
		out_code_nxt = 0;
	end
end

endmodule