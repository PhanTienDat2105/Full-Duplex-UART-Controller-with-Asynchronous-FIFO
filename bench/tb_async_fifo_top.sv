`timescale 1ns / 1ps

module tb_async_fifo_top();

    // -------------------------------------------------------------------------
    // KHAI BÁO PARAMETER
    // -------------------------------------------------------------------------
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4; // Độ sâu = 16

    // -------------------------------------------------------------------------
    // TÍN HIỆU KẾT NỐI
    // -------------------------------------------------------------------------
    logic wclk;
    logic w_rst;
    logic w_en;
    logic [DATA_WIDTH-1:0] w_data;
    logic w_full;
    
    logic rclk;
    logic r_rst;
    logic r_en;
    logic r_empty;
    logic [DATA_WIDTH-1:0] r_data;

    // -------------------------------------------------------------------------
    // GỌI DUT (Device Under Test)
    // -------------------------------------------------------------------------
    async_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .* // Nối dây tự động theo tên giống nhau (Tính năng ăn tiền của SV)
    );

    // -------------------------------------------------------------------------
    // GENERATE CLOCK BẤT ĐỒNG BỘ
    // -------------------------------------------------------------------------
    // Ghi cực nhanh (200MHz -> T=5ns)
    initial begin
        wclk = 1'b0;
        forever #2.5 wclk = ~wclk;
    end

    // Đọc chậm (50MHz -> T=20ns)
    initial begin
        rclk = 1'b0;
        forever #10 rclk = ~rclk;
    end

    // -------------------------------------------------------------------------
    // KỊCH BẢN MÔ PHỎNG (STIMULUS)
    // -------------------------------------------------------------------------
    initial begin
        // Khởi tạo trạng thái ban đầu
        w_rst = 1'b1;
        r_rst = 1'b1;
        w_en  = 1'b0;
        w_data = '0;
        r_en  = 1'b0;
        
        // Reset 2 miền clock (Nên giữ reset đủ lâu để qua vài nhịp clock)
        #50;
        w_rst = 1'b0;
        r_rst = 1'b0;
        
        $display("========================================");
        $display("[INFO] Bat dau test Asynchronous FIFO");
        $display("========================================");
        
        // Chờ đồng bộ ban đầu
        #50;

        // ---------------------------------------------------------
        // GIAI ĐOẠN 1: Bắn liên thanh đến khi ĐẦY (Write Burst)
        // ---------------------------------------------------------
        $display("[TEST] Giai doan 1: Ghi du lieu cho den khi FULL");
        @(posedge wclk);
        w_en = 1'b1;
        
        // Vòng lặp tự động ghi, tăng dần giá trị data
        for (int i = 0; i < 20; i++) begin
            if (!w_full) begin
                w_data = w_data + 1;
                $display("[WRITE] Time: %0t | Data: %d", $realtime, w_data);
            end else begin
                $display("[WRITE ERROR CAUGHT] Time: %0t | FIFO Full! Khong the ghi %d", $realtime, w_data + 1);
            end
            @(posedge wclk);
        end
        w_en = 1'b0; // Dừng ghi

        // Đợi một lúc cho tín hiệu ngấm
        #100;

        // ---------------------------------------------------------
        // GIAI ĐOẠN 2: Đọc từ từ cho đến khi RỖNG (Read Burst)
        // ---------------------------------------------------------
        $display("\n[TEST] Giai doan 2: Doc du lieu cho den khi EMPTY");
        @(posedge rclk);
        r_en = 1'b1;
        
        for (int j = 0; j < 20; j++) begin
            if (!r_empty) begin
                @(posedge rclk);
                $display("[READ]  Time: %0t | Data out: %d", $realtime, r_data);
            end else begin
                $display("[READ ERROR CAUGHT] Time: %0t | FIFO Empty! Khong the doc", $realtime);
                @(posedge rclk);
            end
        end
        r_en = 1'b0; // Dừng đọc

        // Kết thúc
        #50;
        $display("========================================");
        $display("[INFO] Hoan tat test Asynchronous FIFO");
        $display("========================================");
        $finish;
    end

endmodule