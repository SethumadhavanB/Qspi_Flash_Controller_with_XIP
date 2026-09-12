`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10.08.2026 09:59:45
// Design Name:
// Module Name: Tx_Shift_Reg
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
module Tx_Shift_Reg(
     input wire  Clk,
     input wire  Reset,
     input wire  Tx_Shift,
     input wire  Tx_Load_Opcode,
     input wire  Tx_Load_Addr,
     input wire  Tx_Load_Dummy,
     input wire  Tx_Load_Mode,
     input wire  Tx_Load_Data,
     input wire  Tx_Load_Status,
     input wire [7:0] Opcode,
     input wire [31:0] Addr,
     input wire [7:0] Data,
     input wire [7:0] Mode,
    //  input wire [3:0] Tx_Ioen,
     input wire     Addr_4Byte,
     input wire [1:0]  Line_Width,   // 00=1-bit, 01=2-bit, 10=4-bit
     output wire [3:0]  Shift_Out
);

reg [31:0] Shift_Reg;

always @(posedge Clk or negedge Reset)
begin
    if (!Reset)
    begin
        Shift_Reg <= 32'd0;
    end
    else if (Tx_Load_Opcode)
    begin
        Shift_Reg <= {Opcode,24'd0};
    end
    else if (Tx_Load_Addr)
    begin
        Shift_Reg <= Addr_4Byte ? Addr : {Addr[23:0], 8'd0};
    end
    else if (Tx_Load_Dummy)
    begin
        Shift_Reg <= 32'd0 ; 
    end
    
    else if(Tx_Load_Mode)
    begin
       Shift_Reg <= {Mode,24'd0};
    end
    else if (Tx_Load_Data)
    begin
        Shift_Reg <= {Data,24'd0};
    end
    
    else if (Tx_Load_Status)
    begin
        Shift_Reg <= {8'h05,24'd0};
    end
    else if (Tx_Shift)
    begin
        case (Line_Width)
            2'b00: Shift_Reg <= {Shift_Reg[30:0], 1'b0};
            2'b01: Shift_Reg <= {Shift_Reg[29:0], 2'b0};
            2'b10: Shift_Reg <= {Shift_Reg[27:0], 4'b0};
            default: Shift_Reg <= {Shift_Reg[30:0], 1'b0};
        endcase
    end
end

    assign Shift_Out[0] = (Line_Width == 2'b00) ? Shift_Reg[31] :
                        (Line_Width == 2'b01) ? Shift_Reg[30] : Shift_Reg[28];
    assign Shift_Out[1] = (Line_Width == 2'b01) ? Shift_Reg[31] : Shift_Reg[29];
    assign Shift_Out[2] = Shift_Reg[30];
    assign Shift_Out[3] = Shift_Reg[31];
endmodule