//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================

input   [IP_WIDTH*4-1:0]  IN_character;
input   [IP_WIDTH*5-1:0]  IN_weight;

output  [IP_WIDTH*4-1:0]  OUT_character;

// ===============================================================
// Declaration
// ===============================================================

// Input
genvar i_in;

// Bubble sort
genvar i, j;
wire [8:0] tmp[IP_WIDTH*2-1][IP_WIDTH];
wire [8:0] ans[IP_WIDTH];

// Output
genvar i_out;

// ===============================================================
// Input
// ===============================================================

generate
    for(i_in = 0; i_in < IP_WIDTH; i_in = i_in + 1) begin
        assign tmp[0][i_in] = {IN_character[(i_in*4+3):(i_in*4)], IN_weight[(i_in*5+4):(i_in*5)]};
    end
endgenerate

// ===============================================================
// Bubble sort
// ===============================================================

generate
    for(i = 0; i < IP_WIDTH - 1; i = i + 1) begin
        assign tmp[2*i+1][0] = tmp[2*i][0];

        for(j = 0; j < IP_WIDTH - 1; j = j + 1) begin
            if(j < IP_WIDTH - 1 - i) begin
                assign tmp[2*i+2][j+0] = (tmp[2*i+1][j+0][4:0] > tmp[2*i+0][j+1][4:0]) ? tmp[2*i+0][j+1] : tmp[2*i+1][j+0];
                assign tmp[2*i+1][j+1] = (tmp[2*i+1][j+0][4:0] > tmp[2*i+0][j+1][4:0]) ? tmp[2*i+1][j+0] : tmp[2*i+0][j+1];
            end
            else begin
                assign tmp[2*i+2][j+0] = tmp[2*i+1][j+0];
                assign tmp[2*i+1][j+1] = tmp[2*i+0][j+1];
            end
        end

        assign tmp[2*i+2][IP_WIDTH-1] = tmp[2*i+1][IP_WIDTH-1];
    end
endgenerate

// ===============================================================
// Output
// ===============================================================

generate
    for (i_out = 0; i_out < IP_WIDTH; i_out = i_out + 1) begin
        assign OUT_character[4*i_out+3:4*i_out] = tmp[IP_WIDTH*2-2][i_out][8:5];
    end
endgenerate

endmodule

// Example of expansion a part of the loop of bubble sort
/*///////////////////////////////////////////////////////////////////////////
assign tmp[1][0] = tmp[0][0];

assign tmp[2][0] = (tmp[1][0][4:0] > tmp[0][1][4:0]) ? tmp[0][1] : tmp[1][0];
assign tmp[1][1] = (tmp[1][0][4:0] > tmp[0][1][4:0]) ? tmp[1][0] : tmp[0][1];

assign tmp[2][1] = (tmp[1][1][4:0] > tmp[0][2][4:0]) ? tmp[0][2] : tmp[1][1];
assign tmp[1][2] = (tmp[1][1][4:0] > tmp[0][2][4:0]) ? tmp[1][1] : tmp[0][2];

assign tmp[2][2] = (tmp[1][2][4:0] > tmp[0][3][4:0]) ? tmp[0][3] : tmp[1][2];
assign tmp[1][3] = (tmp[1][2][4:0] > tmp[0][3][4:0]) ? tmp[1][2] : tmp[0][3];

assign tmp[2][3] = (tmp[1][3][4:0] > tmp[0][4][4:0]) ? tmp[0][4] : tmp[1][3];
assign tmp[1][4] = (tmp[1][3][4:0] > tmp[0][4][4:0]) ? tmp[1][3] : tmp[0][4];

assign tmp[2][4] = (tmp[1][4][4:0] > tmp[0][5][4:0]) ? tmp[0][5] : tmp[1][4];
assign tmp[1][5] = (tmp[1][4][4:0] > tmp[0][5][4:0]) ? tmp[1][4] : tmp[0][5];

assign tmp[2][5] = (tmp[1][5][4:0] > tmp[0][6][4:0]) ? tmp[0][6] : tmp[1][5];
assign tmp[1][6] = (tmp[1][5][4:0] > tmp[0][6][4:0]) ? tmp[1][5] : tmp[0][6];

assign tmp[2][6] = (tmp[1][6][4:0] > tmp[0][7][4:0]) ? tmp[0][7] : tmp[1][6];
assign tmp[1][7] = (tmp[1][6][4:0] > tmp[0][7][4:0]) ? tmp[1][6] : tmp[0][7];

assign tmp[2][7] = tmp[1][7];
/////////////////////////////////////////////////////////////////////////////
assign tmp[3][0] = tmp[2][0];

assign tmp[4][0] = (tmp[3][0][4:0] > tmp[2][1][4:0]) ? tmp[2][1] : tmp[3][0];
assign tmp[3][1] = (tmp[3][0][4:0] > tmp[2][1][4:0]) ? tmp[3][0] : tmp[2][1];

assign tmp[4][1] = (tmp[3][1][4:0] > tmp[2][2][4:0]) ? tmp[2][2] : tmp[3][1];
assign tmp[3][2] = (tmp[3][1][4:0] > tmp[2][2][4:0]) ? tmp[3][1] : tmp[2][2];

assign tmp[4][2] = (tmp[3][2][4:0] > tmp[2][3][4:0]) ? tmp[2][3] : tmp[3][2];
assign tmp[3][3] = (tmp[3][2][4:0] > tmp[2][3][4:0]) ? tmp[3][2] : tmp[2][3];

assign tmp[4][3] = (tmp[3][3][4:0] > tmp[2][4][4:0]) ? tmp[2][4] : tmp[3][3];
assign tmp[3][4] = (tmp[3][3][4:0] > tmp[2][4][4:0]) ? tmp[3][3] : tmp[2][4];

assign tmp[4][4] = (tmp[3][4][4:0] > tmp[2][5][4:0]) ? tmp[2][5] : tmp[3][4];
assign tmp[3][5] = (tmp[3][4][4:0] > tmp[2][5][4:0]) ? tmp[3][4] : tmp[2][5];

assign tmp[4][5] = (tmp[3][5][4:0] > tmp[2][6][4:0]) ? tmp[2][6] : tmp[3][5];
assign tmp[3][6] = (tmp[3][5][4:0] > tmp[2][6][4:0]) ? tmp[3][5] : tmp[2][6];

assign tmp[4][6] = tmp[3][6];
assign tmp[3][7] = tmp[2][7];

assign tmp[4][7] = tmp[3][7];
///////////////////////////////////////////////////////////////////////////*/