
module Xip_Prefetch_Buffer #(
    parameter LINE_BYTES = 32,      // 16, 32, 64 or 128
    parameter LINE_SHIFT = 5        // log2(LINE_BYTES)
)(
    input  wire        HCLK,
    input  wire        HRESETn,
 
    input  wire        invalidate,
 
    input  wire        req,
    input  wire [31:0] req_addr,
    output reg  [31:0] rsp_data,
    output reg         rsp_valid,
 
    output reg  [31:0] xip_addr,
    output wire [7:0]  xip_length,
    output reg         xip_req,
    input  wire        xip_done,
 
    output reg         fifo_rd_en,
    input  wire [7:0]  fifo_rdata,
    input  wire        fifo_empty,
 
    output wire        busy
);
 
    localparam [7:0]  LINE_CNT = LINE_BYTES;
    localparam [31:0] Tag_mask = ~((32'd1 << LINE_SHIFT) - 32'd1);
    localparam [31:0] Off_mask =  ((32'd1 << LINE_SHIFT) - 32'd1);
 
    localparam IDX_W = LINE_SHIFT;
 
    assign xip_length = LINE_CNT;
 
    reg [7:0]  Buffer_Mem [0:LINE_BYTES-1];
    reg [31:0] Tag;
    reg        line_valid;
 
    reg [7:0]  fill_idx;
    reg [31:0] fill_tag;
    reg [31:0] held_addr;
    reg        fill_stale;
 
    reg [1:0]  rd_pipe;
 
    wire [31:0] held_tag = held_addr & Tag_mask;
    wire [7:0]  byte_off = held_addr[7:0] & Off_mask[7:0];
    wire        hit      = line_valid && (held_tag == Tag);
 

    wire [IDX_W-1:0] idx0 = {byte_off[IDX_W-1:2], 2'b00};
    wire [IDX_W-1:0] idx1 = idx0 + 2'd1;
    wire [IDX_W-1:0] idx2 = idx0 + 2'd2;
    wire [IDX_W-1:0] idx3 = idx0 + 2'd3;
 
    localparam [2:0] Idle      = 3'd0;
    localparam [2:0] Check     = 3'd1;
    localparam [2:0] Flash_Req = 3'd2;
    localparam [2:0] Fill_Buff = 3'd3;
    localparam [2:0] Data_Read = 3'd4;
 
    reg [2:0] state;
    assign busy = (state != Idle);
    integer i;
 
    wire miss_start = (state == Check) && !hit;
    wire fill_last  = (state == Fill_Buff) && rd_pipe[1] &&
                      (fill_idx == (LINE_CNT - 8'd1));
 
    always @(posedge HCLK or negedge HRESETn)
        line_valid <= !HRESETn   ? 1'b0        :
                      invalidate ? 1'b0        :
                      miss_start ? 1'b0        :
                      fill_last  ? !fill_stale :
                                   line_valid;
 
    always @(posedge HCLK or negedge HRESETn)
        fill_stale <= !HRESETn   ? 1'b0 :
                      miss_start ? 1'b0 :
                      (invalidate && ((state == Flash_Req) ||
                                      (state == Fill_Buff))) ? 1'b1 :
                                   fill_stale;
 

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state      <= Idle;
            Tag        <= 32'd0;
            fill_idx   <= 8'd0;
            fill_tag   <= 32'd0;
            held_addr  <= 32'd0;
            xip_req    <= 1'b0;
            xip_addr   <= 32'd0;
            fifo_rd_en <= 1'b0;
            rd_pipe    <= 2'b00;
            rsp_valid  <= 1'b0;
            rsp_data   <= 32'd0;
            for (i = 0; i < LINE_BYTES; i = i + 1)
                Buffer_Mem[i] <= 8'd0;
        end
        else begin
            fifo_rd_en <= 1'b0;
            rd_pipe    <= {rd_pipe[0], fifo_rd_en};
            rsp_valid  <= 1'b0;
 
            case (state)
 
            Idle: begin
                if (req) begin
                    held_addr <= req_addr;   
                    state     <= Check;
                end
            end
 
            Check: begin
                if (hit) begin
                    // Byte 0 lowest: little-endian.
                    rsp_data  <= {Buffer_Mem[idx3], Buffer_Mem[idx2],
                                  Buffer_Mem[idx1], Buffer_Mem[idx0]};
                    rsp_valid <= 1'b1;
                    state     <= Idle;
                end
                else begin
                    xip_addr <= held_tag;   
                    fill_tag <= held_tag;
                    fill_idx <= 8'd0;
                    xip_req  <= 1'b1;       
                    state    <= Flash_Req;
                end
            end
 
            Flash_Req: begin
                if (xip_done)
                    state <= Fill_Buff;
            end
 
            Fill_Buff: begin
                if (!fifo_empty && (fill_idx < LINE_CNT)
                    && !fifo_rd_en && !rd_pipe[0])
                    fifo_rd_en <= 1'b1;

                if (rd_pipe[1]) begin
                    Buffer_Mem[fill_idx[IDX_W-1:0]] <= fifo_rdata;
                    fill_idx <= fill_idx + 1'b1;
 
                    if (fill_idx == (LINE_CNT - 8'd1)) begin
                        xip_req <= 1'b0;
                        Tag     <= fill_tag;
                        state   <= Data_Read;
                    end
                end
            end
 
            Data_Read: begin
                rsp_data  <= {Buffer_Mem[idx3], Buffer_Mem[idx2],
                              Buffer_Mem[idx1], Buffer_Mem[idx0]};
                rsp_valid <= 1'b1;
                state     <= Idle;
            end
 
            default: state <= Idle;
            endcase
        end
    end
 
endmodule