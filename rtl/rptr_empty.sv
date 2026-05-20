`timescale 1ns / 1ps

module rptr_empty #(
    parameter int ADDR_WIDTH = 4 
)(
    input  logic rclk,
    input  logic reset,
    input  logic r_en,
    input  logic [ADDR_WIDTH:0] rq2_wgray, // Con trỏ Write Gray đã được đồng bộ mang sang
    
    output logic r_empty,
    output logic [ADDR_WIDTH-1:0] r_addr,  // 4 bit địa chỉ thật cấp cho RAM
    output logic [ADDR_WIDTH:0] r_gray     // 5 bit Gray gửi sang miền Write
);

    logic [ADDR_WIDTH:0] r_bin, r_bin_next;
    logic [ADDR_WIDTH:0] r_gray_next;

    // 1. Tăng con trỏ nhị phân (Chỉ tăng khi có lệnh đọc VÀ không rỗng)
    assign r_bin_next = r_bin + (r_en & ~r_empty);
    
    // 2. Chuyển đổi Binary sang Gray
    assign r_gray_next = (r_bin_next >> 1) ^ r_bin_next;
    
    // 3. Cấp địa chỉ thật cho RAM
    assign r_addr = r_bin[ADDR_WIDTH-1:0];

    // 4. Cập nhật thanh ghi
    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            r_bin   <= '0;
            r_gray  <= '0;
            r_empty <= 1'b1; // Mới reset xong thì FIFO chắc chắn Rỗng
        end else begin
            r_bin   <= r_bin_next;
            r_gray  <= r_gray_next;
            
            // ĐIỀU KIỆN EMPTY CHO MÃ GRAY: 
            // Tất cả các bit của con trỏ Đọc phải TRÙNG KHỚP 100% với con trỏ Ghi
            r_empty <= (r_gray_next == rq2_wgray);
        end
    end

endmodule