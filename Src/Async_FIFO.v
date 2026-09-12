`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 14:16:21
// Design Name: 
// Module Name: Async_FIFO
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
`default_nettype none
module Async_FIFO #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  wire wr_clk,
    input  wire wr_rst,
    input  wire wr_en,
    input  wire [WIDTH-1:0] din,
    input  wire  rd_clk,
    input  wire  rd_rst,
    input  wire  rd_en,
    output wire [WIDTH-1:0] dout,
    output wire  Full,
    output wire  Empty
);
wire [$clog2(DEPTH):0] wr_ptr_gray;
wire [$clog2(DEPTH):0] rd_ptr_gray;
wire [$clog2(DEPTH):0] wr_ptr;
wire [$clog2(DEPTH):0] rd_ptr;
wire [$clog2(DEPTH):0] rd_ptr_gray_s;
wire [$clog2(DEPTH):0] wr_ptr_gray_s;

Sync #($clog2(DEPTH)+1) s1 (.clk(wr_clk),.rst(wr_rst),.din(rd_ptr_gray),.q(rd_ptr_gray_s));
Sync #($clog2(DEPTH)+1) s2 (.clk(rd_clk),.rst(rd_rst),.din(wr_ptr_gray),.q(wr_ptr_gray_s));
wr_ptr_handler #(DEPTH) I1 (.wr_clk(wr_clk),.wr_rst(wr_rst),.wr_en(wr_en),.rd_ptr_gray(rd_ptr_gray_s),.wr_ptr(wr_ptr),.wr_ptr_gray(wr_ptr_gray),.Full(Full));
rd_ptr_handler #(DEPTH) I2 (.rd_clk(rd_clk),.rd_rst(rd_rst),.rd_en(rd_en),.wr_ptr_gray(wr_ptr_gray_s),.Empty(Empty),.rd_ptr(rd_ptr),.rd_ptr_gray(rd_ptr_gray));
fifo_mem #(DEPTH,WIDTH) I3 (.wr_clk_en((wr_en &(~Full))),.rd_clk_en((rd_en &(~Empty))),.wr_clk(wr_clk),.rd_clk(rd_clk),.rd_rst(rd_rst),.wr_rst(wr_rst),.din(din),.wr_ptr(wr_ptr[(($clog2(DEPTH))-1):0]),.rd_ptr(rd_ptr[(($clog2(DEPTH))-1):0]),.dout(dout));
endmodule
