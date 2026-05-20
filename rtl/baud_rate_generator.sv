`timescale 1ns / 1ps

module baud_rate_generator 
// --- KHỐI PARAMETER ĐƯỢC TÁCH RIÊNG RA BÊN NGOÀI ---
#(
    parameter int SYS_CLK_FREQ = 100_000_000,
    parameter int BAUD_RATE    = 115200
)
// --------------------------------------------------
(
    input  logic sys_clk,
    input  logic reset, // Posedge reset (Active-High)
    
    output logic tx_baud_clk,
    output logic rx_baud_clk_16x
);

    // --- CÁC HẰNG SỐ TÍNH TOÁN NỘI BỘ (LOCALPARAM) ---
    localparam int RX_DIV = SYS_CLK_FREQ / (BAUD_RATE * 16 * 2);
    localparam int TX_DIV = SYS_CLK_FREQ / (BAUD_RATE * 2);

    localparam int RX_CNT_WIDTH = $clog2(RX_DIV);
    localparam int TX_CNT_WIDTH = $clog2(TX_DIV);

    // --- KHAI BÁO CÁC BỘ ĐẾM ---
    logic [RX_CNT_WIDTH-1:0] rx_counter;
    logic [TX_CNT_WIDTH-1:0] tx_counter;

    // -------------------------------------------------------------------------
    // BỘ ĐẾM TẠO XUNG NHỊP RX (Tần số = 16 x Baud_rate)
    // -------------------------------------------------------------------------
    always_ff @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            rx_counter      <= '0;
            rx_baud_clk_16x <= 1'b0;
        end else begin
            if (rx_counter == RX_DIV[RX_CNT_WIDTH-1:0] - 1'b1) begin
                rx_counter      <= '0;
                rx_baud_clk_16x <= ~rx_baud_clk_16x; 
            end else begin
                rx_counter      <= rx_counter + 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // BỘ ĐẾM TẠO XUNG NHỊP TX (Tần số = Baud_rate)
    // -------------------------------------------------------------------------
    always_ff @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            tx_counter  <= '0;
            tx_baud_clk <= 1'b0;
        end else begin
            if (tx_counter == TX_DIV[TX_CNT_WIDTH-1:0] - 1'b1) begin
                tx_counter  <= '0;
                tx_baud_clk <= ~tx_baud_clk; 
            end else begin
                tx_counter  <= tx_counter + 1'b1;
            end
        end
    end

endmodule