`timescale 1ns / 1ps

module tb_sync_2ff();

    // -------------------------------------------------------------------------
    // KHAI BÁO PARAMETER
    // -------------------------------------------------------------------------
    localparam int WIDTH = 5; // Độ rộng của con trỏ (Giả sử FIFO sâu 16 -> Trỏ 5 bit)

    // -------------------------------------------------------------------------
    // KHAI BÁO TÍN HIỆU
    // -------------------------------------------------------------------------
    logic clk;
    logic reset;
    logic [WIDTH-1:0] async_in;
    logic [WIDTH-1:0] sync_out;

    // -------------------------------------------------------------------------
    // GỌI MODULE CẦN KIỂM THỬ (DUT)
    // -------------------------------------------------------------------------
    sync_2ff #(
        .WIDTH(WIDTH)
    ) dut (
        .clk      (clk),
        .reset    (reset),
        .async_in (async_in),
        .sync_out (sync_out)
    );

    // -------------------------------------------------------------------------
    // BỘ TẠO XUNG NHỊP ĐÍCH (Destination Clock)
    // Giả sử tần số 50MHz -> Chu kỳ T = 20ns (Lật mỗi 10ns)
    // Các cạnh lên (Posedge) sẽ rơi vào: 10, 30, 50, 70, 90... ns
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // KỊCH BẢN MÔ PHỎNG (Cố tình tạo dữ liệu bất đồng bộ)
    // -------------------------------------------------------------------------
    initial begin
        // 1. Giai đoạn Reset
        reset    = 1'b1;
        async_in = '0;
        
        #25; // Nhả reset ở thời điểm 25ns
        reset = 1'b0;
        
        $display("[TIME: %0t] Reset released.", $realtime);

        // 2. Bắn dữ liệu bất đồng bộ (Asynchronous Injection)
        // Cố tình thay đổi async_in ở thời điểm 42ns (Lệch pha với cạnh clock ở 50ns)
        #17; 
        async_in = 5'b00011;
        $display("[TIME: %0t] Async Data IN  = %b (Waiting for synchronization...)", $realtime, async_in);

        // Đợi một lúc rồi thay đổi tiếp ở thời điểm 86ns (Lệch pha với cạnh clock ở 90ns)
        #44; 
        async_in = 5'b00111;
        $display("[TIME: %0t] Async Data IN  = %b (Waiting for synchronization...)", $realtime, async_in);

        // Thay đổi tiếp ở 143ns
        #57;
        async_in = 5'b01111;
        $display("[TIME: %0t] Async Data IN  = %b (Waiting for synchronization...)", $realtime, async_in);

        #100;
        $display("[TIME: %0t] Simulation finished.", $realtime);
        $finish;
    end

    // -------------------------------------------------------------------------
    // TỰ ĐỘNG THEO DÕI NGÕ RA (Monitor)
    // -------------------------------------------------------------------------
    always @(sync_out) begin
        $display("[TIME: %0t] SYNC Data OUT = %b", $realtime, sync_out);
    end

endmodule