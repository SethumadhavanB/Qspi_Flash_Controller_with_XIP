`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 14:17:36
// Design Name: 
// Module Name: fifo_mem
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
`default_nettype wire
module fifo_mem #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  wire  wr_clk_en,
    input  wire  rd_clk_en,
    input  wire  wr_clk,
    input wire rd_clk,
    input wire  wr_rst,
    input wire  rd_rst,
    input  wire [WIDTH-1:0]din,
    input  wire [$clog2(DEPTH)-1:0] wr_ptr,
    input  wire [$clog2(DEPTH)-1:0] rd_ptr,
    output reg  [WIDTH-1:0]  dout
);

reg [WIDTH-1:0] mem [DEPTH-1:0];

//assign dout = (rd_clk_en)? mem[rd_ptr]:0;
always @(posedge rd_clk or negedge rd_rst) begin
    if (!rd_rst)
        dout <={WIDTH{1'b0}};
    else if (rd_clk_en)
        dout <= mem[rd_ptr];
end

// WRITE
integer i;
always @(posedge wr_clk or negedge wr_rst) begin
    if (!wr_rst) begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] <= 0;
    end
    else if (wr_clk_en) begin
        mem[wr_ptr] <= din;
    end
end

endmodule

