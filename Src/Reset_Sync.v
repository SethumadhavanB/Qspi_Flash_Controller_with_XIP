`timescale 1ns / 1ps
`default_nettype none
module Reset_Sync (
    input  wire clk,
    input  wire reset_n,
    output reg reset_sync_n
);

    reg sync_ff1;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sync_ff1 <= 1'b0;
            reset_sync_n <= 1'b0;
        end
        else begin
            sync_ff1 <= reset_n;
            reset_sync_n <= sync_ff1;
        end
    end

