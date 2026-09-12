`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 14:10:52
// Design Name: 
// Module Name: wr_ptr_handler
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

module wr_ptr_handler #(parameter DEPTH = 8)(
    input  wire  wr_clk,
    input  wire  wr_rst,
    input  wire  wr_en,
    input  wire [$clog2(DEPTH):0]  rd_ptr_gray,
    output reg  [$clog2(DEPTH):0]  wr_ptr,
    output reg [$clog2(DEPTH):0]  wr_ptr_gray,
    output wire  Full
);

wire [$clog2(DEPTH):0] rd_ptr;
wire [$clog2(DEPTH):0] wr_ptr_gray_un;

genvar i;
generate
    assign rd_ptr[$clog2(DEPTH)] = rd_ptr_gray[$clog2(DEPTH)];
    for(i = $clog2(DEPTH)-1; i >= 0; i = i - 1)
    begin : GRAY2BIN
        assign rd_ptr[i] = rd_ptr[i+1] ^ rd_ptr_gray[i];
    end
endgenerate

assign wr_ptr_gray_un = (wr_ptr >> 1) ^ wr_ptr;
always@(posedge wr_clk or negedge wr_rst)
begin
    if(!wr_rst)
          wr_ptr_gray <= 0;
    else
        wr_ptr_gray <= wr_ptr_gray_un;
end

always @(posedge wr_clk or negedge wr_rst)
begin
    if(!wr_rst)
    begin
        wr_ptr <= 'd0;
    end
    else
    begin
        if(wr_en)
        begin
            if(!Full)
                wr_ptr <= wr_ptr + 1'b1;
        end
    end
end

assign Full = ((wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]) && (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]));

endmodule
