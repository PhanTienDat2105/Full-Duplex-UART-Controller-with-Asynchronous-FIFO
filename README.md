

```markdown
# Parameterizable Full-Duplex UART Controller with Asynchronous FIFO

### Module Breakdown

1. **`baud_rate_generator.sv`**: Calculates the precise clock division factor using `$clog2()` based on system configuration. It outputs two clocks: `tx_baud_clk` (exactly at the baud rate frequency) and `rx_baud_clk_16x` (16 times the baud rate for oversampling).
2. **`fifo_mem.sv`**: A parameterized Dual-Port SRAM module enabling concurrent write and read operations from completely asynchronous clock edges.
3. **`sync_2ff.sv`**: A robust 2-Stage Flip-Flop (2-Flop) Synchronizer designed to capture multi-bit Gray code pointers across the clock boundary while effectively mitigating metastability risks.
4. **`wptr_full.sv` & `rptr_empty.sv**`: The algorithmic core of the FIFO. These modules compute binary memory addresses, convert them to Gray code for safe synchronization, and implement specialized math to generate pessimistic `Full` and `Empty` flags.
5. **`uart_tx.sv`**: An isolated FSM that serializes 8-bit parallel data from the TX FIFO into a standard UART frame format (1 Start Bit, 8 Data Bits, 1 Stop Bit).
6. **`uart_rx.sv`**: An advanced serial receiver featuring a **16x Oversampling Technique** to robustly filter line noise, prevent glitches, and execute mid-bit data locking.
7. **`uart_top_controller.sv`**: The top-level wrapper module that handles internal port mapping and incorporates glue logic (such as a 1-cycle latency pipeline register) to match synchronous RAM access times with the UART FSM states.

---

## 🛠️ Key Technical Concepts Implemented

### 1. Clock Domain Crossing (CDC) & Metastability Mitigation

Directly sampling a fast asynchronous signal in a different clock domain can cause the destination Flip-Flop to enter a metastable state—where its output hangs between logic `0` and `1`. This design employs a **2-Flop Synchronizer** (`sync_2ff.sv`) on all crossing pointer paths. The first stage allows a metastable signal to settle, while the second stage ensures a clean, synchronized logic level is distributed to the control logic.

### 2. Gray Code Pointer Synchronization & Wrap-Around Math

When transferring pointers across asynchronous boundaries, standard binary values cannot be used because multi-bit transitions (e.g., `0111` to `1000` alters 4 bits concurrently) can lead to catastrophic decoding errors due to uneven wire delays.

* This project implements **Binary-to-Gray Conversion** using the hardware-efficient expression: `Gray = (Bin >> 1) ^ Bin`.
* Since Gray code changes only **1 bit at a time**, the synchronizer will at worst sample the old value or the new value, completely eliminating corrupted intermediate states.
* To detect the `Full` condition with an extra wrap-around bit ($N+1$ bits), the design applies a dedicated Gray code condition: **The two most significant bits (MSBs) must be inverted, while all remaining lower bits must match exactly**.



### 3. 16x Oversampling Technique

To maximize tolerance against clock drift and line reflections, the `uart_rx` module operates on a clock 16 times faster than the incoming bit rate.

* Upon detecting a falling edge (Start Bit candidate), a specialized counter counts exactly 7 cycles of `rx_baud_clk_16x` to verify and lock onto the **precise geometric center** of the Start Bit.
* From that point onward, the FSM samples the serial input line precisely every **16 clock ticks**, ensuring that data bits are always read at their peak voltage stability window, far away from transition edges.

---

## 📂 Repository File Structure

```text
├── rtl/
│   ├── baud_rate_generator.sv   # Parameterized clock divider module
│   ├── fifo_mem.sv              # Dual-Port synchronous RAM for FIFO
│   ├── sync_2ff.sv              # 2-Stage Flip-Flop Synchronizer for CDC
│   ├── wptr_full.sv             # Write pointer controller & Full flag logic
│   ├── rptr_empty.sv            # Read pointer controller & Empty flag logic
│   ├── async_fifo_top.sv        # Top-level Asynchronous FIFO wrapper
│   ├── uart_tx.sv               # UART Transmitter (Serialization FSM)
│   ├── uart_rx.sv               # UART Receiver (16x Oversampling FSM)
│   └── uart_top_controller.sv   # Full system integrated Top module
└── bench/
    ├── tb_baud_rate_generator.sv # Unit Testbench for Baud rate divider
    ├── tb_fifo_mem.sv            # Unit Testbench for Dual-Port Memory
    ├── tb_sync_2ff.sv            # Unit Testbench for Synchronizer 
    ├── tb_async_fifo_top.sv      # Burst verification for Asynchronous FIFO
    └── tb_uart_top_controller.sv # End-to-End loopback system Testbench

```

---

## 📊 Verification & Simulation Strategy

The IP core has been rigorously verified through a layered simulation strategy in AMD Xilinx Vivado Simulator.

### Full-System Loopback Verification (`tb_uart_top_controller.sv`)

The main verification environment sets up a physical hardware **Loopback** where the `tx_out` pin is wired directly to the `rx_in` pin on the testbench level.

```systemverilog
// Testbench Loopback Port Mapping
uart_top_controller #(
    .SYS_CLK_FREQ(100_000_000),
    .BAUD_RATE(115200)
) dut (
    .sys_clk(sys_clk),
    .rx_in(serial_line), // Looped back
    .tx_out(serial_line) // Looped back
    // ... other system ports
);

```

#### Verification Flow:

1. **Write Burst**: The testbench mimics a high-speed CPU by asserting `tx_en` at **100 MHz**, writing 4 distinct bytes (`8'hAA`, `8'hBB`, `8'hCC`, `8'hDD`) into the TX FIFO sequentially in just **40 ns**.
2. **Physical Transmission**: The CPU goes into an idle polling state. The TX FIFO synchronizes data to the slow `tx_baud_clk` domain, and the UART TX serializes the data packet bit-by-bit onto the `serial_line`. At 115200 Baud, each frame spans exactly **86.8 µs**.
3. **Reception & Dynamic Polling**: The UART RX detects the frame, utilizes 16x oversampling to extract the parallel bytes, and pushes them directly into the RX FIFO. The CPU executes an immediate dynamic read (`rx_read_en`) as soon as the FIFO non-empty flag (`~rx_fifo_empty`) is asserted, validating complete data integrity.

---

## 🚀 How to Run (Vivado Setup Guide)

1. Clone this repository to your local directory:
```bash
git clone [https://github.com/PhanTienDat2105/UART_Asynchronous_FIFO.git](https://github.com/PhanTienDat2105/UART_Asynchronous_FIFO.git)

```


2. Open **Xilinx Vivado** (Recommended version 2024.1 or later).
3. Create a new project and select **RTL Project**.
4. Add all SystemVerilog files located in the `rtl/` folder as design sources.
5. Add all SystemVerilog files located in the `bench/` folder as simulation sources.
6. Set `tb_uart_top_controller` as the top module for your simulation set (`sim_1`).
7. In the **Flow Navigator**, click **Run Simulation** -> **Run Behavioral Simulation**.
8. To visualize the full physical transmission window, run the simulation for at least `400 us` by executing `run 400us` in the Tcl Console, or press **`F`** to **Zoom Fit** the entire waveform view.


