//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC(
  // Input signals
    opt,
    in_n0, in_n1, in_n2, in_n3, in_n4,  
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
input [2:0] opt;
output reg [9:0] out_n;         					

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment 
wire signed [4:0]   n0, n1, n2, n3, n4;
wire signed [4:0]   w00, w10, w20,
                    w01, w11, w21, w31,
                    w02, w12, w22, w32,
                    w03, w13, w23, w33,
                    w04, w14, w24;  
wire signed [4:0]   w0, w1, w2, w3, w4;  
wire signed [5:0]   sum0;
wire signed [7:0]   sum1;
wire signed [9:0]   sum2;
wire signed [4:0]   mul_in_0, mul_in_1;
wire signed [9:0]   mul_out;

reg signed  [4:0]   avg0, avg1;
reg signed  [9:0]   avg2;
reg signed  [9:0]   out;

//================================================================
//    DESIGN
//================================================================

// Bose-nelson sorting
assign w00 = (in_n0 < in_n1) ? in_n0 : in_n1;
assign w01 = (in_n0 < in_n1) ? in_n1 : in_n0;
assign w03 = (in_n3 < in_n4) ? in_n3 : in_n4;
assign w04 = (in_n3 < in_n4) ? in_n4 : in_n3;
assign w02 = (in_n2 < w04) ? in_n2 : w04;
assign w14 = (in_n2 < w04) ? w04 : in_n2;
assign w12 = (w02 < w03) ? w02 : w03;
assign w13 = (w02 < w03) ? w03 : w02;
assign w10 = (w00 < w13) ? w00 : w13;
assign w23 = (w00 < w13) ? w13 : w00;
assign w20 = (w10 < w12) ? w10 : w12;
assign w22 = (w10 < w12) ? w12 : w10;
assign w11 = (w01 < w14) ? w01 : w14;
assign w24 = (w01 < w14) ? w14 : w01;
assign w21 = (w11 < w23) ? w11 : w23;
assign w33 = (w11 < w23) ? w23 : w11;
assign w31 = (w21 < w22) ? w21 : w22;
assign w32 = (w21 < w22) ? w22 : w21;

// Check sorting order
assign w0 = (opt[1]) ? w24 : w20;
assign w1 = (opt[1]) ? w33 : w31;
assign w2 = (opt[1]) ? w32 : w32;
assign w3 = (opt[1]) ? w31 : w33;
assign w4 = (opt[1]) ? w20 : w24;

// Average of w0 and w4
assign sum0 = w0 + w4;
assign avg0 = (opt[0]) ? (sum0/2) : 0;

// Normalization
assign n0 = w0 - avg0;
assign n1 = w1 - avg0;
assign n2 = w2 - avg0;
assign n3 = w3 - avg0;
assign n4 = w4 - avg0;

// Average of n0 ~ n4
assign sum1 = ((n0 + n1) + (n2 + n3)) + n4;
always @(*) begin
    case (sum1)
        -19: avg1 =  -3; -18: avg1 =  -3; -17: avg1 =  -3; -16: avg1 =  -3; -15: avg1 =  -3; 
        -14: avg1 =  -2; -13: avg1 =  -2; -12: avg1 =  -2; -11: avg1 =  -2; -10: avg1 =  -2;
         -9: avg1 =  -1;  -8: avg1 =  -1;  -7: avg1 =  -1;  -6: avg1 =  -1;  -5: avg1 =  -1;
         -4: avg1 =   0;  -3: avg1 =   0;  -2: avg1 =   0;  -1: avg1 =   0;   0: avg1 =   0;
          1: avg1 =   0;   2: avg1 =   0;   3: avg1 =   0;   4: avg1 =   0;   5: avg1 =   1;
          6: avg1 =   1;   7: avg1 =   1;   8: avg1 =   1;   9: avg1 =   1;  10: avg1 =   2;
         11: avg1 =   2;  12: avg1 =   2;  13: avg1 =   2;  14: avg1 =   2;  15: avg1 =   3;
         16: avg1 =   3;  17: avg1 =   3;  18: avg1 =   3;  19: avg1 =   3;  20: avg1 =   4; 
         21: avg1 =   4;  22: avg1 =   4;  23: avg1 =   4;  24: avg1 =   4;  25: avg1 =   5;
         26: avg1 =   5;  27: avg1 =   5;  28: avg1 =   5;  29: avg1 =   5;  30: avg1 =   6;
         31: avg1 =   6;  32: avg1 =   6;  33: avg1 =   6;  34: avg1 =   6;  35: avg1 =   7;
         36: avg1 =   7;  37: avg1 =   7;  38: avg1 =   7;  39: avg1 =   7;  40: avg1 =   8;
         41: avg1 =   8;  42: avg1 =   8;  43: avg1 =   8;  44: avg1 =   8;  45: avg1 =   9;
         46: avg1 =   9;  47: avg1 =   9;  48: avg1 =   9;  49: avg1 =   9;  50: avg1 =  10;
         51: avg1 =  10;  52: avg1 =  10;  53: avg1 =  10;  54: avg1 =  10;  55: avg1 =  11; 
         56: avg1 =  11;  57: avg1 =  11;  58: avg1 =  11;  59: avg1 =  11;  60: avg1 =  12;
         61: avg1 =  12;  62: avg1 =  12;  63: avg1 =  12;  64: avg1 =  12;  65: avg1 =  13;
         66: avg1 =  13;  67: avg1 =  13;  68: avg1 =  13;
        default: avg1 = 0;
    endcase
end

// Average of (n0 + n3*avg1 + mul_out_1)
assign sum2 = n0 + n3*avg1 + mul_out;
always @(*) begin
    case (sum2)
        /*-50: avg2 = -16; -49: avg2 = -16; -48: avg2 = -16;
        -47: avg2 = -15; -46: avg2 = -15; -45: avg2 = -15;
        -44: avg2 = -14; -43: avg2 = -14; -42: avg2 = -14;
        -41: avg2 = -13; -40: avg2 = -13; -39: avg2 = -13;*/
        -38: avg2 = -12; -37: avg2 = -12; -36: avg2 = -12;
        -35: avg2 = -11; -34: avg2 = -11; -33: avg2 = -11;
        -32: avg2 = -10; -31: avg2 = -10; -30: avg2 = -10;
        -29: avg2 =  -9; -28: avg2 =  -9; -27: avg2 =  -9;
        -26: avg2 =  -8; -25: avg2 =  -8; -24: avg2 =  -8; 
        -23: avg2 =  -7; -22: avg2 =  -7; -21: avg2 =  -7;
        -20: avg2 =  -6; -19: avg2 =  -6; -18: avg2 =  -6;
        -17: avg2 =  -5; -16: avg2 =  -5; -15: avg2 =  -5;
        -14: avg2 =  -4; -13: avg2 =  -4; -12: avg2 =  -4;
        -11: avg2 =  -3; -10: avg2 =  -3;  -9: avg2 =  -3;
         -8: avg2 =  -2;  -7: avg2 =  -2;  -6: avg2 =  -2;
         -5: avg2 =  -1;  -4: avg2 =  -1;  -3: avg2 =  -1;
         -2: avg2 =   0;  -1: avg2 =   0;   0: avg2 =   0;
          1: avg2 =   0;   2: avg2 =   0;   3: avg2 =   1;
          4: avg2 =   1;   5: avg2 =   1;   6: avg2 =   2;
          7: avg2 =   2;   8: avg2 =   2;   9: avg2 =   3; 
         10: avg2 =   3;  11: avg2 =   3;  12: avg2 =   4;
         13: avg2 =   4;  14: avg2 =   4;  15: avg2 =   5;
         16: avg2 =   5;  17: avg2 =   5;  18: avg2 =   6;
         19: avg2 =   6;  20: avg2 =   6;  21: avg2 =   7;
         22: avg2 =   7;  23: avg2 =   7;  24: avg2 =   8;
         25: avg2 =   8;  26: avg2 =   8;  27: avg2 =   9;
         28: avg2 =   9;  29: avg2 =   9;  30: avg2 =  10;
         31: avg2 =  10;  32: avg2 =  10;  33: avg2 =  11;
         34: avg2 =  11;  35: avg2 =  11;  36: avg2 =  12;
         37: avg2 =  12;  38: avg2 =  12;  39: avg2 =  13;
         40: avg2 =  13;  41: avg2 =  13;  42: avg2 =  14;
         43: avg2 =  14;  44: avg2 =  14;  45: avg2 =  15;
         46: avg2 =  15;  47: avg2 =  15;  48: avg2 =  16; 
         49: avg2 =  16;  50: avg2 =  16;  51: avg2 =  17;
         52: avg2 =  17;  53: avg2 =  17;  54: avg2 =  18;
         55: avg2 =  18;  56: avg2 =  18;  57: avg2 =  19;
         58: avg2 =  19;  59: avg2 =  19;  60: avg2 =  20;
         61: avg2 =  20;  62: avg2 =  20;  63: avg2 =  21;
         64: avg2 =  21;  65: avg2 =  21;  66: avg2 =  22;
         67: avg2 =  22;  68: avg2 =  22;  69: avg2 =  23;
         70: avg2 =  23;  71: avg2 =  23;  72: avg2 =  24;
         73: avg2 =  24;  74: avg2 =  24;  75: avg2 =  25;
         76: avg2 =  25;  77: avg2 =  25;  78: avg2 =  26;
         79: avg2 =  26;  80: avg2 =  26;  81: avg2 =  27;
         82: avg2 =  27;  83: avg2 =  27;  84: avg2 =  28;
         85: avg2 =  28;  86: avg2 =  28;  87: avg2 =  29; 
         88: avg2 =  29;  89: avg2 =  29;  90: avg2 =  30;
         91: avg2 =  30;  92: avg2 =  30;  93: avg2 =  31;
         94: avg2 =  31;  95: avg2 =  31;  96: avg2 =  32;
         97: avg2 =  32;  98: avg2 =  32;  99: avg2 =  33;
        100: avg2 =  33; 101: avg2 =  33; 102: avg2 =  34;
        103: avg2 =  34; 104: avg2 =  34; 105: avg2 =  35;
        106: avg2 =  35; 107: avg2 =  35; 108: avg2 =  36;
        109: avg2 =  36; 110: avg2 =  36; 111: avg2 =  37;
        112: avg2 =  37; 113: avg2 =  37; 114: avg2 =  38;
        115: avg2 =  38; 116: avg2 =  38; 117: avg2 =  39;
        118: avg2 =  39; 119: avg2 =  39; 120: avg2 =  40;
        121: avg2 =  40; 122: avg2 =  40; 123: avg2 =  41; 
        124: avg2 =  41; 125: avg2 =  41; 126: avg2 =  42;
        127: avg2 =  42; 128: avg2 =  42; 129: avg2 =  43;
        130: avg2 =  43; 131: avg2 =  43; 132: avg2 =  44;
        133: avg2 =  44; 134: avg2 =  44; 135: avg2 =  45;
        136: avg2 =  45; 137: avg2 =  45; 138: avg2 =  46;
        139: avg2 =  46; 140: avg2 =  46; 141: avg2 =  47;
        142: avg2 =  47; 143: avg2 =  47; 144: avg2 =  48;
        145: avg2 =  48; 146: avg2 =  48; 147: avg2 =  49;
        148: avg2 =  49; 149: avg2 =  49; 150: avg2 =  50; 
        151: avg2 =  50; 152: avg2 =  50; 153: avg2 =  51;
        154: avg2 =  51; 155: avg2 =  51; 156: avg2 =  52;
        157: avg2 =  52; 158: avg2 =  52; 159: avg2 =  53;
        160: avg2 =  53; 161: avg2 =  53; 162: avg2 =  54;
        163: avg2 =  54; 164: avg2 =  54; 165: avg2 =  55;
        166: avg2 =  55; 167: avg2 =  55; 168: avg2 =  56;
        169: avg2 =  56; 170: avg2 =  56; 171: avg2 =  57;
        172: avg2 =  57; 173: avg2 =  57; 174: avg2 =  58;
        175: avg2 =  58; 176: avg2 =  58; 177: avg2 =  59;
        178: avg2 =  59; 179: avg2 =  59; 180: avg2 =  60;
        181: avg2 =  60; 182: avg2 =  60; 183: avg2 =  61; 
        184: avg2 =  61; 185: avg2 =  61; 186: avg2 =  62;
        187: avg2 =  62; 188: avg2 =  62; 189: avg2 =  63;
        190: avg2 =  63; 191: avg2 =  63; 192: avg2 =  64;
        193: avg2 =  64; 194: avg2 =  64; 195: avg2 =  65;
        196: avg2 =  65; 197: avg2 =  65; 198: avg2 =  66;
        199: avg2 =  66; 200: avg2 =  66; 201: avg2 =  67;
        202: avg2 =  67; 203: avg2 =  67; 204: avg2 =  68;
        205: avg2 =  68; 206: avg2 =  68; 207: avg2 =  69;
        208: avg2 =  69; 209: avg2 =  69; 210: avg2 =  70;
        211: avg2 =  70; 212: avg2 =  70; 213: avg2 =  71;
        214: avg2 =  71; 215: avg2 =  71; 216: avg2 =  72;
        217: avg2 =  72; 218: avg2 =  72; 219: avg2 =  73;
        220: avg2 =  73; 221: avg2 =  73; 222: avg2 =  74; 
        223: avg2 =  74; 224: avg2 =  74; 225: avg2 =  75;
        226: avg2 =  75; 227: avg2 =  75; 228: avg2 =  76;
        229: avg2 =  76; 230: avg2 =  76; 231: avg2 =  77;
        232: avg2 =  77; 233: avg2 =  77; 234: avg2 =  78;
        235: avg2 =  78; 236: avg2 =  78; 237: avg2 =  79;
        238: avg2 =  79; 239: avg2 =  79; 240: avg2 =  80;
        241: avg2 =  80; 242: avg2 =  80; 243: avg2 =  81;
        244: avg2 =  81; 245: avg2 =  81; 246: avg2 =  82;
        247: avg2 =  82; 248: avg2 =  82; 249: avg2 =  83;
        250: avg2 =  83; 251: avg2 =  83; 252: avg2 =  84;
        253: avg2 =  84; 254: avg2 =  84; 255: avg2 =  85;
        256: avg2 =  85; 257: avg2 =  85; 258: avg2 =  86; 
        259: avg2 =  86; 260: avg2 =  86; 261: avg2 =  87;
        262: avg2 =  87; 263: avg2 =  87; 264: avg2 =  88;
        265: avg2 =  88; 266: avg2 =  88; 267: avg2 =  89;
        268: avg2 =  89; 269: avg2 =  89; 270: avg2 =  90;
        271: avg2 =  90; 272: avg2 =  90; 273: avg2 =  91;
        274: avg2 =  91; 275: avg2 =  91; 276: avg2 =  92;
        277: avg2 =  92; 278: avg2 =  92; 279: avg2 =  93;
        280: avg2 =  93; 281: avg2 =  93; 282: avg2 =  94;
        283: avg2 =  94; 284: avg2 =  94; 285: avg2 =  95;
        286: avg2 =  95; 287: avg2 =  95; 288: avg2 =  96;
        289: avg2 =  96; 290: avg2 =  96; 291: avg2 =  97; 
        292: avg2 =  97; 293: avg2 =  97; 294: avg2 =  98;
        295: avg2 =  98; 296: avg2 =  98; 297: avg2 =  99;
        298: avg2 =  99; 299: avg2 =  99; 300: avg2 = 100;
        301: avg2 = 100; 302: avg2 = 100; 303: avg2 = 101;
        304: avg2 = 101; 305: avg2 = 101; 306: avg2 = 102;
        307: avg2 = 102; 308: avg2 = 102; 309: avg2 = 103;
        310: avg2 = 103; 311: avg2 = 103; 312: avg2 = 104;
        313: avg2 = 104; 314: avg2 = 104; 315: avg2 = 105;
        316: avg2 = 105; 317: avg2 = 105; 318: avg2 = 106;
        319: avg2 = 106; 320: avg2 = 106; 321: avg2 = 107;
        322: avg2 = 107; 323: avg2 = 107; 324: avg2 = 108;
        325: avg2 = 108; 326: avg2 = 108; 327: avg2 = 109; 
        328: avg2 = 109; 329: avg2 = 109; 330: avg2 = 110;
        331: avg2 = 110; 332: avg2 = 110; 333: avg2 = 111;
        334: avg2 = 111; 335: avg2 = 111; 336: avg2 = 112;
        337: avg2 = 112; 338: avg2 = 112; 339: avg2 = 113;
        340: avg2 = 113; 341: avg2 = 113; 342: avg2 = 114;
        343: avg2 = 114; 344: avg2 = 114; 345: avg2 = 115;
        346: avg2 = 115; 347: avg2 = 115; 348: avg2 = 116;
        349: avg2 = 116; 350: avg2 = 116; 351: avg2 = 117; 
        352: avg2 = 117; 353: avg2 = 117; 354: avg2 = 118;
        355: avg2 = 118; 356: avg2 = 118; 357: avg2 = 119;
        358: avg2 = 119; 359: avg2 = 119; 360: avg2 = 120;
        361: avg2 = 120; 362: avg2 = 120; 363: avg2 = 121;
        364: avg2 = 121; 365: avg2 = 121; 366: avg2 = 122;
        367: avg2 = 122; 368: avg2 = 122; 369: avg2 = 123;
        370: avg2 = 123; 371: avg2 = 123; 372: avg2 = 124;
        373: avg2 = 124; 374: avg2 = 124; 375: avg2 = 125;
        376: avg2 = 125; 377: avg2 = 125; 378: avg2 = 126;
        379: avg2 = 126; 380: avg2 = 126; 381: avg2 = 127;
        382: avg2 = 127; 383: avg2 = 127; 384: avg2 = 128; 
        385: avg2 = 128; 386: avg2 = 128; 387: avg2 = 129;
        388: avg2 = 129; 389: avg2 = 129; 390: avg2 = 130;
        391: avg2 = 130; 392: avg2 = 130; 393: avg2 = 131;
        394: avg2 = 131; 395: avg2 = 131; 396: avg2 = 132;
        397: avg2 = 132; 398: avg2 = 132; 399: avg2 = 133;
        400: avg2 = 133; 401: avg2 = 133; 402: avg2 = 134;
        403: avg2 = 134; 404: avg2 = 134; 405: avg2 = 135;
        406: avg2 = 135; 407: avg2 = 135; 408: avg2 = 136;
        409: avg2 = 136; 410: avg2 = 136; 411: avg2 = 137; 
        412: avg2 = 137; 413: avg2 = 137; 414: avg2 = 138;
        /*415: avg2 = 138; 416: avg2 = 138; 417: avg2 = 139;
        418: avg2 = 139; 419: avg2 = 139; 420: avg2 = 140;
        421: avg2 = 140; 422: avg2 = 140; 423: avg2 = 141;
        424: avg2 = 141; 425: avg2 = 141; 426: avg2 = 142;
        427: avg2 = 142; 428: avg2 = 142; 429: avg2 = 143;
        430: avg2 = 143; 431: avg2 = 143; 432: avg2 = 144;
        433: avg2 = 144; 434: avg2 = 144; 435: avg2 = 145;
        436: avg2 = 145; 437: avg2 = 145; 438: avg2 = 146;
        439: avg2 = 146; 440: avg2 = 146; 441: avg2 = 147;
        442: avg2 = 147; 443: avg2 = 147; 444: avg2 = 148; 
        445: avg2 = 148; 446: avg2 = 148; 447: avg2 = 149;
        448: avg2 = 149; 449: avg2 = 149; 450: avg2 = 150;*/
        default: 
            avg2 = 0;
    endcase
end

// Share multiplier of (n0, n4) and (n1, n2)
assign mul_in_0 = (opt[2]) ? n0 : n1;
assign mul_in_1 = (opt[2]) ? n4 : n2;
assign mul_out = mul_in_0*mul_in_1;

// Calculation
always @(*) begin
    if(opt[2])begin
        out = n3*3 - mul_out;
        out_n = (out[9]) ? -out : out;
    end
    else begin
        out = avg2;
        out_n = out;
    end
end

endmodule
