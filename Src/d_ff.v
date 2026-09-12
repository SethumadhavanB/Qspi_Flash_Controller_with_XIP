`timescale 1ns / 1ps

module d_ff (
    input  wire clk,      // Clock signal
    input  wire rst_n,    // Active-low asynchronous reset
    input  wire d,        // Data input
    output reg  q         // Data output
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;    // Reset output to 0
        end else begin
            q <= d;       // Capture input on rising clock edge
        end
    end

endmodule