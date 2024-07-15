module bridge(input clk, INF.bridge_inf inf);
import usertype::*;

//================================================================
// State Type
//================================================================

typedef enum logic [2:0]{
    IDLE,
    WAIT_AR_READY,
    WAIT_R_VALID,
    CAL,
    CAL_DONE,
    WAIT_AW_READY,
    WAIT_W_READY,
    WAIT_B_VALID
} state_t;

//================================================================
// Declaration
//================================================================

// FSM
state_t      state, state_nxt;

// C_input
logic [ 7:0] C_addr, C_addr_nxt;
logic [63:0] C_data_w, C_data_w_nxt;

// C_output
logic        C_out_valid, C_out_valid_nxt;
logic [ 1:0] C_data_r, C_data_r_nxt;

logic [ 1:0] cnt_4, cnt_4_nxt;

// Read DRAM
logic        AR_VALID, AR_VALID_nxt;

logic        R_READY, R_READY_nxt;

// Write DRAM
logic        AW_VALID, AW_VALID_nxt;

logic        W_VALID, W_VALID_nxt;

logic        B_READY, B_READY_nxt;

// CAL
Action       act;

Date         date;

Barrel_No    box_no;

logic signed [12:0] sup_black_tea;
logic signed [12:0] sup_green_tea;
logic signed [12:0] sup_milk;
logic signed [12:0] sup_pineapple_juice;

Bev_Bal      cur_bev, cur_bev_nxt;

logic signed [12:0] add_a, add_b, add_z;

Error_Msg err_msg, err_msg_nxt;

//================================================================
// FSM
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : FSM_DFF
    if(!inf.rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_nxt;
    end
end

always_comb begin : FSM_COMB
    case (state)
        IDLE         : state_nxt = (inf.C_in_valid) ? WAIT_AR_READY : IDLE;
        WAIT_AR_READY: state_nxt = (inf.AR_READY  ) ? WAIT_R_VALID  : WAIT_AR_READY;
        WAIT_R_VALID : state_nxt = (inf.R_VALID   ) ? CAL           : WAIT_R_VALID;
        CAL          : state_nxt = (act[1])         ? CAL_DONE      : (((cnt_4 == 3) || ((err_msg == No_Ing) || (err_msg == No_Exp))) ? CAL_DONE : CAL);
        CAL_DONE     : state_nxt = (act[1])         ? IDLE          : (((err_msg == No_Ing) || (err_msg == No_Exp)) ? IDLE : WAIT_AW_READY);
        WAIT_AW_READY: state_nxt = (inf.AW_READY  ) ? WAIT_W_READY  : WAIT_AW_READY;
        WAIT_W_READY : state_nxt = (inf.W_READY   ) ? WAIT_B_VALID  : WAIT_W_READY;
        WAIT_B_VALID : state_nxt = (inf.B_VALID   ) ? IDLE          : WAIT_B_VALID;
    endcase
end

//================================================================
// Read DRAM
//================================================================

// WAIT_AR_READY
always_ff @(posedge clk or negedge inf.rst_n) begin : AR_VALID_DFF
    if(!inf.rst_n) begin
        AR_VALID <= 0;
    end
    else begin
        AR_VALID <= AR_VALID_nxt;
    end
end

always_comb begin : AR_VALID_COMB
    case (state)
        IDLE: begin
            if(inf.C_in_valid) begin
                AR_VALID_nxt = 1;
            end
            else begin
                AR_VALID_nxt = 0;
            end
        end
        WAIT_AR_READY: begin
            if(inf.AR_READY) begin
                AR_VALID_nxt = 0;
            end
            else begin
                AR_VALID_nxt = 1;
            end
        end
        default: begin
            AR_VALID_nxt = 0;
        end
    endcase
end

assign inf.AR_VALID = AR_VALID;

assign inf.AR_ADDR = {6'b100000, C_addr, 3'b000};

// WAIT_R_VALID
always_ff @(posedge clk or negedge inf.rst_n) begin : R_READY_DFF
    if(!inf.rst_n) begin
        R_READY <= 0;
    end
    else begin
        R_READY <= R_READY_nxt;
    end
end

always_comb begin : R_READY_COMB
    case (state)
        WAIT_AR_READY: begin
            if(inf.AR_READY) begin
                R_READY_nxt = 1;
            end
            else begin
                R_READY_nxt = 0;
            end
        end
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                R_READY_nxt = 0;
            end
            else begin
                R_READY_nxt = 1;
            end
        end
        default: begin
            R_READY_nxt = 0;
        end
    endcase
end

assign inf.R_READY = R_READY;

//================================================================
// Write DRAM
//================================================================

// WAIT_AW_READY
always_ff @(posedge clk or negedge inf.rst_n) begin : AW_VALID_DFF
    if(!inf.rst_n) begin
        AW_VALID <= 0;
    end
    else begin
        AW_VALID <= AW_VALID_nxt;
    end
end

always_comb begin : AW_VALID_COMB
    case (state)
        CAL_DONE: begin
            if((!act[1]) && !((err_msg == No_Ing) || (err_msg == No_Exp))) begin
                AW_VALID_nxt = 1;
            end
            else begin
                AW_VALID_nxt = 0;
            end
        end
        WAIT_AW_READY: begin
            if(inf.AW_READY) begin
                AW_VALID_nxt = 0;
            end
            else begin
                AW_VALID_nxt = 1;
            end
        end
        default: begin
            AW_VALID_nxt = 0;
        end
    endcase
end

assign inf.AW_VALID = AW_VALID;

assign inf.AW_ADDR = {6'b100000, C_addr, 3'b000};

// WAIT_W_READY
always_ff @(posedge clk or negedge inf.rst_n) begin : W_VALID_DFF
    if(!inf.rst_n) begin
        W_VALID <= 0;
    end
    else begin
        W_VALID <= W_VALID_nxt;
    end
end

always_comb begin : W_VALID_COMB
    case (state)
        WAIT_AW_READY: begin
            if(inf.AW_READY) begin
                W_VALID_nxt = 1;
            end
            else begin
                W_VALID_nxt = 0;
            end
        end
        WAIT_W_READY: begin
            if(inf.W_READY) begin
                W_VALID_nxt = 0;
            end
            else begin
                W_VALID_nxt = 1;
            end
        end
        default: begin
            W_VALID_nxt = 0;
        end
    endcase
end

assign inf.W_VALID = W_VALID;

assign inf.W_DATA = C_data_w;

// WAIT_B_VALID
always_ff @(posedge clk or negedge inf.rst_n) begin : B_READY_DFF
    if(!inf.rst_n) begin
        B_READY <= 0;
    end
    else begin
        B_READY <= B_READY_nxt;
    end
end

always_comb begin : B_READY_COMB
    case (state)
        WAIT_AW_READY: begin
            if(inf.AW_READY) begin
                B_READY_nxt = 1;
            end
            else begin
                B_READY_nxt = 0;
            end
        end
        WAIT_W_READY: begin
            B_READY_nxt = 1;
        end
        WAIT_B_VALID: begin
            if(inf.B_VALID) begin
                B_READY_nxt = 0;
            end
            else begin
                B_READY_nxt = 1;
            end
        end
        default: begin
            B_READY_nxt = 0;
        end
    endcase
end

assign inf.B_READY = B_READY;

//================================================================
// ???
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : C_addr_DFF
    if(!inf.rst_n) begin
        C_addr <= 0;
    end
    else begin
        C_addr <= C_addr_nxt;
    end
end

always_comb begin : C_addr_COMB
    C_addr_nxt = inf.C_addr;
end

always_ff @(posedge clk or negedge inf.rst_n) begin : C_data_w_DFF
    if(!inf.rst_n) begin
        C_data_w <= 0;
    end
    else begin
        C_data_w <= C_data_w_nxt;
    end
end

always_comb begin : C_data_w_COMB
    case (state)
        WAIT_R_VALID: begin
            C_data_w_nxt = inf.C_data_w;
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    C_data_w_nxt = {1'b0, sup_green_tea, sup_milk, act, date.M, sup_pineapple_juice, add_z, date.D};
                end
                Supply: begin
                    if(add_b[11:0] > ~add_a[11:0]) begin // supplement > 4095 - current beverage
                        C_data_w_nxt = {1'b0, sup_green_tea, sup_milk, act, date.M, sup_pineapple_juice, 13'd4095, date.D};
                    end
                    else begin
                        C_data_w_nxt = {1'b0, sup_green_tea, sup_milk, act, date.M, sup_pineapple_juice, add_z, date.D};
                    end
                end
                default: begin
                    C_data_w_nxt = inf.C_data_w;
                end
            endcase
        end
        CAL_DONE: begin
            case (act)
                Make_drink: begin
                    if(err_msg == No_Err) begin
                        C_data_w_nxt = {sup_black_tea[11:0], sup_green_tea[11:0], {4'b0, cur_bev.M}, sup_milk[11:0], sup_pineapple_juice[11:0], {3'b0, cur_bev.D}};
                    end
                    else begin
                        C_data_w_nxt = {cur_bev.black_tea, cur_bev.green_tea, {4'b0, cur_bev.M}, cur_bev.milk, cur_bev.pineapple_juice, {3'b0, cur_bev.D}};
                    end
                end
                Supply: begin
                    C_data_w_nxt = {sup_black_tea[11:0], sup_green_tea[11:0], {4'b0, cur_bev.M}, sup_milk[11:0], sup_pineapple_juice[11:0], {3'b0, cur_bev.D}};
                end
                default: begin
                    C_data_w_nxt = {cur_bev.black_tea, cur_bev.green_tea, {4'b0, cur_bev.M}, cur_bev.milk, cur_bev.pineapple_juice, {3'b0, cur_bev.D}};
                end
            endcase
        end
        default: begin
            C_data_w_nxt = C_data_w;
        end
    endcase
end

//================================================================
// CAL
//================================================================

// pattern data
// remind:
// assign inf.C_data_w = { 1'b0,                   // [63]
//                         sup_black_tea,          // [62:50]
//                         sup_green_tea,          // [49:37]
//                         act,                    // [36:35]
//                         date.M,                 // [34:31]
//                         sup_milk,               // [30:18]
//                         sup_pineapple_juice,    // [17: 5]
//                         date.D};                // [ 4: 0]
assign {sup_black_tea, sup_green_tea, act, date.M, sup_milk, sup_pineapple_juice, date.D} = C_data_w[62:0];

// dram data
always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_black_tea_DFF
    if(!inf.rst_n) begin
        cur_bev.black_tea <= 0;
    end
    else begin
        cur_bev.black_tea <= cur_bev_nxt.black_tea;
    end
end

always_comb begin : cur_bev_black_tea_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.black_tea = inf.R_DATA[63:52];
            end
            else begin
                cur_bev_nxt.black_tea = cur_bev.black_tea;
            end
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    cur_bev_nxt.black_tea = cur_bev.green_tea;
                end
                Supply: begin
                    if(inf.C_r_wb) begin
                        cur_bev_nxt.black_tea = cur_bev.green_tea;
                    end
                    else begin
                        cur_bev_nxt.black_tea = cur_bev.black_tea;
                    end
                end
                default: begin
                    cur_bev_nxt.black_tea = cur_bev.black_tea;
                end
            endcase
        end
        default: begin
            cur_bev_nxt.black_tea = cur_bev.black_tea;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_green_tea_DFF
    if(!inf.rst_n) begin
        cur_bev.green_tea <= 0;
    end
    else begin
        cur_bev.green_tea <= cur_bev_nxt.green_tea;
    end
end

always_comb begin : cur_bev_green_tea_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.green_tea = inf.R_DATA[51:40];
            end
            else begin
                cur_bev_nxt.green_tea = cur_bev.green_tea;
            end
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    cur_bev_nxt.green_tea = cur_bev.milk;
                end
                Supply: begin
                    if(inf.C_r_wb) begin
                        cur_bev_nxt.green_tea = cur_bev.milk;
                    end
                    else begin
                        cur_bev_nxt.green_tea = cur_bev.green_tea;
                    end
                end
                default: begin
                    cur_bev_nxt.green_tea = cur_bev.green_tea;
                end
            endcase
        end
        default: begin
            cur_bev_nxt.green_tea = cur_bev.green_tea;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_month_DFF
    if(!inf.rst_n) begin
        cur_bev.M <= 0;
    end
    else begin
        cur_bev.M <= cur_bev_nxt.M;
    end
end

always_comb begin : cur_bev_month_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.M = inf.R_DATA[35:32];
            end
            else begin
                cur_bev_nxt.M = cur_bev.M;
            end
        end
        CAL: begin
            if(inf.C_r_wb) begin
                cur_bev_nxt.M = date.M;
            end
            else begin
                cur_bev_nxt.M = cur_bev.M;
            end
        end
        default: begin
            cur_bev_nxt.M = cur_bev.M;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_milk_DFF
    if(!inf.rst_n) begin
        cur_bev.milk <= 0;
    end
    else begin
        cur_bev.milk <= cur_bev_nxt.milk;
    end
end

always_comb begin : cur_bev_milk_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.milk = inf.R_DATA[31:20];
            end
            else begin
                cur_bev_nxt.milk = cur_bev.milk;
            end
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    cur_bev_nxt.milk = cur_bev.pineapple_juice;
                end
                Supply: begin
                    if(inf.C_r_wb) begin
                        cur_bev_nxt.milk = cur_bev.pineapple_juice;
                    end
                    else begin
                        cur_bev_nxt.milk = cur_bev.milk;
                    end
                end
                default: begin
                    cur_bev_nxt.milk = cur_bev.milk;
                end
            endcase
        end
        default: begin
            cur_bev_nxt.milk = cur_bev.milk;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_pineapple_juice_DFF
    if(!inf.rst_n) begin
        cur_bev.pineapple_juice <= 0;
    end
    else begin
        cur_bev.pineapple_juice <= cur_bev_nxt.pineapple_juice;
    end
end

always_comb begin : cur_bev_pineapple_juice_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.pineapple_juice = inf.R_DATA[19:8];
            end
            else begin
                cur_bev_nxt.pineapple_juice = cur_bev.pineapple_juice;
            end
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    cur_bev_nxt.pineapple_juice = cur_bev.black_tea;
                end
                Supply: begin
                    if(inf.C_r_wb) begin
                        cur_bev_nxt.pineapple_juice = cur_bev.black_tea;
                    end
                    else begin
                        cur_bev_nxt.pineapple_juice = cur_bev.pineapple_juice;
                    end
                end
                default: begin
                    cur_bev_nxt.pineapple_juice = cur_bev.pineapple_juice;
                end
            endcase
        end
        default: begin
            cur_bev_nxt.pineapple_juice = cur_bev.pineapple_juice;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin : cur_bev_day_DFF
    if(!inf.rst_n) begin
        cur_bev.D <= 0;
    end
    else begin
        cur_bev.D <= cur_bev_nxt.D;
    end
end

always_comb begin : cur_bev_day_COMB
    case (state)
        WAIT_R_VALID: begin
            if(inf.R_VALID) begin
                cur_bev_nxt.D = inf.R_DATA[4:0];
            end
            else begin
                cur_bev_nxt.D = cur_bev.D;
            end
        end
        CAL: begin
            if(inf.C_r_wb) begin
                cur_bev_nxt.D = date.D;
            end
            else begin
                cur_bev_nxt.D = cur_bev.D;
            end
        end
        default: begin
            cur_bev_nxt.D = cur_bev.D;
        end
    endcase
end

// cnt_4
always_ff @(posedge clk or negedge inf.rst_n) begin : cnt_4_DFF
    if(!inf.rst_n) begin
        cnt_4 <= 0;
    end
    else begin
        cnt_4 <= cnt_4_nxt;
    end
end

always_comb begin : cnt_4_COMB
    case (state)
        CAL: begin
            case (act)
                Make_drink: begin
                    cnt_4_nxt = cnt_4 + 1;
                end
                Supply: begin
                    if(inf.C_r_wb) begin
                        cnt_4_nxt = cnt_4 + 1;
                    end
                    else begin
                        cnt_4_nxt = 0;
                    end
                end
                default: begin
                    cnt_4_nxt = 0;
                end
            endcase
        end
        default: begin
            cnt_4_nxt = 0;
        end
    endcase
end

// adder
assign add_a = cur_bev.black_tea;

assign add_b = sup_black_tea;

assign add_z = add_a + add_b;

// answer
always_ff @(posedge clk or negedge inf.rst_n) begin : err_msg_DFF
    if(!inf.rst_n) begin
        err_msg <= No_Err;
    end
    else begin
        err_msg <= err_msg_nxt;
    end
end

always_comb begin : err_msg_COMB
    case (state)
        IDLE: begin
            err_msg_nxt = No_Err;
        end
        CAL: begin
            case (act)
                Make_drink: begin
                    if((date.M > cur_bev.M) || ((date.M == cur_bev.M) && (date.D > cur_bev.D))) begin
                        err_msg_nxt = No_Exp;
                    end
                    else if(add_z[12]) begin
                        err_msg_nxt = No_Ing;
                    end
                    else begin
                        err_msg_nxt = err_msg;
                    end
                end
                Supply: begin
                    if((add_z[12]) && (inf.C_r_wb)) begin
                        err_msg_nxt = Ing_OF;
                    end
                    else begin
                        err_msg_nxt = err_msg;
                    end
                end
                Check_Valid_Date: begin
                    if((date.M > cur_bev.M) || ((date.M == cur_bev.M) && (date.D > cur_bev.D))) begin
                        err_msg_nxt = No_Exp;
                    end
                    else begin
                        err_msg_nxt = err_msg;
                    end
                end
                default: err_msg_nxt = err_msg;
            endcase 
        end
        default: begin
            err_msg_nxt = err_msg;
        end
    endcase
end

//================================================================
// Output
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin : C_out_valid_DFF
    if(!inf.rst_n) begin
        C_out_valid <= 0;
    end
    else begin
        C_out_valid <= C_out_valid_nxt;
    end
end

always_comb begin : C_out_valid_COMB
    case (state)
        CAL_DONE: begin
            case (act)
                Make_drink: begin
                    if((err_msg == No_Ing) || (err_msg == No_Exp)) begin
                        C_out_valid_nxt = 1;
                    end
                    else begin
                        C_out_valid_nxt = 0;
                    end
                end
                Check_Valid_Date: begin
                    C_out_valid_nxt = 1;
                end
                default: begin
                    C_out_valid_nxt = 0;
                end
            endcase
        end
        WAIT_B_VALID: begin
            if(inf.B_VALID) begin
                C_out_valid_nxt = 1;
            end
            else begin
                C_out_valid_nxt = 0;
            end
        end
        default: begin
            C_out_valid_nxt = 0;
        end
    endcase
end

assign inf.C_out_valid = C_out_valid;

always_ff @(posedge clk or negedge inf.rst_n) begin : C_data_r_DFF
    if(!inf.rst_n) begin
        C_data_r <= 0;
    end
    else begin
        C_data_r <= C_data_r_nxt;
    end
end

always_comb begin : C_data_r_COMB
    case (state)
        CAL_DONE: begin
            case (act)
                Make_drink: begin
                    if((err_msg == No_Ing) || (err_msg == No_Exp)) begin
                        C_data_r_nxt = err_msg;
                    end
                    else begin
                        C_data_r_nxt = 0;
                    end
                end
                Check_Valid_Date: begin
                    C_data_r_nxt = err_msg;
                end
                default: begin
                    C_data_r_nxt = 0;
                end
            endcase
        end
        WAIT_B_VALID: begin
            if(inf.B_VALID) begin
                C_data_r_nxt = err_msg;
            end
            else begin
                C_data_r_nxt = 0;
            end
        end
        default: begin
            C_data_r_nxt = 0;
        end
    endcase
end

assign inf.C_data_r = {62'b0, C_data_r};

endmodule