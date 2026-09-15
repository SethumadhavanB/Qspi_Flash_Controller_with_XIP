`timescale 1ns / 1ps
`default_nettype none
module Ahb_Xip_Slave #(
    parameter [31:0] XIP_BASE = 32'h8000_0000,
    parameter [31:0] XIP_MASK = 32'hFF80_0000,   // 8 MB window
    parameter [15:0] TIMEOUT  = 16'd50000
)(
    input  wire        HCLK,
    input  wire        HRESETn,
 
    input  wire        xip_en,
 
    // ---- AHB-Lite slave ----
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [31:0] HWDATA,
    input  wire        HREADY,
 
    output reg  [31:0] HRDATA,
    output reg         HREADYOUT,
    output reg  [1:0]  HRESP,
 
    // ---- to Xip_Prefetch_Buffer ----
    output reg         req,
    output reg  [31:0] req_addr,
    input  wire [31:0] rsp_data,
    input  wire        rsp_valid
);
 
    localparam [1:0] RESP_OKAY  = 2'b00;
    localparam [1:0] RESP_ERROR = 2'b01;
 
    localparam [1:0] Idle  = 2'd0;
    localparam [1:0] Wait  = 2'd1;
    localparam [1:0] Err1  = 2'd2;
    localparam [1:0] Err2  = 2'd3;
 
    reg [1:0]  state;
    reg [15:0] tmo;
 
    wire addr_valid = HSEL && HREADY && HTRANS[1];
    wire in_range   = ((HADDR & XIP_MASK) == (XIP_BASE & XIP_MASK));
    wire size_ok    = (HSIZE == 3'b010);
 
    wire read_req = addr_valid && !HWRITE && in_range && size_ok && xip_en;
    wire bad_req  = addr_valid &&  in_range &&
                    (HWRITE || !size_ok || !xip_en);
 
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state     <= Idle;
            HREADYOUT <= 1'b1;
            HRESP     <= RESP_OKAY;
            HRDATA    <= 32'd0;
            req       <= 1'b0;
            req_addr  <= 32'd0;
            tmo       <= 16'd0;
        end
        else begin
            req <= 1'b0;                    
 
            case (state)
 
            Idle: begin
                HREADYOUT <= 1'b1;          
                HRESP     <= RESP_OKAY;
 
                if (read_req) begin
                    req_addr  <= {9'd0, HADDR[22:2], 2'b00};
                    req       <= 1'b1;
                    HREADYOUT <= 1'b0;      
                    tmo       <= 16'd0;
                    state     <= Wait;
                end
                else if (bad_req) begin
                    HREADYOUT <= 1'b0;
                    HRESP     <= RESP_ERROR;
                    state     <= Err1;
                end
            end

            Wait: begin
                HREADYOUT <= 1'b0;
                tmo       <= tmo + 1'b1;
 
                if (rsp_valid) begin
                    HRDATA    <= rsp_data;
                    HREADYOUT <= 1'b1;
                    HRESP     <= RESP_OKAY;
                    state     <= Idle;
                end
                else if (tmo >= TIMEOUT) begin
                    HRESP <= RESP_ERROR;
                    state <= Err1;
                end
            end
 
            Err1: begin
                HRESP     <= RESP_ERROR;
                HREADYOUT <= 1'b0;
                state     <= Err2;
            end
 
            Err2: begin
                HRESP     <= RESP_ERROR;
                HREADYOUT <= 1'b1;
                state     <= Idle;
            end
 
            default: state <= Idle;
            endcase
        end
    end
 
endmodule