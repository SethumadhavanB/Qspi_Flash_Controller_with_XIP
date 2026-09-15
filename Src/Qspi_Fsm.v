`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 16:59:09
// Design Name: 
// Module Name: Qspi_Fsm
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
module Qspi_Fsm(
    input  wire Clk,
    input  wire Reset,
    input  wire Start,
    input  wire Opcode_En,
    input  wire Addr_En,
    input  wire Mode_En,
    input  wire Dummy_En,
    input  wire Data_W_En,
    input  wire Data_R_En,
    input  wire Poll_WIP_En,

    input  wire [1:0]Opcode_Line,
    input  wire [1:0]Addr_Line,
    input  wire [1:0]Mode_Line,
    input  wire [1:0]Data_Line,

    input  wire [7:0]Dummy,
    input  wire [7:0]Data_Length,
    input  wire WIP,
    input  wire Addr_4Byte,

    output reg Tx_Load_Opcode,
    output reg Tx_Load_Addr,
    output reg Tx_Load_Mode,
    output reg Tx_Load_Dummy,
    output reg Tx_Load_Data,
    output reg Tx_Load_Status,

    output reg Tx_Shift,
    output reg Rx_Shift,
    output reg [3:0]Ioen,
    output reg CS,
    output reg Busy,
    output reg Done,
    output reg Error,
    output reg Need_Data,
    output wire Write_Data,
    output reg [1:0] Tx_Line_Width,   
    output reg [1:0] Rx_Line_Width    
);

    localparam Idle         = 4'd0;
    localparam Opcode       = 4'd1;
    localparam Address      = 4'd2;
    localparam Mode_State   = 4'd3;
    localparam Dummy_Cycle  = 4'd4;
    localparam Data_State   = 4'd5;
    localparam Send_Cmd     = 4'd6;
    localparam Check_WIP    = 4'd7;
    localparam Done_State   = 4'd8;
    localparam Error_State  = 4'd9;
    localparam Poll_Load = 4'd10;
    

    reg [3:0] Current, Next_State;

    reg [4:0] Count;
    reg [4:0] Opcode_Count;
    reg [4:0] Addr_Count;
    reg [4:0] Mode_Count;
    reg [4:0] Status_Count;
    reg [3:0] Opcode_Ioen, Addr_Ioen, Mode_Ioen, Tx_Data_Ioen,Rx_Data_Ioen;
    reg [2:0] Bit_Count, Bit_Count_Max;
    reg [7:0] Byte_Count;

    wire Opcode_Done, Address_Done, Mode_Done, Dummy_Done, Data_Done, Read_Done, Status_Done;
    wire Tx_Byte_Done, Fetch_Data;
    reg  Rx_Byte_Done;
    wire Rx_Byte_Last_Bit;

    // Current State
    always @(posedge Clk or negedge Reset) 
    begin
        if (!Reset) Current <= Idle;
        else   Current <= Next_State;
    end

    //Next State
    always @(*) 
    begin
        case (Current)

            Idle: begin
                if (Start) 
                begin
                    if (Opcode_En && !(Data_W_En && Data_R_En)) Next_State = Opcode;
                    else Next_State = Error_State;
                end
                else       Next_State = Idle;
            end

            Opcode: begin
                if (Opcode_Done) begin
                    if (Addr_En)                          Next_State = Address;
                    else if (Mode_En)                     Next_State = Mode_State;
                    else if (Dummy_En && (Dummy != 0))    Next_State = Dummy_Cycle;
                    else if (Data_W_En && !Addr_En && !Mode_En && !Dummy_En) Next_State = Data_State;
                    else if (Data_R_En)                   Next_State = Data_State;
                    else if (Poll_WIP_En)                 Next_State = Poll_Load;
                    else                                  Next_State = Done_State;
                end else Next_State = Opcode;
            end
            
            
            Address: begin
                if (Address_Done) begin
                    if (Mode_En)                          Next_State = Mode_State;
                    else if (Dummy_En && (Dummy != 0))    Next_State = Dummy_Cycle;
                    else if (Data_W_En || Data_R_En)      Next_State = Data_State;
                    else if (Poll_WIP_En)                 Next_State = Poll_Load;
                    else                                  Next_State = Done_State;
                end else Next_State = Address;
            end
            
            Mode_State: begin
                if (Mode_Done) begin
                    if (Dummy_En && (Dummy != 0))    Next_State = Dummy_Cycle;
                    else if (Data_W_En || Data_R_En) Next_State = Data_State;
                    else if (Poll_WIP_En)            Next_State = Poll_Load;
                    else                              Next_State = Done_State;
                end else Next_State = Mode_State;
            end
            
            Dummy_Cycle: begin
                if (Dummy_Done) begin
                    if (Data_W_En || Data_R_En) Next_State = Data_State;
                    else if (Poll_WIP_En)       Next_State = Poll_Load;
                    else                         Next_State = Done_State;
                end else Next_State = Dummy_Cycle;
            end

            Data_State: begin
                if (Data_Done || Read_Done) begin
                    if (Poll_WIP_En) Next_State = Poll_Load;
                    else             Next_State = Done_State;
                end else Next_State = Data_State;
            end
            Poll_Load :begin
                Next_State = Send_Cmd;
            end
            Send_Cmd: begin
                if (Opcode_Done) Next_State = Check_WIP;
                else              Next_State = Send_Cmd;
            end

            Check_WIP: begin
                if (Status_Done) begin
                    if (WIP) Next_State = Poll_Load;
                    else     Next_State = Done_State;
                end else Next_State = Check_WIP;
            end

            Done_State:  Next_State = Idle;
            Error_State: Next_State = Idle;
            default:     Next_State = Idle;
        endcase
    end

    // ---- output logic ----
    always @(*) begin
        Tx_Load_Opcode = 1'b0;
        Tx_Load_Addr   = 1'b0;
        Tx_Load_Mode   = 1'b0;
        Tx_Load_Dummy  = 1'b0;
        Tx_Load_Data   = 1'b0;
        Tx_Load_Status = 1'b0;
        Tx_Shift       = 1'b0;
        Rx_Shift       = 1'b0;
        Ioen           = 4'b0000;
        CS             = 1'b1;
        Busy           = 1'b0;
        Done           = 1'b0;
        Error          = 1'b0;
        Need_Data      = 1'b0;

        case (Current)

            Idle: begin
                if (Start) 
                begin
                if(Opcode_En) Tx_Load_Opcode = 1'b1;
                end
            end

            Opcode: begin
                CS       = 1'b0;
                Busy     = 1'b1;
                Ioen     = Opcode_Ioen;
                Tx_Shift = 1'b1;

                if ((Count == 5'd6) && Data_W_En && !Addr_En && !Mode_En &&
                    !(Dummy_En && (Dummy != 0)))
                    Need_Data = 1'b1;
                    
                    if (Opcode_Done) begin
                        if (Addr_En)
                            Tx_Load_Addr = 1'b1;
                        else if (Mode_En)
                            Tx_Load_Mode = 1'b1;
                        else if (Data_W_En && !Addr_En && !Mode_En && !(Dummy_En && (Dummy != 0)))
                            Tx_Load_Data = 1'b1;
                        else if(Data_R_En) CS =1'b0;
                        else if(Poll_WIP_En) CS =1'b1;
                    end
            end

            Address: begin
                CS       = 1'b0;
                Busy     = 1'b1;
                Ioen     = Addr_Ioen;
                Tx_Shift = 1'b1;

                if ((Count == Addr_Count - 1'b1) && Data_W_En && !Mode_En &&
                    (!(Dummy_En && (Dummy != 0)) || (Dummy == 8'd1)))
                    Need_Data = 1'b1;

                if (Address_Done) begin
                    if (Mode_En)
                        Tx_Load_Mode = 1'b1;
                    else if (Dummy_En && (Dummy != 0))
                        Tx_Load_Dummy = 1'b1;
                    else if (Data_W_En)
                        Tx_Load_Data = 1'b1;
                end
            end

            Mode_State: begin
                CS       = 1'b0;
                Busy     = 1'b1;
                Ioen     = Mode_Ioen;
                Tx_Shift = 1'b1;

                if ((Count == Mode_Count - 1'b1) && Data_W_En &&
                    (!(Dummy_En && (Dummy != 0)) || (Dummy == 8'd1)))
                    Need_Data = 1'b1;

                if (Mode_Done) begin
                    if (Dummy_En && (Dummy != 0))
                        Tx_Load_Dummy = 1'b1;
                    else if (Data_W_En)
                        Tx_Load_Data = 1'b1;
                end
            end

                Dummy_Cycle: begin
                CS   = 1'b0;
                Busy = 1'b1;

                if ((Addr_Line != 2'b00) && (Count < 5'd2))
                    Ioen = Addr_Ioen;
                else
                    Ioen = 4'b0000;

                if ((Dummy >= 8'd2) && (Count == (Dummy - 8'd2)) && Data_W_En)
                    Need_Data = 1'b1;
                if (Dummy_Done && Data_W_En)
                    Tx_Load_Data = 1'b1;
            end

            Data_State: begin
                CS   = 1'b0;
                Busy = 1'b1;
                Ioen = 4'b0000;
                if (Data_W_En) begin
                    Ioen = Tx_Data_Ioen;
                    Tx_Shift = 1'b1;
                    if (Fetch_Data && (Byte_Count != Data_Length - 1'b1))
                        Need_Data = 1'b1;
                    if (Tx_Byte_Done)
                        Tx_Load_Data = 1'b1;
                    end 
                else if (Data_R_En) begin
                    Ioen = 4'b0000; 
                    Rx_Shift = 1'b1;

                end
            end
            
            Poll_Load: 
            begin
                Tx_Load_Status = 1'b1;
            end

            Send_Cmd: begin
                CS       = 1'b0;
                Busy     = 1'b1;
                Ioen     = 4'b0001;
                Tx_Shift = 1'b1;
            end

            Check_WIP: begin
                CS       = 1'b0;
                Busy     = 1'b1;
                Ioen     = 4'b0000;
                Rx_Shift = 1'b1;
//                if (Status_Done && WIP)
//                    Tx_Load_Status = 1'b1;
            end
            
 

            Done_State: begin
                CS   = 1'b1;
                Done = 1'b1;
            end

            Error_State: begin
                CS    = 1'b1;
                Error = 1'b1;
            end

            default: CS = 1'b1;
        endcase
    end

    always @(*)
    begin
        case (Opcode_Line)
            2'd0: begin Opcode_Ioen = 4'b0001; Opcode_Count = 5'd7; end
            2'd1: begin Opcode_Ioen = 4'b0011; Opcode_Count = 5'd3; end
            2'd2: begin Opcode_Ioen = 4'b1111; Opcode_Count = 5'd1; end
            default: begin Opcode_Ioen = 4'b0001; Opcode_Count = 5'd7; end
        endcase

        case (Addr_Line)
            2'd0: begin Addr_Ioen = 4'b0001; Addr_Count = Addr_4Byte ? 5'd31 : 5'd23; end
            2'd1: begin Addr_Ioen = 4'b0011; Addr_Count = Addr_4Byte ? 5'd15 : 5'd11; end
            2'd2: begin Addr_Ioen = 4'b1111; Addr_Count = Addr_4Byte ? 5'd7  : 5'd5;  end
            default: begin Addr_Ioen = 4'b0001; Addr_Count = Addr_4Byte ? 5'd31 : 5'd23; end
        endcase

        case (Mode_Line)
            2'd0: begin Mode_Ioen = 4'b0001; Mode_Count = 5'd7; end
            2'd1: begin Mode_Ioen = 4'b0011; Mode_Count = 5'd3; end
            2'd2: begin Mode_Ioen = 4'b1111; Mode_Count = 5'd1; end
            default: begin Mode_Ioen = 4'b0001; Mode_Count = 5'd7; end
        endcase

        case (Data_Line)
            2'd0: begin Tx_Data_Ioen = 4'b0001;  Bit_Count_Max = 3'd7; end
            2'd1: begin Tx_Data_Ioen = 4'b0011; Bit_Count_Max = 3'd3; end
            2'd2: begin Tx_Data_Ioen = 4'b1111;  Bit_Count_Max = 3'd1; end
            default: begin Tx_Data_Ioen = 4'b0001; Bit_Count_Max = 3'd7; end
        endcase

        Status_Count = 5'd7;
    end

    // ---- line width presented to the shift registers, per phase ----
    always @(*)
    begin
        case (Current)
            Opcode:      begin Tx_Line_Width = Opcode_Line; Rx_Line_Width = 2'b00; end
            Address:     begin Tx_Line_Width = Addr_Line;   Rx_Line_Width = 2'b00; end
            Mode_State:  begin Tx_Line_Width = Mode_Line;   Rx_Line_Width = 2'b00; end
            Dummy_Cycle: begin Tx_Line_Width = Addr_Line;   Rx_Line_Width = 2'b00; end
            Data_State:  begin Tx_Line_Width = Data_Line;   Rx_Line_Width = Data_Line; end
            Send_Cmd:    begin Tx_Line_Width = 2'b00;       Rx_Line_Width = 2'b00; end
            Check_WIP:   begin Tx_Line_Width = 2'b00;       Rx_Line_Width = 2'b00; end
            default:     begin Tx_Line_Width = 2'b00;       Rx_Line_Width = 2'b00; end
        endcase
    end

    // ---- phase bit-position counter ----
    always @(posedge Clk or negedge Reset)
    begin
        if (!Reset) Count <= 5'd0;
        else 
        begin
            case (Current)
                Opcode:      Count <= Opcode_Done  ? 5'd0 : Count + 1'b1;
                Address:     Count <= Address_Done ? 5'd0 : Count + 1'b1;
                Mode_State:  Count <= Mode_Done    ? 5'd0 : Count + 1'b1;
                Dummy_Cycle: Count <= Dummy_Done   ? 5'd0 : Count + 1'b1;
                Send_Cmd:    Count <= Opcode_Done  ? 5'd0 : Count + 1'b1;
                Check_WIP:   Count <= Status_Done  ? 5'd0 : Count + 1'b1;
                default:     Count <= 5'd0;
            endcase
        end
    end

    // ---- data-phase byte/bit counters ----
    always @(posedge Clk or negedge Reset) 
    begin
        if (!Reset) 
        begin
            Bit_Count  <= 3'd0;
            Byte_Count <= 8'd0;
        end 
        else if (Current == Data_State) 
        begin
            if (Bit_Count == Bit_Count_Max) 
            begin
                Bit_Count  <= 3'd0;
                Byte_Count <= Byte_Count + 1'b1;
            end 
            else 
            begin
                Bit_Count <= Bit_Count + 1'b1;
            end
        end 
        else begin
            Bit_Count  <= 3'd0;
            Byte_Count <= 8'd0;
        end
    end

   assign Opcode_Done  = ((Current == Opcode)&&(Count == Opcode_Count)) ||((Current == Send_Cmd) && (Count == 5'd7));
    assign Address_Done = (Current == Address) && (Count == Addr_Count);
    assign Mode_Done    = (Current == Mode_State)  && (Count == Mode_Count);
    assign Dummy_Done   = (Current == Dummy_Cycle) && (Count == (Dummy - 8'd1));
    assign Status_Done  = (Current == Check_WIP)   && (Count == Status_Count);

    assign Tx_Byte_Done = (Current == Data_State) && Data_W_En && (Bit_Count == Bit_Count_Max);
    assign Fetch_Data = (Current == Data_State) && Data_W_En && (Bit_Count == Bit_Count_Max - 1'b1);
    assign Data_Done = (Current == Data_State) && Data_W_En &&((Data_Length == 8'd0) || ((Byte_Count == Data_Length - 1'b1) && (Bit_Count == Bit_Count_Max)));

    assign Read_Done = (Current == Data_State) && Data_R_En &&((Data_Length == 8'd0) || ((Byte_Count == Data_Length - 1'b1) && (Bit_Count == Bit_Count_Max)));
    assign Rx_Byte_Last_Bit = (Current == Data_State) && Data_R_En && (Bit_Count == Bit_Count_Max);
    
    always @(posedge Clk or negedge Reset) begin
        if (!Reset) Rx_Byte_Done <= 1'b0;
        else Rx_Byte_Done <= Rx_Byte_Last_Bit;
    end
    assign Write_Data = Rx_Byte_Done;
    

endmodule
    