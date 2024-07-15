module PREFIX (
    // input port
    clk,
    rst_n,
    in_valid,
    opt,
    in_data,
    // output port
    out_valid,
    out
);

input clk;
input rst_n;
input in_valid;
input opt;
input [4:0] in_data;
output reg out_valid;
output reg signed [94:0] out;

// parameter
parameter   IDLE            = 0,
            IN              = 1,
            EVALUATE        = 2,
            EVALUATE_CHECK  = 3,
            SCAN            = 4,
            CMP_PRIOR       = 5,
            POP_ALL_OP      = 6,
            OUT             = 7;

parameter   add = 2'b00,
            sub = 2'b01,
            mul = 2'b10,
            div = 2'b11;

integer i;

// reg & wire
reg  [2:0] state;
reg  [2:0] state_nxt;

reg  in_valid_reg;
wire in_valid_nxt;

reg  opt_reg;
wire opt_nxt;

reg  [ 4:0] in_data_reg;
wire [ 4:0] in_data_nxt;

// evaluate
reg  signed [40:0] stack [18:0];
reg  signed [40:0] stack_nxt [18:0];

reg  [ 0:0] num_or_op [18:0]; // 0: op, 1: num
reg  [ 0:0] num_or_op_nxt [18:0];

reg  [ 4:0] cnt_eva_1;
reg  [ 4:0] cnt_eva_1_nxt;

reg  [ 3:0] cnt_eva_2;
reg  [ 3:0] cnt_eva_2_nxt;

wire signed [40:0] num1;
wire signed [40:0] num2;
wire signed [40:0] op;

wire  num1_check;
wire  num2_check;
wire  op_check;

wire signed [40:0] add_ans;
wire signed [40:0] sub_ans;
wire signed [40:0] mul_ans;
wire signed [40:0] div_ans;

// infix to prefix
reg  [4:0] RPE [19];
reg  [4:0] RPE_nxt [19];

reg  [4:0] op_stack [9];
reg  [4:0] op_stack_nxt [9];

reg  [3:0] cnt_op;
reg  [3:0] cnt_op_nxt;

reg  [4:0] cnt_scan;
reg  [4:0] cnt_scan_nxt;

reg  [4:0] cur_op;
reg  [4:0] cur_op_nxt;

// output
reg  signed [94:0] out_nxt;
reg  out_valid_nxt;

//============================================
//                  FSM
//============================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_nxt;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) begin
                state_nxt = IN;
            end
            else begin
                state_nxt = IDLE;
            end
        end
        IN: begin
            if(in_valid) begin
                state_nxt = IN;
            end
            else begin
                if(!opt_reg) begin
                    state_nxt = EVALUATE;
                end
                else begin
                    state_nxt = SCAN;
                end
            end
        end
        EVALUATE: begin
            if((num1_check) && (num2_check) && (!op_check)) begin
                state_nxt = EVALUATE_CHECK;
            end
            else begin
                state_nxt = EVALUATE;
            end
        end
        EVALUATE_CHECK: begin
            if(cnt_eva_2 == 9) begin
                state_nxt = OUT;
            end
            else begin
                state_nxt = EVALUATE;
            end
        end
        SCAN: begin
            if(cnt_scan == 18) begin
                state_nxt = POP_ALL_OP;
            end
            else if(num_or_op[0] == 1) begin // if top one of reserve of origin stack is operand
                state_nxt = SCAN;
            end
            else if(cnt_op == 0) begin // if operator stack is empty
                state_nxt = SCAN;
            end
            else begin
                state_nxt = CMP_PRIOR;
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin // if operator stack is empty
                state_nxt = SCAN;
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin // if current operator is smaller to the top one of operator stack
                state_nxt = CMP_PRIOR;
            end
            else begin
                state_nxt = SCAN;
            end
        end
        POP_ALL_OP: begin
            if(cnt_op == 0) begin
                state_nxt = OUT;
            end
            else begin
                state_nxt = POP_ALL_OP;
            end
        end
        OUT: begin
            state_nxt = IDLE;
        end
        default: begin
            state_nxt = IDLE;
        end
    endcase
end

//============================================
//                  INPUT
//============================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_reg <= 0;
    end
    else begin
        in_valid_reg <= in_valid_nxt;
    end
end

assign in_valid_nxt = in_valid;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        opt_reg <= 0;
    end
    else begin
        opt_reg <= opt_nxt;
    end
end

assign opt_nxt = (in_valid && !in_valid_reg) ? opt : opt_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_data_reg <= 0;
    end
    else begin
        in_data_reg <= in_data_nxt;
    end
end

assign in_data_nxt = (in_valid) ? in_data : in_data_reg;

//============================================
//                  EVALUATE
//============================================

assign num1 = stack[cnt_eva_1 + 0];
assign num2 = stack[cnt_eva_1 + 1];
assign op = stack[cnt_eva_1 + 2];

assign num1_check = num_or_op[cnt_eva_1 + 0];
assign num2_check = num_or_op[cnt_eva_1 + 1];
assign op_check = num_or_op[cnt_eva_1 + 2];

assign add_ans = num2 + num1;
assign sub_ans = num2 - num1;
assign mul_ans = num2 * num1;
assign div_ans = num2 / num1;

// cnt_eva_1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_eva_1 <= 0;
    end
    else begin
        cnt_eva_1 <= cnt_eva_1_nxt;
    end
end

always @(*) begin
    case (state)
        EVALUATE: begin
            if((num1_check) && (num2_check) && (!op_check)) begin // num, num, op
                cnt_eva_1_nxt = 0;
            end
            else begin
                cnt_eva_1_nxt = cnt_eva_1 + 1;
            end
        end 
        default: begin
            cnt_eva_1_nxt = 0;
        end
    endcase
end

// cnt_eva_2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_eva_2 <= 0;
    end
    else begin
        cnt_eva_2 <= cnt_eva_2_nxt;
    end
end

always @(*) begin
    case (state)
        EVALUATE: begin
            if((num1_check) && (num2_check) && (!op_check)) begin // num1, num2, op
                cnt_eva_2_nxt = cnt_eva_2 + 1;
            end
            else begin
                cnt_eva_2_nxt = cnt_eva_2;
            end
        end 
        EVALUATE_CHECK: begin
            cnt_eva_2_nxt = cnt_eva_2;
        end
        default: begin
            cnt_eva_2_nxt = 0;
        end
    endcase
end

// num or op
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 19; i = i + 1) begin
            num_or_op[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 19; i = i + 1) begin
            num_or_op[i] <= num_or_op_nxt[i];
        end
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            for(i = 0; i < 19; i = i + 1) begin
                num_or_op_nxt[i] = 0;
            end
        end
        IN: begin
            num_or_op_nxt[0] = (in_data_reg[4]) ? 0 : 1;
            for(i = 1; i < 19; i = i + 1) begin
                num_or_op_nxt[i] = num_or_op[i - 1];
            end
        end
        EVALUATE: begin
            if((num1_check) && (num2_check) && (!op_check)) begin
                for(i = 0; i < 19; i = i + 1) begin
                    if(i < cnt_eva_1) begin
                        num_or_op_nxt[i] = num_or_op[i];
                    end
                    else if(i == cnt_eva_1) begin
                        num_or_op_nxt[i] = 1;
                    end
                    else if(i < 17 - cnt_eva_2*2) begin
                        num_or_op_nxt[i] = num_or_op[i + 2];
                    end
                    else begin
                        num_or_op_nxt[i] = 0;
                    end
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    num_or_op_nxt[i] = num_or_op[i];
                end
            end
        end
        SCAN: begin
            if(cnt_scan < 18) begin
                if(num_or_op[0] == 1) begin
                    for(i = 0; i < 18; i = i + 1) begin
                        num_or_op_nxt[i] = num_or_op[i + 1];
                    end
                    num_or_op_nxt[18] = 0;
                end
                else if(cnt_op == 0) begin
                    for(i = 0; i < 18; i = i + 1) begin
                        num_or_op_nxt[i] = num_or_op[i + 1];
                    end
                    num_or_op_nxt[18] = 0;
                end
                else begin
                    for(i = 0; i < 19; i = i + 1) begin
                        num_or_op_nxt[i] = num_or_op[i];
                    end
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    num_or_op_nxt[i] = num_or_op[i];
                end
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin
                for(i = 0; i < 18; i = i + 1) begin
                    num_or_op_nxt[i] = num_or_op[i + 1];
                end
                num_or_op_nxt[18] = 0;
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin
                for(i = 0; i < 19; i = i + 1) begin
                    num_or_op_nxt[i] = num_or_op[i];
                end
            end
            else begin
                for(i = 0; i < 18; i = i + 1) begin
                    num_or_op_nxt[i] = num_or_op[i + 1];
                end
                num_or_op_nxt[18] = 0;
            end
        end
        default: begin
            for(i = 0; i < 19; i = i + 1) begin
                num_or_op_nxt[i] = num_or_op[i];
            end
        end
    endcase
end

// stack
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 19; i = i + 1) begin
            stack[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 19; i = i + 1) begin
            stack[i] <= stack_nxt[i];
        end
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            for(i = 0; i < 19; i = i + 1) begin
                stack_nxt[i] = 0;
            end
        end
        IN: begin
            stack_nxt[0] = in_data_reg;
            for(i = 1; i < 19; i = i + 1) begin
                stack_nxt[i] = stack[i - 1];
            end
        end
        EVALUATE: begin
            if((num1_check) && (num2_check) && (!op_check)) begin
                for(i = 0; i < 19; i = i + 1) begin
                    if(i < cnt_eva_1) begin
                        stack_nxt[i] = stack[i];
                    end
                    else if (i == cnt_eva_1) begin
                        case (op[1:0])
                            add: stack_nxt[i] = add_ans;
                            sub: stack_nxt[i] = sub_ans;
                            mul: stack_nxt[i] = mul_ans;
                            div: stack_nxt[i] = div_ans;
                        endcase
                    end
                    else if(i < 17 - cnt_eva_2*2) begin
                        stack_nxt[i] = stack[i + 2];
                    end
                    else begin
                        stack_nxt[i] = 0;
                    end
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    stack_nxt[i] = stack[i];
                end
            end
        end
        SCAN: begin
            if(cnt_scan < 18) begin
                if(num_or_op[0] == 1) begin
                    for(i = 0; i < 18; i = i + 1) begin
                        stack_nxt[i] = stack[i + 1];
                    end
                    stack_nxt[18] = 0;
                end
                else if(cnt_op == 0) begin
                    for(i = 0; i < 18; i = i + 1) begin
                        stack_nxt[i] = stack[i + 1];
                    end
                    stack_nxt[18] = 0;
                end
                else begin
                    for(i = 0; i < 19; i = i + 1) begin
                        stack_nxt[i] = stack[i];
                    end
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    stack_nxt[i] = stack[i];
                end
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin
                for(i = 0; i < 18; i = i + 1) begin
                    stack_nxt[i] = stack[i + 1];
                end
                stack_nxt[18] = 0;
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin
                for(i = 0; i < 19; i = i + 1) begin
                    stack_nxt[i] = stack[i];
                end
            end
            else begin
                for(i = 0; i < 18; i = i + 1) begin
                    stack_nxt[i] = stack[i + 1];
                end
                stack_nxt[18] = 0;
            end
        end
        default: begin
            for(i = 0; i < 19; i = i + 1) begin
                stack_nxt[i] = stack[i];
            end
        end
    endcase
end

//============================================
//              INFIX TO PREFIX
//============================================

// cnt scan
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_scan <= 0;
    end
    else begin
        cnt_scan <= cnt_scan_nxt;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            cnt_scan_nxt = 0;
        end
        SCAN: begin
            cnt_scan_nxt = cnt_scan + 1;
        end
        default: begin
            cnt_scan_nxt = cnt_scan;
        end
    endcase
end

// cnt op
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_op <= 0;
    end
    else begin
        cnt_op <= cnt_op_nxt;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            cnt_op_nxt = 0;
        end
        SCAN: begin
            if(!(num_or_op[0]) && (cnt_op == 0)) begin
                cnt_op_nxt = cnt_op + 1;
            end
            else begin
                cnt_op_nxt = cnt_op;
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin // if operator stack is empty
                cnt_op_nxt = cnt_op + 1;
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin // if current operator is prior to the top one of operator stack
                cnt_op_nxt = cnt_op - 1;
            end
            else begin
                cnt_op_nxt = cnt_op + 1;
            end
        end
        POP_ALL_OP: begin
            cnt_op_nxt = cnt_op - 1;
        end
        default: begin
            cnt_op_nxt = cnt_op;
        end
    endcase
end

// RPE
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (i = 0; i < 19; i = i + 1) begin
            RPE[i] <= 0;
        end
    end
    else begin
        for (i = 0; i < 19; i = i + 1) begin
            RPE[i] <= RPE_nxt[i];
        end
    end
end

always @(*) begin
    case (state)
        SCAN: begin
            if(num_or_op[0] == 1) begin
                RPE_nxt[0] = stack[0];
                for(i = 1; i < 19; i = i + 1) begin
                    RPE_nxt[i] = RPE[i - 1];
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    RPE_nxt[i] = RPE[i];
                end
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin
                for(i = 0; i < 19; i = i + 1) begin
                    RPE_nxt[i] = RPE[i];
                end
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin
                RPE_nxt[0] = op_stack[0];
                for(i = 1; i < 19; i = i + 1) begin
                    RPE_nxt[i] = RPE[i - 1];
                end
            end
            else begin
                for(i = 0; i < 19; i = i + 1) begin
                    RPE_nxt[i] = RPE[i];
                end
            end
        end
        POP_ALL_OP: begin
            RPE_nxt[0] = op_stack[0];
            for(i = 1; i < 19; i = i + 1) begin
                RPE_nxt[i] = RPE[i - 1];
            end 
        end
        default: begin
            for(i = 0; i < 19; i = i + 1) begin
                RPE_nxt[i] = RPE[i];
            end
        end
    endcase
end

// op stack
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1) begin
            op_stack[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 9; i = i + 1) begin
            op_stack[i] <= op_stack_nxt[i];
        end
    end
end

always @(*) begin
    case (state)
        SCAN: begin
            if(!(num_or_op[0]) && (cnt_op == 0)) begin
                op_stack_nxt[0] = stack[0];
                for(i = 1; i < 9; i = i + 1) begin
                    op_stack_nxt[i] = op_stack[i - 1];
                end
            end
            else begin
                for(i = 0; i < 9; i = i + 1) begin
                    op_stack_nxt[i] = op_stack[i];
                end
            end
        end
        CMP_PRIOR: begin
            if(cnt_op == 0) begin
                op_stack_nxt[0] = stack[0];
                for(i = 1; i < 9; i = i + 1) begin
                    op_stack_nxt[i] = op_stack[i - 1];
                end
            end
            else if(!(stack[0][1]) && (op_stack[0][1])) begin
                for(i = 0; i < 8; i = i + 1) begin
                    op_stack_nxt[i] = op_stack[i + 1];
                end
                op_stack_nxt[8] = 0;
            end
            else begin
                op_stack_nxt[0] = stack[0];
                for(i = 1; i < 9; i = i + 1) begin
                    op_stack_nxt[i] = op_stack[i - 1];
                end
            end
        end
        POP_ALL_OP: begin
            for(i = 0; i < 8; i = i + 1) begin
                op_stack_nxt[i] = op_stack[i + 1];
            end
            op_stack_nxt[8] = 0;
        end
        default: begin
            for(i = 0; i < 9; i = i + 1) begin
                op_stack_nxt = op_stack;
            end
        end
    endcase
end

//============================================
//                  OUT
//============================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
    end
end

always @(*) begin
    case (state)
        EVALUATE_CHECK: begin
            if(cnt_eva_2 == 9) begin
                out_valid_nxt = 1;
            end
            else begin
                out_valid_nxt = 0;
            end
        end
        POP_ALL_OP: begin
            if(cnt_op == 0) begin
                out_valid_nxt = 1;
            end
            else begin
                out_valid_nxt = 0;
            end
        end
        default: begin
            out_valid_nxt = 0;
        end
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else begin
        out <= out_nxt;
    end
end

always @(*) begin
    case (state)
        EVALUATE_CHECK: begin
            if(cnt_eva_2 == 9) begin
                out_nxt = stack[0];
            end
            else begin
                out_nxt = 0;
            end
        end
        POP_ALL_OP: begin
            if(cnt_op == 0) begin
                out_nxt = {RPE[18], RPE[17], RPE[16], RPE[15], RPE[14], RPE[13], RPE[12], RPE[11], RPE[10], RPE[9], RPE[8], RPE[7], RPE[6], RPE[5], RPE[4], RPE[3], RPE[2], RPE[1], RPE[0]};
            end
            else begin
                out_nxt = 0;
            end
        end
        default: begin
            out_nxt = 0;
        end
    endcase
end

endmodule