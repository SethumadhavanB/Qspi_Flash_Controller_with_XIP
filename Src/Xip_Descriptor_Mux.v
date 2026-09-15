`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.09.2026 10:50:33
// Design Name: 
// Module Name: Xip_Descriptor_Mux
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

module Xip_Descriptor_Mux (
    input  wire      xip_owns,
 
    // ---- indirect descriptor (from CDC_Block, SCLK domain) ----
    input  wire [7:0]  ind_opcode,
    input  wire [31:0] ind_addr,
    input  wire [7:0]  ind_mode,
    input  wire [7:0]  ind_dummy,
    input  wire [7:0]  ind_length,
    input  wire [1:0]  ind_opcode_line,
    input  wire [1:0]  ind_addr_line,
    input  wire [1:0]  ind_mode_line,
    input  wire [1:0]  ind_data_line,
    input  wire        ind_opcode_en,
    input  wire        ind_addr_en,
    input  wire        ind_mode_en,
    input  wire        ind_dummy_en,
    input  wire        ind_data_w_en,
    input  wire        ind_data_r_en,
    input  wire        ind_poll_wip_en,
    input  wire        ind_addr_4byte,
 
    // ---- XIP address and line length (from Xip_Cdc / prefetch buffer) ----
    input  wire [31:0] xip_addr,
    input  wire [7:0]  xip_length,   // line size: 16 / 32 / 64 bytes
 
    // ---- merged descriptor to Qspi_Core ----
    output wire [7:0]  core_opcode,
    output wire [31:0] core_addr,
    output wire [7:0]  core_mode,
    output wire [7:0]  core_dummy,
    output wire [7:0]  core_length,
    output wire [1:0]  core_opcode_line,
    output wire [1:0]  core_addr_line,
    output wire [1:0]  core_mode_line,
    output wire [1:0]  core_data_line,
    output wire        core_opcode_en,
    output wire        core_addr_en,
    output wire        core_mode_en,
    output wire        core_dummy_en,
    output wire        core_data_w_en,
    output wire        core_data_r_en,
    output wire        core_poll_wip_en,
    output wire        core_addr_4byte
);
 

    localparam [7:0] XIP_OPCODE = 8'hEB;
    localparam [7:0] XIP_MODE   = 8'h00;  
    localparam [7:0] XIP_DUMMY  = 8'd6;
    localparam [1:0] LINE_1     = 2'b00;
    localparam [1:0] LINE_4     = 2'b10;
 
    assign core_opcode      = xip_owns ? XIP_OPCODE : ind_opcode;
    assign core_addr        = xip_owns ? xip_addr   : ind_addr;
    assign core_mode        = xip_owns ? XIP_MODE   : ind_mode;
    assign core_dummy       = xip_owns ? XIP_DUMMY  : ind_dummy;
    assign core_length      = xip_owns ? xip_length : ind_length;
 
    assign core_opcode_line = xip_owns ? LINE_1 : ind_opcode_line;
    assign core_addr_line   = xip_owns ? LINE_4 : ind_addr_line;
    assign core_mode_line   = xip_owns ? LINE_4 : ind_mode_line;
    assign core_data_line   = xip_owns ? LINE_4 : ind_data_line;
 
    assign core_opcode_en   = xip_owns ? 1'b1 : ind_opcode_en;
    assign core_addr_en     = xip_owns ? 1'b1 : ind_addr_en;

    assign core_mode_en     = xip_owns ? 1'b0 : ind_mode_en;
    assign core_dummy_en    = xip_owns ? 1'b1 : ind_dummy_en;
    assign core_data_w_en   = xip_owns ? 1'b0 : ind_data_w_en;
    assign core_data_r_en   = xip_owns ? 1'b1 : ind_data_r_en;
    assign core_poll_wip_en = xip_owns ? 1'b0 : ind_poll_wip_en;
    assign core_addr_4byte  = xip_owns ? 1'b0 : ind_addr_4byte;
    endmodule