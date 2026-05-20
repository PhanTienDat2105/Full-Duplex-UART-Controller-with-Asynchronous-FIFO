`timescale 1ns / 1ps

module tb_uart_top_controller();

    // -------------------------------------------------------------------------
    // PARAMETERS
    // -------------------------------------------------------------------------
    localparam int SYS_CLK_FREQ = 100_000_000;
    localparam int BAUD_RATE    = 115200;
    localparam int DATA_WIDTH   = 8;
    localparam int ADDR_WIDTH   = 4;
    
    // -------------------------------------------------------------------------
    // SIGNALS
    // -------------------------------------------------------------------------
    logic sys_clk;
    logic reset;
    
    // Giao tiếp ghi TX
    logic [DATA_WIDTH-1:0] tx_data_in;
    logic tx_en;
    logic tx_fifo_full;
    
    // Giao tiếp đọc RX
    logic rx_read_en;
    logic [DATA_WIDTH-1:0] rx_data_out;
    logic rx_fifo_empty;
    
    // Giao tiếp vật lý (Loopback wire)
    logic serial_line;

    // -------------------------------------------------------------------------
    // INSTANTIATE THE TOP LEVEL
    // -------------------------------------------------------------------------
    uart_top_controller #(
        .SYS_CLK_FREQ(SYS_CLK_FREQ),
        .BAUD_RATE   (BAUD_RATE),
        .DATA_WIDTH  (DATA_WIDTH),
        .ADDR_WIDTH  (ADDR_WIDTH)
    ) dut (
        .sys_clk      (sys_clk),
        .reset        (reset),
        .tx_data_in   (tx_data_in),
        .tx_en        (tx_en),
        .tx_fifo_full (tx_fifo_full),
        .rx_read_en   (rx_read_en),
        .rx_data_out  (rx_data_out),
        .rx_fifo_empty(rx_fifo_empty),
        .rx_in        (serial_line),
        .tx_out       (serial_line) 
    );

    // -------------------------------------------------------------------------
    // CLOCK GENERATION (100MHz)
    // -------------------------------------------------------------------------
    initial begin
        sys_clk = 1'b0;
        forever #5 sys_clk = ~sys_clk;
    end

    // -------------------------------------------------------------------------
    // MAIN STIMULUS
    // -------------------------------------------------------------------------
    initial begin
        // Khởi tạo
        reset = 1'b1;
        tx_en = 1'b0;
        tx_data_in = '0;
        rx_read_en = 1'b0;
        
        #50;
        reset = 1'b0;
        $display("==================================================");
        $display("[INFO] BAT DAU TEST LOOPBACK UART (DYNAMIC READ)");
        $display("==================================================");
        #100;

        // ---------------------------------------------------------------------
        // BƯỚC 1: CPU NHỒI 4 BYTES VÀO TX FIFO
        // ---------------------------------------------------------------------
        @(posedge sys_clk);
        tx_en = 1'b1;
        tx_data_in = 8'hAA; @(posedge sys_clk); $display("[TX CPU] Ghi vao FIFO: %h", tx_data_in);
        tx_data_in = 8'hBB; @(posedge sys_clk); $display("[TX CPU] Ghi vao FIFO: %h", tx_data_in);
        tx_data_in = 8'hCC; @(posedge sys_clk); $display("[TX CPU] Ghi vao FIFO: %h", tx_data_in);
        tx_data_in = 8'hDD; @(posedge sys_clk); $display("[TX CPU] Ghi vao FIFO: %h", tx_data_in);
        tx_en = 1'b0;

        // ---------------------------------------------------------------------
        // BƯỚC 2 & 3: CPU ĐỌC ONLINE - CÓ BYTE NÀO HÚP BYTE ĐÓ
        // ---------------------------------------------------------------------
        $display("[INFO] CPU dang cho du lieu tu duong truyen...");
        $display("--------------------------------------------------");
        
        for (int i = 0; i < 4; i++) begin
            // 1. Đợi cho đến khi RX FIFO có hàng (cờ empty rớt xuống 0)
            wait(rx_fifo_empty == 1'b0);
            
            // 2. Kích hoạt xung đọc kéo dài đúng 1 chu kỳ sys_clk
            @(posedge sys_clk);
            rx_read_en = 1'b1;
            
            @(posedge sys_clk);
            rx_read_en = 1'b0; // Hạ lệnh đọc ngay lập tức để không bị đọc lố sang byte sau
            
            // 3. Trễ nhẹ 1ns để mạch cập nhật data ngõ ra ổn định rồi in báo cáo
            #1;
            $display("[RX CPU] Doc tu FIFO thanh cong: %h tai thoi diem %0t ns", rx_data_out, $realtime);
            
            // Cách ra một đoạn nhỏ trước khi quay lại check byte kế tiếp
            #5000; 
        end

        #5000;
        $display("==================================================");
        $display("[INFO] HOAN TAT TEST LOOPBACK DYNAMIC.");
        $display("==================================================");
        $finish;
    end

endmodule