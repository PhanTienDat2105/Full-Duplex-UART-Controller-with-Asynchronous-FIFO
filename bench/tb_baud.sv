`timescale 1ns / 1ps

module tb_baud_rate_generator();

    // -------------------------------------------------------------------------
    // KHAI BÁO PARAMETER KHỚP VỚI THIẾT KẾ
    // -------------------------------------------------------------------------
    localparam int SYS_CLK_FREQ = 100_000_000; // 100 MHz
    localparam int BAUD_RATE    = 115200;      // 115200 bps
    
    // Chu kỳ xung nhịp hệ thống: 1 / 100MHz = 10ns (Lật mỗi 5ns)
    localparam real SYS_CLK_PERIOD = 10.0; 

    // -------------------------------------------------------------------------
    // KHAI BÁO CÁC TÍN HIỆU KẾT NỐI
    // -------------------------------------------------------------------------
    logic sys_clk;
    logic reset;
    logic tx_baud_clk;
    logic rx_baud_clk_16x;

    // Các biến dùng để đo đạc thời gian thực tế trên Waveform
    realtime tx_edge_time, tx_period;
    realtime rx_edge_time, rx_period;

    // -------------------------------------------------------------------------
    // GỌI MODULE CẦN KIỂM THỬ (DUT - Device Under Test)
    // -------------------------------------------------------------------------
    baud_rate_generator #(
        .SYS_CLK_FREQ (SYS_CLK_FREQ),
        .BAUD_RATE    (BAUD_RATE)
    ) dut (
        .sys_clk         (sys_clk),
        .reset           (reset),
        .tx_baud_clk     (tx_baud_clk),
        .rx_baud_clk_16x (rx_baud_clk_16x)
    );

    // -------------------------------------------------------------------------
    // BỘ TẠO XUNG NHỊP HỆ THỐNG (CLOCK GENERATOR)
    // -------------------------------------------------------------------------
    initial begin
        sys_clk = 1'b0;
        forever #(SYS_CLK_PERIOD / 2.0) sys_clk = ~sys_clk;
    end

    // -------------------------------------------------------------------------
    // KỊCH BẢN MÔ PHỎNG (STIMULUS)
    // -------------------------------------------------------------------------
    initial begin
        // Trạng thái ban đầu
        reset = 1'b0;
        
        // Kích hoạt Reset tích cực mức cao (Active-High) tại posedge
        #(SYS_CLK_PERIOD * 2);
        reset = 1'b1;
        
        // Duy trì reset trong 5 chu kỳ clock
        #(SYS_CLK_PERIOD * 5);
        reset = 1'b0;
        
        $display("[TB INFO] Reset successfully released at %t", $realtime);

        // Chạy mô phỏng đủ lâu để xung nhịp TX (vốn rất chậm) có thể lật trạng thái
        // 1 bit UART ở tốc độ 115200 tốn khoảng 8.68 us = 8680 ns. 
        // Ta chạy 30 us để thấy được vài chu kỳ của tx_baud_clk.
        #30000ns;
        
        $display("[TB INFO] Simulation finished.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // TỰ ĐỘNG ĐO ĐẠC VÀ KIỂM TRA CHU KỲ CỦA TX_BAUD_CLK
    // Lý thuyết: T = 1 / 115200 Hz = 8680.55 ns
    // -------------------------------------------------------------------------
    always @(posedge tx_baud_clk) begin
        if (!reset) begin
            tx_period = $realtime - tx_edge_time;
            tx_edge_time = $realtime;
            if (tx_period > 0) begin
                $display("[MEASUREMENT] TX Baud Clock Period: %0.2f ns (Expected: ~8680.55 ns)", tx_period);
            end
        end
    end

    // -------------------------------------------------------------------------
    // TỰ ĐỘNG ĐO ĐẠC VÀ KIỂM TRA CHU KỲ CỦA RX_BAUD_CLK_16X
    // Lý thuyết: T = 1 / (115200 * 16) Hz = 542.53 ns
    // -------------------------------------------------------------------------
    always @(posedge rx_baud_clk_16x) begin
        if (!reset) begin
            rx_period = $realtime - rx_edge_time;
            rx_edge_time = $realtime;
            if (rx_period > 0) begin
                $display("[MEASUREMENT] RX Baud Clock (16x) Period: %0.2f ns (Expected: ~542.53 ns)", rx_period);
            end
        end
    end

endmodule