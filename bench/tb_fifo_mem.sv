`timescale 1ns / 1ps

module tb_fifo_mem();

    // -------------------------------------------------------------------------
    // KHAI BÁO PARAMETER (Khớp với DUT)
    // -------------------------------------------------------------------------
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;

    // -------------------------------------------------------------------------
    // KHAI BÁO TÍN HIỆU
    // -------------------------------------------------------------------------
    logic wclk;
    logic w_en;
    logic [ADDR_WIDTH-1:0] w_addr;
    logic [DATA_WIDTH-1:0] w_data;
    
    logic rclk;
    logic r_en;
    logic [ADDR_WIDTH-1:0] r_addr;
    logic [DATA_WIDTH-1:0] r_data;

    // -------------------------------------------------------------------------
    // GỌI MODULE (DUT - Device Under Test)
    // -------------------------------------------------------------------------
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk   (wclk),
        .w_en   (w_en),
        .w_addr (w_addr),
        .w_data (w_data),
        .rclk   (rclk),
        .r_en   (r_en),
        .r_addr (r_addr),
        .r_data (r_data)
    );

    // -------------------------------------------------------------------------
    // BỘ TẠO XUNG NHỊP (BẤT ĐỒNG BỘ)
    // -------------------------------------------------------------------------
    // wclk: 100 MHz (T = 10ns)
    initial begin
        wclk = 1'b0;
        forever #5 wclk = ~wclk;
    end

    // rclk: 50 MHz (T = 20ns) -> Cố tình chạy chậm hơn
    initial begin
        rclk = 1'b0;
        forever #10 rclk = ~rclk;
    end

    // -------------------------------------------------------------------------
    // KỊCH BẢN MÔ PHỎNG (STIMULUS)
    // -------------------------------------------------------------------------
    initial begin
        // 1. KHỞI TẠO TÍN HIỆU
        w_en   = 1'b0;
        w_addr = '0;
        w_data = '0;
        r_en   = 1'b0;
        r_addr = '0;
        
        #25; // Chờ hệ thống ổn định

        $display("==================================================");
        $display("[TEST START] Bat dau Kiem chung Dual-Port RAM");
        $display("==================================================");

        // 2. GIAI ĐOẠN GHI DỮ LIỆU (Hoạt động theo wclk)
        @(posedge wclk);
        w_en = 1'b1; // Cho phép ghi

        // Ghi dữ liệu vào 4 địa chỉ đầu tiên
        w_addr = 4'd0; w_data = 8'hAA; @(posedge wclk);
        $display("[WRITE] Time: %0t ns | Addr: %0d | Data: %h", $realtime, w_addr, w_data);
        
        w_addr = 4'd1; w_data = 8'hBB; @(posedge wclk);
        $display("[WRITE] Time: %0t ns | Addr: %0d | Data: %h", $realtime, w_addr, w_data);
        
        w_addr = 4'd2; w_data = 8'hCC; @(posedge wclk);
        $display("[WRITE] Time: %0t ns | Addr: %0d | Data: %h", $realtime, w_addr, w_data);
        
        w_addr = 4'd3; w_data = 8'hDD; @(posedge wclk);
        $display("[WRITE] Time: %0t ns | Addr: %0d | Data: %h", $realtime, w_addr, w_data);

        w_en = 1'b0; // Ngừng ghi
        
        #50; // Chờ một khoảng thời gian

        $display("--------------------------------------------------");

        // 3. GIAI ĐOẠN ĐỌC DỮ LIỆU (Hoạt động theo rclk)
        @(posedge rclk);
        r_en = 1'b1; // Cho phép đọc

        // Đọc dữ liệu từ 4 địa chỉ đã ghi
        r_addr = 4'd0; @(posedge rclk); 
        // Dữ liệu r_data sẽ xuất hiện ở cạnh clock rclk tiếp theo
        $display("[READ]  Time: %0t ns | Addr: %0d | Data expected: AA | Data out: %h", $realtime, r_addr, r_data);
        
        r_addr = 4'd1; @(posedge rclk);
        $display("[READ]  Time: %0t ns | Addr: %0d | Data expected: BB | Data out: %h", $realtime, r_addr, r_data);
        
        r_addr = 4'd2; @(posedge rclk);
        $display("[READ]  Time: %0t ns | Addr: %0d | Data expected: CC | Data out: %h", $realtime, r_addr, r_data);
        
        r_addr = 4'd3; @(posedge rclk);
        $display("[READ]  Time: %0t ns | Addr: %0d | Data expected: DD | Data out: %h", $realtime, r_addr, r_data);

        r_en = 1'b0; // Ngừng đọc

        #50;
        $display("==================================================");
        $display("[TEST DONE] Kiem chung hoan tat.");
        $display("==================================================");
        $finish;
    end

endmodule