`timescale 1ns / 1ps
`default_nettype none
module Apb_Slave (
    input  wire PCLK,
    input  wire PRESETn,

    input  wire PSEL,
    input  wire PENABLE,
    input  wire PWRITE,
    input  wire [3:0]  PSTRB,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,

    output reg  [31:0] PRDATA,
    output reg  PREADY,
    output reg  PSLVERR,

    output wire [7:0]  reg_addr,
    output wire [31:0] reg_wdata,
    output wire [3:0]  reg_strb,
    output wire reg_we,
    output wire reg_re,
    input  wire [31:0] reg_rdata,
    input  wire data_done,
    input  wire Qspi_done,
    input wire Qspi_Error
);

    localparam ADDR_CONTROL = 8'h04;
    localparam ADDR_OPCODE  = 8'h08;
    localparam ADDR_ADDRESS = 8'h0C;
    localparam ADDR_MODE    = 8'h10;
    localparam ADDR_DUMMY   = 8'h14;
    localparam ADDR_LENGTH  = 8'h18;
    localparam ADDR_DATA    = 8'h1C;

    wire access_phase = PSEL && PENABLE;
    wire valid_addr   = (PADDR == ADDR_CONTROL) || (PADDR == ADDR_OPCODE)  ||
                        (PADDR == ADDR_ADDRESS) || (PADDR == ADDR_MODE)    ||
                        (PADDR == ADDR_DUMMY)   || (PADDR == ADDR_LENGTH)  ||
                        (PADDR == ADDR_DATA);

    wire valid_strb =
        (PADDR == ADDR_CONTROL && PSTRB == 4'b0111) ||
        (PADDR == ADDR_OPCODE  && PSTRB == 4'b0001) ||
        (PADDR == ADDR_ADDRESS && PSTRB == 4'b1111) ||
        (PADDR == ADDR_MODE    && PSTRB == 4'b0001) ||
        (PADDR == ADDR_DUMMY   && PSTRB == 4'b0001) ||
        (PADDR == ADDR_LENGTH  && PSTRB == 4'b0001) ||
        (PADDR == ADDR_DATA    && ((PSTRB == 4'b0001) || (PSTRB == 4'b0011) || (PSTRB == 4'b0111) || (PSTRB == 4'b1111)));

    wire data_access = access_phase && (PADDR == ADDR_DATA);
    wire Start       = access_phase && (PADDR == ADDR_CONTROL) && PWDATA[0] && PWRITE;

    assign reg_addr  = PADDR;
    assign reg_wdata = PWDATA;
    assign reg_strb  = PSTRB;
    assign reg_we    = access_phase && PWRITE;
    assign reg_re    = access_phase && !PWRITE;
    reg Busy;

    always @(posedge PCLK or negedge PRESETn)
    begin
        if (!PRESETn)
        begin
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;
            PRDATA  <= 32'd0;
            Busy <= 1'b0;
        end
        else
        begin
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

            if(Busy)
            begin
                if (Qspi_done)
                begin
                        PREADY <= 1'b1;
                        Busy <= 1'b0;
                end
                else if (Qspi_Error)
                begin
                    PREADY <= 1'b1;
                    Busy <= 1'b0;
                    PSLVERR <= 1'b1;
                end
                    else
                    PREADY <= 1'b0;
            end

            else if (access_phase)
            begin
                if (!valid_addr || (PWRITE && !valid_strb))
                begin
                    PREADY  <= 1'b1;
                    PSLVERR <= 1'b1;
                end

                else if (data_access)
                begin
                    PREADY <= data_done;
                    if (data_done && !PWRITE)
                        PRDATA <= reg_rdata;
                end

                else if (Start)
                begin
                    Busy <= 1'b1;
                end

                else
                begin
                    PREADY <= 1'b1;
                    if (!PWRITE)
                        PRDATA <= reg_rdata;
                end
            end
        end
    end
endmodule