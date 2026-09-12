// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 25.08.2026 22:37:42
// // Design Name: 
// // Module Name: Fifo_Handler
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////
// `default_nettype none
// module Fifo_Handler(
//     input wire clk,
//     input wire reset,
    
//     input wire [31:0] tx_data,
//     input wire [3:0] tx_strb,
//     input wire tx_en,
//     output reg tx_done,
    
//     output reg rx_done,
//     input wire rx_en,
//     output reg wr_en,
//     output reg [7:0] fifo_w_data,
//     input wire full,
//     output wire rd_en,          // CHANGED: reg -> wire (combinational)
//     input wire empty
// );
//     reg [1:0] Count;
//     reg [2:0] byte_count;
//     reg [31:0] tx_data_reg;
//     reg tx_busy;
//     assign rd_en = rx_en && !empty;

//     always @(posedge clk or negedge reset)
//     begin
//         if (!reset)
//         begin
//             Count       <= 2'd0;
//             byte_count  <= 3'd0;
//             tx_data_reg <= 32'd0;
//             tx_busy     <= 1'b0;
//             wr_en       <= 1'b0;
//             fifo_w_data <= 8'd0;
//             tx_done     <= 1'b0;
//             rx_done     <= 1'b0;
//         end
//         else
//         begin
//             wr_en   <= 1'b0;
//             tx_done <= 1'b0;
//             rx_done <= rd_en;  
//             if (tx_en && !tx_busy)
//             begin
//                 tx_data_reg <= tx_data;
//                 Count       <= 2'd0;
//                 tx_busy     <= 1'b1;
//                 case (tx_strb)
//                     4'b0001: byte_count <= 3'd1;
//                     4'b0011: byte_count <= 3'd2;
//                     4'b0111: byte_count <= 3'd3;
//                     4'b1111: byte_count <= 3'd4;
//                     default: byte_count <= 3'd0;
//                 endcase
//             end
//             if (tx_busy && !full)
//             begin
//                 case (Count)
//                     2'd0: fifo_w_data <= tx_data_reg[7:0];
//                     2'd1: fifo_w_data <= tx_data_reg[15:8];
//                     2'd2: fifo_w_data <= tx_data_reg[23:16];
//                     2'd3: fifo_w_data <= tx_data_reg[31:24];
//                 endcase
//                 wr_en <= 1'b1;
//                 if (Count == (byte_count - 1'b1))
//                 begin
//                     tx_done    <= 1'b1;
//                     tx_busy    <= 1'b0;
//                     Count      <= 2'd0;
//                     byte_count <= 3'd0;
//                 end
//                 else
//                 begin
//                     Count <= Count + 1'b1;
//                 end
//             end
//         end
//     end
// endmodule

`default_nettype none
module Fifo_Handler(
    input wire clk,
    input wire reset,

    input wire [31:0] tx_data,
    input wire [3:0] tx_strb,
    input wire tx_en,
    output reg tx_done,

    output reg rx_done,
    input wire rx_en,
    output reg wr_en,
    output reg [7:0] fifo_w_data,
    input wire full,
    output wire rd_en,

    input wire empty
);
    reg [1:0] Count;
    reg [2:0] byte_count;
    reg [31:0] tx_data_reg;
    reg tx_busy;

    wire tx_last_byte;

    assign rd_en = rx_en && !empty;
    assign tx_last_byte = tx_busy && !full && (Count == (byte_count - 1'b1));

    always @(posedge clk or negedge reset)
    begin
        if (!reset)
        begin
            Count       <= 2'd0;
            byte_count  <= 3'd0;
            tx_data_reg <= 32'd0;
            tx_busy     <= 1'b0;
            wr_en       <= 1'b0;
            fifo_w_data <= 8'd0;
            tx_done     <= 1'b0;
            rx_done     <= 1'b0;
        end
        else
        begin
            wr_en   <= 1'b0;
            tx_done <= 1'b0;
            rx_done <= rd_en;

            if (tx_en && !tx_busy)
            begin
                tx_data_reg <= tx_data;
            end

            if (tx_busy && !full)
            begin
                case (Count)
                    2'd0: fifo_w_data <= tx_data_reg[7:0];
                    2'd1: fifo_w_data <= tx_data_reg[15:8];
                    2'd2: fifo_w_data <= tx_data_reg[23:16];
                    2'd3: fifo_w_data <= tx_data_reg[31:24];
                endcase
                wr_en   <= 1'b1;
                tx_done <= tx_last_byte;
            end

            tx_busy <= tx_last_byte ? 1'b0 : ((tx_en && !tx_busy) ? 1'b1 : tx_busy);

            Count <= tx_last_byte       ? 2'd0 :
                     (tx_busy && !full)  ? (Count + 1'b1) :
                     (tx_en && !tx_busy) ? 2'd0 : Count;

            byte_count <= tx_last_byte ? 3'd0 :
                          (tx_en && !tx_busy) ?
                              ((tx_strb==4'b0001) ? 3'd1 :
                               (tx_strb==4'b0011) ? 3'd2 :
                               (tx_strb==4'b0111) ? 3'd3 :
                               (tx_strb==4'b1111) ? 3'd4 : 3'd0)
                          : byte_count;
        end
    end
endmodule
