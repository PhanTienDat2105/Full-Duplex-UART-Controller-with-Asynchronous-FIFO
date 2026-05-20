`timescale 1ns / 1ps

module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4  // Độ sâu = 2^4 = 16 words
)(
    input  logic wclk,
    input  logic w_en,
    input  logic [ADDR_WIDTH-1:0] w_addr,
    input  logic [DATA_WIDTH-1:0] w_data,
    
    input  logic rclk,
    input  logic r_en,
    input  logic [ADDR_WIDTH-1:0] r_addr,
    output logic [DATA_WIDTH-1:0] r_data
);

    // Khai báo mảng bộ nhớ (SRAM)
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // -------------------------------------------------------------------------
    // CỔNG GHI (Hoạt động theo wclk)
    // -------------------------------------------------------------------------
    always_ff @(posedge wclk) begin
        if (w_en) begin
            mem[w_addr] <= w_data;
        end
    end

    // -------------------------------------------------------------------------
    // CỔNG ĐỌC (Hoạt động theo rclk)
    // -------------------------------------------------------------------------
    always_ff @(posedge rclk) begin
        if (r_en) begin
            r_data <= mem[r_addr];
        end
    end

endmodule