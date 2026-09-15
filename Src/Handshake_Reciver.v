`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 15:43:43
// Design Name: 
// Module Name: Handshake_Reciver
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
module Handshake_Reciver(
   input  wire        SCLK,
   input  wire        SRESETn,
   input  wire        REQ,
   input  wire [7:0]  reg_opcode_hold,
   input  wire [31:0] reg_addr_hold,
   input  wire [7:0]  reg_mode_hold,
   input  wire [7:0]  reg_dummy_hold,
   input  wire [7:0] reg_length_hold,
   input  wire [1:0]  opcode_line_hold,
   input  wire [1:0]  addr_line_hold,
   input  wire [1:0]  data_line_hold,
   input wire [1:0] mode_line_hold,
   input  wire        start_hold,
   input  wire        opcode_en_hold,
   input  wire        addr_en_hold,
   input  wire        mode_en_hold,
   input  wire        dummy_en_hold,
   input  wire        data_w_en_hold,
   input  wire        data_r_en_hold,
   input wire         poll_wip_en_hold,
   input wire         addr_4byte_hold,
   output reg        ACK,
   output reg [7:0]  reg_opcode,
   output reg [31:0] reg_addr,
   output reg [7:0]  reg_mode,
   output reg [7:0]  reg_dummy,
   output reg [7:0] reg_length,
   output reg [1:0]  opcode_line,
   output reg [1:0]  addr_line,
   output reg [1:0]  data_line,
   output reg [1:0] mode_line,
   
   output reg start_sclk,
   output reg opcode_en,
   output reg addr_en,
   output reg mode_en,
   output reg dummy_en,
   output reg data_w_en,
   output reg data_r_en,
   output reg poll_wip_en,
   output reg addr_4byte
    );
    
     reg REQ_d;
      wire REQ_rise;
      always @(posedge SCLK or negedge SRESETn) begin
          if (!SRESETn)
              REQ_d <= 1'b0;
          else
              REQ_d <= REQ;
      end
      assign REQ_rise = REQ & ~REQ_d;
      
      
      always @(posedge SCLK or negedge SRESETn) begin
              if (!SRESETn) begin
                  ACK <= 1'b0;
                  start_sclk <= 1'b0;
                  reg_opcode <= 8'b0;
                  reg_addr   <= 32'b0;
                  reg_mode   <= 8'b0;
                  reg_dummy  <= 8'b0;
                  reg_length <= 8'b0;
                  opcode_line <= 2'b0;
                  addr_line   <= 2'b0;
                  data_line   <= 2'b0;
                  mode_line   <= 2'b0;
                  opcode_en <= 1'b0;
                  addr_en   <= 1'b0;
                  mode_en   <= 1'b0;
                  dummy_en  <= 1'b0;
                  data_w_en   <= 1'b0;
                  data_r_en   <= 1'b0;
                  poll_wip_en <= 1'b0;
                  addr_4byte <=1'b0;
              end
              else
              begin
                start_sclk <= 1'b0;
                if (REQ_rise && !ACK)
                 begin
                    reg_opcode <= reg_opcode_hold;
                    reg_addr   <= reg_addr_hold;
                    reg_mode   <= reg_mode_hold;
                    reg_dummy  <= reg_dummy_hold;
                    reg_length <= reg_length_hold;
                    opcode_line <= opcode_line_hold;
                    addr_line   <= addr_line_hold;
                    data_line   <= data_line_hold;
                    mode_line  <= mode_line_hold;
                    opcode_en <= opcode_en_hold;
                    addr_en   <= addr_en_hold;
                    mode_en   <= mode_en_hold;
                    dummy_en  <= dummy_en_hold;
                    data_w_en   <= data_w_en_hold;
                    data_r_en   <= data_r_en_hold;
                    poll_wip_en <= poll_wip_en_hold;
                    addr_4byte <= addr_4byte_hold;
                    start_sclk <= start_hold;
                    ACK <= 1'b1;
                 end
                 else if (!REQ) 
                 begin    
                   ACK <= 1'b0;
                 end         
             end
    end
endmodule
