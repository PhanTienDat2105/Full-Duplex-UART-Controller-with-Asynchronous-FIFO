`timescale 1ns / 1ps

module uart_top_controller #(
    parameter int SYS_CLK_FREQ = 100_000_000,
    parameter int BAUD_RATE    = 115200,
    parameter int DATA_WIDTH   = 8,
    parameter int ADDR_WIDTH   = 4  // Độ sâu FIFO = 16 bytes
)(
    // Giao tiếp hệ thống (System Interface) chạy bằng sys_clk
    input  logic sys_clk,
    input  logic reset,         // Posedge reset chung cho toàn hệ thống
    
    input  logic [DATA_WIDTH-1:0] tx_data_in,
    input  logic tx_en,         // Yêu cầu ghi vào TX FIFO
    output logic tx_fifo_full,  // Báo TX FIFO đầy
    
    input  logic rx_read_en,    // Yêu cầu đọc từ RX FIFO
    output logic [DATA_WIDTH-1:0] rx_data_out,
    output logic rx_fifo_empty, // Báo RX FIFO rỗng
    
    // Giao tiếp vật lý (Physical Interface)
    input  logic rx_in,         // Chân nhận dữ liệu UART
    output logic tx_out         // Chân phát dữ liệu UART
);

    // -------------------------------------------------------------------------
    // DÂY NỘI BỘ (Internal Wires)
    // -------------------------------------------------------------------------
    // Clock signals
    logic tx_baud_clk;
    logic rx_baud_clk_16x;
    
    // TX Internal Interface
    logic [DATA_WIDTH-1:0] tx_data_to_uart;
    logic tx_fifo_empty;
    logic tx_fifo_r_en;
    logic tx_busy;
    logic tx_start;

    // RX Internal Interface
    logic [DATA_WIDTH-1:0] rx_data_from_uart;
    logic rx_valid;
    logic rx_fifo_full; // Có thể bỏ qua không xuất ra ngoài nếu CPU đọc đủ nhanh

    // -------------------------------------------------------------------------
    // 1. BAUD RATE GENERATOR
    // -------------------------------------------------------------------------
    baud_rate_generator #(
        .SYS_CLK_FREQ(SYS_CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_rate (
        .sys_clk        (sys_clk),
        .reset          (reset),
        .tx_baud_clk    (tx_baud_clk),
        .rx_baud_clk_16x(rx_baud_clk_16x)
    );

    // -------------------------------------------------------------------------
    // 2. TX ASYNC FIFO (System -> UART)
    // -------------------------------------------------------------------------
    async_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_tx_fifo (
        .wclk   (sys_clk),
        .w_rst  (reset),
        .w_en   (tx_en),
        .w_data (tx_data_in),
        .w_full (tx_fifo_full),
        
        .rclk   (tx_baud_clk),
        .r_rst  (reset),
        .r_en   (tx_fifo_r_en),
        .r_empty(tx_fifo_empty),
        .r_data (tx_data_to_uart)
    );

    // -------------------------------------------------------------------------
    // LOGIC KẾT DÍNH: ĐIỀU KHIỂN UART TX TỪ TX FIFO
    // -------------------------------------------------------------------------
    // Cho phép đọc FIFO nếu: FIFO có data (không rỗng) + UART TX rảnh + Chưa tạo xung start
    assign tx_fifo_r_en = ~tx_fifo_empty & ~tx_busy & ~tx_start;

    // Tạo trễ 1 chu kỳ clock cho tín hiệu tx_start (Để đợi RAM xuất dữ liệu)
    always_ff @(posedge tx_baud_clk or posedge reset) begin
        if (reset) begin
            tx_start <= 1'b0;
        end else begin
            tx_start <= tx_fifo_r_en;
        end
    end

    // -------------------------------------------------------------------------
    // 3. UART TRANSMITTER
    // -------------------------------------------------------------------------
    uart_tx u_uart_tx (
        .tx_baud_clk(tx_baud_clk),
        .reset      (reset),
        .tx_start   (tx_start),
        .tx_data    (tx_data_to_uart),
        .tx_out     (tx_out),
        .tx_busy    (tx_busy)
    );

    // -------------------------------------------------------------------------
    // 4. UART RECEIVER
    // -------------------------------------------------------------------------
    uart_rx u_uart_rx (
        .rx_baud_clk_16x(rx_baud_clk_16x),
        .reset          (reset),
        .rx_in          (rx_in),
        .rx_data        (rx_data_from_uart),
        .rx_valid       (rx_valid)
    );

    // -------------------------------------------------------------------------
    // 5. RX ASYNC FIFO (UART -> System)
    // -------------------------------------------------------------------------
    async_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_rx_fifo (
        .wclk   (rx_baud_clk_16x),
        .w_rst  (reset),
        .w_en   (rx_valid),            // Mỗi khi RX nhận xong 1 byte, nhét thẳng vào FIFO
        .w_data (rx_data_from_uart),
        .w_full (rx_fifo_full),        // Cờ này phòng thủ, system cần đọc kịp thời
        
        .rclk   (sys_clk),
        .r_rst  (reset),
        .r_en   (rx_read_en),
        .r_empty(rx_fifo_empty),
        .r_data (rx_data_out)
    );

endmodule