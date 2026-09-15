`timescale 1ns / 1ps
`default_nettype wire

module Xip_Handshake_Sync(
 
    input  wire        HCLK,
    input  wire        HRESETn,
 
    input  wire        ACK,
    output reg         REQ,
 
    input  wire        xip_req,
    input  wire [31:0] xip_addr,
    input  wire [7:0]  xip_length,
 
    output reg  [31:0] xip_addr_hold,
    output reg  [7:0]  xip_length_hold,
    output reg         xip_req_hold
);
 
    reg  req_d;
    wire req_pulse;
 
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            req_d <= 1'b0;
        else
            req_d <= xip_req;
    end
 
    assign req_pulse = xip_req & ~req_d;
 
    // Handshake
    always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        REQ             <= 1'b0;
        xip_addr_hold   <= 32'd0;
        xip_length_hold <= 8'd0;
        xip_req_hold    <= 1'b0;
    end
    else begin
        if (xip_req && !REQ && !ACK && !xip_req_hold) begin
            xip_addr_hold   <= xip_addr;
            xip_length_hold <= xip_length;
            xip_req_hold    <= 1'b1;
            REQ             <= 1'b1;
        end
        else if (ACK) begin
            REQ <= 1'b0;
        end
        else if (!xip_req) begin
            xip_req_hold <= 1'b0;
        end
    end
end
 
endmodule