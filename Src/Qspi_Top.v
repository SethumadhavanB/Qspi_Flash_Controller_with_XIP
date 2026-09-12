`timescale 1ns / 1ps
`default_nettype none
module qspi_top (
    input  wire        PCLK,
    input  wire        PRESETn,

    input  wire        SCLK,
    input  wire        SRESETn,

    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [3:0]  PSTRB,

    input  wire [7:0]  PADDR,
    input  wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    output wire        spi_cs_n,
    output wire        spi_sclk,

    inout wire [3:0] Io
);
    // APB SLAVE -> REGISTER BANK

    wire [7:0]  apb_reg_addr;
    wire [31:0] apb_reg_wdata;
    wire [3:0]  apb_reg_strb;
    wire        apb_reg_we;
    wire        apb_reg_re;
    wire [31:0] reg_rdata;
    wire        data_done;

    // REGISTER BANK -> CDC
    wire [7:0]  reg_opcode;
    wire [31:0] reg_addr;
    wire [1:0]  mode_line;
    wire        addr_4byte;
    wire [7:0]  reg_mode;
    wire [7:0]  reg_dummy;
    wire [7:0]  reg_length;
    wire [1:0]  opcode_line;
    wire [1:0]  addr_line;
    wire [1:0]  data_line;
    wire        start;
    wire        opcode_en;
    wire        addr_en;
    wire        mode_en;
    wire        dummy_en;
    wire        data_w_en;
    wire        data_r_en;
    wire        poll_wip_en;
    


    // REGISTER BANK <-> FIFO HANDLER
    wire [31:0] tx_data;
    wire [3:0]  tx_strb;
    wire        tx_en;
    wire        tx_done;

    wire        rx_done;
    wire        rx_en;


    // CDC -> SCLK DOMAIN
    wire [7:0]  reg_opcode_Q;
    wire [31:0] reg_addr_Q;
    wire        addr_4byte_Q;
    wire [7:0]  reg_mode_Q;
    wire [7:0]  reg_dummy_Q;
    wire [7:0]  reg_length_Q;

    wire [1:0]  opcode_line_Q;
    wire [1:0]  addr_line_Q;
    wire [1:0]  data_line_Q;
    wire [1:0]  mode_line_Q;

    wire        start_Q;
    wire        opcode_en_Q;
    wire        addr_en_Q;
    wire        mode_en_Q;
    wire        dummy_en_Q;
    wire        data_w_en_Q;
    wire        data_r_en_Q;
    wire        poll_wip_en_Q;



    // TX ASYNC FIFO
    wire        tx_fifo_wr_en;
    wire [7:0]  tx_fifo_wdata;
    wire        tx_fifo_full;

    wire        tx_fifo_rd_en;
    wire [7:0]  tx_fifo_rdata;
    wire        tx_fifo_empty;


    // RX ASYNC FIFO
    wire        rx_fifo_wr_en;
    wire [7:0]  rx_fifo_wdata;
    wire        rx_fifo_full;

    wire        rx_fifo_rd_en;
    wire [7:0]  rx_fifo_rdata;
    wire        rx_fifo_empty;

    // QSPI CORE SIGNALS
    wire        qspi_busy;
    wire        qspi_done;
    wire        qspi_error;
    wire        qspi_Core_done;
    wire [7:0]  qspi_rx_data;
    wire        qspi_need_data;
    wire        qspi_write_data;
    wire qspi_done_S;
    wire qspi_error_S;
    wire qspi_Core_error;

    // QSPI PHY SIGNALS
    wire [3:0] Tx_Data;
    wire [3:0] Rx_In;
    wire [3:0] Ioen;
    

    wire PRESETn_S;
    wire SRESETn_S;

    Reset_Sync p_domain (.clk(PCLK),.reset_n(PRESETn),.reset_sync_n(PRESETn_S));
    Reset_Sync s_domain (.clk(SCLK),.reset_n(SRESETn),.reset_sync_n(SRESETn_S));



    // 1. APB SLAVE
    Apb_Slave apb_slave_inst (

        .PCLK       (PCLK),
        .PRESETn    (PRESETn_S),

        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PSTRB      (PSTRB),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),

        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR),

        .reg_addr   (apb_reg_addr),
        .reg_wdata  (apb_reg_wdata),
        .reg_strb   (apb_reg_strb),

        .reg_we     (apb_reg_we),
        .reg_re     (apb_reg_re),

        .reg_rdata  (reg_rdata),
        .data_done  (data_done),
        .Qspi_done(qspi_Core_done),
        .Qspi_Error(qspi_Core_error)
    );


    // 2. REGISTER BANK
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
        .mode_line(mode_line),

        .start      (start),
        .opcode_en  (opcode_en),
        .addr_en    (addr_en),
        .mode_en    (mode_en),
        .dummy_en   (dummy_en),
        .data_w_en  (data_w_en),
        .data_r_en  (data_r_en),
        .poll_wip_en (poll_wip_en),
        .addr_4byte(addr_4byte),

        .tx_data    (tx_data),
        .tx_strb    (tx_strb),
        .tx_en      (tx_en),
        .tx_done    (tx_done),

        .fifo_r_Data(rx_fifo_rdata),
        .rx_done    (rx_done),
        .empty      (rx_fifo_empty),
        .rx_en      (rx_en)
    );


    // 3. FIFO HANDLER

    Fifo_Handler fifo_handler_inst (

        .clk         (PCLK),
        .reset       (PRESETn_S),

        // TX
        .tx_data     (tx_data),
        .tx_strb     (tx_strb),
        .tx_en       (tx_en),
        .tx_done     (tx_done),

        // RX
        .rx_done     (rx_done),
        .rx_en       (rx_en),

        // TX FIFO
        .wr_en       (tx_fifo_wr_en),
        .fifo_w_data (tx_fifo_wdata),
        .full        (tx_fifo_full),

        // RX FIFO
        .rd_en       (rx_fifo_rd_en),
       
        .empty       (rx_fifo_empty)
    );



    // 4. TX ASYNC FIFO
    Async_FIFO #(
        .DEPTH (256),
        .WIDTH (8)
    ) tx_fifo_inst (

        .wr_clk  (PCLK),
        .wr_rst  (PRESETn_S),
        .wr_en   (tx_fifo_wr_en),
        .din     (tx_fifo_wdata),

        .rd_clk  (SCLK),
        .rd_rst (SRESETn_S),
        .rd_en   (tx_fifo_rd_en),
        .dout    (tx_fifo_rdata),

        .Full    (tx_fifo_full),
        .Empty   (tx_fifo_empty)
    );

    // 5. RX ASYNC FIFO

    Async_FIFO #(
        .DEPTH (256),
        .WIDTH (8)
    ) rx_fifo_inst (

        .wr_clk  (SCLK),
        .wr_rst  (SRESETn_S),
        .wr_en   (rx_fifo_wr_en),
        .din     (qspi_rx_data),

        .rd_clk  (PCLK),
        .rd_rst  (PRESETn_S),
        
        .rd_en   (rx_fifo_rd_en),
        .dout    (rx_fifo_rdata),

        .Full    (rx_fifo_full),
        .Empty   (rx_fifo_empty)
    );


    // 6. CDC BLOCK

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

        .start      (start),
        .opcode_en  (opcode_en),
        .addr_en    (addr_en),
        .mode_en    (mode_en),
        .dummy_en   (dummy_en),
        .data_w_en  (data_w_en),
        .data_r_en  (data_r_en),
        .poll_wip_en(poll_wip_en),
        .addr_4byte(addr_4byte),

        .reg_opcode_Q (reg_opcode_Q),
        .reg_addr_Q   (reg_addr_Q),
        .reg_mode_Q   (reg_mode_Q),
        .reg_dummy_Q  (reg_dummy_Q),
        .reg_length_Q (reg_length_Q),

        .opcode_line_Q(opcode_line_Q),
        .addr_line_Q  (addr_line_Q),
        .data_line_Q  (data_line_Q),
        .mode_line_Q (mode_line_Q),

        .start_Q      (start_Q),
        .opcode_en_Q  (opcode_en_Q),
        .addr_en_Q    (addr_en_Q),
        .mode_en_Q    (mode_en_Q),
        .dummy_en_Q   (dummy_en_Q),
        .data_w_en_Q  (data_w_en_Q),
        .data_r_en_Q  (data_r_en_Q),
        .poll_wip_en_Q(poll_wip_en_Q),
        .addr_4byte_Q(addr_4byte_Q)
    );


    // 7. QSPI CORE

    Qspi_Core qspi_ctrl_inst (

        .Clk          (SCLK),
        .Reset        (SRESETn_S),
        .Start        (start_Q),
        .Opcode_En    (opcode_en_Q),
        .Addr_En      (addr_en_Q),
        .Mode_En      (mode_en_Q),
        .Dummy_En     (dummy_en_Q),
        .Data_W_En    (data_w_en_Q),
        .Data_R_En    (data_r_en_Q),

        .Poll_WIP_En  (poll_wip_en_Q),

        .Opcode_Line  (opcode_line_Q),
        .Addr_Line    (addr_line_Q),
        .Mode_Line    (mode_line_Q),
        .Data_Line    (data_line_Q),
        .Addr_4Byte   (addr_4byte_Q),

        .Opcode       (reg_opcode_Q),
        .Addr         (reg_addr_Q),
        .Mode         (reg_mode_Q),
        .Dummy        (reg_dummy_Q),
        .Data_Length  (reg_length_Q),

        .Data         (tx_fifo_rdata),

        // QSPI PHY
        .Tx_Data      (Tx_Data),
        .Ioen         (Ioen),

        // Status
        .Busy         (qspi_busy),
        .CS           (spi_cs_n),
        .Done         (qspi_done),
        .Error        (qspi_error),

        // RX
        .Rx_Data      (qspi_rx_data),
        .Rx_In        (Rx_In),

        // FIFO control
        .Need_Data    (qspi_need_data),
        .Write_Data   (qspi_write_data)
    );
    
    d_ff done_d (.clk(SCLK),.rst_n (SRESETn_S),.d(qspi_done),.q(qspi_done_S));
    Sync #(1) done_sync  (.clk(PCLK), .rst(PRESETn_S),.din(qspi_done_S),.q(qspi_Core_done));

    d_ff error_d (.clk(SCLK),.rst_n (SRESETn_S),.d(qspi_error),.q(qspi_error_S));
    Sync #(1) error_sync  (.clk(PCLK), .rst(PRESETn_S),.din(qspi_error_S),.q(qspi_Core_error));

    // 8. TX FIFO READ CONTROL

    assign tx_fifo_rd_en =
            qspi_need_data &&
            !tx_fifo_empty;


    // 9. RX FIFO WRITE CONTROL

    assign rx_fifo_wr_en =
            qspi_write_data &&
            !rx_fifo_full;

    assign rx_fifo_wdata =
            qspi_rx_data;

    // 10. SPI CLOCK

   
    assign spi_sclk = ~SCLK;

    // 11. QSPI BIDIRECTIONAL PHY
    
    assign Io[0] = (Ioen[0]) ? Tx_Data[0] : 1'bz;  
    assign Io[1] = (Ioen[1]) ? Tx_Data[1] : 1'bz;  
    assign Io[2] = (Ioen[2]) ? Tx_Data[2] : 1'bz;  
    assign Io[3] = (Ioen[3]) ? Tx_Data[3] : 1'bz;  

    assign Rx_In[0] = Io[0];
    assign Rx_In[1] = Io[1];
    assign Rx_In[2] = Io[2];
    assign Rx_In[3] = Io[3];

endmodule