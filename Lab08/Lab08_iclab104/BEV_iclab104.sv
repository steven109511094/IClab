module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.

//================================================================
// State Type
//================================================================

/*typedef enum logic  [1:0] { IDLE    = 2'h0, 
                            INPUT   = 2'h1,
                            CAL     = 2'h2,
                            OUTPUT  = 2'h3
} state_t;*/

//================================================================
// Declaration
//================================================================

// FSM
//state_t      state, state_nxt;

// INPUT
Action       act, act_nxt;

Order_Info   order, order_nxt;

Date         date, date_nxt;

Barrel_No    box_no, box_no_nxt;

logic signed [12:0] sup_black_tea      , sup_black_tea_nxt;
logic signed [12:0] sup_green_tea      , sup_green_tea_nxt;
logic signed [12:0] sup_milk           , sup_milk_nxt;
logic signed [12:0] sup_pineapple_juice, sup_pineapple_juice_nxt;

logic signed [12:0] need_black_tea;
logic signed [12:0] need_green_tea;
logic signed [12:0] need_milk;
logic signed [12:0] need_pineapple_juice;

logic [ 1:0] cnt_4, cnt_4_nxt;

// CAL
logic        C_in_valid, C_in_valid_nxt;

logic        C_r_wb, C_r_wb_nxt; // 1: box_sup input ready

// OUTPUT
logic        out_valid, out_valid_nxt;

Error_Msg    err_msg, err_msg_nxt;

logic        complete, complete_nxt;

//================================================================
// FSM
//================================================================

/*always_ff @(posedge clk or negedge inf.rst_n) begin : FSM_DFF
    if(!inf.rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_nxt;
    end
end

always_comb begin : FSM_COMB
    case (state)
        IDLE: begin
            if(inf.sel_action_valid) begin
                state_nxt = INPUT;
            end
            else begin
                state_nxt = IDLE;
            end
        end
        INPUT: begin
            if(act[0]) begin // Supply
                if((inf.box_sup_valid) && (cnt_4 == 3)) begin
                    state_nxt = CAL;
                end
                else begin
                    state_nxt = INPUT;
                end
            end
            else begin // Make_drink, Check_Valid_Dat
                if(inf.box_no_valid) begin
                    state_nxt = CAL;
                end
                else begin
                    state_nxt = INPUT;
                end
            end
        end
        CAL: begin
            if(inf.C_out_valid) begin
                state_nxt = OUTPUT;
            end
            else begin
                state_nxt = CAL;
            end
        end
        OUTPUT: begin
            state_nxt = IDLE;
        end
    endcase
end*/

//================================================================
// INPUT
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : act_DFF
    if(!inf.rst_n) begin
        act <= Make_drink;
    end
    else begin
        act <= act_nxt;
    end
end

always_comb begin : act_COMB
    if(inf.sel_action_valid) begin
        act_nxt = inf.D.d_act[0];
    end
    else begin
        act_nxt = act;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : type_DFF
    if(!inf.rst_n) begin
        order.Bev_Type_O <= Black_Tea;
    end
    else begin
        order.Bev_Type_O <= order_nxt.Bev_Type_O;
    end
end

always_comb begin : type_COMB
    if(inf.type_valid) begin
        order_nxt.Bev_Type_O = inf.D.d_type[0];
    end
    else begin
        order_nxt.Bev_Type_O = order.Bev_Type_O;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : size_DFF
    if(!inf.rst_n) begin
        order.Bev_Size_O <= L;
    end
    else begin
        order.Bev_Size_O <= order_nxt.Bev_Size_O;
    end
end

always_comb begin : size_COMB
    if(inf.size_valid) begin
        order_nxt.Bev_Size_O = inf.D.d_size[0];
    end
    else begin
        order_nxt.Bev_Size_O = order.Bev_Size_O;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : month_DFF
    if(!inf.rst_n) begin
        date.M <= 0;
    end
    else begin
        date.M <= date_nxt.M;
    end
end

always_comb begin : month_COMB
    if(inf.date_valid) begin
        date_nxt.M = inf.D.d_date[0][8:5];
    end
    else begin
        date_nxt.M = date.M;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : day_DFF
    if(!inf.rst_n) begin
        date.D <= 0;
    end
    else begin
        date.D <= date_nxt.D;
    end
end

always_comb begin : day_COMB
    if(inf.date_valid) begin
        date_nxt.D = inf.D.d_date[0][4:0];
    end
    else begin
        date_nxt.D = date.D;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : sup_black_tea_DFF
    if(!inf.rst_n) begin
        sup_black_tea <= 0;
    end
    else begin
        sup_black_tea <= sup_black_tea_nxt;
    end
end

always_comb begin : sup_black_tea_COMB
    if((inf.box_sup_valid) && !(cnt_4)) begin
        sup_black_tea_nxt = {1'b0, inf.D.d_ing[0]};
    end
    else if(act == Make_drink) begin
        sup_black_tea_nxt = need_black_tea;
    end
    else begin
        sup_black_tea_nxt = sup_black_tea;
    end
end

always_comb begin : need_black_tea_COMB
    case (order.Bev_Type_O)
        Black_Tea: begin
            case (order.Bev_Size_O)
                L: need_black_tea = -960; 
                M: need_black_tea = -720; 
                S: need_black_tea = -480; 
                default: need_black_tea = 0; 
            endcase
        end
        Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_black_tea = -720; 
                M: need_black_tea = -540; 
                S: need_black_tea = -360; 
                default: need_black_tea = 0; 
            endcase
        end
        Extra_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_black_tea = -480; 
                M: need_black_tea = -360; 
                S: need_black_tea = -240; 
                default: need_black_tea = 0; 
            endcase
        end
        Super_Pineapple_Tea: begin
            case (order.Bev_Size_O)
                L: need_black_tea = -480; 
                M: need_black_tea = -360; 
                S: need_black_tea = -240; 
                default: need_black_tea = 0; 
            endcase
        end
        Super_Pineapple_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_black_tea = -480; 
                M: need_black_tea = -360; 
                S: need_black_tea = -240; 
                default: need_black_tea = 0; 
            endcase
        end
        default: need_black_tea = 0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : sup_green_tea_DFF
    if(!inf.rst_n) begin
        sup_green_tea <= 0;
    end
    else begin
        sup_green_tea <= sup_green_tea_nxt;
    end
end

always_comb begin : sup_green_tea_COMB
    if((inf.box_sup_valid) && (cnt_4 == 1)) begin
        sup_green_tea_nxt = {1'b0, inf.D.d_ing[0]};
    end
    else if(act == Make_drink) begin
        sup_green_tea_nxt = need_green_tea;
    end
    else begin
        sup_green_tea_nxt = sup_green_tea;
    end
end

always_comb begin : need_green_tea_COMB
    case (order.Bev_Type_O)
        Green_Tea: begin
            case (order.Bev_Size_O)
                L: need_green_tea = -960; 
                M: need_green_tea = -720; 
                S: need_green_tea = -480; 
                default: need_green_tea = 0; 
            endcase
        end
        Green_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_green_tea = -480; 
                M: need_green_tea = -360; 
                S: need_green_tea = -240; 
                default: need_green_tea = 0; 
            endcase
        end
        default: need_green_tea = 0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : sup_milk_DFF
    if(!inf.rst_n) begin
        sup_milk <= 0;
    end
    else begin
        sup_milk <= sup_milk_nxt;
    end
end

always_comb begin : sup_milk_COMB
    if((inf.box_sup_valid) && (cnt_4 == 2)) begin
        sup_milk_nxt = {1'b0, inf.D.d_ing[0]};
    end
    else if(act == Make_drink) begin
        sup_milk_nxt = need_milk;
    end
    else begin
        sup_milk_nxt = sup_milk;
    end
end

always_comb begin : need_milk_COMB
    case (order.Bev_Type_O)
        Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_milk = -240; 
                M: need_milk = -180; 
                S: need_milk = -120; 
                default: need_milk = 0; 
            endcase
        end
        Extra_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_milk = -480; 
                M: need_milk = -360; 
                S: need_milk = -240; 
                default: need_milk = 0; 
            endcase
        end
        Green_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_milk = -480; 
                M: need_milk = -360; 
                S: need_milk = -240; 
                default: need_milk = 0; 
            endcase
        end
        Super_Pineapple_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_milk = -240; 
                M: need_milk = -180; 
                S: need_milk = -120; 
                default: need_milk = 0; 
            endcase
        end
        default: need_milk = 0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : sup_pineapple_juice_DFF
    if(!inf.rst_n) begin
        sup_pineapple_juice <= 0;
    end
    else begin
        sup_pineapple_juice <= sup_pineapple_juice_nxt;
    end
end

always_comb begin : sup_pineapple_juice_COMB
    if((inf.box_sup_valid) && (cnt_4 == 3)) begin
        sup_pineapple_juice_nxt = {1'b0, inf.D.d_ing[0]};
    end
    else if(act == Make_drink) begin
        sup_pineapple_juice_nxt = need_pineapple_juice;
    end
    else begin
        sup_pineapple_juice_nxt = sup_pineapple_juice;
    end
end

always_comb begin : need_pineapple_juice_COMB
    case (order.Bev_Type_O)
        Pineapple_Juice: begin
            case (order.Bev_Size_O)
                L: need_pineapple_juice = -960; 
                M: need_pineapple_juice = -720; 
                S: need_pineapple_juice = -480; 
                default: need_pineapple_juice = 0; 
            endcase
        end
        Super_Pineapple_Tea: begin
            case (order.Bev_Size_O)
                L: need_pineapple_juice = -480; 
                M: need_pineapple_juice = -360; 
                S: need_pineapple_juice = -240; 
                default: need_pineapple_juice = 0; 
            endcase
        end
        Super_Pineapple_Milk_Tea: begin
            case (order.Bev_Size_O)
                L: need_pineapple_juice = -240; 
                M: need_pineapple_juice = -180; 
                S: need_pineapple_juice = -120; 
                default: need_pineapple_juice = 0; 
            endcase
        end
        default: need_pineapple_juice = 0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cnt_4_DFF
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
    else begin
        cnt_4_nxt = cnt_4;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : box_no_DFF
    if(!inf.rst_n) begin
        box_no <= 0;
    end
    else begin
        box_no <= box_no_nxt;
    end
end

always_comb begin : box_no_COMB
    if(inf.box_no_valid) begin
        box_no_nxt = inf.D.d_box_no[0];
    end
    else begin
        box_no_nxt = box_no;
    end
end

// For debug
//logic here;
//assign here = (box_no == 219) ? 1 : 0;

//================================================================
// CAL
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : C_in_valid_DFF
    if(!inf.rst_n) begin
        C_in_valid <= 0;
    end
    else begin
        C_in_valid <= C_in_valid_nxt;
    end
end

always_comb begin : C_in_valid_COMB
    if(inf.box_no_valid) begin
        C_in_valid_nxt = 1;
    end
    else begin
        C_in_valid_nxt = 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : C_r_wb_DFF
    if(!inf.rst_n) begin
        C_r_wb <= 0;
    end
    else begin
        C_r_wb <= C_r_wb_nxt;
    end
end

always_comb begin : C_r_wb_COMB
    if((inf.box_sup_valid) && (cnt_4 == 3)) begin
        C_r_wb_nxt = 1;
    end
    else if(out_valid) begin
        C_r_wb_nxt = 0;
    end
    else begin
        C_r_wb_nxt = C_r_wb;
    end
end

assign inf.C_in_valid = C_in_valid;
assign inf.C_r_wb = C_r_wb;
assign inf.C_addr = box_no;
assign inf.C_data_w = { 1'b0,                   // [63]
                        sup_black_tea,          // [62:50]
                        sup_green_tea,          // [49:37]
                        act,                    // [36:35]
                        date.M,                 // [34:31]
                        sup_milk,               // [30:18]
                        sup_pineapple_juice,    // [17: 5]
                        date.D};                // [ 4: 0]

//================================================================
// OUTPUT
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : out_valid_DFF
    if(!inf.rst_n) begin
        out_valid <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
    end
end

always_comb begin : out_valid_COMB
    if(inf.C_out_valid) begin
        out_valid_nxt = 1;
    end
    else begin
        out_valid_nxt = 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : err_msg_DFF
    if(!inf.rst_n) begin
        err_msg <= No_Err;
    end
    else begin
        err_msg <= err_msg_nxt;
    end
end

always_comb begin : err_msg_COMB
    if(inf.C_out_valid) begin
        err_msg_nxt = inf.C_data_r[1:0];
    end
    else begin
        err_msg_nxt = 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin : complete_DFF
    if(!inf.rst_n) begin
        complete <= 0;
    end
    else begin
        complete <= complete_nxt;
    end
end

always_comb begin : complete_COMB
    if(inf.C_out_valid) begin
        complete_nxt = !(inf.C_data_r[1:0]);
    end
    else begin
        complete_nxt = 0;
    end
end

assign inf.out_valid = out_valid;
assign inf.err_msg = err_msg;
assign inf.complete = complete;

endmodule

//always_ff @(posedge clk or negedge inf.rst_n) begin : blockName_DFF
//    if(!inf.rst_n) begin
//        
//    end
//    else begin
//        
//    end
//end

//always_comb begin : blockName_COMB
//    
//end
//
//black_tea;
//green_tea;
//milk;
//pineapple_juice;