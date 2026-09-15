`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.08.2026 14:42:51
// Design Name: 
// Module Name: Register_Bank
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
module Register_Bank(
    input  wire  PCLK,
    input  wire  PRESETn,
    input  wire [7:0]  reg_waddr,
    input  wire [31:0] reg_wdata,
    input  wire [3:0]  reg_strb,
    input  wire  reg_we,
    input  wire  reg_re,
    output reg  [31:0] reg_rdata,
    output wire data_done,

    output reg  [7:0]  reg_opcode,
    output reg  [31:0] reg_addr,
    output reg  [7:0]  reg_mode,
    output reg  [7:0]  reg_dummy,
    output reg  [7:0] reg_length,

    output wire [1:0] opcode_line,
    output wire [1:0] addr_line,
    output wire [1:0] data_line,
    output wire [1:0] mode_line,
    output wire       addr_4byte,

    output wire start,
    output wire opcode_en,
    output wire addr_en,
    output wire mode_en,
    output wire dummy_en,
    output wire data_w_en,
    output wire data_r_en,
    output wire poll_wip_en,

    output reg  [31:0] tx_data,
    output reg  [3:0]  tx_strb,
    output reg  tx_en,
    input  wire tx_done,

    input  wire [7:0]  fifo_r_Data,
    input  wire  rx_done,
    input  wire  empty,
    output wire  rx_en

);
    localparam ADDR_CONTROL = 8'h04;
    localparam ADDR_OPCODE  = 8'h08;
    localparam ADDR_ADDRESS = 8'h0C;
    localparam ADDR_MODE    = 8'h10;
    localparam ADDR_DUMMY   = 8'h14;
    localparam ADDR_LENGTH  = 8'h18;
    localparam ADDR_DATA    = 8'h1C;

    reg [16:0] reg_control;qedccccc
    reg tx_pending;
    reg rx_pending;
    reg [7:0] rx_data_reg;
    reg rx_data_valid;

    wire reg_we_pulse;
    wire tx_pending_set;

     assign start    =  reg_control[0];
     assign opcode_en = reg_control[1];
     assign addr_en   = reg_control[2];
     assign mode_en   = reg_control[3];
     assign dummy_en  = reg_control[4];
     assign data_w_en   = reg_control[5];
     assign data_r_en = reg_control[6];
     assign poll_wip_en = reg_control[13];
     assign opcode_line = reg_control[8:7];
     assign addr_line = reg_control[10:9];
     assign data_line = reg_control[12:11];
     assign mode_line   = reg_control[15:14];
     assign addr_4byte  = reg_control[16];

    assign rx_en = reg_re && (reg_waddr == ADDR_DATA) && !rx_pending && !empty;

    assign data_done = (tx_done && tx_pending) || rx_data_valid;

    assign tx_pending_set = reg_we_pulse && (reg_waddr == ADDR_DATA) &&
                             ((reg_strb==4'b0001)||(reg_strb==4'b0011)||(reg_strb==4'b0111)||(reg_strb==4'b1111)) &&
                             !tx_pending;

     always @(posedge PCLK or negedge PRESETn) begin
             if (!PRESETn)
             begin
                 reg_control <= 17'd0;
                 reg_opcode  <= 8'd0;
                 reg_addr    <= 32'd0;
                 reg_mode    <= 8'd0;
                 reg_dummy   <= 8'd0;
                 reg_length  <= 8'd0;
                 tx_data     <= 32'd0;
                 rx_data_reg <= 8'd0;
                 tx_strb     <= 4'd0;
                 tx_en       <= 1'b0;
                 tx_pending  <= 1'b0;
                 rx_pending  <= 1'b0;
                 rx_data_valid <= 1'b0;
             end
             else
             begin
              tx_en <= 1'b0;
              if (reg_we_pulse)
              begin
                case(reg_waddr)
                ADDR_CONTROL :begin if(reg_strb== 4'b0111) reg_control <= reg_wdata[16:0];  end
                ADDR_OPCODE  :begin if(reg_strb== 4'b0001) reg_opcode <= reg_wdata[7:0]; end
                ADDR_ADDRESS :begin if(reg_strb== 4'b1111) reg_addr <= reg_wdata; end
                ADDR_MODE    :begin if(reg_strb== 4'b0001) reg_mode <= reg_wdata[7:0]; end
                ADDR_DUMMY   :begin if(reg_strb== 4'b0001) reg_dummy <= reg_wdata[7:0];end
                ADDR_LENGTH  :begin if(reg_strb== 4'b0001) reg_length <= reg_wdata[7:0];end
                ADDR_DATA    :begin
                                  if(((reg_strb == 4'b0001)||(reg_strb == 4'b0011)||(reg_strb == 4'b0111)||(reg_strb == 4'b1111)))
                                  begin
                                    if(!tx_pending) begin
                                        tx_data <= reg_wdata;
                                        tx_strb <= reg_strb;
                                        tx_en   <= 1'b1;
                                     end
                                  end
                              end
                default:begin end
                endcase
             end

             tx_pending <= tx_done ? 1'b0 : (tx_pending_set ? 1'b1 : tx_pending);

             rx_pending <= rx_done ? 1'b0 : (rx_en ? 1'b1 : rx_pending);

             if (rx_done)
                 rx_data_reg <= fifo_r_Data;

             rx_data_valid <= rx_done ? 1'b1 :
                               ((data_done && reg_re && (reg_waddr == ADDR_DATA)) ? 1'b0 : rx_data_valid);

       end
   end
  always@(*)
  begin
        case (reg_waddr)
            ADDR_CONTROL: reg_rdata = {15'd0, reg_control};
            ADDR_OPCODE: reg_rdata = {24'd0, reg_opcode};
            ADDR_ADDRESS: reg_rdata = reg_addr;
            ADDR_MODE: reg_rdata = {24'd0, reg_mode};
            ADDR_DUMMY: reg_rdata = {24'd0, reg_dummy};
            ADDR_LENGTH:reg_rdata = {24'd0, reg_length};
            ADDR_DATA:reg_rdata = {24'd0, rx_data_reg};
            default:reg_rdata = 32'd0;
        endcase
    end

   reg reg_we_d;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            reg_we_d <= 1'b0;
        else
            reg_we_d <= reg_we;
    end

    assign reg_we_pulse = reg_we && !reg_we_d;

endmodule
