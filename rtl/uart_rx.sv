`timescale 1ns / 1ps

module uart_rx (
    input  logic       rx_baud_clk_16x, // Xung nhịp tốc độ cao (16 x Baudrate)
    input  logic       reset,           // Posedge reset
    input  logic       rx_in,           // Chân nhận tín hiệu vật lý
    
    output logic [7:0] rx_data,         // Dữ liệu 8-bit đã gom xong
    output logic       rx_valid         // Xung báo hiệu (1 chu kỳ) có data mới hợp lệ
);

    // -------------------------------------------------------------------------
    // ĐỊNH NGHĨA TRẠNG THÁI FSM
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE       = 2'b00,
        START_BIT  = 2'b01,
        DATA_BITS  = 2'b10,
        STOP_BIT   = 2'b11
    } state_t;

    state_t state;
    
    // Các thanh ghi nội bộ
    logic [3:0] sample_cnt; // Bộ đếm 16 nhịp (từ 0 -> 15)
    logic [2:0] bit_idx;    // Bộ đếm bit dữ liệu (từ 0 -> 7)
    logic [7:0] shift_reg;  // Thanh ghi dịch gom dữ liệu

    // -------------------------------------------------------------------------
    // KHỐI LOGIC ĐIỀU KHIỂN & NHẬN DỮ LIỆU
    // -------------------------------------------------------------------------
    always_ff @(posedge rx_baud_clk_16x or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            sample_cnt <= '0;
            bit_idx    <= '0;
            shift_reg  <= '0;
            rx_data    <= '0;
            rx_valid   <= 1'b0;
        end else begin
            // Mặc định rx_valid chỉ nháy 1 xung rồi tắt
            rx_valid <= 1'b0; 

            case (state)
                IDLE: begin
                    sample_cnt <= '0;
                    bit_idx    <= '0;
                    
                    // Phát hiện cạnh xuống của Start Bit
                    if (rx_in == 1'b0) begin
                        state <= START_BIT;
                    end
                end
                
                START_BIT: begin
                    // Đếm đến 7 (tức là đi được nửa chu kỳ bit)
                    if (sample_cnt == 4'd7) begin
                        // Kiểm tra lại lần nữa xem rx_in có thực sự là mức 0 không
                        // (Tránh trường hợp nhiễu gai (glitch) làm sụt áp ngắn hạn)
                        if (rx_in == 1'b0) begin
                            sample_cnt <= '0;
                            state      <= DATA_BITS;
                        end else begin
                            state <= IDLE; // Nhiễu ảo, quay lại chờ
                        end
                    end else begin
                        sample_cnt <= sample_cnt + 1'b1;
                    end
                end
                
                DATA_BITS: begin
                    // Cứ đếm đủ 16 nhịp (1 chu kỳ baud) là lại lấy mẫu 1 lần
                    if (sample_cnt == 4'd15) begin
                        sample_cnt <= '0;
                        // Gom bit vào thanh ghi dịch (Đưa bit mới vào MSB, dịch sang phải)
                        shift_reg <= {rx_in, shift_reg[7:1]};
                        
                        if (bit_idx == 3'd7) begin
                            state <= STOP_BIT;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        sample_cnt <= sample_cnt + 1'b1;
                    end
                end
                
                STOP_BIT: begin
                    // Đợi đến giữa chu kỳ của Stop Bit để chốt sổ
                    if (sample_cnt == 4'd15) begin
                        state <= IDLE;
                        // Stop bit chuẩn phải là mức 1
                        if (rx_in == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1; // Bắn xung báo cáo: "Có data ngon!"
                        end
                    end else begin
                        sample_cnt <= sample_cnt + 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule