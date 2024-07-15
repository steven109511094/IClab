//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
    `define CYCLE_TIME 40.0
`endif

module pseudo_DRAM(
	clk, rst_n,
	AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
);

input clk, rst_n;
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output reg AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output reg W_READY;
// write response channel
output reg B_VALID;
output reg [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output reg AR_READY;
// read data channel
output reg [63:0] R_DATA;
output reg R_VALID;
output reg [1:0] R_RESP;
input R_READY;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
real CYCLE = `CYCLE_TIME;
integer latency_r, latency_w, latency_b;
reg [31:0] addr;
reg [63:0] data;

reg [31:0] AR_ADDR_reg;
reg AR_VALID_reg;
reg [31:0] AW_ADDR_reg;
reg AW_VALID_reg;
reg R_READY_reg;
reg [63:0] W_DATA_reg;
reg W_VALID_reg;

//================================================================
// wire & registers 
//================================================================
reg [63:0] DRAM[0:8191];
initial begin
	$readmemh(DRAM_p_r, DRAM);
	reset_signal_task;
end

//================================================================
// Reset signal
//================================================================
task reset_signal_task; begin
	wait(~rst_n);
	AW_READY = 0;
	W_READY = 0;
	B_VALID = 0;
	B_RESP = 0;
	AR_READY = 0;
	R_DATA = 0;
	R_VALID = 0;
	R_RESP = 0;

	AR_VALID_reg = 0;
	AR_ADDR_reg = 0;
	AW_VALID_reg = 0;
	AW_ADDR_reg = 0;
	R_READY_reg = 0;
	W_VALID_reg = 0;
	W_DATA_reg = 0;
end endtask

//================================================================
// SD -> DRAM
//================================================================
always @(*) begin
	if(AW_VALID) @(negedge clk) begin
		repeat({$random()} % 49 + 2) @(posedge clk);
		AW_READY = 1;
		@(posedge clk);
		AW_READY = 0;
	end
end

always @(*) begin
	if(AW_READY) @(negedge clk) begin
		addr = AW_ADDR;
		repeat({$random()} % 99 + 2) @(posedge clk);
		W_READY = 1;
	end
end

always @(*) begin
	if(W_VALID && W_READY) @(negedge clk) begin
		data = W_DATA;
		@(posedge clk);
		W_READY = 0;
	end
end

always @(*) begin
	if(W_VALID && W_READY) @(negedge clk) begin
		repeat({$random()} % 99 + 2) @(posedge clk);
		B_VALID = 1;
		@(posedge clk);
		B_VALID = 0;
	end
end

always @(*) begin
	if(B_READY && B_VALID) begin
		//$display("Real:");
		//$display("DRAM is written with %d in %d", data, addr);
		DRAM[addr] = data;
	end
end

//================================================================
// DRAM -> SD
//================================================================
always @(*) begin
	if(AR_VALID) @(negedge clk) begin
		repeat({$random()} % 49 + 2) @(posedge clk);
		AR_READY = 1;
		@(posedge clk);
		AR_READY = 0;
	end
end

always @(*) begin
	if(AR_READY) @(negedge clk) begin
		addr = AR_ADDR;
		repeat({$random()} % 99 + 2) @(posedge clk);
		wait(R_READY);
		R_VALID = 1;
		@(posedge clk);
		R_VALID = 0;
	end
end

always @(*) begin
	if(R_VALID) @(negedge clk) begin
		R_DATA = DRAM[addr];
		//$display("Real:");
		//$display("SD is written with %d from %d of DRAM", R_DATA, addr);
	end
	else begin
		R_DATA = 0;
	end
end

//================================================================
// Check spec
//================================================================

// Check spec 1
always @(negedge clk) begin
	if((AR_VALID === 0) && (AR_ADDR !== 0)) begin
        YOU_FAIL_task;
        //$display("SPEC DRAM-1-1 FAIL");
		$display("*                            SPEC DRAM-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
	if((AW_VALID === 0) && (AW_ADDR !== 0)) begin
		YOU_FAIL_task;
        //$display("SPEC DRAM-1-2 FAIL");
		$display("*                            SPEC DRAM-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
	end
	if((W_VALID === 0) && (W_DATA !== 0) && (W_DATA !== 'bx)) begin
		YOU_FAIL_task;
        //$display("SPEC DRAM-1-3 FAIL");
		$display("*                            SPEC DRAM-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
	end
end

// Check spec 2
always @(*) begin
	if((AR_ADDR < 0) || (AR_ADDR > 8191)) begin
        YOU_FAIL_task;
        //$display("SPEC DRAM-2-1 FAIL");
		$display("*                            SPEC DRAM-2 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
	if((AW_ADDR < 0) || (AW_ADDR > 8191)) begin
        YOU_FAIL_task;
        //$display("SPEC DRAM-2-2 FAIL");
		$display("*                            SPEC DRAM-2 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end

// Check spec 3
always @(*) begin
	@(negedge clk);
	if((AR_READY !== 1) && (AR_VALID === 1)) begin
		AR_ADDR_reg = AR_ADDR;
		AR_VALID_reg = AR_VALID;
		while(AR_READY !== 1) @(negedge clk) begin
			if((AR_ADDR_reg !== AR_ADDR) || (AR_VALID_reg !== AR_VALID)) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-3-1 FAIL");
				$display("*                            SPEC DRAM-3 FAIL                           *");
				$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
		end
	end
end


always @(*) begin
	@(negedge clk);
	if((AW_READY !== 1) && (AW_VALID === 1)) begin
		AW_ADDR_reg = AW_ADDR;
		AW_VALID_reg = AW_VALID;
		while(AW_READY !== 1) @(negedge clk) begin
			if((AW_ADDR_reg !== AW_ADDR) || (AW_VALID_reg !== AW_VALID)) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-3-2 FAIL");
				$display("*                            SPEC DRAM-3 FAIL                           *");
				$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
		end
	end
end

always @(*) begin
	@(negedge clk);
	if((R_VALID !== 1) && (R_READY === 1)) begin
		R_READY_reg = R_READY;
		while(R_VALID !== 1) @(negedge clk) begin
			if(R_READY_reg !== R_READY) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-3-3 FAIL");
				$display("*                            SPEC DRAM-3 FAIL                           *");
				$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
		end
	end
end

always @(*) begin
	@(negedge clk);
	if((W_READY !== 1) && (W_VALID === 1)) begin
		W_DATA_reg = W_DATA;
		W_VALID_reg = W_VALID;
		while(W_READY !== 1) @(negedge clk) begin
			if((W_DATA_reg !== W_DATA) || (W_VALID_reg !== W_VALID)) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-3-4 FAIL");
				$display("*                            SPEC DRAM-3 FAIL                           *");
				$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
		end
	end
end

// Check spec 4
always @(*) begin
	if(AR_READY === 'b1) begin
		@(negedge clk);
		latency_r = 0;
		while(R_READY !== 'b1) begin
			if(latency_r == 100) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-4-1 FAIL");
				$display("*                            SPEC DRAM-4 FAIL                           *");
        		$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
			latency_r++;
			@(negedge clk);
		end
	end
	if(AW_READY === 'b1) begin
		@(negedge clk);
		latency_w = 0;
		while(W_VALID !== 'b1) begin
			if(latency_w == 100) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-4-2 FAIL");
				$display("*                            SPEC DRAM-4 FAIL                           *");
        		$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
			latency_w++;
			@(negedge clk);
		end
	end
	if(B_VALID === 'b1) begin
		@(negedge clk);
		latency_b = 0;
		while(B_READY !== 'b1) begin
			if(latency_b == 100) begin
				YOU_FAIL_task;
				//$display("SPEC DRAM-4-3 FAIL");
				$display("*                            SPEC DRAM-4 FAIL                           *");
        		$display("*************************************************************************");
				repeat(2) #CYCLE;
				$finish;
			end
			latency_b++;
			@(negedge clk);
		end
	end
end

// Check spec 5
always @(*) begin
	if(((AR_READY === 'b1) || (AR_VALID === 'b1)) && (R_READY === 'b1)) begin
		YOU_FAIL_task;
        //$display("SPEC DRAM-5-1 FAIL");
		$display("*                            SPEC DRAM-5 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
	end
	if(((AW_READY === 'b1) || (AW_VALID === 'b1)) && (W_VALID === 'b1)) begin
		YOU_FAIL_task;
        //$display("SPEC DRAM-5-2 FAIL");
		$display("*                            SPEC DRAM-5 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
	end
end

//////////////////////////////////////////////////////////////////////

task YOU_FAIL_task; begin
    $display("*************************************************************************");
    $display("*                                 FAIL!                                 *");
    $display("*                    Error message from pseudo_DRAM.v                   *");
end endtask

endmodule
