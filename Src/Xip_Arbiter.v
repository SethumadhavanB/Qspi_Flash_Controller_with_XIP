`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 9.09.2026 15:49:41
// Design Name: 
// Module Name: Xip_Arbiter
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
`default_nettype none
module Xip_Arbiter (
    input  wire       SCLK,
    input  wire       SRESETn,

    input  wire       apb_start,    
    input  wire       xip_req,

    
    input  wire [7:0] xip_length,   

    input  wire       core_busy,        
    input  wire       core_write_data,

    output reg        xip_owns,         
    output wire       core_start,       
    output reg        xip_done   

);
    reg [7:0] rx_count;
    reg       xip_launched;

    always @(posedge SCLK or negedge SRESETn) begin
        if (!SRESETn)
            xip_owns <= 1'b0;
        else if (!xip_owns && !core_busy && !apb_start && xip_req)
            xip_owns <= 1'b1;            
        else if (xip_owns && !xip_req)
            xip_owns <= 1'b0;           
    end

    always @(posedge SCLK or negedge SRESETn) begin
        if (!SRESETn) begin
            rx_count <= 8'd0;
            xip_done <= 1'b0;
        end
        else if (!xip_owns) begin
            rx_count <= 8'd0;
            xip_done <= 1'b0;
        end
        else begin
            if (core_write_data && (rx_count < xip_length))
                rx_count <= rx_count + 1'b1;
 
            if (rx_count == xip_length)
                xip_done <= 1'b1;       
        end
    end
    
    always @(posedge SCLK or negedge SRESETn) begin
        if (!SRESETn)          xip_launched <= 1'b0;
        else if (!xip_owns)    xip_launched <= 1'b0;
        else if (core_busy)    xip_launched <= 1'b1;
    end
 
    wire xip_go = xip_owns && !xip_launched && !core_busy;
    assign core_start = xip_owns ? xip_go : apb_start; 
endmodule