`timescale 1ns / 1ps

module async_fifo_top #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
)(
    // Miền Ghi (Write Domain)
    input  logic wclk,
    input  logic w_rst,
    input  logic w_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic w_full,
    
    // Miền Đọc (Read Domain)
    input  logic rclk,
    input  logic r_rst,
    input  logic r_en,
    output logic r_empty,
    output logic [DATA_WIDTH-1:0] r_data
);

    // -------------------------------------------------------------------------
    // KHAI BÁO CÁC ĐƯỜNG DÂY NỘI BỘ (Internal Wires)
    // -------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] w_addr;
    logic [ADDR_WIDTH-1:0] r_addr;
    
    logic [ADDR_WIDTH:0]   w_gray;
    logic [ADDR_WIDTH:0]   r_gray;
    
    logic [ADDR_WIDTH:0]   wq2_rgray; // Con trỏ Read Gray đã đồng bộ sang miền Write
    logic [ADDR_WIDTH:0]   rq2_wgray; // Con trỏ Write Gray đã đồng bộ sang miền Read

    // -------------------------------------------------------------------------
    // 1. DUAL-PORT RAM (Bộ nhớ lõi)
    // -------------------------------------------------------------------------
    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        .wclk   (wclk),
        // Chỉ cho phép ghi vào RAM nếu có lệnh w_en và FIFO CHƯA ĐẦY
        .w_en   (w_en & ~w_full), 
        .w_addr (w_addr),
        .w_data (w_data),
        
        .rclk   (rclk),
        // Chỉ cho phép đọc từ RAM nếu có lệnh r_en và FIFO CHƯA RỖNG
        .r_en   (r_en & ~r_empty),
        .r_addr (r_addr),
        .r_data (r_data)
    );

    // -------------------------------------------------------------------------
    // 2. BỘ ĐỒNG BỘ: R_GRAY -> W_DOMAIN (Mang con trỏ Đọc sang miền Ghi)
    // -------------------------------------------------------------------------
    sync_2ff #(
        .WIDTH (ADDR_WIDTH + 1)
    ) u_sync_r2w (
        .clk      (wclk),
        .reset    (w_rst),
        .async_in (r_gray),
        .sync_out (wq2_rgray)
    );

    // -------------------------------------------------------------------------
    // 3. BỘ ĐỒNG BỘ: W_GRAY -> R_DOMAIN (Mang con trỏ Ghi sang miền Đọc)
    // -------------------------------------------------------------------------
    sync_2ff #(
        .WIDTH (ADDR_WIDTH + 1)
    ) u_sync_w2r (
        .clk      (rclk),
        .reset    (r_rst),
        .async_in (w_gray),
        .sync_out (rq2_wgray)
    );

    // -------------------------------------------------------------------------
    // 4. LOGIC CON TRỎ GHI & CỜ FULL
    // -------------------------------------------------------------------------
    wptr_full #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_wptr_full (
        .wclk      (wclk),
        .reset     (w_rst),
        .w_en      (w_en),
        .wq2_rgray (wq2_rgray),
        .w_full    (w_full),
        .w_addr    (w_addr),
        .w_gray    (w_gray)
    );

    // -------------------------------------------------------------------------
    // 5. LOGIC CON TRỎ ĐỌC & CỜ EMPTY
    // -------------------------------------------------------------------------
    rptr_empty #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_rptr_empty (
        .rclk      (rclk),
        .reset     (r_rst),
        .r_en      (r_en),
        .rq2_wgray (rq2_wgray),
        .r_empty   (r_empty),
        .r_addr    (r_addr),
        .r_gray    (r_gray)
    );

endmodule