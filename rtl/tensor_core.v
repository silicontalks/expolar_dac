`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2018 04:29:28 PM
// Design Name: 
// Module Name: tensor_slice
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tensor_core #
(
// Accelerator based infomation
        parameter integer CONFIG_WIDTH = 32,
        parameter integer FEATURE_WIDTH = 8,
        parameter integer FEATURE_ROW = 6,
        parameter integer FEATURE_COL = 12,
        parameter integer WEIGHT_SIZE_WIDTH = 64, // 7x9, the last bit is redundant
        parameter integer WEIGHT_UINDEX = 4,
        parameter integer TENSOR_SLICE = 8, // 4 per slice, 8 slices in total
        parameter integer BIAS_WIDTH = 8,
        parameter integer TENSOR_WIDTH = 8
)
(
input    clk, 
input    rst,
input    [CONFIG_WIDTH-1 : 0]                         cfg_reg,
input    [FEATURE_WIDTH*FEATURE_ROW*FEATURE_COL-1: 0] feature ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight1 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight2 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight3 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight4 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight5 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight6 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight7 ,
input    [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]      weight8 ,
input    [BIAS_WIDTH*TENSOR_SLICE-1 : 0]              bias8,
output   [TENSOR_WIDTH*TENSOR_SLICE-1 : 0]            tnsout,
output   [127:0] irst
);


// cfg_reg format
//  | 31 -- 28 | 27 -- 26 | 25 -- 0 |
//  | FS,X-4b  | FS,Y-2b  | Send to slice|

// Feature Selection , like sliding

reg [FEATURE_WIDTH*FEATURE_COL-1: 0] col_selection1, col_selection2,col_selection3;
reg [FEATURE_WIDTH*9-1: 0]           wnd_3x3;

always @(*) begin
    case (cfg_reg[27:26])
        2'b00: begin
            col_selection1 = feature[FEATURE_WIDTH*FEATURE_COL-1:0];
            col_selection2 = feature[FEATURE_WIDTH*FEATURE_COL*2-1:FEATURE_WIDTH*FEATURE_COL];
            col_selection3 = feature[FEATURE_WIDTH*FEATURE_COL*3-1:FEATURE_WIDTH*FEATURE_COL*2];
        end
        2'b01: begin
            col_selection1 = feature[FEATURE_WIDTH*FEATURE_COL*2-1:FEATURE_WIDTH*FEATURE_COL];
            col_selection2 = feature[FEATURE_WIDTH*FEATURE_COL*3-1:FEATURE_WIDTH*FEATURE_COL*2];
            col_selection3 = feature[FEATURE_WIDTH*FEATURE_COL*4-1:FEATURE_WIDTH*FEATURE_COL*3];
        end
        2'b10: begin
            col_selection1 = feature[FEATURE_WIDTH*FEATURE_COL*3-1:FEATURE_WIDTH*FEATURE_COL*2];
            col_selection2 = feature[FEATURE_WIDTH*FEATURE_COL*4-1:FEATURE_WIDTH*FEATURE_COL*3];
            col_selection3 = feature[FEATURE_WIDTH*FEATURE_COL*5-1:FEATURE_WIDTH*FEATURE_COL*4];
        end
        2'b11: begin
            col_selection1 = feature[FEATURE_WIDTH*FEATURE_COL*4-1:FEATURE_WIDTH*FEATURE_COL*3];
            col_selection2 = feature[FEATURE_WIDTH*FEATURE_COL*5-1:FEATURE_WIDTH*FEATURE_COL*4];
            col_selection3 = feature[FEATURE_WIDTH*FEATURE_COL*6-1:FEATURE_WIDTH*FEATURE_COL*5];
        end
    endcase
end

always @(*) begin
    case (cfg_reg[31:28])
        4'd0: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-1:FEATURE_WIDTH*FEATURE_COL-24], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-1:FEATURE_WIDTH*FEATURE_COL-24], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-1:FEATURE_WIDTH*FEATURE_COL-24]};
        
        4'd1: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-9:FEATURE_WIDTH*FEATURE_COL-32], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-9:FEATURE_WIDTH*FEATURE_COL-32], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-9:FEATURE_WIDTH*FEATURE_COL-32]};
        
        4'd2: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-17:FEATURE_WIDTH*FEATURE_COL-40], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-17:FEATURE_WIDTH*FEATURE_COL-40], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-17:FEATURE_WIDTH*FEATURE_COL-40]};
        
        4'd3: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-25:FEATURE_WIDTH*FEATURE_COL-48], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-25:FEATURE_WIDTH*FEATURE_COL-48], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-25:FEATURE_WIDTH*FEATURE_COL-48]};

        4'd4: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-33:FEATURE_WIDTH*FEATURE_COL-56], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-33:FEATURE_WIDTH*FEATURE_COL-56], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-33:FEATURE_WIDTH*FEATURE_COL-56]};
        
        4'd5: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-41:FEATURE_WIDTH*FEATURE_COL-64], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-41:FEATURE_WIDTH*FEATURE_COL-64], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-41:FEATURE_WIDTH*FEATURE_COL-64]};

        4'd6: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-49:FEATURE_WIDTH*FEATURE_COL-72], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-49:FEATURE_WIDTH*FEATURE_COL-72], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-49:FEATURE_WIDTH*FEATURE_COL-72]};

        4'd7: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-57:FEATURE_WIDTH*FEATURE_COL-80], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-57:FEATURE_WIDTH*FEATURE_COL-80], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-57:FEATURE_WIDTH*FEATURE_COL-80]};

        4'd8: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-65:FEATURE_WIDTH*FEATURE_COL-88], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-65:FEATURE_WIDTH*FEATURE_COL-88], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-65:FEATURE_WIDTH*FEATURE_COL-88]};

        4'd9: wnd_3x3= {col_selection3[FEATURE_WIDTH*FEATURE_COL-73:FEATURE_WIDTH*FEATURE_COL-96], 
            col_selection2[FEATURE_WIDTH*FEATURE_COL-73:FEATURE_WIDTH*FEATURE_COL-96], 
            col_selection1[FEATURE_WIDTH*FEATURE_COL-73:FEATURE_WIDTH*FEATURE_COL-96]};
        
        default: wnd_3x3=0;
    endcase
end

// Generate 8 slices

// for debug only

tensor_slice ts1(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight1),
.xbias(bias8[7:0]),
.xsout(tnsout[7:0]),
.ximd(irst[15:0])
);

tensor_slice ts2(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight2),
.xbias(bias8[15:8]),
.xsout(tnsout[15:8]),
.ximd(irst[31:16])
);

tensor_slice ts3(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight3),
.xbias(bias8[23:16]),
.xsout(tnsout[23:16]),
.ximd(irst[47:32])
);

tensor_slice ts4(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight4),
.xbias(bias8[31:24]),
.xsout(tnsout[31:24]),
.ximd(irst[63:48])
);

tensor_slice ts5(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight5),
.xbias(bias8[39:32]),
.xsout(tnsout[39:32]),
.ximd(irst[79:64])
);

tensor_slice ts6(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight6),
.xbias(bias8[47:40]),
.xsout(tnsout[47:40]),
.ximd(irst[95:80])
);

tensor_slice ts7(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight7),
.xbias(bias8[55:48]),
.xsout(tnsout[55:48]),
.ximd(irst[111:96])
);

tensor_slice ts8(
.clk(clk), 
.rst(rst),
.xcfg_reg(cfg_reg[25:0]),
.xwnd_3x3(wnd_3x3),
.xweight(weight8),
.xbias(bias8[63:56]),
.xsout(tnsout[63:56]),
.ximd(irst[127:112])
);

endmodule