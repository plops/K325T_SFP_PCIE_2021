# PCIe DMA Subsystem - Comprehensive Technical Documentation

## Overview and Technical Specifications

The **k7325_PCIe_DMA_V2** project implements a high-performance PCIe Gen2 x4 DMA subsystem on the Xilinx Kintex-7 XC7K325T FPGA, achieving up to **20 Gbps aggregate bandwidth** with typical throughput of **~1.8 GB/s**.  

### Core Configuration Parameters

The system is configured with the following primary parameters:

- **Data Width**: 64 bits (C_PCIE_USER_DATA_WIDTH = 64)
- **Number of Channels**: 1 (C_PCIE_NUM_CHNL = 1)
- **PCIe Configuration**: Gen2 x4 (4 lanes at 5 GT/s per lane)
- **Target Device**: xc7k325tffg676-2 (Kintex-7 325T, speed grade -2)
- **Maximum Payload Size**: 256 bytes (configurable)
- **Maximum Read Request Size**: 512 bytes (C_MAX_READ_REQ_BYTES = 512)  

## System Architecture

### Top-Level Integration

The `Example_Top.vhd` module serves as the top-level design entity, instantiating two primary components:

1. **gvi_pcie_gen2x4_wrapper**: PCIe Gen2 x4 endpoint wrapper
2. **chnl_tester**: Channel test module for DMA validation  

The top level connects PCIe physical signals (differential TX/RX pairs), reference clock, reset, and all channel interface signals between the PCIe wrapper and application logic.  

### Three-Layer Architecture

The subsystem implements a three-layer architecture:

1. **Physical/Protocol Layer**: PCIe endpoint core with GTX transceivers
2. **DMA Engine Layer**: RIFFA framework for scatter-gather DMA
3. **Application Layer**: Channel interface for user logic  

## PCIe Endpoint Core Architecture

### Core Components

The PCIe endpoint core (`pcie_k7_gen2x4`) integrates multiple functional blocks:

**1. GTXE2 Transceivers**
- Four GTX channels implementing 8b/10b encoding at 5 GT/s per lane
- Located at GTXE2_CHANNEL_X0Y0 through X0Y3
- Reference clock input: 100 MHz differential  

**2. PCIe Hard Block**
- Xilinx PCIe 2.1 hard IP located at PCIE_X0Y0
- Implements Transaction Layer, Data Link Layer, and Physical Layer functions
- Configuration space management and flow control  

**3. PIPE Interface Pipeline**
- Synchronization logic for transceiver lanes (pcie_k7_gen2x4_pipe_sync.v)
- TX and RX phase alignment control
- Delay bypass and reset management  

**4. AXI Bridge**
- Converts TLP packets to/from AXI4-Stream protocol
- Transmit throttle controller (pcie_k7_gen2x4_axi_basic_tx_thrtl_ctl.vhd)
- TX/RX data pipelines with flow control  

**5. BRAM Storage**
- Block RAM hierarchy for TX/RX buffering
- Managed by pcie_bram_top_7x, pcie_brams_7x, and pcie_bram_7x modules
- Dynamic BRAM allocation based on data width and configuration  

## RIFFA DMA Engine Architecture

### RIFFA Endpoint Module

The `riffa_endpoint_64.v` module serves as the central coordinator for all DMA operations with the following key parameters:

- **C_PCI_DATA_WIDTH**: 64 bits
- **C_NUM_CHNL**: 12 channels supported (configured to 1)
- **C_MAX_READ_REQ_BYTES**: 512 bytes
- **C_TAG_WIDTH**: 5 bits (supporting 32 outstanding requests)
- **C_ALTERA**: Set to 1 for compatibility (0 for Xilinx)  

The endpoint connects to the PCIe core via AXI4-Stream interfaces and manages channel interfaces for application logic.  

### Transmit (TX) Path Architecture

**TX Engine (tx_engine_64.v)**

The transmit engine consists of two sub-components:

1. **tx_engine_upper_64.v**: Formats read/write requests into PCIe TLP packets
   - Handles memory write requests with address, length, and data
   - Generates memory read requests with proper header formatting
   - Buffers formatted packets in FIFO (C_FIFO_DEPTH = 512)  

2. **tx_engine_lower_64.v**: Multiplexes and outputs formatted packets
   - Handles completion requests from RX engine
   - Manages AXI4-Stream output interface
   - Controls TX_DATA_VALID, TX_TLP_END_FLAG, and TX_TLP_START_FLAG signals  

**TX Port Components**

- **tx_port_64.v**: Manages channel interface and scatter-gather list reading
- **sg_list_reader_64.v**: Reads scatter-gather descriptor lists from memory
- **tx_port_channel_gate_64.v**: Channel gating and transaction event capture
- **tx_port_writer.v**: Breaks transactions into individual transfers respecting payload size and 4KB page boundaries  

### Receive (RX) Path Architecture

**RX Engine (rx_engine_64.v)**

The receive engine parses incoming PCIe TLPs with support for:

- **Memory Read Requests** (32-bit and 64-bit addressing)
- **Memory Write Requests** (32-bit and 64-bit addressing)
- **Completion TLPs** (with and without data)

TLP format definitions:
- `FMT_RXENG64_RD32`: 7'b00_00000
- `FMT_RXENG64_WR32`: 7'b10_00000
- `FMT_RXENG64_RD64`: 7'b01_00000
- `FMT_RXENG64_WR64`: 7'b11_00000
- `FMT_RXENG64_CPL`: 7'b00_01010
- `FMT_RXENG64_CPLD`: 7'b10_01010  

The engine implements a state machine for request parsing and completion data handling.  

Input/output interfaces include data, byte enables, TLP end flags, and error/poison indicators.  

**Reorder Queue Module**

The `reorder_queue.v` module ensures in-order completion delivery:

- Stores downstream TLPs in RAM indexed by tag
- Outputs packets in increasing tag sequence
- Provides next available tag for TX engine
- Handles up to 2^C_TAG_WIDTH outstanding requests (32 tags with C_TAG_WIDTH=5)  

Key parameters:
- C_NUM_TAGS = 2^C_TAG_WIDTH (32 tags)
- C_DW_PER_TAG = C_MAX_READ_REQ_BYTES/4 (128 DWORDs per tag)
- RAM addressing based on tag and data stride  

**RX Port Components**

- **rx_port_64.v**: Receives data from RX engine and buffers for channel interface
- **fifo_packer_64.v**: Packs incoming data into FIFOs based on data enable signals
- **rx_port_reader.v**: Manages receive lifecycle and issues read requests
- **sg_list_requester.v**: Handles scatter-gather list requests  

### Interrupt Controller

The `interrupt_controller.v` module manages both legacy INTx and MSI interrupts:

**Interrupt Types Supported:**
- Legacy interrupts with assertion/deassertion protocol
- Message Signaled Interrupts (MSI) - single vector

**State Machine:**
- `S_INTRCTLR_IDLE`: Waiting for interrupt request
- `S_INTRCLTR_WORKING`: Processing interrupt
- `S_INTRCLTR_COMPLETE`: Interrupt sent
- `S_INTRCLTR_CLEAR_LEGACY`: Clearing legacy interrupt
- `S_INTRCLTR_DONE`: Interrupt cycle complete  

The controller pulses `INTR_DONE` when the interrupt is successfully sent and handles the CONFIG_INTERRUPT_MSIENABLE signal to select between MSI and legacy modes.  

## Channel Tester Module

### Functional Description

The `chnl_tester.vhd` module demonstrates DMA functionality through a loopback test pattern:

**Generic Parameters:**
- G_DATA_WIDTH: Configurable data width (set to 32 or 64 bits)

**Port Interface:**
- Clock and reset inputs
- RX channel: CHNL_RX, CHNL_RX_ACK, CHNL_RX_LEN, CHNL_RX_OFF, CHNL_RX_DATA, CHNL_RX_DATA_VALID, CHNL_RX_DATA_REN
- TX channel: CHNL_TX, CHNL_TX_ACK, CHNL_TX_LEN, CHNL_TX_OFF, CHNL_TX_DATA, CHNL_TX_DATA_VALID, CHNL_TX_DATA_REN  

### State Machine Operation

The channel tester implements a 4-state FSM:

**State "00" (Wait for RX):**
- Monitors CHNL_RX signal
- Captures CHNL_RX_LEN when transfer starts
- Transitions to state "01"

**State "01" (Receive Data):**
- Asserts CHNL_RX_ACK and CHNL_RX_DATA_REN
- Captures incoming data on CHNL_RX_DATA when CHNL_RX_DATA_VALID is high
- Increments counter by G_DATA_WIDTH/32
- Transitions to state "10" when rCount >= rLen

**State "10" (Prepare TX):**
- Prepares for transmit operation
- Transitions to state "11"

**State "11" (Transmit Data):**
- Asserts CHNL_TX with captured length
- Sets CHNL_TX_LAST to '1' (single transaction)
- Provides data on CHNL_TX_DATA with CHNL_TX_DATA_VALID
- Generates incrementing pattern using rCount_ext
- Returns to state "00" when transmission complete  

## Data Flow Paths

### Host-to-FPGA Write Path

1. Host driver issues memory write TLP via PCIe root complex
2. PCIe physical layer receives data on GTX transceivers
3. PCIe hard block processes TLP headers and validates packet
4. AXI bridge converts TLP to AXI4-Stream format (m_axis_rx interface)
5. RX engine (rx_engine_64.v) parses TLP and extracts address, length, data
6. RX port routes data to appropriate channel based on address mapping
7. Application asserts CHNL_RX_ACK to accept transfer
8. Data transfers on CHNL_RX_DATA with CHNL_RX_DATA_VALID handshake
9. CHNL_RX_LAST signals completion  

### FPGA-to-Host Read Path

1. Application asserts CHNL_TX with CHNL_TX_LEN and CHNL_TX_OFF
2. TX port calculates required memory read requests (respecting 4KB boundaries)
3. TX engine (tx_engine_upper_64.v) formats memory read TLP with address, length, tag
4. TLP sent via AXI4-Stream (s_axis_tx interface) to PCIe core
5. PCIe core transmits read request over physical link
6. Host returns completion TLPs with data payload
7. RX engine receives completions and passes to reorder queue
8. Reorder queue ensures in-order delivery based on tags
9. TX port provides data to application via CHNL_TX_DATA interface
10. CHNL_TX_DATA_REN controls data flow from application  

## Clock Architecture

### Clock Sources and Generation

**Primary Reference Clock:**
- External 100 MHz differential PCIe reference clock (pcie_refclkin_p/n)
- Package pins: H6 (P) and H5 (N)
- Period constraint: 10.000 ns  

**MMCM Clock Generator (pcie_k7_gen2x4_pipe_clock.v):**

Generated clocks from MMCM:
- **clk_125mhz_x0y0**: 125 MHz user clock (USERCLK1) for general logic and RIFFA engine
- **clk_250mhz_x0y0**: 250 MHz user clock (USERCLK2) for high-speed processing
- **PCLK**: PCIe core clock (125/250 MHz depending on link speed)
- **RXUSRCLK**: Receive user clock (link-speed dependent)
- **DCLK**: Debug/DRP clock  

The MMCM implements clock selection logic based on negotiated link speed (Gen1 vs Gen2).  

**Generated Clock Constraints:**  

**TXOUTCLK Reference:**
- 10.000 ns period constraint on GTXE2 TXOUTCLK
- Used as reference for generated clocks  

### Clock Domain Isolation

Physically exclusive clock groups prevent timing analysis across mutually exclusive paths:  

False path constraints for BUFGCTRL clock selection:  

## Reset Architecture

### Reset Sequence and Control

**Primary Reset:**
- External active-low reset: sys_rst_n (pin E17, LVCMOS33 with pullup)  

**Reset FSM Modules:**

1. **pcie_k7_gen2x4_pipe_reset.v**: PIPE interface reset FSM
   - Controls reset sequence for PCIe core
   - Ensures proper timing for MMCM lock
   - Manages transceiver initialization

2. **pcie_k7_gen2x4_gt_reset.v**: GTX transceiver reset FSM
   - Sequences GTXE2_CHANNEL resets
   - Handles PLL lock detection
   - Coordinates with PIPE reset logic  

**Reset Propagation:**

From sys_rst_n, reset propagates through:
1. PIPE reset FSM
2. GT transceiver reset FSM  
3. MMCM reset
4. PCIe hard block reset
5. AXI bridge and RIFFA logic
6. Application channel reset (chnl_reset output)

False path constraint on reset input:  

### Asynchronous Path Constraints

Multiple asynchronous signals have false path constraints to prevent timing violations:

- RXELECIDLE, TXPHINITDONE, TXPHALIGNDONE
- TXDLYSRESETDONE, RXDLYSRESETDONE, RXPHALIGNDONE
- RXCDRLOCK, CFGMSGRECEIVEDPMETO
- CPLLLOCK, QPLLLOCK  

Additional false paths for link management signals:  

## Configuration Parameters and Settings

### PCIe Configuration Registers

The RIFFA endpoint receives dynamic configuration from the PCIe core:

**Link Configuration:**
- CONFIG_LINK_WIDTH: 6-bit encoding (000100 = x4)
- CONFIG_LINK_RATE: 2-bit encoding (10 = 5.0 GT/s for Gen2)
- CONFIG_MAX_READ_REQUEST_SIZE: 3-bit encoding (010 = 512B)
- CONFIG_MAX_PAYLOAD_SIZE: 3-bit encoding (001 = 256B)

**Flow Control:**
- CONFIG_MAX_CPL_DATA: Receive credit limit for data
- CONFIG_MAX_CPL_HDR: Receive credit limit for headers  
- CONFIG_CPL_BOUNDARY_SEL: Read completion boundary (0=64B, 1=128B)

**Interrupt Configuration:**
- CONFIG_INTERRUPT_MSIENABLE: MSI enable flag
- CONFIG_BUS_MASTER_ENABLE: Bus master enable
- CONFIG_COMPLETER_ID: 16-bit completer ID  

### Device Configuration

**Pin Assignment Summary:**

PCIe Lanes:
- Lane 0: GTXE2_CHANNEL_X0Y3, Package pin J4
- Lane 1: GTXE2_CHANNEL_X0Y2, Package pin L4
- Lane 2: GTXE2_CHANNEL_X0Y1, Package pin N4
- Lane 3: GTXE2_CHANNEL_X0Y0, Package pin R4  

Debug/Status Signals:
- link_up: Pin B20 (LVCMOS33)
- Dbg_LED: Pin A19 (LVCMOS33)  

### Bitstream Configuration

**SPI Flash Configuration:**
- Bus width: 4-bit (x4 SPI)
- Configuration rate: 50 MHz
- Flash device: MT25QL256 (256 Mbit)
- Unused pins: PULLUP
- Compression: Enabled  

**Voltage Configuration:**
- CONFIG_VOLTAGE: 3.3V
- CFGBVS: VCCO
- Operating conditions: vcco33 at 1.500V  

## Implementation Details

### Project Structure

**Vivado Project:**
- Project file: PCIE_DMA_Demo.xpr (42 KB)
- Tool version: Vivado 2019.1
- Top-level: Example_Top.vhd (VHDL)
- Active constraints: pcie_7k325.xdc  

**Hardware Configuration:**
- Bitstream: 2021_K325T.mcs (MCS format)
- Physical constraints: 2021_K325T.prm
- SPI flash: MT25QL256  

### Wrapper Hierarchy

The PCIe wrapper instantiation flow:

1. **gvi_pcie_gen2x4_wrapper** (VHDL wrapper)
   - Generic parameters: G_NUM_CHNL=1, G_DATA_WIDTH=64
   - Instantiates riffa_top_pcie_7x_v2_1  

2. **riffa_top_pcie_7x_v2_1** (Verilog top)
   - Instantiates pcie_k7_gen2x4 (PCIe core)
   - Instantiates pcie_app_7x (RIFFA application)
   - Optional external clock module  

### Performance Characteristics

**Theoretical vs Actual Performance:**
- Aggregate bandwidth: 20 Gbps (2.5 GB/s theoretical)
- Actual throughput: ~1.8 GB/s
- Performance factors: TLP overhead, link training, flow control, page boundaries

**Throughput Optimization:**
- Scatter-gather DMA eliminates buffer contiguity requirements
- Multi-channel framework (supports up to 12 channels)
- Interrupt coalescing reduces overhead
- Maximum payload size optimized at 256 bytes  

### Supporting Components

**Utility Modules:**

- **syncff.v**: Double flip-flop synchronizer for clock domain crossing
- **cross_domain_signal.v**: Cross-domain signal synchronization
- **async_fifo.v / async_fifo_fwft.v**: Asynchronous FIFOs with first-word fall-through
- **sync_fifo.v**: Synchronous FIFO
- **ram_1clk_1w_1r.v / ram_2clk_1w_1r.v**: Single and dual-clock RAM primitives
- **ff.v**: Simple D flip-flop  

**Common Functions:**
- clog2: Ceiling log base 2 calculation
- clog2s: Signed version of clog2
- Used throughout for parameter calculations  

## Notes

This PCIe DMA subsystem represents a complete, production-ready implementation for high-performance data transfer between a host PC and FPGA. The RIFFA (Reusable Integration Framework for FPGA Accelerators) DMA engine was originally developed by the University of California, San Diego, and provides a robust, well-tested framework for PCIe communication.

Key architectural decisions include:
- 64-bit data path balancing throughput and resource utilization
- Single-channel configuration optimized for this specific application
- Scatter-gather DMA support for flexible memory management
- Tag-based reordering ensuring correct data sequencing
- Both MSI and legacy interrupt support for broad compatibility

The system achieves near-theoretical maximum throughput for PCIe Gen2 x4, with the ~10% overhead primarily due to TLP headers, flow control credits, and 4KB page boundary restrictions inherent to the PCIe protocol.


