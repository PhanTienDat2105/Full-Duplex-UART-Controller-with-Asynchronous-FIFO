`timescale 1ns / 1ps

module sync_2ff #(
    parameter int WIDTH = 5 // Độ rộng con trỏ Gray (Bằng ADDR_WIDTH + 1)
)(
    input  logic clk,       // Xung nhịp của miền đích (Destination Domain)
    input  logic reset,
    input  logic [WIDTH-1:0] async_in, // Con trỏ Gray từ miền kia gửi sang
    
    output logic [WIDTH-1:0] sync_out  // Con trỏ Gray đã được đồng bộ an toàn
);

    // Khai báo 2 tầng Flip-Flop
    logic [WIDTH-1:0] q1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q1       <= '0;
            sync_out <= '0;
        end else begin
            q1       <= async_in; // Tầng 1: Hứng tín hiệu (có thể dính metastability)
            sync_out <= q1;       // Tầng 2: Xuất tín hiệu sạch và ổn định
        end
    end

endmodule