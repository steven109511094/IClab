/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab08: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================

parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

parameter cycle = 2.3;

parameter pat_num = 3601;

parameter integer day   [0:11] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}; // actual day in each month

parameter integer size  [0: 3] = {960, 720, 0, 480}; // L, M, X, S

// This may be possible to use 2d array?
parameter integer ratio_table [0:31] = {1, 0, 0, 0,
                                        3, 0, 1, 0,
                                        1, 0, 1, 0,
                                        0, 1, 0, 0,
                                        0, 1, 1, 0,
                                        0, 0, 0, 1,
                                        1, 0, 0, 1,
                                        2, 0, 1, 1};

integer i, j, i_pat;

integer latency, total_latency;

integer box_addr;

integer ratio_sum;

//================================================================
// wire & registers 
//================================================================

logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 10000 ~ 107ff

//================================================================
// class random
//================================================================

// Class representing a random action.
class random_act;
    randc Action act;
    constraint constr_act{
        act inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

// Class representing a random type of beverage.
class random_bev_type;
    randc Bev_Type bev_type;
    constraint constr_type{
        bev_type inside{Black_Tea      	        ,
                        Milk_Tea	            ,
                        Extra_Milk_Tea          ,
                        Green_Tea 	            ,
                        Green_Milk_Tea          ,
                        Pineapple_Juice         ,
                        Super_Pineapple_Tea     ,
                        Super_Pineapple_Milk_Tea};
    }
endclass

// Class representing a random size of beverage.
class random_bev_size;
    randc Bev_Size bev_size;
    constraint constr_size{
        bev_size inside{L, M, S};
    }
endclass

// Class representing a random date.
class random_date;
    randc Date date;
    constraint constr_month{
        date.M inside{[1:12]};
    }
    /*constraint constr_date{
        date.D inside{[1:day[date.M - 1]]};
    }*/
endclass

// Class representing a random number of box from 0 to 255.
class random_box_no;
    randc Barrel_No box_no;
    constraint constr_box_no{
        box_no inside{[0:255]};
    }
endclass

// Class representing a random number of supplementary ingrediant from 0 to 4095.
class random_box_sup;
    rand Bev_Bal box_sup;
    constraint constr_black_tea{
        box_sup.black_tea inside{[0:4095]};
    }
    constraint constr_green_tea{
        box_sup.green_tea inside{[0:4095]};
    }
    constraint constr_milk{
        box_sup.milk inside{[0:4095]};
    }
    constraint constr_pineapple_juice{
        box_sup.pineapple_juice inside{[0:4095]};
    }
endclass

//================================================================
// declaration
//================================================================

// Random generator
random_act      rand_act;
random_bev_type rand_bev_type;
random_bev_size rand_bev_size;
random_date     rand_date;
random_box_no   rand_box_no;
random_box_sup  rand_box_sup;

// For gen_signal_task
Signal_Type signal_type;

// Information from DRAM
Month   golden_month;
Day     golden_day;
ING     golden_black_tea;
ING     golden_green_tea;
ING     golden_milk;
ING     golden_pineapple_juice;

// Ingrediants consumed in Make_drink
ING     consum_black_tea;
ING     consum_green_tea;
ING     consum_milk;
ING     consum_pineapple_juice;

// Golden answer
Error_Msg golden_err;

//================================================================
// initial
//================================================================

initial begin
    // Load DRAM
    $readmemh(DRAM_p_r, golden_DRAM);

    // Reset 
    reset_task;

    // Main loop
    for(i_pat = 0; i_pat < pat_num; i_pat = i_pat + 1) begin
        // Generate input signals
        input_task;
        //cov_input_task;

        // Wait out_valid
        wait_out_valid_task;

        // Calculate golden answer 
        // And check output answer with golden answer
        check_ans_task;

        // Pass current pattern
        $display ("             \033[0;%2dmPass Pattern NO. %d    latency = %d  \033[m    ", 32, i_pat, latency);
    end

    // Pass all patterns
    YOU_PASS_TASK;
end

//================================================================
// tasks
//================================================================

task reset_task; begin
    // Reset random generator
    rand_act = new();
    rand_bev_type = new();
    rand_bev_size = new();
    rand_date = new();
    rand_box_no = new();
    rand_box_sup = new();

    // Reset total latency
    total_latency = 0;

    // Reset information of pattern
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.type_valid = 1'b0;
    inf.size_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.box_no_valid = 1'b0;
    inf.box_sup_valid = 1'b0;
    inf.D = 'dx;

    // Control clock
    force clk = 0;
    #(cycle); inf.rst_n = 0;
    #(cycle); inf.rst_n = 1;  
	release clk;

    // Check output signals after reset
    //check_spec_1; // reset check is moved to checker.sv
end endtask

task input_task; begin
    // Random delay for 1 ~ 4 cycle between reset/output and input
    repeat($urandom_range(1, 4)) @(negedge clk);

    //$display("i_pat: %d", i_pat);
    // Random actio
    signal_type = act;
    gen_signal_task;
    //$display("action: %d", rand_act.act);

    // Generate signals corresponding to action
    case (rand_act.act)
        Make_drink: begin // type -> size -> today's date -> box number
            // Random type of beverage
            signal_type = bev_type;
            gen_signal_task;
            //$display("type: %d", rand_bev_type.bev_type);

            // Random size of beverage
            signal_type = bev_size;
            gen_signal_task;
            //$display("size: %d", rand_bev_size.bev_size);

            // Random date of today
            signal_type = date;
            gen_signal_task;
            //$display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);
        end
        Supply: begin // expired date -> box number -> black tea -> green tea -> milk -> pineapple juice           
            // Random expired date
            signal_type = date;
            gen_signal_task;
            //$display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);

            // Random number of 4 supplementary ingrediants
            signal_type = box_sup;
            gen_signal_task;
            //$display("black tea.: %d", rand_box_sup.box_sup.black_tea);
            //$display("green tea.: %d", rand_box_sup.box_sup.green_tea);
            //$display("milk.: %d", rand_box_sup.box_sup.milk);
            //$display("pineapple juice.: %d", rand_box_sup.box_sup.pineapple_juice);
        end
        Check_Valid_Date: begin // today's date -> box number            
            // Random date of today
            signal_type = date;
            gen_signal_task;
            //display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);
        end
    endcase
end endtask

task gen_signal_task; begin
    // Generate signals corresponding to signal_type for 1 cycle
    // Then, make valid and D unavailable
    // And random delay for 1 ~ 4 cycle between each input
    case (signal_type)
        act: begin
            rand_act.randomize();

            inf.sel_action_valid = 1'b1;
            inf.D[11:0] = {10'b0, rand_act.act};
            @(negedge clk);

            inf.sel_action_valid = 1'b0;
            inf.D = 'bx;
            repeat($urandom_range(0, 3)) @(negedge clk);
        end
        box_no: begin
            rand_box_no.randomize();

            inf.box_no_valid = 1'b1;
            inf.D[11:0] = {4'b0, rand_box_no.box_no};
            @(negedge clk);

            inf.box_no_valid = 1'b0;
            inf.D = 'bx;
            repeat($urandom_range(0, 3)) @(negedge clk);
        end
        box_sup: begin
            rand_box_sup.randomize();

            for(i = 0; i < 4; i = i + 1) begin
                inf.box_sup_valid = 1'b1;
                case (i)
                    0: inf.D[11:0] = rand_box_sup.box_sup.black_tea;
                    1: inf.D[11:0] = rand_box_sup.box_sup.green_tea;
                    2: inf.D[11:0] = rand_box_sup.box_sup.milk;
                    3: inf.D[11:0] = rand_box_sup.box_sup.pineapple_juice;
                endcase
                @(negedge clk);

                inf.box_sup_valid = 1'b0;
                inf.D = 'bx;
                repeat($urandom_range(0, 3)) @(negedge clk);
            end
        end
        bev_type: begin
            rand_bev_type.randomize();

            inf.type_valid = 1'b1;
            inf.D[11:0] = {9'b0, rand_bev_type.bev_type};
            @(negedge clk);

            inf.type_valid = 1'b0;
            inf.D = 'bx;
            repeat($urandom_range(0, 3)) @(negedge clk);
        end
        bev_size: begin
            rand_bev_size.randomize();

            inf.size_valid = 1'b1;
            inf.D[11:0] = {10'b0, rand_bev_size.bev_size};
            @(negedge clk);

            inf.size_valid = 1'b0;
            inf.D = 'bx;
            repeat($urandom_range(0, 3)) @(negedge clk);
        end
        date: begin
            rand_date.randomize();
            rand_date.date.D = $urandom_range(1, day[rand_date.date.M - 1]);

            inf.date_valid = 1'b1;
            inf.D[11:0] = {3'b0, rand_date.date.M, rand_date.date.D};
            @(negedge clk);

            inf.date_valid = 1'b0;
            inf.D = 'bx;
            repeat($urandom_range(0, 3)) @(negedge clk);
        end
    endcase
end endtask

task cov_input_task;
    // Random delay for 1 ~ 4 cycle between reset/output and input
    //repeat($urandom_range(1, 4)) @(negedge clk);
    repeat(1) @(negedge clk);

    //$display("i_pat: %d", i_pat);
    // Random action
    signal_type = act;
    cov_gen_signal_task;
    //$display("action: %d", rand_act.act);

    // Generate signals corresponding to action
    case (rand_act.act)
        Make_drink: begin // type -> size -> today's date -> box number
            // Random type of beverage
            signal_type = bev_type;
            cov_gen_signal_task;
            //$display("type: %d", rand_bev_type.bev_type);

            // Random size of beverage
            signal_type = bev_size;
            cov_gen_signal_task;
            //$display("type: %d", rand_bev_size.bev_size);

            // Random date of today
            signal_type = date;
            cov_gen_signal_task;
            //$display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            cov_gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);
        end
        Supply: begin // expired date -> box number -> black tea -> green tea -> milk -> pineapple juice           
            // Random expired date
            signal_type = date;
            cov_gen_signal_task;
            //$display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            cov_gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);

            // Random number of 4 supplementary ingrediants
            signal_type = box_sup;
            cov_gen_signal_task;
            //$display("black tea.: %d", rand_box_sup.box_sup.black_tea);
            //$display("green tea.: %d", rand_box_sup.box_sup.green_tea);
            //$display("milk.: %d", rand_box_sup.box_sup.milk);
            //$display("pineapple juice.: %d", rand_box_sup.box_sup.pineapple_juice);
        end
        Check_Valid_Date: begin // today's date -> box number            
            // Random date of today
            signal_type = date;
            cov_gen_signal_task;
            //display("date: %d / %d", rand_date.date.M, rand_date.date.D);

            // Random number of box
            signal_type = box_no;
            cov_gen_signal_task;
            //$display("box no.: %d", rand_box_no.box_no);
        end
    endcase
endtask 

task cov_gen_signal_task; begin
    // Generate signals corresponding to signal_type for 1 cycle
    // Then, make valid and D unavailable
    // And random delay for 1 ~ 4 cycle between each input
    case (signal_type)
        act: begin
            if(i_pat < 2000) begin
                rand_act.act = Make_drink;
            end
            else if(i_pat < 2400) begin
                rand_act.act = (i_pat % 2 == 0) ? Supply : Make_drink;
            end
            else if(i_pat < 2800) begin
                rand_act.act = (i_pat % 2 == 0) ? Make_drink : Check_Valid_Date;
            end
            else if(i_pat < 3000) begin
                rand_act.act = Supply;
            end
            else if(i_pat < 3400) begin
                rand_act.act = (i_pat % 2 == 0) ? Supply : Check_Valid_Date;
            end
            else if(i_pat < 3600) begin
                rand_act.act = Check_Valid_Date;
            end
            else begin
                rand_act.act = Make_drink;
            end

            inf.sel_action_valid = 1'b1;
            inf.D[11:0] = {10'b0, rand_act.act};
            @(negedge clk);

            inf.sel_action_valid = 1'b0;
            inf.D = 'bx;
            //repeat($urandom_range(0, 3)) @(negedge clk);
        end
        box_no: begin
            rand_box_no.box_no = 0;

            inf.box_no_valid = 1'b1;
            inf.D[11:0] = {4'b0, rand_box_no.box_no};
            @(negedge clk);

            inf.box_no_valid = 1'b0;
            inf.D = 'bx;
            //repeat($urandom_range(0, 3)) @(negedge clk);
        end
        box_sup: begin
            rand_box_sup.randomize();

            for(i = 0; i < 4; i = i + 1) begin
                inf.box_sup_valid = 1'b1;
                case (i)
                    0: inf.D[11:0] = rand_box_sup.box_sup.black_tea;
                    1: inf.D[11:0] = rand_box_sup.box_sup.green_tea;
                    2: inf.D[11:0] = rand_box_sup.box_sup.milk;
                    3: inf.D[11:0] = rand_box_sup.box_sup.pineapple_juice;
                endcase
                @(negedge clk);

                inf.box_sup_valid = 1'b0;
                inf.D = 'bx;
                //repeat($urandom_range(0, 3)) @(negedge clk);
            end
        end
        bev_type: begin
            case (i_pat/300)
                0: rand_bev_type.bev_type = Black_Tea;
                1: rand_bev_type.bev_type = Milk_Tea;
                2: rand_bev_type.bev_type = Extra_Milk_Tea;
                3: rand_bev_type.bev_type = Green_Tea;
                4: rand_bev_type.bev_type = Green_Milk_Tea;
                5: rand_bev_type.bev_type = Pineapple_Juice;
                6: rand_bev_type.bev_type = Super_Pineapple_Tea;
                7: rand_bev_type.bev_type = (i_pat < 2200) ? Super_Pineapple_Tea : Super_Pineapple_Milk_Tea;
                default: rand_bev_type.bev_type = Super_Pineapple_Milk_Tea;
            endcase
            /*if(i_pat < 300) begin
                rand_bev_type.bev_type = Black_Tea;
            end
            else if(i_pat < 600) begin
                rand_bev_type.bev_type = Milk_Tea;
            end
            else if(i_pat < 901) begin
                rand_bev_type.bev_type = Extra_Milk_Tea;
            end
            else if(i_pat < 1201) begin
                rand_bev_type.bev_type = Green_Tea;
            end
            else if(i_pat < 1501) begin
                rand_bev_type.bev_type = Green_Milk_Tea;
            end
            else if(i_pat < 1801) begin
                rand_bev_type.bev_type = Pineapple_Juice;
            end
            else if(i_pat < 2202) begin
                rand_bev_type.bev_type = Super_Pineapple_Tea;
            end
            else begin
                rand_bev_type.bev_type = Super_Pineapple_Milk_Tea;
            end*/

            inf.type_valid = 1'b1;
            inf.D[11:0] = {9'b0, rand_bev_type.bev_type};
            @(negedge clk);

            inf.type_valid = 1'b0;
            inf.D = 'bx;
            //repeat($urandom_range(0, 3)) @(negedge clk);
        end
        bev_size: begin
            if(i_pat % 3 == 0) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat % 3 == 1) begin
                rand_bev_size.bev_size = M;
            end
            else begin
                rand_bev_size.bev_size = S;
            end
            /*if(i_pat < 100) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 200) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 301) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 401) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 501) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 601) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 701) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 801) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 901) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 1001) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 1101) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 1201) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 1301) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 1401) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 1501) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 1601) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 1701) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 1801) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 1901) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 2002) begin
                rand_bev_size.bev_size = M;
            end
            else if(i_pat < 2202) begin
                rand_bev_size.bev_size = S;
            end
            else if(i_pat < 2402) begin
                rand_bev_size.bev_size = L;
            end
            else if(i_pat < 2602) begin
                rand_bev_size.bev_size = M;
            end
            else begin
                rand_bev_size.bev_size = S;
            end*/

            inf.size_valid = 1'b1;
            inf.D[11:0] = {10'b0, rand_bev_size.bev_size};
            @(negedge clk);

            inf.size_valid = 1'b0;
            inf.D = 'bx;
            //repeat($urandom_range(0, 3)) @(negedge clk);
        end
        date: begin
            rand_date.randomize();
            rand_date.date.D = $urandom_range(1, day[rand_date.date.M - 1]);

            inf.date_valid = 1'b1;
            inf.D[11:0] = {3'b0, rand_date.date.M, rand_date.date.D};
            @(negedge clk);

            inf.date_valid = 1'b0;
            inf.D = 'bx;
            //repeat($urandom_range(0, 3)) @(negedge clk);
        end
    endcase
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1) begin
        latency = latency + 1;
        
        //check_spec_2; // latency check is moved to checker.sv

        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    // Choose box
    box_addr = 65536 + 8*rand_box_no.box_no;

    // Load golden information from DRAM
    golden_month            = {golden_DRAM[box_addr + 4]};
    golden_day              = {golden_DRAM[box_addr + 0]};
    golden_black_tea        = {golden_DRAM[box_addr + 7][7:0], golden_DRAM[box_addr + 6][7:4]};
    golden_green_tea        = {golden_DRAM[box_addr + 6][3:0], golden_DRAM[box_addr + 5][7:0]};
    golden_milk             = {golden_DRAM[box_addr + 3][7:0], golden_DRAM[box_addr + 2][7:4]};
    golden_pineapple_juice  = {golden_DRAM[box_addr + 2][3:0], golden_DRAM[box_addr + 1][7:0]};

    //$display("golden_action         : %d", rand_act.act          );
    //$display("golden_month          : %d", golden_month          );
    //$display("golden_day            : %d", golden_day            );
    //$display("golden_black_tea      : %d", golden_black_tea      );
    //$display("golden_green_tea      : %d", golden_green_tea      );
    //$display("golden_milk           : %d", golden_milk           );
    //$display("golden_pineapple_juice: %d", golden_pineapple_juice);

    // Calculate answer corresponding to action
    case (rand_act.act)
        Make_drink: begin
            // Calculate consumed ingrediants due to the order
            ratio_sum = 0;
            for(i = 0; i < 4; i = i + 1) begin
                ratio_sum = ratio_sum + ratio_table[rand_bev_type.bev_type*4 + i];
            end
            consum_black_tea        = (size[rand_bev_size.bev_size] * ratio_table[rand_bev_type.bev_type*4 + 0]) / ratio_sum;
            consum_green_tea        = (size[rand_bev_size.bev_size] * ratio_table[rand_bev_type.bev_type*4 + 1]) / ratio_sum;
            consum_milk             = (size[rand_bev_size.bev_size] * ratio_table[rand_bev_type.bev_type*4 + 2]) / ratio_sum;
            consum_pineapple_juice  = (size[rand_bev_size.bev_size] * ratio_table[rand_bev_type.bev_type*4 + 3]) / ratio_sum;

            // Calculate golden error
            if((rand_date.date.M > golden_month) || ((rand_date.date.M == golden_month) && (rand_date.date.D > golden_day))) begin
                golden_err = No_Exp;
            end // Check if ingrediants are expired
            else if((consum_black_tea > golden_black_tea) || (consum_green_tea > golden_green_tea) || (consum_milk > golden_milk) || (consum_pineapple_juice > golden_pineapple_juice)) begin
                golden_err = No_Ing;
            end // Check if ingrediants are enough
            else begin
                golden_err = No_Err;
            end // No error

            // Deduct ingrediants in DRAM if there is no error
            {golden_DRAM[box_addr + 7][7:0], golden_DRAM[box_addr + 6][7:4]} = (golden_err == No_Err) ? (golden_black_tea       - consum_black_tea      ) : golden_black_tea;
            {golden_DRAM[box_addr + 6][3:0], golden_DRAM[box_addr + 5][7:0]} = (golden_err == No_Err) ? (golden_green_tea       - consum_green_tea      ) : golden_green_tea;
            {golden_DRAM[box_addr + 3][7:0], golden_DRAM[box_addr + 2][7:4]} = (golden_err == No_Err) ? (golden_milk            - consum_milk           ) : golden_milk;
            {golden_DRAM[box_addr + 2][3:0], golden_DRAM[box_addr + 1][7:0]} = (golden_err == No_Err) ? (golden_pineapple_juice - consum_pineapple_juice) : golden_pineapple_juice;
        end
        Supply: begin
            // Calculate golden error
            if((rand_box_sup.box_sup.black_tea > 4095 - golden_black_tea) || (rand_box_sup.box_sup.green_tea > 4095 - golden_green_tea) || (rand_box_sup.box_sup.milk > 4095 - golden_milk) || (rand_box_sup.box_sup.pineapple_juice > 4095 - golden_pineapple_juice)) begin
                golden_err = Ing_OF;
            end // Check if supplementary ingrediants overflow
            else begin
                golden_err = No_Err;
            end // No error

            // Replace expired date in DRAM
            {golden_DRAM[box_addr + 4]} = rand_date.date.M;
            {golden_DRAM[box_addr + 0]} = rand_date.date.D;

            // Add ingrediants in DRAM if there is no error
            {golden_DRAM[box_addr + 7][7:0], golden_DRAM[box_addr + 6][7:4]} = (rand_box_sup.box_sup.black_tea          > 4095 - golden_black_tea       ) ? 4095 : (golden_black_tea       + rand_box_sup.box_sup.black_tea      );
            {golden_DRAM[box_addr + 6][3:0], golden_DRAM[box_addr + 5][7:0]} = (rand_box_sup.box_sup.green_tea          > 4095 - golden_green_tea       ) ? 4095 : (golden_green_tea       + rand_box_sup.box_sup.green_tea      );
            {golden_DRAM[box_addr + 3][7:0], golden_DRAM[box_addr + 2][7:4]} = (rand_box_sup.box_sup.milk               > 4095 - golden_milk            ) ? 4095 : (golden_milk            + rand_box_sup.box_sup.milk           );
            {golden_DRAM[box_addr + 2][3:0], golden_DRAM[box_addr + 1][7:0]} = (rand_box_sup.box_sup.pineapple_juice    > 4095 - golden_pineapple_juice ) ? 4095 : (golden_pineapple_juice + rand_box_sup.box_sup.pineapple_juice);
        end
        Check_Valid_Date: begin
            // Calculate golden error
            if((rand_date.date.M > golden_month) || ((rand_date.date.M == golden_month) && (rand_date.date.D > golden_day))) begin
                golden_err = No_Exp;
            end // Check if ingrediants are expired
            else begin
                golden_err = No_Err;
            end // No error
        end
    endcase

    //$display("");
    //$display("golden_month          : %d", {golden_DRAM[box_addr + 4]});
    //$display("golden_day            : %d", {golden_DRAM[box_addr + 0]});
    //$display("golden_black_tea      : %d", {golden_DRAM[box_addr + 7][7:0], golden_DRAM[box_addr + 6][7:4]});
    //$display("golden_green_tea      : %d", {golden_DRAM[box_addr + 6][3:0], golden_DRAM[box_addr + 5][7:0]});
    //$display("golden_milk           : %d", {golden_DRAM[box_addr + 3][7:0], golden_DRAM[box_addr + 2][7:4]});
    //$display("golden_pineapple_juice: %d", {golden_DRAM[box_addr + 2][3:0], golden_DRAM[box_addr + 1][7:0]}); 

    // Check answer of output
    check_spec_3;
end endtask  

//================================================================
// check specification tasks
//================================================================

task check_spec_1; begin
    if((inf.out_valid !== 1'b0) || (inf.err_msg !== No_Err) || (inf.complete !== 1'b0)) begin
        YOU_FAIL_TASK;
        $display("************************************************************");
        $display("*                       Wrong Answer!                      *");
        $display("*      Output signal should be 0 after initial RESET!      *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
end endtask

task check_spec_2; begin
    if(latency == 1000) begin
        YOU_FAIL_TASK;
        $display("*************************************************************************");
        $display("*                             Wrong Answer!                             *");
        $display("*                          fail pattern: %5d                          *", i_pat);
        $display("*            The execution latency is limited in 1000 cycles            *");
        $display("*************************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
end endtask

task check_spec_3; begin
    if(inf.err_msg !== golden_err) begin
        YOU_FAIL_TASK;
        $display("*************************************************************************");
        $display("*                             Wrong Answer!                             *");
        $display("                           fail pattern: %5d                          *", i_pat);
        $display("*************************************************************************");
        $display("golden err  = %b\n", golden_err);
        $display("your   err  = %b\n", inf.err_msg);
        repeat(2) @(negedge clk);
        $finish;
    end
    else if((inf.complete !== 1) && (golden_err == No_Err)) begin
        YOU_FAIL_TASK;
        $display("*************************************************************************");
        $display("*                             Wrong Answer!                             *");
        $display("                           fail pattern: %5d                          *", i_pat);
        $display("              Complete should be 1 when there's no error                *");
        $display("*************************************************************************");
        $display("golden_err    = %b\n", golden_err);
        $display("your answer   = %b\n", inf.err_msg);
        $display("your complete = %b\n", inf.complete);
        repeat(2) @(negedge clk);
        $finish;
    end
    else if((inf.complete === 1) && (golden_err != No_Err)) begin
        YOU_FAIL_TASK;
        $display("*************************************************************************");
        $display("*                             Wrong Answer!                             *");
        $display("                           fail pattern: %5d                          *", i_pat);
        $display("              Complete should be 0 when there's an error                *");
        $display("*************************************************************************");
        $display("golden_err    = %b\n", golden_err);
        $display("your answer   = %b\n", inf.err_msg);
        $display("your complete = %b\n", inf.complete);
        repeat(2) @(negedge clk);
        $finish;
    end
end endtask

//================================================================
// display result tasks
//================================================================

task YOU_FAIL_TASK; begin
    $display("\033[38;2;252;238;238m                                                                                                                                           ");      
    $display("\033[38;2;252;238;238m                                                                                                :L777777v7.                                ");
    $display("\033[31m  i:..::::::i.      :::::         ::::    .:::.       \033[38;2;252;238;238m                                       .vYr::::::::i7Lvi                             ");
    $display("\033[31m  BBBBBBBBBBBi     iBBBBBL       .BBBB    7BBB7       \033[38;2;252;238;238m                                      JL..\033[38;2;252;172;172m:r777v777i::\033[38;2;252;238;238m.ijL                           ");
    $display("\033[31m  BBBB.::::ir.     BBB:BBB.      .BBBv    iBBB:       \033[38;2;252;238;238m                                    :K: \033[38;2;252;172;172miv777rrrrr777v7:.\033[38;2;252;238;238m:J7                         ");
    $display("\033[31m  BBBQ            :BBY iBB7       BBB7    :BBB:       \033[38;2;252;238;238m                                   :d \033[38;2;252;172;172m.L7rrrrrrrrrrrrr77v: \033[38;2;252;238;238miI.                       ");
    $display("\033[31m  BBBB            BBB. .BBB.      BBB7    :BBB:       \033[38;2;252;238;238m                                  .B \033[38;2;252;172;172m.L7rrrrrrrrrrrrrrrrr7v..\033[38;2;252;238;238mBr                      ");
    $display("\033[31m  BBBB:r7vvj:    :BBB   gBBs      BBB7    :BBB:       \033[38;2;252;238;238m                                  S:\033[38;2;252;172;172m v7rrrrrrrrrrrrrrrrrrr7v. \033[38;2;252;238;238mB:                     ");
    $display("\033[31m  BBBBBBBBBB7    BBB:   .BBB.     BBB7    :BBB:       \033[38;2;252;238;238m                                 .D \033[38;2;252;172;172mi7rrrrrrr777rrrrrrrrrrr7v. \033[38;2;252;238;238mB.                    ");
    $display("\033[31m  BBBB    ..    iBBBBBBBBBBBP     BBB7    :BBB:       \033[38;2;252;238;238m                                 rv\033[38;2;252;172;172m v7rrrrrr7rirv7rrrrrrrrrr7v \033[38;2;252;238;238m:I                    ");
    $display("\033[31m  BBBB          BBBBi7vviQBBB.    BBB7    :BBB.       \033[38;2;252;238;238m                                 2i\033[38;2;252;172;172m.v7rrrrrr7i  :v7rrrrrrrrrrvi \033[38;2;252;238;238mB:                   ");
    $display("\033[31m  BBBB         rBBB.      BBBQ   .BBBv    iBBB2ir777L7\033[38;2;252;238;238m                                 2i.\033[38;2;252;172;172mv7rrrrrr7v \033[38;2;252;238;238m:..\033[38;2;252;172;172mv7rrrrrrrrr77 \033[38;2;252;238;238mrX                   ");
    $display("\033[31m .BBBB        :BBBB       BBBB7  .BBBB    7BBBBBBBBBBB\033[38;2;252;238;238m                                 Yv \033[38;2;252;172;172mv7rrrrrrrv.\033[38;2;252;238;238m.B \033[38;2;252;172;172m.vrrrrrrrrrrL.\033[38;2;252;238;238m:5                   ");
    $display("\033[31m  . ..        ....         ...:   ....    ..   .......\033[38;2;252;238;238m                                 .q \033[38;2;252;172;172mr7rrrrrrr7i \033[38;2;252;238;238mPv \033[38;2;252;172;172mi7rrrrrrrrrv.\033[38;2;252;238;238m:S                   ");
    $display("\033[38;2;252;238;238m                                                                                        Lr \033[38;2;252;172;172m77rrrrrr77 \033[38;2;252;238;238m:B. \033[38;2;252;172;172mv7rrrrrrrrv.\033[38;2;252;238;238m:S                   ");
    $display("\033[38;2;252;238;238m                                                                                         B: \033[38;2;252;172;172m7v7rrrrrv. \033[38;2;252;238;238mBY \033[38;2;252;172;172mi7rrrrrrr7v \033[38;2;252;238;238miK                   ");
    $display("\033[38;2;252;238;238m                                                                              .::rriii7rir7. \033[38;2;252;172;172m.r77777vi \033[38;2;252;238;238m7B  \033[38;2;252;172;172mvrrrrrrr7r \033[38;2;252;238;238m2r                   ");
    $display("\033[38;2;252;238;238m                                                                       .:rr7rri::......    .     \033[38;2;252;172;172m.:i7s \033[38;2;252;238;238m.B. \033[38;2;252;172;172mv7rrrrr7L..\033[38;2;252;238;238mB                    ");
    $display("\033[38;2;252;238;238m                                                        .::7L7rriiiirr77rrrrrrrr72BBBBBBBBBBBBvi:..  \033[38;2;252;172;172m.  \033[38;2;252;238;238mBr \033[38;2;252;172;172m77rrrrrvi \033[38;2;252;238;238mKi                    ");
    $display("\033[38;2;252;238;238m                                                    :rv7i::...........    .:i7BBBBQbPPPqPPPdEZQBBBBBr:.\033[38;2;252;238;238m ii \033[38;2;252;172;172mvvrrrrvr \033[38;2;252;238;238mvs                     ");
    $display("\033[38;2;252;238;238m                    .S77L.                      .rvi:. ..:r7QBBBBBBBBBBBgri.    .:BBBPqqKKqqqqPPPPPEQBBBZi  \033[38;2;252;172;172m:777vi \033[38;2;252;238;238mvI                      ");
    $display("\033[38;2;252;238;238m                    B: ..Jv                   isi. .:rBBBBBQZPPPPqqqPPdERBBBBBi.    :BBRKqqqqqqqqqqqqPKDDBB:  \033[38;2;252;172;172m:7. \033[38;2;252;238;238mJr                       ");
    $display("\033[38;2;252;238;238m                   vv SB: iu                rL: .iBBBQEPqqPPqqqqqqqqqqqqqPPPPbQBBB:   .EBQKqqqqqqPPPqqKqPPgBB:  .B:                        ");
    $display("\033[38;2;252;238;238m                  :R  BgBL..s7            rU: .qBBEKPqqqqqqqqqqqqqqqqqqqqqqqqqPPPEBBB:   EBEPPPEgQBBQEPqqqqKEBB: .s                        ");
    $display("\033[38;2;252;238;238m               .U7.  iBZBBBi :ji         5r .MBQqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPKgBB:  .BBBBBdJrrSBBQKqqqqKZB7  I:                      ");
    $display("\033[38;2;252;238;238m              v2. :rBBBB: .BB:.ru7:    :5. rBQqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBB:  :.        .5BKqqqqqqBB. Kr                     ");
    $display("\033[38;2;252;238;238m             .B .BBQBB.   .RBBr  :L77ri2  BBqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPbBB   \033[38;2;252;172;172m.irrrrri  \033[38;2;252;238;238mQQqqqqqqKRB. 2i                    ");
    $display("\033[38;2;252;238;238m              27 :BBU  rBBBdB \033[38;2;252;172;172m iri::::: \033[38;2;252;238;238m.BQKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqKRBs\033[38;2;252;172;172mirrr7777L: \033[38;2;252;238;238m7BqqqqqqqXZB. BLv772i              ");
    $display("\033[38;2;252;238;238m               rY  PK  .:dPMB \033[38;2;252;172;172m.Y77777r.\033[38;2;252;238;238m:BEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBqi\033[38;2;252;172;172mirrrrrv: \033[38;2;252;238;238muBqqqqqqqqqgB  :.:. B:             ");
    $display("\033[38;2;252;238;238m                iu 7BBi  rMgB \033[38;2;252;172;172m.vrrrrri\033[38;2;252;238;238mrBEqKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQgi\033[38;2;252;172;172mirrrrv. \033[38;2;252;238;238mQQqqqqqqqqqXBb .BBB .s:.           ");
    $display("\033[38;2;252;238;238m                i7 BBdBBBPqbB \033[38;2;252;172;172m.vrrrri\033[38;2;252;238;238miDgPPbPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQDi\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m:BdqqqqqqqqqqPB. rBB. .:iu7         ");
    $display("\033[38;2;252;238;238m                iX.:iBRKPqKXB.\033[38;2;252;172;172m 77rrr\033[38;2;252;238;238mi7QPBBBBPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPB7i\033[38;2;252;172;172mrr7r \033[38;2;252;238;238m.vBBPPqqqqqqKqBZ  BPBgri: 1B        ");
    $display("\033[38;2;252;238;238m                 ivr .BBqqKXBi \033[38;2;252;172;172mr7rri\033[38;2;252;238;238miQgQi   QZKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPEQi\033[38;2;252;172;172mirr7r.  \033[38;2;252;238;238miBBqPqqqqqqPB:.QPPRBBB LK        ");
    $display("\033[38;2;252;238;238m                   :I. iBgqgBZ \033[38;2;252;172;172m:7rr\033[38;2;252;238;238miJQPB.   gRqqqqqqqqPPPPPPPPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQ7\033[38;2;252;172;172mirrr7vr.  \033[38;2;252;238;238mUBqqPPgBBQPBBKqqqKB  B         ");
    $display("\033[38;2;252;238;238m                     v7 .BBR: \033[38;2;252;172;172m.r7ri\033[38;2;252;238;238miggqPBrrBBBBBBBBBBBBBBBBBBQEPPqqPPPqqqqqqqqqqqqqqqqqqqqqqqqqPgPi\033[38;2;252;172;172mirrrr7v7  \033[38;2;252;238;238mrBPBBP:.LBbPqqqqqB. u.        ");
    $display("\033[38;2;252;238;238m                      .j. . \033[38;2;252;172;172m :77rr\033[38;2;252;238;238miiBPqPbBB::::::.....:::iirrSBBBBBBBQZPPPPPqqqqqqqqqqqqqqqqqqqqEQi\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.BB:     :BPqqqqqDB .B        ");
    $display("\033[38;2;252;238;238m                       YL \033[38;2;252;172;172m.i77rrrr\033[38;2;252;238;238miLQPqqKQJ. \033[38;2;252;172;172m ............       \033[38;2;252;238;238m..:irBBBBBBZPPPqqqqqqqPPBBEPqqqdRr\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.B  .iBB  dQPqqqqPBi Y:       ");
    $display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172mrv7rrrrri\033[38;2;252;238;238miPgqqqqKZB.\033[38;2;252;172;172m.v77777777777777ri::..   \033[38;2;252;238;238m  ..:rBBBBQPPqqqqPBUvBEqqqPRr\033[38;2;252;172;172mirrrrrrvi\033[38;2;252;238;238m iB:RBBbB7 :BQqPqKqBR r7       ");
    $display("\033[38;2;252;238;238m                    iI.\033[38;2;252;172;172m.v7rrrrrrri\033[38;2;252;238;238midgqqqqqKB:\033[38;2;252;172;172m 77rrrrrrrrrrrrr77777777ri:..   \033[38;2;252;238;238m .:1BBBEPPB:   BbqqPQr\033[38;2;252;172;172mirrrr7vr\033[38;2;252;238;238m .BBBZPqqDB  .JBbqKPBi vi       ");
    $display("\033[38;2;252;238;238m                   :B \033[38;2;252;172;172miL7rrrrrrrri\033[38;2;252;238;238mibgqqqqqqBr\033[38;2;252;172;172m r7rrrrrrrrrrrrrrrrrrrrr777777ri:.  \033[38;2;252;238;238m .iBBBBi  .BbqqdRr\033[38;2;252;172;172mirr7v7: \033[38;2;252;238;238m.Bi.dBBPqqgB:  :BPqgB  B        ");
    $display("\033[38;2;252;238;238m                   .K.i\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238miZgqqqqqqEB \033[38;2;252;172;172m.vrrrrrrrrrrrrrrrrrrrrrrrrrrr777vv7i.  \033[38;2;252;238;238m :PBBBBPqqqEQ\033[38;2;252;172;172miir77:  \033[38;2;252;238;238m:BB:  .rBPqqEBB. iBZB. Rr        ");
    $display("\033[38;2;252;238;238m                    iM.:\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238mUQPqqqqqPBi\033[38;2;252;172;172m i7rrrrrrrrrrrrrrrrrrrrrrrrr77777i.   \033[38;2;252;238;238m.  :BddPqqqqEg\033[38;2;252;172;172miir7. \033[38;2;252;238;238mrBBPqBBP. :BXKqgB  BBB. 2r         ");
    $display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172miv77rrrrri\033[38;2;252;238;238mrBPqqqqqqPB: \033[38;2;252;172;172m:7777rrrrrrrrrrrrrrr777777ri.   \033[38;2;252;238;238m.:uBBBBZPqqqqqqPQL\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m.BZqqPB:  qMqqPB. Yv:  Ur          ");
    $display("\033[38;2;252;238;238m                       1L:.\033[38;2;252;172;172m:77v77rii\033[38;2;252;238;238mqQPqqqqqPbBi \033[38;2;252;172;172m .ir777777777777777ri:..   \033[38;2;252;238;238m.:rBBBRPPPPPqqqqqqqgQ\033[38;2;252;172;172miirr7vr \033[38;2;252;238;238m:BqXQ: .BQPZBBq ...:vv.           ");
    $display("\033[38;2;252;238;238m                         LJi..\033[38;2;252;172;172m::r7rii\033[38;2;252;238;238mRgKPPPPqPqBB:.  \033[38;2;252;172;172m ............     \033[38;2;252;238;238m..:rBBBBPPqqKKKKqqqPPqPbB1\033[38;2;252;172;172mrvvvvvr  \033[38;2;252;238;238mBEEDQBBBBBRri. 7JLi              ");
    $display("\033[38;2;252;238;238m                           .jL\033[38;2;252;172;172m  777rrr\033[38;2;252;238;238mBBBBBBgEPPEBBBvri:::::::::irrrbBBBBBBDPPPPqqqqqqXPPZQBBBBr\033[38;2;252;172;172m.......\033[38;2;252;238;238m.:BBBBg1ri:....:rIr                 ");
    $display("\033[38;2;252;238;238m                            vI \033[38;2;252;172;172m:irrr:....\033[38;2;252;238;238m:rrEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQQBBBBBBBBBBBBBQr\033[38;2;252;172;172mi:...:.   \033[38;2;252;238;238m.:ii:.. .:.:irri::                    ");
    $display("\033[38;2;252;238;238m                             71vi\033[38;2;252;172;172m:::irrr::....\033[38;2;252;238;238m    ...:..::::irrr7777777777777rrii::....  ..::irvrr7sUJYv7777v7ii..                         ");
    $display("\033[38;2;252;238;238m                               .i777i. ..:rrri77rriiiiiii:::::::...............:::iiirr7vrrr:.                                             ");
    $display("\033[38;2;252;238;238m                                                      .::::::::::::::::::::::::::::::                                                      \033[m");
    $display("\n");
end endtask


task YOU_PASS_TASK; begin
    $display("\033[37m                                                                                                                                          ");        
    $display("\033[37m                                                                                \033[32m      :BBQvi.                                              ");        
    $display("\033[37m                                                              .i7ssrvs7         \033[32m     BBBBBBBBQi                                           ");        
    $display("\033[37m                        .:r7rrrr:::.        .::::::...   .i7vr:.      .B:       \033[32m    :BBBP :7BBBB.                                         ");        
    $display("\033[37m                      .Kv.........:rrvYr7v7rr:.....:rrirJr.   .rgBBBBg  Bi      \033[32m    BBBB     BBBB                                         ");        
    $display("\033[37m                     7Q  :rubEPUri:.       ..:irrii:..    :bBBBBBBBBBBB  B      \033[32m   iBBBv     BBBB       vBr                               ");        
    $display("\033[37m                    7B  BBBBBBBBBBBBBBB::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB :R     \033[32m   BBBBBKrirBBBB.     :BBBBBB:                            ");        
    $display("\033[37m                   Jd .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Bi    \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB                             ");        
    $display("\033[37m                  uZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B    \033[32m  BBBB   .::.      EBBBi :BBU                             ");        
    $display("\033[37m                 7B .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B    \033[32m MBBBr           vBBBu   BBB.                             ");        
    $display("\033[37m                .B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: JJ   \033[32m i7PB          iBBBBB.  iBBB                              ");        
    $display("\033[37m                B. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  Lu             \033[32m  vBBBBPBBBBPBBB7       .7QBB5i                ");        
    $display("\033[37m               Y1 KBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi XBBBBBBBi :B            \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7              ");        
    $display("\033[37m              :B .BBBBBBBBBBBBBsRBBBBBBBBBBBrQBBBBB. UBBBRrBBBBBBr 1BBBBBBBBB  B.          \033[32m    .       BBBB       BBBB  :BBBB             ");        
    $display("\033[37m              Bi BBBBBBBBBBBBBi :BBBBBBBBBBE .BBK.  .  .   QBBBBBBBBBBBBBBBBBB  Bi         \033[32m           rBBBr       BBBB    BBBU            ");        
    $display("\033[37m             .B .BBBBBBBBBBBBBBQBBBBBBBBBBBB       \033[38;2;242;172;172mBBv \033[37m.LBBBBBBBBBBBBBBBBBBBBBB. B7.:ii:   \033[32m           vBBB        .BBBB   :7i.            ");        
    $display("\033[37m            .B  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBbYQB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBB  Jr:::rK7 \033[32m             .7  BBB7   iBBBg                  ");        
    $display("\033[37m           7M  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBB..i   .   v1                  \033[32mdBBB.   5BBBr                 ");        
    $display("\033[37m          sZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBB iD2BBQL.                 \033[32m ZBBBr  EBBBv     YBBBBQi     ");        
    $display("\033[37m  .7YYUSIX5 .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBY.:.      :B                 \033[32m  iBBBBBBBBD     BBBBBBBBB.   ");        
    $display("\033[37m LB.        ..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBMBBB. BP17si                 \033[32m    :LBBBr      vBBBi  5BBB   ");        
    $display("\033[37m  KvJPBBB :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mZB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBsiJr .i7ssr:                \033[32m          ...   :BBB:   BBBu  ");        
    $display("\033[37m i7ii:.   ::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBj \033[38;2;242;172;172muBi \033[37mQBBBBBBBBBBBBBBBBBBBBBBBBi.ir      iB                \033[32m         .BBBi   BBBB   iMBu  ");        
    $display("\033[37mDB    .  vBdBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg \033[38;2;242;172;172m7Bi \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB rBrXPv.                \033[32m          BBBX   :BBBr        ");        
    $display("\033[37m :vQBBB. BQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ \033[38;2;242;172;172miB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .L:ii::irrrrrrrr7jIr   \033[32m          .BBBv  :BBBQ        ");        
    $display("\033[37m :7:.   .. 5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBB:            ..... ..YB. \033[32m           .BBBBBBBBB:        ");        
    $display("\033[37mBU  .:. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mB7 \033[37mgBBBBBBBBBBBBBBBBBBBBBBBBBB. gBBBBBBBBBBBBBBBBBB. BL \033[32m             rBBBBB1.         ");        
    $display("\033[37m rY7iB: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mB7 \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBB. QBBBBBBBBBBBBBBBBBi  v5                                ");        
    $display("\033[37m     us EBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \033[38;2;242;172;172mIr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgu7i.:BBBBBBBr Bu                                 ");        
    $display("\033[37m      B  7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.\033[38;2;242;172;172m:i \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBv:.  .. :::  .rr    rB                                  ");        
    $display("\033[37m      us  .BBBBBBBBBBBBBQLXBBBBBBBBBBBBBBBBBBBBBBBBq  .BBBBBBBBBBBBBBBBBBBBBBBBBv  :iJ7vri:::1Jr..isJYr                                   ");        
    $display("\033[37m      B  BBBBBBB  MBBBM      qBBBBBBBBBBBBBBBBBBBBBB: BBBBBBBBBBBBBBBBBBBBBBBBBB  B:           iir:                                       ");        
    $display("\033[37m     iB iBBBBBBBL       BBBP. :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B.                                                       ");        
    $display("\033[37m     P: BBBBBBBBBBB5v7gBBBBBB  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Br                                                        ");        
    $display("\033[37m     B  BBBs 7BBBBBBBBBBBBBB7 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                         ");        
    $display("\033[37m    .B :BBBB.  EBBBBBQBBBBBJ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. B.                                                         ");        
    $display("\033[37m    ij qBBBBBg          ..  .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                          ");        
    $display("\033[37m    UY QBBBBBBBBSUSPDQL...iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK EL                                                          ");        
    $display("\033[37m    B7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: B:                                                          ");        
    $display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYrBB vBBBBBBBBBBBBBBBBBBBBBBBB. Ls                                                          ");        
    $display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi_  /UBBBBBBBBBBBBBBBBBBBBBBBBB. :B:                                                        ");        
    $display("\033[37m   rM .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  ..IBBBBBBBBBBBBBBBBQBBBBBBBBBB  B                                                        ");        
    $display("\033[37m   B  BBBBBBBBBdZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBBBBBBBBBBEji:..     sBBBBBBBr Br                                                       ");        
    $display("\033[37m  7B 7BBBBBBBr     .:vXQBBBBBBBBBBBBBBBBBBBBBBBBBQqui::..  ...i:i7777vi  BBBBBBr Bi                                                       ");        
    $display("\033[37m  Ki BBBBBBB  rY7vr:i....  .............:.....  ...:rii7vrr7r:..      7B  BBBBB  Bi                                                       ");        
    $display("\033[37m  B. BBBBBB  B:    .::ir77rrYLvvriiiiiiirvvY7rr77ri:..                 bU  iQBB:..rI                                                      ");        
    $display("\033[37m.S: 7BBBBP  B.                                                          vI7.  .:.  B.                                                     ");        
    $display("\033[37mB: ir:.   :B.                                                             :rvsUjUgU.                                                      ");        
    $display("\033[37mrMvrrirJKur                                                                                                                               \033[m");
    $display ("----------------------------------------------------------------------------------------------------------------------");
    $display ("                                                  Congratulations!                						             ");
    $display ("                                           You have passed all patterns!          						             ");
    $display ("                                           Your execution cycles = %5d cycles                                                            ", total_latency);
    $display ("                                           Your clock period = %.1f ns                                                               ", cycle);
    $display ("                                           Total Latency = %.1f ns                                                               ", total_latency*cycle);
    $display ("----------------------------------------------------------------------------------------------------------------------");     
    /*repeat(2)@(negedge clk);
    $display ("----------------------------------------------------------------------------------------------------------------------");*/

    $finish;	
end endtask

endprogram
