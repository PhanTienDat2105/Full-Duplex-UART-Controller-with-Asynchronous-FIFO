`timescale 1ns / 1ps

module wptr_full #(
    parameter int ADDR_WIDTH = 4 // Chiều sâu 16 (2^4), con trỏ sẽ có 5 bit
)(
    input  logic wclk,
    input  logic reset,
    input  logic w_en,
    input  logic [ADDR_WIDTH:0] wq2_rgray, // Con trỏ Read Gray đã được đồng bộ mang sang
    
    output logic w_full,
    output logic [ADDR_WIDTH-1:0] w_addr,  // 4 bit địa chỉ thật cấp cho RAM
    output logic [ADDR_WIDTH:0] w_gray     // 5 bit Gray gửi sang miền Read
);

    logic [ADDR_WIDTH:0] w_bin, w_bin_next;
    logic [ADDR_WIDTH:0] w_gray_next;

    // 1. Tăng con trỏ nhị phân (Chỉ tăng khi có lệnh ghi VÀ chưa đầy)
    assign w_bin_next = w_bin + (w_en & ~w_full);
    
    // 2. Chuyển đổi Binary sang Gray: G = (B >> 1) XOR B
    assign w_gray_next = (w_bin_next >> 1) ^ w_bin_next;
    
    // 3. Cấp địa chỉ thật cho RAM (Cắt bỏ bit MSB)
    assign w_addr = w_bin[ADDR_WIDTH-1:0];

    // 4. Cập nhật thanh ghi
    always_ff @(posedge wclk or posedge reset) begin
        if (reset) begin
            w_bin  <= '0;
            w_gray <= '0;
            w_full <= 1'b0;
        end else begin
            w_bin  <= w_bin_next;
            w_gray <= w_gray_next;
            
            // ĐIỀU KIỆN FULL CHO MÃ GRAY: 
            // 2 bit cao nhất phải NGƯỢC NHAU, các bit còn lại GIỐNG NHAU
            w_full <= (w_gray_next == {~wq2_rgray[ADDR_WIDTH:ADDR_WIDTH-1], 
                                        wq2_rgray[ADDR_WIDTH-2:0]});
        end
    end

endmodule