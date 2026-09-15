`timescale 1ns / 1ps
`default_nettype wire

module Xip_Handshake_Receiver (
 
    input  wire        SCLK,
    input  wire        SRESETn,
 
    input  wire        REQ,
 
    input  wire [31:0] xip_addr_hold,
    input  wire [7:0]  xip_length_hold,
    input  wire        xip_req_hold,
 
    output reg         ACK,
 
    output reg  [31:0] xip_addr,
    output reg  [7:0]  xip_length,
    output reg         xip_req
);
 
    reg  REQ_d;
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
            ACK        <= 1'b0;
            xip_addr   <= 32'd0;
            xip_length <= 8'd0;
            xip_req    <= 1'b0;
        end
        else begin
            if (REQ_rise && !ACK) begin
                xip_addr   <= xip_addr_hold;
                xip_length <= xip_length_hold;
                xip_req    <= xip_req_hold;
                ACK        <= 1'b1;
            end
            else if (!REQ) begin
                ACK     <= 1'b0;
                xip_req <= 1'b0;    
            end
        end
    end
 
endmodule