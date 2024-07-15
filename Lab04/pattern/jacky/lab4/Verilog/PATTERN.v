//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab04 Exercise		: Convolutional Neural Network (CNN) - Pattern
//   Author     		: Jacky (jackyyeh1999@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2024-03-22)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      50.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 10000

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	  Weight,
    Opt,
    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
output reg         clk, rst_n, in_valid;
output reg [31:0]  Img;
output reg [31:0]  Kernel;
output reg [31:0]  Weight;
output reg [ 1:0]  Opt;
input              out_valid;
input      [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

real CYCLE = `CYCLE_TIME;
integer pat_read, ans_read, file;
integer PAT_NUM;
integer total_latency, latency;
integer out_val_clk_times;
integer i_pat;
integer out_cnt;
real out_fp, ans_fp, dif;

//================================================================
// wire & registers
//================================================================
reg [31:0] img_data [0:47]; // 48
reg [31:0] ker_data [0:26]; // 27
reg [31:0] wgt_data [0:3];  // 4
reg [31:0] ans[0:3]; // 4
reg [1:0]  opt_data;

//================================================================
// clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial begin
  pat_read = $fopen("../00_TESTBED/input.txt", "r");
  ans_read = $fopen("../00_TESTBED/output.txt", "r");
  reset_signal_task;

  i_pat = 0;
  total_latency = 0;
  file = $fscanf(pat_read, "%d", PAT_NUM);
  for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
    input_task;
    wait_out_valid_task;
    check_ans_task;
    total_latency = total_latency + latency;
  end
  $fclose(pat_read);

  YOU_PASS_task;
end

initial begin
  while(1) begin
    if((out_valid === 0) && (out !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be reset when out_valid is low.                *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    if((in_valid === 1) && (out_valid === 1))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_valid cannot overlap with in_valid.                        *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end

//================================================================
// task
//================================================================
task reset_signal_task;
begin
  rst_n    = 1;
  force clk= 0;
  #(0.5 * CYCLE);
  rst_n    = 0;
  in_valid = 0;
  Img      = 'bx;
  Kernel   = 'bx;
  Weight   = 'bx;
  Opt      = 'bx;
  #(10 * CYCLE);
  if( (out_valid !== 0) || (out !== 0) )
  begin
    $display("***********************************************************************");
    $display("*  Error                                                              *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    // DO NOT PUT @(negedge clk) HERE
    $finish;
  end
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;
end
endtask

task input_task;
begin
  // Read 4 Golden answers
  for(integer i = 0; i < 4; i=i+1) file = $fscanf(ans_read, "%h", ans[i]);
  // Read input(in) and answer(ans) here (two statement)
  file = $fscanf(pat_read, "%d", opt_data);
  for(integer i = 0; i < 48; i=i+1) file = $fscanf(pat_read, "%h", img_data[i]);
  for(integer i = 0; i < 27; i=i+1) file = $fscanf(pat_read, "%h", ker_data[i]);
  for(integer i = 0; i < 4; i=i+1)  file = $fscanf(pat_read, "%h", wgt_data[i]);
  // Set pattern signal
  if(i_pat=='d1) repeat(2)@(negedge clk);
  in_valid = 1'b1;
  for(integer i = 0; i < 48; i=i+1) begin
    //$write("\033[0;34mI.%4d BEEGIN\033[m",i);
    // Opt
    if(i < 1) Opt = opt_data;
    else      Opt = 'bx;
    // Img
    Img  = img_data[i];
    // Kernel
    if(i < 27) Kernel = ker_data[i];
    else       Kernel = 'bx;
    // Weight
    if(i < 4)  Weight = wgt_data[i];
    else       Weight = 'bx;
    @(negedge clk);
  end

  // Disable input
  Img      = 'bx;
  in_valid = 'b0;
end
endtask

task wait_out_valid_task;
begin
  latency = -1;
  while(out_valid !== 1) begin
    latency = latency + 1;
    if(latency >= 1000)
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The execution latency are over  1,000 cycles.                      *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
  total_latency = total_latency + latency;
end
endtask

task check_ans_task;
begin
  for(integer i = 0; i < 4; i=i+1)
  begin
    if(out_valid!==1)
    begin
      $display("*****************************************************************************");
      $display("*  Error:                                                                   *");
      $display("*  out_valid and out_data must be asserted for only 4 cycles.              *");
      $display("*****************************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end

    out_fp = $bitstoshortreal(out);
    ans_fp = $bitstoshortreal(ans[i]);
    dif    = $abs(out_fp - ans_fp) / ans_fp;
    if(dif >= 0.002)
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be correct when out_valid is high              *");
      $display("*  Your        : %08h %22.16f                      *", out, out_fp);
      $display("*  Gloden      : %08h %22.16f                      *", ans[i], ans_fp);
      $display("*  Difference  :            %12.8f                              *", dif);
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end

    @(negedge clk);
  end

  @(negedge clk);
  if((out_valid===1))
  begin
      $display("*****************************************************************************");
      $display("*  Error:                                                                   *");
      $display("*  out_valid and out_data must be asserted for only 4 cycles.              *");
      $display("*****************************************************************************");
      repeat(2)@(negedge clk);
      $finish;
  end

  $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m \033[0;33mDiff : %12.8f\033[m",i_pat , latency, dif);
  repeat(3)@(negedge clk);
end
endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask


endmodule
