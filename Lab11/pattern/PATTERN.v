//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2024 ICLAB Spring Course
//   Lab11      : SNN
//   Author     : ZONG-RUI CAO
//   File       : PATTERN.v (w/ CG, cg_en = 0)
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   DESCRIPTION: 2024 Spring IC Lab / Exercise Lab11 / SNN
//   Release version : v1.0 (Release Date: May-2024)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define CYCLE_TIME    15
`define CG_EN          0

module PATTERN(
    // Output signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    img,
    ker,
    weight,

    // Input signals
    out_valid,
    out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [7:0] img;
output reg [7:0] ker;
output reg [7:0] weight;

input out_valid;
input  [9:0] out_data;

integer i_pat;
integer i;
integer j;
integer k;
integer l;
integer total_latency;
integer latency;

parameter PAT_NUM = 10000;
parameter CYCLE_DELAY = 1000;
integer   SEED = 587;

// ===============================================================
// Clock Cycle
// ===============================================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// wire & registers 
//================================================================
reg [7:0]  golden_img_0[0:5][0:5];
reg [7:0]  golden_img_1[0:5][0:5];
reg [7:0]  golden_ker[0:2][0:2];
reg [7:0]  golden_weight[0:1][0:1];
reg [19:0] golden_feature_map_0[0:3][0:3];
reg [19:0] golden_feature_map_1[0:3][0:3];
reg [7:0]  golden_quan_4x4_0[0:3][0:3];
reg [7:0]  golden_quan_4x4_1[0:3][0:3];
reg [7:0]  golden_pool_0[0:1][0:1];
reg [7:0]  golden_pool_1[0:1][0:1];
reg [16:0] golden_fc_0[0:3];
reg [16:0] golden_fc_1[0:3];
reg [7:0]  golden_quan_4x1_0[0:3];
reg [7:0]  golden_quan_4x1_1[0:3];
reg [9:0]  golden_l1_distance;
reg [9:0]  golden_ans;

//================================================================
// tasks 
//================================================================

initial begin
    reset_signal_task;
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        input_task;
        golden_task;
        wait_out_valid_task;
        check_ans_task;
        $display("\033[1;32mPASS PATTERN NO.%4d \033[1;34m Latency = %3d\033[m", i_pat, latency);
    end
    YOU_PASS_task;
end

task reset_signal_task; begin 

    force clk = 0;
    rst_n    = 'b1;
    cg_en    = `CG_EN;
    in_valid = 'b0;
    img      = 'bx;
    ker      = 'bx;
    weight   = 'bx;
    total_latency = 0;

    #CYCLE;       rst_n = 0; 
    #(CYCLE * 2); rst_n = 1;
    
    if(out_valid !== 'b0 || out_data !== 'b0) begin
        $display("\033[m---------------------------------------------------------------------------------------\033[m");
        $display("\033[m     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                                    \033[m");
        $display("\033[m    ▄▀            ▀▄      ▄▄                                                           \033[m");
        $display("\033[m    █  ▀   ▀       ▀▄▄   █  █      FAIL !                                              \033[m");
        $display("\033[m    █   ▀▀            ▀▀▀   ▀▄  ╭  All output signal should be reset after RESET at %8t PS\033[m", $time);
        $display("\033[m    █  ▄▀▀▀▄                 █  ╭                                                      \033[m");
        $display("\033[m    ▀▄                       █                                                         \033[m");
        $display("\033[m     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                                          \033[m");
        $display("\033[m     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                                           \033[m");
        $display("\033[m---------------------------------------------------------------------------------------\033[m");
        repeat(2) #CYCLE;
        $finish;
    end
    #CYCLE; release clk;
    @(negedge clk);
end endtask

task input_task; begin

    repeat($random(SEED) % 3 + 2) @(negedge clk);

    for(i=0;i<72;i=i+1) begin
        in_valid = 1'b1;

        if(i<9) begin
            ker = {$random(SEED)} % 256;
            golden_ker[i/3][i%3] = ker;
        end else
            ker = 'bx;

        if(i<4) begin
            weight = {$random(SEED)} % 256;
            golden_weight[i/2][i%2] = weight;
        end else
            weight = 'bx;

        if(i<36) begin
            img = {$random(SEED)} % 256;
            golden_img_0[i/6][i%6] = img;
        end else begin
            img = {$random(SEED)} % 256;
            golden_img_1[(i-36)/6][(i-36)%6] = img;
        end

        @(negedge clk);

    end

    in_valid=0;
    img='dx;
    ker = 'dx;
    weight='dx;
end endtask 

task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
        latency = latency + 1;
        if(latency == CYCLE_DELAY) begin
            $display("\033[m-----------------------------------------------------------------------------\033[m");
            $display("\033[m     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                          \033[m");
            $display("\033[m    ▄▀            ▀▄      ▄▄                                                 \033[m");
            $display("\033[m    █  ▀   ▀       ▀▄▄   █  █      FAIL !                                    \033[m");
            $display("\033[m    █   ▀▀            ▀▀▀   ▀▄  ╭  The execution latency is over cycles  %3d\033[m", CYCLE_DELAY);
            $display("\033[m    █  ▄▀▀▀▄                 █  ╭                                            \033[m");
            $display("\033[m    ▀▄                       █                                               \033[m");
            $display("\033[m     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                                \033[m");
            $display("\033[m     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                                 \033[m");
            $display("\033[m-----------------------------------------------------------------------------\033[m");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task golden_task; begin

    for(i=0;i<4;i=i+1)begin
        for(j=0;j<4;j=j+1)begin
            golden_feature_map_0[i][j] =    golden_img_0[i  ][j] * golden_ker[0][0] + golden_img_0[i  ][j+1] * golden_ker[0][1] + golden_img_0[i  ][j+2] * golden_ker[0][2] + 
                                            golden_img_0[i+1][j] * golden_ker[1][0] + golden_img_0[i+1][j+1] * golden_ker[1][1] + golden_img_0[i+1][j+2] * golden_ker[1][2] + 
                                            golden_img_0[i+2][j] * golden_ker[2][0] + golden_img_0[i+2][j+1] * golden_ker[2][1] + golden_img_0[i+2][j+2] * golden_ker[2][2] ; 

            golden_feature_map_1[i][j] =    golden_img_1[i  ][j] * golden_ker[0][0] + golden_img_1[i  ][j+1] * golden_ker[0][1] + golden_img_1[i  ][j+2] * golden_ker[0][2] + 
                                            golden_img_1[i+1][j] * golden_ker[1][0] + golden_img_1[i+1][j+1] * golden_ker[1][1] + golden_img_1[i+1][j+2] * golden_ker[1][2] + 
                                            golden_img_1[i+2][j] * golden_ker[2][0] + golden_img_1[i+2][j+1] * golden_ker[2][1] + golden_img_1[i+2][j+2] * golden_ker[2][2] ; 
        end
    end

    for(i=0;i<4;i=i+1)begin
        for(j=0;j<4;j=j+1)begin
            golden_quan_4x4_0[i][j] = golden_feature_map_0[i][j] / 2295;
            golden_quan_4x4_1[i][j] = golden_feature_map_1[i][j] / 2295;
        end
    end

    for(i=0;i<2;i=i+1)begin
        for(j=0;j<2;j=j+1)begin
            l = golden_quan_4x4_0[i*2][j*2];
            for(k=0;k<4;k=k+1)begin
                l = (l >golden_quan_4x4_0[i*2+k/2][j*2+k%2]) ? l : golden_quan_4x4_0[i*2+k/2][j*2+k%2];
            end         
            golden_pool_0[i][j] = l;

            l = golden_quan_4x4_1[i*2][j*2];
            for(k=0;k<4;k=k+1)begin
                l = (l >golden_quan_4x4_1[i*2+k/2][j*2+k%2]) ? l : golden_quan_4x4_1[i*2+k/2][j*2+k%2];
            end         
            golden_pool_1[i][j] = l;
        end
    end

    for(i=0;i<4;i=i+1)begin
        golden_fc_0[i] = golden_pool_0[i/2][0] * golden_weight[0][i%2] + golden_pool_0[i/2][1] * golden_weight[1][i%2];
        golden_fc_1[i] = golden_pool_1[i/2][0] * golden_weight[0][i%2] + golden_pool_1[i/2][1] * golden_weight[1][i%2];
    end

    for(i=0;i<4;i=i+1)begin
        golden_quan_4x1_0[i] = golden_fc_0[i] / 510;
        golden_quan_4x1_1[i] = golden_fc_1[i] / 510;
    end

    golden_l1_distance = 0;
    for(i=0;i<4;i=i+1)begin
        golden_l1_distance = golden_l1_distance + ((golden_quan_4x1_0[i] > golden_quan_4x1_1[i]) ? (golden_quan_4x1_0[i] - golden_quan_4x1_1[i]) : (golden_quan_4x1_1[i] - golden_quan_4x1_0[i]));
    end

    golden_ans = (golden_l1_distance >= 16) ? golden_l1_distance : 0;

end endtask

task check_ans_task; begin
    if (out_valid === 1'b1) begin   
        if(out_data !== golden_ans) begin
            $display("\033[m--------------------------------------------------------------------\033[m");
            $display("\033[m     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                 \033[m");
            $display("\033[m    ▄▀            ▀▄      ▄▄       \033[0;32;31mFAIL at PATTERN NO.%4d \033[m", i_pat);
            $display("\033[m    █  ▀   ▀       ▀▄▄   █  █      \033[0;32;31m Your  Ans = %7d\033[m", out_data);
            $display("\033[m    █   ▀▀            ▀▀▀   ▀▄  ╭  \033[0;32;31mGolden Ans = %7d\033[m", golden_ans);
            $display("\033[m    █  ▄▀▀▀▄                 █  ╭                                   \033[m");
            $display("\033[m    ▀▄                       █                                      \033[m");
            $display("\033[m     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                       \033[m");
            $display("\033[m     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                        \033[m");
            $display("\033[m--------------------------------------------------------------------\033[m");

            $display("\033[44;1m[=========]\033[m");
            $display("\033[44;1m[ Image_0 ]\033[m");
            $display("\033[44;1m[=========]\033[m");
            for(i=0;i<6;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d %7d %7d \033[m", golden_img_0[i][0], golden_img_0[i][1], golden_img_0[i][2], golden_img_0[i][3], golden_img_0[i][4], golden_img_0[i][5]);
            end

            $display("\033[44;1m[=========]\033[m");
            $display("\033[44;1m[ Image_1 ]\033[m");
            $display("\033[44;1m[=========]\033[m");
            for(i=0;i<6;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d %7d %7d \033[m", golden_img_1[i][0], golden_img_1[i][1], golden_img_1[i][2], golden_img_1[i][3], golden_img_1[i][4], golden_img_1[i][5]);
            end

            $display("\033[44;1m[========]\033[m");
            $display("\033[44;1m[ Kernel ]\033[m");
            $display("\033[44;1m[========]\033[m");
            for(i=0;i<3;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d \033[m", golden_ker[i][0], golden_ker[i][1], golden_ker[i][2]);
            end

            $display("\033[44;1m[========]\033[m");
            $display("\033[44;1m[ Weight ]\033[m");
            $display("\033[44;1m[========]\033[m");
            for(i=0;i<2;i=i+1) begin
                $display("\033[1;35m %7d %7d \033[m", golden_weight[i][0], golden_weight[i][1]);
            end

            $display("\033[42;1m[===============]\033[m");
            $display("\033[42;1m[ Convolution_0 ]\033[m");
            $display("\033[42;1m[===============]\033[m");
            for(i=0;i<4;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_feature_map_0[i][0], golden_feature_map_0[i][1], golden_feature_map_0[i][2], golden_feature_map_0[i][3]);
            end

            $display("\033[42;1m[===============]\033[m");
            $display("\033[42;1m[ Convolution_1 ]\033[m");
            $display("\033[42;1m[===============]\033[m");
            for(i=0;i<4;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_feature_map_1[i][0], golden_feature_map_1[i][1], golden_feature_map_1[i][2], golden_feature_map_1[i][3]);
            end

            $display("\033[42;1m[====================]\033[m");
            $display("\033[42;1m[ Quantization_4x4_0 ]\033[m");
            $display("\033[42;1m[====================]\033[m");
            for(i=0;i<4;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_quan_4x4_0[i][0], golden_quan_4x4_0[i][1], golden_quan_4x4_0[i][2], golden_quan_4x4_0[i][3]);
            end

            $display("\033[42;1m[====================]\033[m");
            $display("\033[42;1m[ Quantization_4x4_1 ]\033[m");
            $display("\033[42;1m[====================]\033[m");
            for(i=0;i<4;i=i+1) begin
                $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_quan_4x4_1[i][0], golden_quan_4x4_1[i][1], golden_quan_4x4_1[i][2], golden_quan_4x4_1[i][3]);
            end

            $display("\033[42;1m[==============]\033[m");
            $display("\033[42;1m[ MaxPooling_0 ]\033[m");
            $display("\033[42;1m[==============]\033[m");
            for(i=0;i<2;i=i+1) begin
                $display("\033[1;35m %7d %7d \033[m", golden_pool_0[i][0], golden_pool_0[i][1]);
            end

            $display("\033[42;1m[==============]\033[m");
            $display("\033[42;1m[ MaxPooling_1 ]\033[m");
            $display("\033[42;1m[==============]\033[m");
            for(i=0;i<2;i=i+1) begin
                $display("\033[1;35m %7d %7d \033[m", golden_pool_1[i][0], golden_pool_1[i][1],);
            end

            $display("\033[42;1m[==================]\033[m");
            $display("\033[42;1m[ FullyConnected_0 ]\033[m");
            $display("\033[42;1m[==================]\033[m");
            $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_fc_0[0], golden_fc_0[1], golden_fc_0[2], golden_fc_0[3]);

            $display("\033[42;1m[==================]\033[m");
            $display("\033[42;1m[ FullyConnected_0 ]\033[m");
            $display("\033[42;1m[==================]\033[m");
            $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_fc_1[0], golden_fc_1[1], golden_fc_1[2], golden_fc_1[3]);


            $display("\033[42;1m[====================]\033[m");
            $display("\033[42;1m[ Quantization_4x1_0 ]\033[m");
            $display("\033[42;1m[====================]\033[m");
            $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_quan_4x1_0[0], golden_quan_4x1_0[1], golden_quan_4x1_0[2], golden_quan_4x1_0[3]);

            $display("\033[42;1m[====================]\033[m");
            $display("\033[42;1m[ Quantization_4x1_1 ]\033[m");
            $display("\033[42;1m[====================]\033[m");
            $display("\033[1;35m %7d %7d %7d %7d \033[m", golden_quan_4x1_1[0], golden_quan_4x1_1[1], golden_quan_4x1_1[2], golden_quan_4x1_1[3]);

            $display("\033[42;1m[=============]\033[m");
            $display("\033[42;1m[ L1 Distance ]\033[m");
            $display("\033[42;1m[=============]\033[m");
            $display("\033[1;35m %7d \033[m", golden_l1_distance);

            $finish;   
        end     
        @(negedge clk);
    end 
end endtask

task YOU_PASS_task; begin
    $display("\033[m------------------------------------------------------------------------\033[m");
    $display("\033[m     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                     \033[m");
    $display("\033[m    ▄▀            ▀▄      ▄▄                                            \033[m");
    $display("\033[m    █  ▀   ▀       ▀▄▄   █  █      \033[0;35mCongratulations !                    \033[m");
    $display("\033[m    █   ▀▀            ▀▀▀   ▀▄  ╭  \033[0;35mYou have passed all patterns !       \033[m");
    $display("\033[m    █ ▀▄▀▄▄▀                 █  ╭  \033[0;35mYour execution cycles = %5d cycles   \033[m", total_latency);
    $display("\033[m    ▀▄                       █                                          \033[m");
    $display("\033[m     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           \033[m");
    $display("\033[m     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            \033[m");
    $display("\033[m------------------------------------------------------------------------\033[m");  
    $finish;
end endtask

always@(*)begin
    @(negedge clk);
    if(in_valid && out_valid)begin
        $display("--------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      \033[0;32;31mFAIL at %8t PS\033[m", $time);
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  \033[0;32;31mThe out_valid cannot overlap with in_valid\033[m");
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("--------------------------------------------------------------------------------");  
        repeat(9)@(negedge clk);
        $finish;            
    end 
end
always@(*)begin
    @(negedge clk);
    if(~out_valid && out_data !== 0)begin
        $display("--------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █      \033[0;32;31mFAIL at %8t PS\033[m", $time);
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  \033[0;32;31mThe out_code should be 0 when out_valid is low\033[m");
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("--------------------------------------------------------------------------------");
        repeat(9)@(negedge clk);
        $finish;            
    end 
end

endmodule