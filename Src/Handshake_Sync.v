`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 26.08.2026 09:45:11
// Design Name:
// Module Name: Handshake_Sync
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

module Handshake_Sync(
    input wire PCLK,
    input wire PRESETn,
    input wire ACK,
    output reg REQ,
    input wire [7:0]reg_opcode,
    input wire [31:0]reg_addr,
    input wire [7:0]reg_mode,
    input wire [7:0]reg_dummy,
    input wire [7:0]reg_length,
    input wire [1:0]opcode_line,
    input wire [1:0]addr_line,
    input wire [1:0]data_line,
    input wire [1:0]mode_line,
    input wire start,
    input wire opcode_en,
    input wire addr_en,
    input wire mode_en,
    input wire dummy_en,
    input wire data_w_en,
    input wire data_r_en,
    input wire poll_wip_en,
    input wire addr_4byte,

    output reg [7:0]reg_opcode_hold,
    output reg [31:0]reg_addr_hold,
    output reg [7:0]reg_mode_hold,
    output reg [7:0]reg_dummy_hold,
    output reg [7:0]reg_length_hold,
    output reg [1:0]opcode_line_hold,
    output reg [1:0]addr_line_hold,
    output reg [1:0]data_line_hold,
    output reg [1:0]mode_line_hold,
    output reg start_hold,
    output reg opcode_en_hold,
    output reg addr_en_hold,
    output reg mode_en_hold,
    output reg dummy_en_hold,
    output reg data_r_en_hold,
    output reg data_w_en_hold,
    output reg poll_wip_en_hold,
    output reg addr_4byte_hold
    );

    // Edge De
    reg start_d;
    wire start_pulse;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            start_d <= 1'b0;
        else
            start_d <= start;
    end
    assign start_pulse = start & ~start_d;


    //Handshake Logic
    always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        REQ              <= 1'b0;
        reg_opcode_hold  <= 8'b0;
        reg_addr_hold    <= 32'b0;
        reg_mode_hold    <= 8'b0;
        reg_dummy_hold   <= 8'b0;
        reg_length_hold  <= 8'b0;
        opcode_line_hold <= 2'b0;
        addr_line_hold   <= 2'b0;
        data_line_hold   <= 2'b0;
        mode_line_hold   <= 2'b0;
        start_hold       <= 1'b0;
        opcode_en_hold   <= 1'b0;
        addr_en_hold     <= 1'b0;
        mode_en_hold     <= 1'b0;
        dummy_en_hold    <= 1'b0;
        data_w_en_hold   <= 1'b0;
        data_r_en_hold   <= 1'b0;
        poll_wip_en_hold <= 1'b0;
        addr_4byte_hold  <= 1'b0; // Fixed typo (was '1 meb')
    end else begin
        if (start_pulse && !REQ && !ACK) begin
            reg_opcode_hold  <= reg_opcode;
            reg_addr_hold    <= reg_addr;
            reg_mode_hold    <= reg_mode;
            reg_dummy_hold   <= reg_dummy;
            reg_length_hold  <= reg_length;
            opcode_line_hold <= opcode_line;
            addr_line_hold   <= addr_line;
            data_line_hold   <= data_line;
            mode_line_hold   <= mode_line;
            start_hold       <= 1'b1;
            opcode_en_hold   <= opcode_en;
            addr_en_hold     <= addr_en;
            mode_en_hold     <= mode_en;
            dummy_en_hold    <= dummy_en;
            data_w_en_hold   <= data_w_en;
            data_r_en_hold   <= data_r_en;
            poll_wip_en_hold <= poll_wip_en;
            addr_4byte_hold  <= addr_4byte;
            REQ              <= 1'b1;
        end
         else if (ACK) begin
            REQ <= 1'b0;
        end
        else if (!REQ && !ACK) begin
            start_hold       <= 1'b0;
            opcode_en_hold   <= 1'b0;
            addr_en_hold     <= 1'b0;
            mode_en_hold     <= 1'b0;
            dummy_en_hold    <= 1'b0;
            data_w_en_hold   <= 1'b0;
            data_r_en_hold   <= 1'b0;
            poll_wip_en_hold <= 1'b0;
            addr_4byte_hold  <= 1'b0;
        end
    end
end
endmodule

