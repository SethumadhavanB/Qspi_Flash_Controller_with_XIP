`timescale 1ns / 1ps
`default_nettype none
module qspi_Controller #(
    parameter XIP_LINE_BYTES = 32,
    parameter XIP_LINE_SHIFT = 5
)(
    // ---------------- clocks and resets ----------------
    input  wire        PCLK,
    input  wire        PRESETn,
 
    input  wire        HCLK,
    input  wire        HRESETn,
 
    input  wire        SCLK,
    input  wire        SRESETn,
 
    // ---------------- APB4 : indirect path ----------------
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [3:0]  PSTRB,
    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,
 
    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,
 
    // ---------------- AHB-Lite : XIP path ----------------
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [31:0] HWDATA,
    input  wire        HREADY,
 
    output wire [31:0] HRDATA,
    output wire        HREADYOUT,
    output wire [1:0]  HRESP,
 
    // ---------------- XIP configuration ----------------
    input  wire        xip_en,
 
    // ---------------- QSPI pins ----------------
    output wire        spi_cs_n,
    output wire        spi_sclk,
    inout  wire [3:0]  Io
);
 

    wire [7:0]  apb_reg_addr;
    wire [31:0] apb_reg_wdata;
    wire [3:0]  apb_reg_strb;
    wire        apb_reg_we;
    wire        apb_reg_re;
    wire [31:0] reg_rdata;
    wire        data_done;
 
    wire [7:0]  reg_opcode;
    wire [31:0] reg_addr;
    wire [7:0]  reg_mode;
    wire [7:0]  reg_dummy;
    wire [7:0]  reg_length;
    wire [1:0]  opcode_line;
    wire [1:0]  addr_line;
    wire [1:0]  data_line;
    wire [1:0]  mode_line;
    wire        addr_4byte;
    wire        start;
    wire        opcode_en;
    wire        addr_en;
    wire        mode_en;
    wire        dummy_en;
    wire        data_w_en;
    wire        data_r_en;
    wire        poll_wip_en;

    wire [31:0] tx_data;
    wire [3:0]  tx_strb;
    wire        tx_en;
    wire        tx_done;
    wire        rx_done;
    wire        rx_en;
 
    wire [7:0]  reg_opcode_Q;
    wire [31:0] reg_addr_Q;
    wire [7:0]  reg_mode_Q;
    wire [7:0]  reg_dummy_Q;
    wire [7:0]  reg_length_Q;
    wire [1:0]  opcode_line_Q;
    wire [1:0]  addr_line_Q;
    wire [1:0]  data_line_Q;
    wire [1:0]  mode_line_Q;
    wire        addr_4byte_Q;
    wire        start_Q;
    wire        opcode_en_Q;
    wire        addr_en_Q;
    wire        mode_en_Q;
    wire        dummy_en_Q;
    wire        data_w_en_Q;
    wire        data_r_en_Q;
    wire        poll_wip_en_Q;

    wire        tx_fifo_wr_en;
    wire [7:0]  tx_fifo_wdata;
    wire        tx_fifo_full;
    wire        tx_fifo_rd_en;
    wire [7:0]  tx_fifo_rdata;
    wire        tx_fifo_empty;
 
    wire        rx_fifo_wr_en;
    wire        rx_fifo_full;
    wire        rx_fifo_rd_en;
    wire [7:0]  rx_fifo_rdata;
    wire        rx_fifo_empty;
 
    wire        xip_rx_wr_en;
    wire        xip_rx_full;
    wire        xip_rx_rd_en;
    wire [7:0]  xip_rx_rdata;
    wire        xip_rx_empty;

    wire        qspi_busy;
    wire        qspi_done;
    wire        qspi_error;
    wire [7:0]  qspi_rx_data;
    wire        qspi_need_data;
    wire        qspi_write_data;
    wire [3:0]  Tx_Data;
    wire [3:0]  Rx_In;
    wire [3:0]  Ioen;
 

    wire        pf_req;
    wire [31:0] pf_req_addr;
    wire [31:0] pf_rsp_data;
    wire        pf_rsp_valid;
    wire        pf_invalidate;
 
    wire        xip_req_h;
    wire [31:0] xip_addr_h;
    wire [7:0]  xip_length_h;
    wire        xip_done_h;
 
    wire        xip_req_s;
    wire [31:0] xip_addr_s;
    wire [7:0]  xip_length_s;
    wire        xip_done_s;
 
    wire        xip_owns;
    wire        core_start;
 
    // merged descriptor
    wire [7:0]  core_opcode;
    wire [31:0] core_addr;
    wire [7:0]  core_mode;
    wire [7:0]  core_dummy;
    wire [7:0]  core_length;
    wire [1:0]  core_opcode_line;
    wire [1:0]  core_addr_line;
    wire [1:0]  core_mode_line;
    wire [1:0]  core_data_line;
    wire        core_opcode_en;
    wire        core_addr_en;
    wire        core_mode_en;
    wire        core_dummy_en;
    wire        core_data_w_en;
    wire        core_data_r_en;
    wire        core_poll_wip_en;
    wire        core_addr_4byte;
    wire        qspi_apb_error;
    wire        qspi_apb_done;
    wire        qspi_Core_busy;
    wire        apb_done_gf;
    wire        apb_error_gf;
    
   wire PRESETn_S,HRESETn_S,SRESETn_S;
   
   Reset_Sync Apb (.clk(PCLK),.reset_n(PRESETn),.reset_sync_n(PRESETn_S));
   Reset_Sync Ahb (.clk(HCLK),.reset_n(HRESETn),.reset_sync_n(HRESETn_S));
   Reset_Sync qspi (.clk(SCLK),.reset_n(SRESETn),.reset_sync_n(SRESETn_S));


    Apb_Slave apb_slave_inst (
        .PCLK      (PCLK),
        .PRESETn   (PRESETn_S),
        .PSEL      (PSEL),
        .PENABLE   (PENABLE),
        .PWRITE    (PWRITE),
        .PSTRB     (PSTRB),
        .PADDR     (PADDR),
        .PWDATA    (PWDATA),
        .PRDATA    (PRDATA),
        .PREADY    (PREADY),
        .PSLVERR   (PSLVERR),
        .reg_addr  (apb_reg_addr),
        .reg_wdata (apb_reg_wdata),
        .reg_strb  (apb_reg_strb),
        .reg_we    (apb_reg_we),
        .reg_re    (apb_reg_re),
        .reg_rdata (reg_rdata),
        .data_done (data_done),
        .Qspi_done  (qspi_apb_done),
        .Qspi_Error (qspi_apb_error)
    );
 
    Register_Bank reg_bank_inst (
        .PCLK       (PCLK),
        .PRESETn    (PRESETn_S),
        .reg_waddr  (apb_reg_addr),
        .reg_wdata  (apb_reg_wdata),
        .reg_strb   (apb_reg_strb),
        .reg_we     (apb_reg_we),
        .reg_re     (apb_reg_re),
        .reg_rdata  (reg_rdata),
        .data_done  (data_done),
 
        .reg_opcode (reg_opcode),
        .reg_addr   (reg_addr),
        .reg_mode   (reg_mode),
        .reg_dummy  (reg_dummy),
        .reg_length (reg_length),
        .opcode_line(opcode_line),
        .addr_line  (addr_line),
        .data_line  (data_line),
        .mode_line  (mode_line),
        .addr_4byte (addr_4byte),
        .start      (start),
        .opcode_en  (opcode_en),
        .addr_en    (addr_en),
        .mode_en    (mode_en),
        .dummy_en   (dummy_en),
        .data_w_en  (data_w_en),
        .data_r_en  (data_r_en),
        .poll_wip_en(poll_wip_en),
 
        .tx_data    (tx_data),
        .tx_strb    (tx_strb),
        .tx_en      (tx_en),
        .tx_done    (tx_done),
 
        .fifo_r_Data(rx_fifo_rdata),
        .rx_done    (rx_done),
        .empty      (rx_fifo_empty),
        .rx_en      (rx_en)
    );
 
    Fifo_Handler fifo_handler_inst (
        .clk         (PCLK),
        .reset       (PRESETn_S),
        .tx_data     (tx_data),
        .tx_strb     (tx_strb),
        .tx_en       (tx_en),
        .tx_done     (tx_done),
        .rx_done     (rx_done),
        .rx_en       (rx_en),
        .wr_en       (tx_fifo_wr_en),
        .fifo_w_data (tx_fifo_wdata),
        .full        (tx_fifo_full),
        .rd_en       (rx_fifo_rd_en),
        .empty       (rx_fifo_empty)
    );
 
 
    Async_FIFO #(.DEPTH(256), .WIDTH(8)) tx_fifo_inst (
        .wr_clk (PCLK),  .wr_rst (PRESETn_S),
        .wr_en  (tx_fifo_wr_en),
        .din    (tx_fifo_wdata),
        .rd_clk (SCLK),  .rd_rst (SRESETn_S),
        .rd_en  (tx_fifo_rd_en),
        .dout   (tx_fifo_rdata),
        .Full   (tx_fifo_full),
        .Empty  (tx_fifo_empty)
    );
 
    Async_FIFO #(.DEPTH(256), .WIDTH(8)) rx_fifo_inst (
        .wr_clk (SCLK),  .wr_rst (SRESETn_S),
        .wr_en  (rx_fifo_wr_en),
        .din    (qspi_rx_data),
        .rd_clk (PCLK),  .rd_rst (PRESETn_S),
        .rd_en  (rx_fifo_rd_en),
        .dout   (rx_fifo_rdata),
        .Full   (rx_fifo_full),
        .Empty  (rx_fifo_empty)
    );

    Async_FIFO #(.DEPTH(64), .WIDTH(8)) xip_rx_fifo_inst (
        .wr_clk (SCLK),  .wr_rst (SRESETn_S),
        .wr_en  (xip_rx_wr_en),
        .din    (qspi_rx_data),
        .rd_clk (HCLK),  .rd_rst (HRESETn_S),
        .rd_en  (xip_rx_rd_en),
        .dout   (xip_rx_rdata),
        .Full   (xip_rx_full),
        .Empty  (xip_rx_empty)
    );
 
 
    CDC_Block cdc_inst (
        .PCLK       (PCLK),
        .PRESETn    (PRESETn_S),
        .SCLK       (SCLK),
        .SRESETn    (SRESETn_S),
 
        .reg_opcode (reg_opcode),
        .reg_addr   (reg_addr),
        .reg_mode   (reg_mode),
        .reg_dummy  (reg_dummy),
        .reg_length (reg_length),
        .opcode_line(opcode_line),
        .addr_line  (addr_line),
        .data_line  (data_line),
        .mode_line  (mode_line),
        .addr_4byte (addr_4byte),
        .start      (start),
        .opcode_en  (opcode_en),
        .addr_en    (addr_en),
        .mode_en    (mode_en),
        .dummy_en   (dummy_en),
        .data_w_en  (data_w_en),
        .data_r_en  (data_r_en),
        .poll_wip_en(poll_wip_en),
 
        .reg_opcode_Q (reg_opcode_Q),
        .reg_addr_Q   (reg_addr_Q),
        .reg_mode_Q   (reg_mode_Q),
        .reg_dummy_Q  (reg_dummy_Q),
        .reg_length_Q (reg_length_Q),
        .opcode_line_Q(opcode_line_Q),
        .addr_line_Q  (addr_line_Q),
        .data_line_Q  (data_line_Q),
        .mode_line_Q  (mode_line_Q),
        .addr_4byte_Q (addr_4byte_Q),
        .start_Q      (start_Q),
        .opcode_en_Q  (opcode_en_Q),
        .addr_en_Q    (addr_en_Q),
        .mode_en_Q    (mode_en_Q),
        .dummy_en_Q   (dummy_en_Q),
        .data_w_en_Q  (data_w_en_Q),
        .data_r_en_Q  (data_r_en_Q),
        .poll_wip_en_Q(poll_wip_en_Q)
    );
 
 
    Ahb_Xip_Slave #(
        .XIP_BASE (32'h8000_0000),
        .XIP_MASK (32'hFF80_0000)
    ) ahb_xip_inst (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn_S),
        .xip_en    (xip_en),
 
        .HSEL      (HSEL),
        .HADDR     (HADDR),
        .HTRANS    (HTRANS),
        .HWRITE    (HWRITE),
        .HSIZE     (HSIZE),
        .HBURST    (HBURST),
        .HWDATA    (HWDATA),
        .HREADY    (HREADY),
        .HRDATA    (HRDATA),
        .HREADYOUT (HREADYOUT),
        .HRESP     (HRESP),
 
        .req       (pf_req),
        .req_addr  (pf_req_addr),
        .rsp_data  (pf_rsp_data),
        .rsp_valid (pf_rsp_valid)
    );
 
    Xip_Prefetch_Buffer #(
        .LINE_BYTES (XIP_LINE_BYTES),
        .LINE_SHIFT (XIP_LINE_SHIFT)
    ) prefetch_inst (
        .HCLK       (HCLK),
        .HRESETn    (HRESETn_S),
        .invalidate (pf_invalidate),
 
        .req        (pf_req),
        .req_addr   (pf_req_addr),
        .rsp_data   (pf_rsp_data),
        .rsp_valid  (pf_rsp_valid),
 
        .xip_addr   (xip_addr_h),
        .xip_length (xip_length_h),
        .xip_req    (xip_req_h),
        .xip_done   (xip_done_h),
 
        .fifo_rd_en (xip_rx_rd_en),
        .fifo_rdata (xip_rx_rdata),
        .fifo_empty (xip_rx_empty),
 
        .busy       ()
    );
 
    Xip_Cdc xip_cdc_inst (
        .HCLK         (HCLK),
        .HRESETn      (HRESETn_S),
        .xip_req_h    (xip_req_h),
        .xip_addr_h   (xip_addr_h),
        .xip_length_h (xip_length_h),
        .xip_done_h   (xip_done_h),
 
        .SCLK         (SCLK),
        .SRESETn      (SRESETn_S),
        .xip_req_s    (xip_req_s),
        .xip_addr_s   (xip_addr_s),
        .xip_length_s (xip_length_s),
        .xip_done_s   (xip_done_s)
    );
 
    Xip_Arbiter xip_arb_inst (
        .SCLK            (SCLK),
        .SRESETn         (SRESETn_S),
        .apb_start       (start_Q),
        .xip_req         (xip_req_s),
        .xip_length      (xip_length_s),
        .core_busy       (qspi_busy),
        .core_write_data (qspi_write_data),
        .xip_owns        (xip_owns),
        .core_start      (core_start),
        .xip_done        (xip_done_s)
    );
 
    Xip_Coherency coherency_inst (
        .SCLK       (SCLK),
        .SRESETn    (SRESETn_S),
        .core_done  (qspi_done),
        .xip_owns   (xip_owns),
        .HCLK       (HCLK),
        .HRESETn    (HRESETn_S),
        .invalidate (pf_invalidate)
    );
 
    Xip_Descriptor_Mux desc_mux_inst (
        .xip_owns         (xip_owns),
        .ind_opcode       (reg_opcode_Q),
        .ind_addr         (reg_addr_Q),
        .ind_mode         (reg_mode_Q),
        .ind_dummy        (reg_dummy_Q),
        .ind_length       (reg_length_Q),
        .ind_opcode_line  (opcode_line_Q),
        .ind_addr_line    (addr_line_Q),
        .ind_mode_line    (mode_line_Q),
        .ind_data_line    (data_line_Q),
        .ind_opcode_en    (opcode_en_Q),
        .ind_addr_en      (addr_en_Q),
        .ind_mode_en      (mode_en_Q),
        .ind_dummy_en     (dummy_en_Q),
        .ind_data_w_en    (data_w_en_Q),
        .ind_data_r_en    (data_r_en_Q),
        .ind_poll_wip_en  (poll_wip_en_Q),
        .ind_addr_4byte   (addr_4byte_Q),
 
        .xip_addr         (xip_addr_s),
        .xip_length       (xip_length_s),
 
        .core_opcode      (core_opcode),
        .core_addr        (core_addr),
        .core_mode        (core_mode),
        .core_dummy       (core_dummy),
        .core_length      (core_length),
        .core_opcode_line (core_opcode_line),
        .core_addr_line   (core_addr_line),
        .core_mode_line   (core_mode_line),
        .core_data_line   (core_data_line),
        .core_opcode_en   (core_opcode_en),
        .core_addr_en     (core_addr_en),
        .core_mode_en     (core_mode_en),
        .core_dummy_en    (core_dummy_en),
        .core_data_w_en   (core_data_w_en),
        .core_data_r_en   (core_data_r_en),
        .core_poll_wip_en (core_poll_wip_en),
        .core_addr_4byte  (core_addr_4byte)
    );
 

 
    Qspi_Core qspi_ctrl_inst (
        .Clk          (SCLK),
        .Reset        (SRESETn_S),
        .Start        (core_start),
        .Opcode_En    (core_opcode_en),
        .Addr_En      (core_addr_en),
        .Mode_En      (core_mode_en),
        .Dummy_En     (core_dummy_en),
        .Data_W_En    (core_data_w_en),
        .Data_R_En    (core_data_r_en),
        .Poll_WIP_En  (core_poll_wip_en),
        .Opcode_Line  (core_opcode_line),
        .Addr_Line    (core_addr_line),
        .Mode_Line    (core_mode_line),
        .Data_Line    (core_data_line),
        .Addr_4Byte   (core_addr_4byte),
        .Opcode       (core_opcode),
        .Addr         (core_addr),
        .Mode         (core_mode),
        .Dummy        (core_dummy),
        .Data_Length  (core_length),
        .Data         (tx_fifo_rdata),
        .Tx_Data      (Tx_Data),
        .Ioen         (Ioen),
        .Busy         (qspi_busy),
        .CS           (spi_cs_n),
        .Done         (qspi_done),
        .Error        (qspi_error),
        .Rx_Data      (qspi_rx_data),
        .Rx_In        (Rx_In),
        .Need_Data    (qspi_need_data),
        .Write_Data   (qspi_write_data)
    );
 
 
    assign tx_fifo_rd_en = qspi_need_data && !tx_fifo_empty;
 
    assign rx_fifo_wr_en = qspi_write_data && !rx_fifo_full && !xip_owns;
    assign xip_rx_wr_en  = qspi_write_data && !xip_rx_full  &&  xip_owns;


    reg xip_owns_at_start;
    always @(posedge SCLK or negedge SRESETn_S) begin
    if (!SRESETn_S)
        xip_owns_at_start <= 1'b0;
    else if (core_start)
        xip_owns_at_start <= xip_owns;
    end

    wire apb_done  = qspi_done  && !xip_owns_at_start;
    wire apb_error = qspi_error && !xip_owns_at_start;

    d_ff  Glt_Done (.clk(SCLK),.rst_n(SRESETn_S),.d(apb_done),.q(apb_done_gf)); 
    d_ff  Glt_Error (.clk(SCLK),.rst_n(SRESETn_S),.d(apb_error),.q(apb_error_gf)); 
 

    Sync #(1) done_sync  (.clk(PCLK), .rst(PRESETn_S),
                          .din(apb_done_gf),  .q(qspi_apb_done));
    Sync #(1) error_sync (.clk(PCLK), .rst(PRESETn_S),
                          .din(apb_error_gf), .q(qspi_apb_error));
 
 
    assign spi_sclk = ~SCLK;
 

 
    assign Io[0] = (Ioen[0]) ? Tx_Data[0] : 1'bz;
    assign Io[1] = (Ioen[1]) ? Tx_Data[1] : 1'bz;
    assign Io[2] = (Ioen[2]) ? Tx_Data[2] : 1'bz;
    assign Io[3] = (Ioen[3]) ? Tx_Data[3] : 1'bz;
 
    assign Rx_In = Io;
 
endmodule
 