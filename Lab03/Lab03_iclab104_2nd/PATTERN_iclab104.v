`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
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

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [13:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data; 

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

integer pat_read;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat;

initial clk = 0;
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

// My Declaration
integer dir, dram_addr, sd_addr;
integer a, idx;
integer cnt_out;
reg [7:0] golden [7:0];

parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
parameter SD_p_r = "../00_TESTBED/SD_init.dat";
reg [63:0] golden_DRAM[0:8191];
reg [63:0] golden_SD [0:65535];

//////////////////////////////////////////////////////////////////////
// Main function
//////////////////////////////////////////////////////////////////////
initial begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r"); 

    reset_signal_task;
    load_golden_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM); 
    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        calculate;

        wait_out_valid_task;

        check_ans_task;
        check_spec_2;

        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end
    $fclose(pat_read);
    YOU_PASS_task;

    $finish;
    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM); //Write down your DRAM Final State
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);		 //Write down your SD CARD Final State
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
task reset_signal_task; begin
    rst_n = 'b1;
    in_valid = 'b0;
 
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;

    cnt_out = 0;
    for(a=0; a<8; a++) begin
        golden[a] = 0;
    end

    force clk = 0;
    #CYCLE; rst_n = 'b0; 
    #(100); check_spec_1;

    #(CYCLE*2); rst_n = 'b1;    
    #CYCLE; release clk;
end endtask

task load_golden_task; begin
    $readmemh(DRAM_p_r, golden_DRAM);
    $readmemh(SD_p_r, golden_SD);
end endtask;

task input_task; begin
    // Read input.txt
    a = $fscanf(pat_read, "%d", dir);
    a = $fscanf(pat_read, "%d", dram_addr);
    a = $fscanf(pat_read, "%d", sd_addr);

    // Random delay for 2 ~ 5 cycle
    repeat({$random()} % 3 + 2) @(negedge clk);

    //Raise input_valid
    in_valid = 1'b1;

    // Input 1 cycle
    direction = dir;
    addr_dram = dram_addr;
    addr_sd = sd_addr;
    @(negedge clk);

    in_valid = 1'b0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd = 'bx;
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
        check_spec_2;
        check_spec_3;
        latency++;
        @(negedge clk);
    end
    check_spec_6;
end endtask;

task calculate; begin
    if(dir == 1) begin
        //$display("Golden:");
        //$display("DRAM is written with %d in %d", golden_SD[sd_addr], dram_addr);
        golden_DRAM[dram_addr] = golden_SD[sd_addr];
    end
    if(dir == 0) begin
        //$display("Golden:");
        //$display("SD is written with %d from %d of DRAM", golden_DRAM[dram_addr], dram_addr);
        golden_SD[sd_addr] = golden_DRAM[dram_addr];
    end
    golden[0] = golden_DRAM[dram_addr][63:56];
    golden[1] = golden_DRAM[dram_addr][55:48];
    golden[2] = golden_DRAM[dram_addr][47:40];
    golden[3] = golden_DRAM[dram_addr][39:32];
    golden[4] = golden_DRAM[dram_addr][31:24];
    golden[5] = golden_DRAM[dram_addr][23:16];
    golden[6] = golden_DRAM[dram_addr][15: 8];
    golden[7] = golden_DRAM[dram_addr][ 7: 0];
end endtask;

task check_ans_task; begin
    cnt_out = 0;
    while(out_valid === 1'b1) begin
        check_spec_4_2;
        check_spec_5;
        cnt_out++;
        @(negedge clk);
    end
    check_spec_4_1;
end endtask;

//////////////////////////////////////////////////////////////////////
// Check spec task
//////////////////////////////////////////////////////////////////////
task check_spec_1; begin
    if (out_valid !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-1 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (out_data !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-2 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (AW_ADDR !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-3 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (AW_VALID !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-4 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (W_VALID !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-5 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (W_DATA !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-6 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (B_READY !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-7 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (AR_ADDR !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-8 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (AR_VALID !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-9 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (R_READY !== 0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-10 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if (MOSI !== 1) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-1-11 FAIL");
        $display("*                            SPEC MAIN-1 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_2; begin
    if (out_data !== 'b0) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-2 FAIL");
        $display("*                            SPEC MAIN-2 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_3; begin
    if(latency == 10000) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-3 FAIL");
        $display("*                            SPEC MAIN-3 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_4_1; begin
    if(cnt_out != 8) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-4-1 FAIL");
        $display("*                            SPEC MAIN-4 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_4_2; begin
    if(cnt_out == 8) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-4-2 FAIL");
        $display("*                            SPEC MAIN-4 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_5; begin
    if(out_data !== golden[cnt_out]) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-5 FAIL");
        $display("*                            SPEC MAIN-5 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
end endtask;

task check_spec_6; begin
    // Check all
    for(idx=0; idx<8192; idx=idx+1) begin
        if(u_DRAM.DRAM[idx] !== golden_DRAM[idx]) begin
            YOU_FAIL_task;
            //$display("SPEC MAIN-6 FAIL");
            $display("*                            SPEC MAIN-6 FAIL                           *");
            $display("*************************************************************************");
            repeat(2) #CYCLE;
            $finish;
        end
    end
    for(idx=0; idx<65536; idx=idx+1) begin
        if(u_SD.SD[idx] !== golden_SD[idx]) begin
            YOU_FAIL_task;
            //$display("SPEC MAIN-6 FAIL");
            $display("*                            SPEC MAIN-6 FAIL                           *");
            $display("*************************************************************************");
            repeat(2) #CYCLE;
            $finish;
        end
    end
    // Simple check
    /*if(u_DRAM.DRAM[dram_addr] !== golden_DRAM[dram_addr]) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-6 FAIL");
        $display("*                            SPEC MAIN-6 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
    if(u_SD.SD[sd_addr] !== golden_SD[sd_addr]) begin
        YOU_FAIL_task;
        //$display("SPEC MAIN-6 FAIL");
        $display("*                            SPEC MAIN-6 FAIL                           *");
        $display("*************************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end*/
end endtask;

//////////////////////////////////////////////////////////////////////


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*************************************************************************");
    $display("*                                 FAIL!                                 *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    // write address channel
    .AW_ADDR(AW_ADDR),
    .AW_VALID(AW_VALID),
    .AW_READY(AW_READY),
    // write data channel
    .W_VALID(W_VALID),
    .W_DATA(W_DATA),
    .W_READY(W_READY),
    // write response channel
    .B_VALID(B_VALID),
    .B_RESP(B_RESP),
    .B_READY(B_READY),
    // read address channel
    .AR_ADDR(AR_ADDR),
    .AR_VALID(AR_VALID),
    .AR_READY(AR_READY),
    // read data channel
    .R_DATA(R_DATA),
    .R_VALID(R_VALID),
    .R_RESP(R_RESP),
    .R_READY(R_READY)
);

pseudo_SD u_SD (
    .clk(clk),
    .MOSI(MOSI),
    .MISO(MISO)
);

endmodule