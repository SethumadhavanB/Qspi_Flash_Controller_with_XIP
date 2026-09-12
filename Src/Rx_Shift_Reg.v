`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.08.2026 11:18:23
// Design Name: 
// Module Name: Rx_Shift_Reg
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
`default_nettype wire
module Rx_Shift_Reg(
    input wire [3:0] Rx_In,
    input wire Clk,
    input wire Reset,
    input wire Rx_Shift,
    input wire [1:0] Line_Width,   // 00=1-bit, 01=2-bit, 10=4-bit
    output wire [7:0] Rx_Data
);
    reg [7:0] Rx_Shift_Reg;



    always @(posedge Clk or negedge Reset) begin
        if (!Reset)
            Rx_Shift_Reg <= 8'd0;
            
        else if (Rx_Shift) begin
            case (Line_Width)
                // 1-line: MISO is IO1
                2'b00: Rx_Shift_Reg <= {Rx_Shift_Reg[6:0], Rx_In[1]};
                // 2-line: IO1 = MSB of the pair
                2'b01: Rx_Shift_Reg <= {Rx_Shift_Reg[5:0], Rx_In[1], Rx_In[0]};
                // 4-line: IO3 = MSB of the nibble
                2'b10: Rx_Shift_Reg <= {Rx_Shift_Reg[3:0], Rx_In[3:0]};
                default: Rx_Shift_Reg <= {Rx_Shift_Reg[6:0], Rx_In[1]};
            endcase
        end
    end

    assign Rx_Data = Rx_Shift_Reg; 
endmodule

