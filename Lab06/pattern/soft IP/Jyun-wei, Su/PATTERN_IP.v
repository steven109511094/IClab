//############################################################################
//   2023 ICLAB Fall Course
//   Lab06       : PATTER_IP
//   Author      : Jyun-wei, Su
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN_IP.v
//   Module Name : PATTERN_IP
//   Release version : 1.0 (Release Date: 2023/10/26)
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif
`define SEED       42
`define PAT_NUM    10000

module PATTERN #(parameter IP_WIDTH = 2)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

//================================================================
// parameters & integer
//================================================================
integer patcount;

//================================================================
// wire & registers
//================================================================
reg [3:0] character[0:IP_WIDTH - 1];
reg [3:0] tmp_character;
reg [4:0] weight[0:IP_WIDTH - 1];
reg [4:0] tmp_weight;
reg [IP_WIDTH*4-1:0] golden_ans;
reg [5:0] msb, lsb;

//================================================================
// clock
//================================================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// initial
//================================================================
initial begin
  reset_signal_task;
  repeat(5) @(negedge clk);

  for(patcount = 0; patcount < `PAT_NUM; patcount = patcount + 1) begin
      gen_pattern;
      input_task;
      gen_answer;
      repeat(1) @(negedge clk);
      check_ans;
      //repeat($urandom_range(3, 5)) @(negedge clk);
  end

  YOU_PASS_task;
end

//================================================================
// task
//================================================================
task reset_signal_task;
begin
  IN_character = 'bx;
  IN_weight = 'bx;
end
endtask

// gen pattern
task gen_pattern; begin
  for(integer i = 0; i < IP_WIDTH; i = i + 1) begin
      character[i] = IP_WIDTH - i - 1;
      weight[i] = $urandom_range(0, 31);
  end
end endtask

// gen answer
task gen_answer; begin
  // bouble sort
  for(integer i = 0; i < IP_WIDTH; i = i + 1) begin
    for(integer j = 0; j < IP_WIDTH - 1; j = j + 1) begin
      if(weight[j + 1] > weight[j]) begin
        tmp_weight = weight[j + 1];
        weight[j + 1] = weight[j];
        weight[j] = tmp_weight;
        tmp_character = character[j + 1];
        character[j + 1] = character[j];
        character[j] = tmp_character;
      end
    end
  end
  case(IP_WIDTH)
  1: golden_ans = {character[0]};
  2: golden_ans = {character[0], character[1]};
  3: golden_ans = {character[0], character[1], character[2]};
  4: golden_ans = {character[0], character[1], character[2], character[3]};
  5: golden_ans = {character[0], character[1], character[2], character[3], character[4]};
  6: golden_ans = {character[0], character[1], character[2], character[3], character[4], character[5]};
  7: golden_ans = {character[0], character[1], character[2], character[3], character[4], character[5], character[6]};
  8: golden_ans = {character[0], character[1], character[2], character[3], character[4], character[5], character[6], character[7]};
  endcase
end endtask

// input task
task input_task; begin
  case(IP_WIDTH)
  1: begin
    IN_character = {character[0]};
    IN_weight = {weight[0]};
  end
  2: begin
    IN_character = {character[0], character[1]};
    IN_weight = {weight[0], weight[1]};
  end
  3: begin
    IN_character = {character[0], character[1], character[2]};
    IN_weight = {weight[0], weight[1], weight[2]};
  end
  4: begin
    IN_character = {character[0], character[1], character[2], character[3]};
    IN_weight = {weight[0], weight[1], weight[2], weight[3]};
  end
  5: begin
    IN_character = {character[0], character[1], character[2], character[3], character[4]};
    IN_weight = {weight[0], weight[1], weight[2], weight[3], weight[4]};
  end
  6: begin
    IN_character = {character[0], character[1], character[2], character[3], character[4], character[5]};
    IN_weight = {weight[0], weight[1], weight[2], weight[3], weight[4], weight[5]};
  end
  7: begin
    IN_character = {character[0], character[1], character[2], character[3], character[4], character[5], character[6]};
    IN_weight = {weight[0], weight[1], weight[2], weight[3], weight[4], weight[5], weight[6]};
  end
  8: begin
    IN_character = {character[0], character[1], character[2], character[3], character[4], character[5], character[6], character[7]};
    IN_weight = {weight[0], weight[1], weight[2], weight[3], weight[4], weight[5], weight[6], weight[7]};
  end

  endcase
end endtask

// check answer
task check_ans; begin
  if(OUT_character !== golden_ans) begin
    $display("***********************************************************************");
    $display("*  Error                                                              *");
    $display("*  The OUT_character should be correct                                *");
    $display("*  IP_WIDTH : %1d                                                       *", IP_WIDTH);
    $display("*  Pattern  : %1d                                                       *", patcount);
    $display("*  Your     : %8h                                                *", OUT_character);
    $display("*  Gloden   : %8h                                                *", golden_ans);
    $display("***********************************************************************");
    repeat(2)@(negedge clk);
    $finish;
  end

  $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32IP_WIDTH: %d\033[m", patcount, IP_WIDTH);
end endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask

endmodule