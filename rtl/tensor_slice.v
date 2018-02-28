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


module tensor_slice #
(
parameter integer CONFIG_WIDTH = 26,
parameter integer WINDOW_SIZE = 9,
parameter integer WEIGHT_SIZE_WIDTH = 64, // 7x9, the last bit is redundant
parameter integer WEIGHT_UINDEX = 4,
parameter integer BIAS_WIDTH = 8,
parameter integer TENSOR_WIDTH = 8,
parameter integer FEATURE_WIDTH = 8
)
(
input   clk, rst,
input   [CONFIG_WIDTH-1 : 0]    xcfg_reg,
input   [WINDOW_SIZE*FEATURE_WIDTH-1 : 0]     xwnd_3x3,
input   [WEIGHT_SIZE_WIDTH*WEIGHT_UINDEX-1 : 0]  xweight,
input   signed [BIAS_WIDTH-1 : 0]      xbias,
output  signed [TENSOR_WIDTH-1 : 0]    xsout,
output  signed [15:0] ximd
);

// xcfg_reg format
//  | 25 --     | 24  -- 21     |20 -- 17  | 16  |  15 --12   | 2 -- 1 | 0 |
//  | Bias/PSum | Psum Index-4b |Out Shift| Relu | Ouput Sel| Wgt Sel| Trigger|

// Weight Selection
reg [63:0] w;

always@(*) begin
    case (xcfg_reg[2:1])
        2'b00: w = xweight[WEIGHT_SIZE_WIDTH-1:0];
        2'b01: w = xweight[2*WEIGHT_SIZE_WIDTH-1:WEIGHT_SIZE_WIDTH];
        2'b10: w = xweight[3*WEIGHT_SIZE_WIDTH-1:2*WEIGHT_SIZE_WIDTH];
        2'b11: w = xweight[4*WEIGHT_SIZE_WIDTH-1:3*WEIGHT_SIZE_WIDTH];
    endcase
end

// Define the scratch pad -16b
reg signed [15:0] sp[0:15]; // or need a submodule?


wire signed [15:0] psum;
assign ximd = {xwnd_3x3[7:0],1'b0,w[6:0]};

always @(posedge clk or negedge rst) begin
    if(~rst) begin
        sp[0] <= 0;
        sp[1] <= 0;
        sp[2] <= 0;
        sp[3] <= 0;
        sp[4] <= 0;
        sp[5] <= 0;
        sp[6] <= 0;
        sp[7] <= 0;
        sp[8] <= 0;
        sp[9] <= 0;
        sp[10] <= 0;
        sp[11] <= 0;
        sp[12] <= 0;
        sp[13] <= 0;
        sp[14] <= 0;
        sp[15] <= 0;
    end
    else begin
        sp[xcfg_reg[24:21]] <= psum;
    end
end



// Bias or partial Sum
wire signed [15:0] adder0;
assign adder0 = xcfg_reg[25]? (xbias <<< (xcfg_reg[20:17])):0;

// 9x9 + bias/parital MAC
wire signed [7:0] x0, x1, x2, x3, x4, x5, x6, x7, x8;
wire signed [6:0] w0, w1, w2, w3, w4, w5, w6, w7, w8;


assign x0 = xwnd_3x3[7:0];
assign x1 = xwnd_3x3[15:8];
assign x2 = xwnd_3x3[23:16];
assign x3 = xwnd_3x3[31:24];
assign x4 = xwnd_3x3[39:32];
assign x5 = xwnd_3x3[47:40];
assign x6 = xwnd_3x3[55:48];
assign x7 = xwnd_3x3[63:56];
assign x8 = xwnd_3x3[71:64];

assign w0 = w[6:0];
assign w1 = w[13:7];
assign w2 = w[20:14];
assign w3 = w[27:21];
assign w4 = w[34:28];
assign w5 = w[41:35];
assign w6 = w[48:42];
assign w7 = w[55:49];
assign w8 = w[62:56];

 
assign psum = x0*w0 + x1*w1 + x2*w2 + x3*w3 + x4*w4 + x5*w5 + x6*w6 + x7*w7 + x8*w8 + adder0;


// output select
wire signed [15:0] slt_output;
assign slt_output = sp[xcfg_reg[15:12]];

// relu
wire relu;
wire signed [15:0] relu_output;
assign relu = xcfg_reg[16];
assign relu_output = relu? ((slt_output>0)? slt_output : 0) : slt_output;

// shift
assign xsout = relu_output >>> (xcfg_reg[20:17]);

endmodule
