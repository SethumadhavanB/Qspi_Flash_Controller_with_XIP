`timescale 1ns / 1ps
`default_nettype none
module Reset_Sync (
    input  wire clk,
    input  wire reset_n,
    output wire reset_sync_n
);

    reg sync_ff1;
    reg sync_ff2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end
        else begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= sync_ff1;
        end
    end

    assign reset_sync_n = sync_ff2;

endmodule