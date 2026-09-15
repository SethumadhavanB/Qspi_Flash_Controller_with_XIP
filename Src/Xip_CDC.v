`timescale 1ns / 1ps
`default_nettype none
module Xip_Cdc (

    // ---------------- HCLK domain ----------------
    input  wire        HCLK,
    input  wire        HRESETn,

    input  wire        xip_req_h,
    input  wire [31:0] xip_addr_h,
    input  wire [7:0]  xip_length_h,
    output wire        xip_done_h,

    // ---------------- SCLK domain ----------------
    input  wire        SCLK,
    input  wire        SRESETn,

    output wire        xip_req_s,
    output wire [31:0] xip_addr_s,
    output wire [7:0]  xip_length_s,
    input  wire        xip_done_s
);

    wire        ACK_Sync, ACK_Unsync;
    wire        REQ_Sync, REQ_Unsync;

    wire [31:0] xip_addr_hold;
    wire [7:0]  xip_length_hold;
    wire        xip_req_hold;

    Xip_Handshake_Sync Xip_HandShake_Tx (
        .HCLK            (HCLK),
        .HRESETn         (HRESETn),
        .ACK             (ACK_Sync),
        .REQ             (REQ_Unsync),
        .xip_req         (xip_req_h),
        .xip_addr        (xip_addr_h),
        .xip_length      (xip_length_h),
        .xip_addr_hold   (xip_addr_hold),
        .xip_length_hold (xip_length_hold),
        .xip_req_hold    (xip_req_hold)
    );

    Sync #(1) REQ_2ff (
        .clk (SCLK), .rst (SRESETn),
        .din (REQ_Unsync), .q (REQ_Sync)
    );

    Sync #(1) ACK_2ff (
        .clk (HCLK), .rst (HRESETn),
        .din (ACK_Unsync), .q (ACK_Sync)
    );

    Xip_Handshake_Receiver Xip_HandShake_Rx (
        .SCLK            (SCLK),
        .SRESETn         (SRESETn),
        .REQ             (REQ_Sync),
        .xip_addr_hold   (xip_addr_hold),
        .xip_length_hold (xip_length_hold),
        .xip_req_hold    (xip_req_hold),
        .ACK             (ACK_Unsync),
        .xip_addr        (xip_addr_s),
        .xip_length      (xip_length_s),
        .xip_req         ()
    );

    Sync #(1) REQLVL_2ff (
        .clk (SCLK), .rst (SRESETn),
        .din (xip_req_h), .q (xip_req_s)
    );

    Sync #(1) DONE_2ff (
        .clk (HCLK), .rst (HRESETn),
        .din (xip_done_s), .q (xip_done_h)
    );

endmodule