`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2026 12:01:02
// Design Name: 
// Module Name: Qspi_Core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Createda
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none
module Qspi_Core(
    input wire Clk,
    input wire Reset,
    
    input wire Start,
    input wire Opcode_En,
    input wire Addr_En,
    input wire Mode_En,
    input wire Dummy_En,
    input wire Data_W_En,
    input wire Data_R_En,
    input wire Poll_WIP_En,
    
    input wire [1:0]Opcode_Line,
    input wire [1:0]Addr_Line,
    input wire [1:0]Mode_Line,
    input wire [1:0]Data_Line,
  
    input wire[7:0]Opcode,
    input wire[31:0]Addr, 
    input wire[7:0]Mode,  
    input wire[7:0]Dummy, 
    input wire[7:0]Data_Length,
    input wire[7:0]Data,
    input wire [3:0] Rx_In,

    input wire Addr_4Byte,
    
    //inout wire [3:0]Io,
    
    output wire Busy,
    output wire CS,
    output wire Done,
    output wire Error,
    output wire [7:0]Rx_Data,
    output wire Need_Data,
    output wire Write_Data,
    output wire [3:0] Tx_Data,
    output wire [3:0] Ioen

    );
    wire Tx_Load_Opcode; 
    wire Tx_Load_Addr;   
    wire Tx_Load_Mode;   
    wire Tx_Load_Dummy;  
    wire Tx_Load_Data;   
    wire Tx_Load_Status;
    
    wire WIP; 
    
    wire Tx_Shift;
    wire Rx_Shift;
    //wire [3:0] Tx_Data;
    //wire [3:0] Rx_In;
    //wire [3:0] Ioen;
    

    wire [7:0] Flash_Data;
    wire [3:0] Rx_Mode;
    wire [1:0] Tx_Line_Width;
    wire [1:0] Rx_Line_Width;

  Qspi_Fsm FSM (
      .Clk(Clk),
      .Reset(Reset),
      .Start(Start),
      .Opcode_En(Opcode_En),
      .Addr_En(Addr_En),
      .Mode_En(Mode_En),
      .Dummy_En(Dummy_En),
      .Data_W_En(Data_W_En),
      .Data_R_En(Data_R_En),
      .Poll_WIP_En(Poll_WIP_En),
      .Addr_4Byte(Addr_4Byte),
      
      .Opcode_Line(Opcode_Line),
      .Addr_Line(Addr_Line),
      .Mode_Line(Mode_Line),
      .Data_Line(Data_Line),
      
      .Dummy(Dummy),
      .Data_Length(Data_Length),
      .WIP(WIP),

      .Tx_Load_Opcode(Tx_Load_Opcode),
      .Tx_Load_Addr(Tx_Load_Addr),
      .Tx_Load_Mode(Tx_Load_Mode),
      .Tx_Load_Dummy(Tx_Load_Dummy),
      .Tx_Load_Data(Tx_Load_Data),
      .Tx_Load_Status(Tx_Load_Status),
      
      .Tx_Shift(Tx_Shift),
      .Rx_Shift(Rx_Shift),
      .Ioen(Ioen),
      .CS(CS),
      .Busy(Busy),
      .Done(Done),
      .Error(Error),
      .Need_Data(Need_Data),
      .Write_Data(Write_Data),
      .Tx_Line_Width(Tx_Line_Width),
      .Rx_Line_Width(Rx_Line_Width)
    );
      Tx_Shift_Reg Tx_Reg (
          .Clk(Clk),
          .Reset(Reset),
          .Tx_Shift(Tx_Shift),
          .Tx_Load_Opcode(Tx_Load_Opcode),
          .Tx_Load_Addr(Tx_Load_Addr),
          .Tx_Load_Dummy(Tx_Load_Dummy),
          .Tx_Load_Mode(Tx_Load_Mode),
          .Tx_Load_Data(Tx_Load_Data),
          .Tx_Load_Status(Tx_Load_Status),
          .Opcode(Opcode),
          .Addr(Addr),
          .Data(Data),
          .Mode(Mode),
          .Addr_4Byte(Addr_4Byte),
          .Line_Width(Tx_Line_Width),
          .Shift_Out(Tx_Data)
    ); 
  Rx_Shift_Reg Rx_Reg (
    .Rx_In(Rx_In),
    .Clk(Clk),
    .Reset(Reset),
    .Rx_Shift(Rx_Shift),
    .Line_Width(Rx_Line_Width),
    .Rx_Data(Flash_Data)
    );

    assign WIP = Flash_Data[0];
    assign Rx_Data = Flash_Data;

     
endmodule
