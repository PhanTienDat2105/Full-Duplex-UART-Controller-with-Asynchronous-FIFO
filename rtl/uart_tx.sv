`timescale 1ns / 1ps

module uart_tx (
    input  logic       tx_baud_clk, // Xung nhịp tốc độ baud (Ví dụ: 115200Hz)
    input  logic       reset,       // Posedge reset
    input  logic       tx_start,    // Xung kích hoạt bắt đầu truyền (Kéo dài 1 chu kỳ clock)
    input  logic [7:0] tx_data,     // Dữ liệu 8-bit cần truyền
    
    output logic       tx_out,      // Chân tín hiệu xuất ra phần cứng vật lý
    output logic       tx_busy      // Cờ báo hiệu đang bận truyền, không nhận thêm data
);

    // -------------------------------------------------------------------------
    // ĐỊNH NGHĨA CÁC TRẠNG THÁI CỦA FSM (State Machine)
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE       = 2'b00,
        START_BIT  = 2'b01,
        DATA_BITS  = 2'b10,
        STOP_BIT   = 2'b11
    } state_t;

    state_t state;
    
    // Các thanh ghi nội bộ
    logic [2:0] bit_idx;   // Bộ đếm từ 0->7 để kiểm soát 8 bit data
    logic [7:0] shift_reg; // Thanh ghi dịch chứa dữ liệu

    // -------------------------------------------------------------------------
    // KHỐI LOGIC ĐIỀU KHIỂN & TRUYỀN DỮ LIỆU
    // -------------------------------------------------------------------------
    always_ff @(posedge tx_baud_clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            tx_out    <= 1'b1;  // Theo chuẩn UART, đường dây rỗi (Idle) luôn ở mức CAO
            tx_busy   <= 1'b0;
            bit_idx   <= '0;
            shift_reg <= '0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out  <= 1'b1;
                    bit_idx <= '0;
                    
                    // Nếu có tín hiệu yêu cầu truyền
                    if (tx_start) begin
                        tx_busy   <= 1'b1;      // Bật cờ bận
                        shift_reg <= tx_data;   // Nạp dữ liệu vào thanh ghi dịch
                        state     <= START_BIT; // Chuyển sang ném Start Bit
                    end else begin
                        tx_busy   <= 1'b0;
                    end
                end
                
                START_BIT: begin
                    tx_out <= 1'b0;     // Start Bit luôn là mức THẤP
                    state  <= DATA_BITS;
                end
                
                DATA_BITS: begin
                    tx_out    <= shift_reg[0]; // Bắn LSB (bit ngoài cùng bên phải) ra đường dây
                    shift_reg <= {1'b0, shift_reg[7:1]}; // Dịch toàn bộ mảng sang phải 1 bit
                    
                    if (bit_idx == 3'd7) begin // Nếu đã bắn đủ 8 bit
                        state <= STOP_BIT;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end
                
                STOP_BIT: begin
                    tx_out <= 1'b1; // Stop Bit luôn là mức CAO
                    state  <= IDLE; // Quay về chờ lệnh tiếp theo
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule