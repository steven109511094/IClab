/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/

Action act;

class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

Date date;

BEV bev_info = new();

always_ff @(posedge clk) begin
    if(inf.sel_action_valid) begin
        act = inf.D.d_act[0];
    end

    if(inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end

    if(inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end

    if(inf.date_valid) begin
        date.M = inf.D.d_date[0][8:5];
        date.D = inf.D.d_date[0][4:0];
    end
end

/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

covergroup Spec1 @(posedge clk iff inf.type_valid);
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/

covergroup Spec2 @(posedge clk iff inf.size_valid);
    option.per_instance = 1;
    option.at_least = 100;
    bsize:coverpoint bev_info.bev_size{
        bins b_bev_size [] = {[L:S]};
    }
endgroup

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/

covergroup Spec3 @(posedge clk iff inf.date_valid);
    option.per_instance = 1;
    option.at_least = 100;
    cross bev_info.bev_type, bev_info.bev_size;
endgroup

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/

covergroup Spec4 @(posedge clk iff inf.out_valid);
    option.per_instance = 1;
    option.at_least = 20;
    coverpoint inf.err_msg {
        bins err[] = {[No_Err:Ing_OF]};
    }
endgroup

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/

covergroup Spec5 @(posedge clk iff inf.sel_action_valid);
    option.per_instance = 1;
    option.at_least = 200;
    coverpoint inf.D.d_act[0] {
        bins act_trans [] = ([0:2] => [0:2]);
    }
endgroup

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/

covergroup Spec6 @(posedge clk iff inf.box_sup_valid);
    option.per_instance = 1;
    option.at_least = 1;
    coverpoint inf.D.d_ing[0] {
        option.auto_bin_max = 32;
    }
endgroup

/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/

Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();
Spec6 cov_inst_6 = new();

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/

parameter integer day   [0:11] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}; // actual day in each month

logic [1:0] cnt_4, cnt_4_nxt;

logic busy, busy_nxt;

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

always @(negedge inf.rst_n) begin
    #1; // delay for changing signal
    assert_1: assert (
        // BEV
        (inf.out_valid === 0) && (inf.err_msg === No_Err) && (inf.complete === 0) &&
        (inf.C_in_valid === 0) && (inf.C_r_wb === 0) && (inf.C_addr === 0) && (inf.C_data_w === 0) && 
        // bridge
        (inf.C_out_valid === 0) && (inf.C_data_r === 0) && 
        (inf.AR_VALID === 0) && (inf.AR_ADDR === 0) && (inf.R_READY === 0) && 
        (inf.AW_VALID === 0) && (inf.AW_ADDR === 0) && (inf.W_VALID === 0) && (inf.W_DATA === 0) && (inf.B_READY === 0)
    )
    else begin
        $fatal(0, "Assertion 1 is violated");
    end
end

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/

always_ff @(negedge clk or negedge inf.rst_n) begin : cnt_4_DFF
    if(!inf.rst_n) begin
        cnt_4 <= 0;
    end
    else begin
        cnt_4 <= cnt_4_nxt;
    end
end

always_comb begin : cnt_4_COMB
    if(inf.box_sup_valid) begin
        cnt_4_nxt = cnt_4 + 1;
    end
    else if(inf.out_valid) begin
        cnt_4_nxt = 0;
    end
    else begin
        cnt_4_nxt = cnt_4;
    end
end

property property_2_1;
    @(negedge clk) (
        (act == Make_drink) && (inf.box_no_valid === 1)
    ) |-> (##[1:1000] inf.out_valid);
endproperty: property_2_1

assert_2_1: assert property (property_2_1) else $fatal(0, "Assertion 2 is violated");

property property_2_2;
    @(negedge clk) (
        (act == Supply) && (inf.box_sup_valid === 1) && (cnt_4 == 3)
    ) |-> (##[1:1000] inf.out_valid);
endproperty: property_2_2

assert_2_2: assert property (property_2_2) else $fatal(0, "Assertion 2 is violated");

property property_2_3;
    @(negedge clk) (
        (act == Check_Valid_Date) && (inf.box_no_valid === 1)
    ) |-> (##[1:1000] inf.out_valid);
endproperty: property_2_3

assert_2_3: assert property (property_2_3) else $fatal(0, "Assertion 2 is violated");

/*
    3. If out_valid does not pull up, complete should be 0. -><- Lab09.pdf
*/

/*
    3. If action is completed (complete=1), err_msg should be 2’b0 (no_err).
*/

property property_3;
    @(negedge clk) (
        inf.complete === 1
    ) |-> (inf.err_msg === No_Err);
endproperty: property_3

assert_3: assert property (property_3) else $fatal(0, "Assertion 3 is violated");

/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/

// Make_drink input order:
// Sel_action -> Beverage Type -> Beverage Size -> Today’s Date -> No. of Ingredient barrel in DRAM.
property property_4_1_1;
    @(negedge clk) (
        (act == Make_drink) && (inf.sel_action_valid === 1)
    ) |=> (##[0:3] inf.type_valid === 1);
endproperty: property_4_1_1

assert_4_1_1: assert property (property_4_1_1) else $fatal(0, "Assertion 4 is violated");

property property_4_1_2;
    @(negedge clk) (
        (act == Make_drink) && (inf.type_valid === 1)
    ) |=> (##[0:3] inf.size_valid === 1);
endproperty: property_4_1_2

assert_4_1_2: assert property (property_4_1_2) else $fatal(0, "Assertion 4 is violated");

property property_4_1_3;
    @(negedge clk) (
        (act == Make_drink) && (inf.size_valid === 1)
    ) |=> (##[0:3] inf.date_valid === 1);
endproperty: property_4_1_3

assert_4_1_3: assert property (property_4_1_3) else $fatal(0, "Assertion 4 is violated");

property property_4_1_4;
    @(negedge clk) (
        (act == Make_drink) && (inf.date_valid === 1)
    ) |=> (##[0:3] inf.box_no_valid === 1);
endproperty: property_4_1_4

assert_4_1_4: assert property (property_4_1_4) else $fatal(0, "Assertion 4 is violated");

// Supply input order:
// Sel_action -> Expired Date -> No. of Ingredient barrel in DRAM -> Black_Tea -> Green_Tea -> Milk -> Pineapple Juice.
property property_4_2_1;
    @(negedge clk) (
        (act == Supply) && (inf.sel_action_valid === 1)
    ) |=> (##[0:3] inf.date_valid === 1);
endproperty: property_4_2_1

assert_4_2_1: assert property (property_4_2_1) else $fatal(0, "Assertion 4 is violated");

property property_4_2_2;
    @(negedge clk) (
        (act == Supply) && (inf.date_valid === 1)
    ) |=> (##[0:3] inf.box_no_valid === 1);
endproperty: property_4_2_2

assert_4_2_2: assert property (property_4_2_2) else $fatal(0, "Assertion 4 is violated");

property property_4_2_3;
    @(negedge clk) (
        (act == Supply) && (inf.box_no_valid === 1)
    ) |=> (##[0:3] inf.box_sup_valid === 1);
endproperty: property_4_2_3

assert_4_2_3: assert property (property_4_2_3) else $fatal(0, "Assertion 4 is violated");

property property_4_2_4;
    @(negedge clk) (
        (act == Supply) && (inf.box_sup_valid === 1) && (cnt_4 != 3)
    ) |=> (##[0:3] inf.box_sup_valid === 1);
endproperty: property_4_2_4

assert_4_2_4: assert property (property_4_2_4) else $fatal(0, "Assertion 4 is violated");

// Check_Valid_Date input order:
// Sel_action -> Today’s Date -> No. of Ingredient box in DRAM.
property property_4_3_1;
    @(negedge clk) (
        (act == Check_Valid_Date) && (inf.sel_action_valid === 1)
    ) |=> (##[0:3] inf.date_valid === 1);
endproperty: property_4_3_1

assert_4_3_1: assert property (property_4_3_1) else $fatal(0, "Assertion 4 is violated");

property property_4_3_2;
    @(negedge clk) (
        (act == Check_Valid_Date) && (inf.date_valid === 1)
    ) |=> (##[0:3] inf.box_no_valid === 1);
endproperty: property_4_3_2

assert_4_3_2: assert property (property_4_3_2) else $fatal(0, "Assertion 4 is violated");

/*
    5. All input valid signals won't overlap with each other. 
*/

property property_5_1;
    @(posedge clk iff inf.sel_action_valid) (
        !((inf.type_valid) || (inf.size_valid) || (inf.date_valid) || (inf.box_no_valid) || (inf.box_sup_valid))
    );
endproperty: property_5_1

assert_5_1: assert property (property_5_1) else $fatal(0, "Assertion 5 is violated");

property property_5_2;
    @(posedge clk iff inf.type_valid) (
        !((inf.size_valid) || (inf.date_valid) || (inf.box_no_valid) || (inf.box_sup_valid))
    );
endproperty: property_5_2

assert_5_2: assert property (property_5_2) else $fatal(0, "Assertion 5 is violated");

property property_5_3;
    @(posedge clk iff inf.size_valid) (
        !((inf.date_valid) || (inf.box_no_valid) || (inf.box_sup_valid))
    );
endproperty: property_5_3

assert_5_3: assert property (property_5_3) else $fatal(0, "Assertion 5 is violated");

property property_5_4;
    @(posedge clk iff inf.date_valid) (
        !((inf.box_no_valid) || (inf.box_sup_valid))
    );
endproperty: property_5_4

assert_5_4: assert property (property_5_4) else $fatal(0, "Assertion 5 is violated");

property property_5_5;
    @(posedge clk iff inf.box_no_valid) (
        !(inf.box_sup_valid)
    );
endproperty: property_5_5

assert_5_5: assert property (property_5_5) else $fatal(0, "Assertion 5 is violated");

/*
    6. Out_valid can only be high for exactly one cycle.
*/

property property_6;
    @(posedge clk) (
        inf.out_valid === 1
    ) |=> inf.out_valid === 0;
endproperty: property_6

assert_6: assert property (property_6) else $fatal(0, "Assertion 6 is violated");

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/

property property_7;
    @(posedge clk) (
        inf.out_valid === 1
    ) |=> (##[0:3] inf.sel_action_valid === 1);
endproperty: property_7

assert_7: assert property (property_7) else $fatal(0, "Assertion 7 is violated");

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

property property_8_1;
    @(negedge clk iff inf.date_valid) (
        (date.M >= 1) && (date.M <= 12)
    );
endproperty: property_8_1

assert_8_1: assert property (property_8_1) else $fatal(0, "Assertion 8 is violated");

property property_8_2;
    @(negedge clk iff inf.date_valid) (
        (date.D >= 1) && (date.D <= day[date.M - 1])
    );
endproperty: property_8_2

assert_8_2: assert property (property_8_2) else $fatal(0, "Assertion 8 is violated");

/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/

always_ff @(posedge clk or negedge inf.rst_n) begin : busy_DFF
    if(!inf.rst_n) begin
        busy <= 0;
    end
    else begin
        busy <= busy_nxt;
    end
end

always_comb begin : busy_COMB
    if(inf.C_in_valid) begin
        busy_nxt = 1;
    end
    else if(inf.C_out_valid) begin
        busy_nxt = 0;
    end
    else begin
        busy_nxt = busy;
    end
end

property property_9_1;
    @(posedge clk) (
        inf.C_in_valid === 1
    ) |=> (inf.C_in_valid === 0);
endproperty: property_9_1

assert_9_1: assert property (property_9_1) else $fatal(0, "Assertion 9 is violated");

property property_9_2;
    @(posedge clk iff busy == 1) (
        inf.C_in_valid === 0
    );
endproperty: property_9_2

assert_9_2: assert property (property_9_2) else $fatal(0, "Assertion 9 is violated");

endmodule
