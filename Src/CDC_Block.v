`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2026 12:23:34
// Design Name: 
// Module Name: CDC_Block
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
module CDC_Block(
    input wire PCLK,
    input wire PRESETn,
    
    input wire SCLK,
    input wire SRESETn,
    
    input wire [7:0]reg_opcode,    
    input wire [31:0]reg_addr,      
    input wire [7:0]reg_mode,      
    input wire [7:0]reg_dummy,     
    input wire [7:0]reg_length,                       
    input wire [1:0]opcode_line,    
    input wire [1:0]addr_line,      
    input wire [1:0]data_line,  
    input wire [1:0]mode_line,                          
    input wire start,                
    input wire opcode_en,            
    input wire addr_en,              
    input wire mode_en,              
    input wire dummy_en,             
    input wire data_w_en,
    input wire data_r_en, 
    input wire poll_wip_en,  
    input wire addr_4byte,         
    output wire [7:0]reg_opcode_Q, 
    output wire [31:0]reg_addr_Q,  
    output wire [7:0]reg_mode_Q,   
    output wire [7:0]reg_dummy_Q,  
    output wire [7:0]reg_length_Q,
    
    output wire [1:0]opcode_line_Q,
    output wire [1:0]addr_line_Q,  
    output wire [1:0]data_line_Q,  
    output wire [1:0]mode_line_Q,
    
    output wire start_Q,           
    output wire opcode_en_Q,       
    output wire addr_en_Q,         
    output wire mode_en_Q,         
    output wire dummy_en_Q,        
    output wire data_w_en_Q, 
    output wire data_r_en_Q,
    output wire poll_wip_en_Q,
    output wire addr_4byte_Q
    );
    wire ACK_Sync,ACK_Unsync;
    wire REQ_Sync,REQ_Unsync;
    
    wire [7:0]reg_opcode_hold;      
    wire [31:0]reg_addr_hold;      
    wire [7:0]reg_mode_hold;       
    wire [7:0]reg_dummy_hold;       
    wire [7:0]reg_length_hold;     
    wire [1:0]opcode_line_hold;     
    wire [1:0]addr_line_hold;       
    wire [1:0]data_line_hold; 
    wire [1:0]mode_line_hold;      
    wire start_hold;                
    wire opcode_en_hold;            
    wire addr_en_hold;              
    wire mode_en_hold;              
    wire dummy_en_hold;             
    wire data_w_en_hold;  
    wire data_r_en_hold; 
    wire poll_wip_en_hold;  
    wire addr_4byte_hold;           
    

    Handshake_Sync HandShake_Tx 
    (  
       .PCLK(PCLK),
       .PRESETn(PRESETn),
       .ACK(ACK_Sync),
       .REQ(REQ_Unsync),
       .reg_opcode(reg_opcode),    
       .reg_addr(reg_addr),      
       .reg_mode(reg_mode),      
       .reg_dummy(reg_dummy),     
       .reg_length(reg_length),                       
       .opcode_line(opcode_line),    
       .addr_line(addr_line),      
       .data_line(data_line),  
       .mode_line(mode_line),                        
       .start(start),                
       .opcode_en(opcode_en),            
       .addr_en(addr_en),              
       .mode_en(mode_en),              
       .dummy_en(dummy_en),             
       .data_w_en(data_w_en),
       .data_r_en(data_r_en), 
       .poll_wip_en(poll_wip_en),
       .addr_4byte(addr_4byte),

       .reg_opcode_hold(reg_opcode_hold), 
       .reg_addr_hold(reg_addr_hold),  
       .reg_mode_hold(reg_mode_hold),   
       .reg_dummy_hold(reg_dummy_hold),  
       .reg_length_hold(reg_length_hold),
       .opcode_line_hold(opcode_line_hold),
       .addr_line_hold(addr_line_hold),  
       .data_line_hold(data_line_hold),
       .mode_line_hold(mode_line_hold),  
       .start_hold(start_hold),           
       .opcode_en_hold(opcode_en_hold),       
       .addr_en_hold(addr_en_hold),         
       .mode_en_hold(mode_en_hold),         
       .dummy_en_hold(dummy_en_hold),        
       .data_w_en_hold(data_w_en_hold),
       .data_r_en_hold(data_r_en_hold),
       .poll_wip_en_hold(poll_wip_en_hold),
       .addr_4byte_hold(addr_4byte_hold)
    );
    
    Sync #(1) REQ_2ff (.clk(SCLK),.rst(SRESETn),.din(REQ_Unsync),.q(REQ_Sync));
    Sync #(1) ACK_2ff (.clk(PCLK),.rst(PRESETn),.din(ACK_Unsync),.q(ACK_Sync));
    
    
    Handshake_Reciver Handshake_Rx(
           .SCLK(SCLK),            
           .SRESETn(SRESETn),         
           .REQ(REQ_Sync),             
           .reg_opcode_hold(reg_opcode_hold), 
           .reg_addr_hold(reg_addr_hold),   
           .reg_mode_hold(reg_mode_hold),   
           .reg_dummy_hold(reg_dummy_hold),  
           .reg_length_hold(reg_length_hold), 
           .opcode_line_hold(opcode_line_hold),
           .addr_line_hold(addr_line_hold),  
           .data_line_hold(data_line_hold), 
           .mode_line_hold(mode_line_hold),
           .start_hold(start_hold),      
           .opcode_en_hold(opcode_en_hold),  
           .addr_en_hold(addr_en_hold),    
           .mode_en_hold(mode_en_hold),    
           .dummy_en_hold(dummy_en_hold),   
           .data_w_en_hold(data_w_en_hold), 
           .data_r_en_hold(data_r_en_hold), 
           .poll_wip_en_hold(poll_wip_en_hold), 
           .addr_4byte_hold(addr_4byte_hold), 
           .ACK(ACK_Unsync),              
           .reg_opcode(reg_opcode_Q),       
           .reg_addr(reg_addr_Q),         
           .reg_mode(reg_mode_Q),         
           .reg_dummy(reg_dummy_Q),        
           .reg_length(reg_length_Q),       
           .opcode_line(opcode_line_Q),      
           .addr_line(addr_line_Q),        
           .data_line(data_line_Q), 
           .mode_line(mode_line_Q),          
           .start_sclk(start_Q),       
           .opcode_en(opcode_en_Q),        
           .addr_en(addr_en_Q),          
           .mode_en(mode_en_Q),          
           .dummy_en(dummy_en_Q),         
           .data_w_en(data_w_en_Q),
           .data_r_en(data_r_en_Q),
           .poll_wip_en(poll_wip_en_Q), 
           .addr_4byte(addr_4byte_Q)           
   );
endmodule
