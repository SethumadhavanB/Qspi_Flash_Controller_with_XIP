`timescale 1ns / 1ps
`default_nettype none
module Xip_Coherency (
    // ---- SCLK domain ----
    input  wire SCLK,
    input  wire SRESETn,
    input  wire core_done,
    input  wire xip_owns,
 
    // ---- HCLK domain ----
    input  wire HCLK,
    input  wire HRESETn,
    output wire invalidate
);

    reg done_toggle;
 
    always @(posedge SCLK or negedge SRESETn) begin
        if (!SRESETn)
            done_toggle <= 1'b0;
        else if (core_done && !xip_owns)
            done_toggle <= ~done_toggle;
    end
    wire tog_sync;
    Sync #(1) TOG_2ff (
        .clk (HCLK), .rst (HRESETn),
        .din (done_toggle), .q (tog_sync)
    );
 
    reg tog_sync_d;
 
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) tog_sync_d <= 1'b0;
        else          tog_sync_d <= tog_sync;
    end
 
    assign invalidate = tog_sync ^ tog_sync_d;
 
endmodule