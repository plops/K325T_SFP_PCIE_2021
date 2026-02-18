[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/plops/K325T_SFP_PCIE_2021)

# K325T_SFP_PCIE_2021

A dual-subsystem FPGA design for the Xilinx Kintex-7 XC7K325T FPGA, implementing high-speed PCIe Gen2 x4 DMA transfers and 10 Gigabit Ethernet UDP/IP networking over SFP+.

## Overview

This project provides two independent but complementary hardware acceleration subsystems:

1. **PCIe DMA Subsystem** - High-speed bidirectional data transfer between host PC and FPGA via PCIe Gen2 x4, achieving up to 20 Gbps aggregate bandwidth using the RIFFA DMA engine
2. **10G UDP/IP SFP Subsystem** - Full 10 Gigabit Ethernet network interface with UDP/IP protocol stack over SFP+ transceivers  

## Hardware Platform

- **FPGA Device:** Xilinx Kintex-7 XC7K325T
- **Package:** FFG676 (676-pin FineLine BGA)
- **Speed Grade:** -2
- **Configuration:** SPI Flash (MT25QL256, 4-bit mode @ 50 MHz)
- **Development Tool:** Xilinx Vivado 2019.1  

## Project Structure

```
K325T_SFP_PCIE_2021/
├── k7325_PCIe_DMA_V2/              # PCIe DMA subsystem
│   ├── PCIe_DMA_V2_5031_spix4_ok/  # Vivado project files
│   ├── readme.md                    # PCIe subsystem documentation
│   └── files.md                     # Detailed file descriptions
│
└── udp_ip_10g_sfp_X1_SFP_A/        # 10G UDP/IP SFP subsystem
    ├── udp_ip_10g_sfp/             # Vivado project files
    ├── files.md                     # Detailed file descriptions
    └── show_files.sh               # Utility script
```

## Features

### PCIe DMA Subsystem

- **PCIe Configuration:** Gen2 x4 (4 lanes @ 5 GT/s per lane)
- **Peak Bandwidth:** 20 Gbps (2.5 GB/s theoretical, ~1.8 GB/s typical)
- **DMA Engine:** RIFFA (Reusable Integration Framework for FPGA Accelerators)
- **Data Width:** 64-bit
- **Maximum Payload:** 256 bytes (configurable)
- **Scatter-Gather Support:** Yes
- **Interrupts:** Legacy INTx and MSI  

**Key Components:**
- PCIe endpoint core with GTXE2 transceivers (`pcie_k7_gen2x4`)
- RIFFA DMA engine with TX/RX engines and reordering
- Channel tester module for validation and loopback testing
- AXI4-Stream interface for data transfer  

### 10G UDP/IP SFP Subsystem

- **Data Rate:** 10 Gbps full-duplex
- **Physical Layer:** 10GBASE-R over SFP+
- **Protocol Stack:** Complete UDP/IP implementation
- **Core Clock:** 156.25 MHz
- **Data Width:** 64-bit AXI Stream
- **Buffering:** Three-tier FIFO architecture  

**Key Components:**
- Xilinx AXI 10G Ethernet MAC/PCS core
- UDP/IP protocol stack module
- Packet FIFOs for TX/RX buffering
- Clock wizard for clock generation
- AXI-Lite state machine for MAC configuration  

## Architecture

### PCIe DMA Data Flow

The PCIe subsystem implements a complete data path from host memory through the PCIe interface to application logic:

1. **Physical Layer:** GTXE2 transceivers handling 8b/10b encoding at 5 GT/s per lane
2. **Protocol Layer:** PCIe 2.1 hard block for TLP processing
3. **DMA Engine:** RIFFA TX/RX engines with scatter-gather and reordering
4. **Application Interface:** Standardized channel protocol with request/acknowledge handshake  

### UDP/IP Network Stack

The UDP subsystem provides a complete network interface:

1. **Physical Layer:** SFP+ transceiver with 10GBASE-R encoding
2. **MAC/PCS Layer:** Xilinx 10G Ethernet core
3. **Network Layer:** IP packet processing with checksum validation
4. **Transport Layer:** UDP datagram handling
5. **Application Layer:** Packet FIFO interface with loopback test logic  

## Getting Started

### Prerequisites

- Xilinx Vivado Design Suite 2019.1 or later
- Kintex-7 XC7K325T FPGA board with:
  - PCIe edge connector (Gen2 x4 minimum)
  - SFP+ cage and compatible transceiver module
  - 100 MHz PCIe reference clock
  - SPI flash for configuration

### Building the PCIe DMA Subsystem

1. Navigate to the PCIe project directory:
   ```bash
   cd K325T_SFP_PCIE_2021/k7325_PCIe_DMA_V2/PCIe_DMA_V2_5031_spix4_ok/
   ```

2. Open the Vivado project:
   ```bash
   vivado PCIE_DMA_Demo.xpr
   ```

3. Generate bitstream and program the FPGA  

### Building the 10G UDP/IP Subsystem

1. Navigate to the UDP/IP project directory:
   ```bash
   cd K325T_SFP_PCIE_2021/udp_ip_10g_sfp_X1_SFP_A/udp_ip_10g_sfp/
   ```

2. Open the Vivado project:
   ```bash
   vivado udp_ip_10g_sfp.xpr
   ```

3. Generate bitstream and program the FPGA  

## Hardware Configuration

### PCIe Pin Assignments

The PCIe subsystem uses the following pin assignments:
- PCIe reference clock: 100 MHz differential input
- PCIe lanes: GTXE2_CHANNEL_X0Y7 through X0Y4 (lanes 0-3)
- System reset: Active-low
- Status indicators: Link-up LED, debug LED  

### Clock Architecture

The design uses multiple clock domains generated from the 100 MHz PCIe reference clock:
- 125 MHz (USERCLK1): General user logic, RIFFA engine
- 250 MHz (USERCLK2): High-speed processing paths
- 156.25 MHz: 10G Ethernet core clock  

## Performance Specifications

### PCIe DMA Performance

| Metric | Value |
|--------|-------|
| PCIe Generation | Gen2 |
| Lane Count | x4 |
| Peak Bandwidth | 20 Gbps (2.5 GB/s) |
| Typical Throughput | ~1.8 GB/s |
| Latency | <10 μs (MSI interrupts) |  

### 10G Ethernet Performance

| Metric | Value |
|--------|-------|
| Line Rate | 10 Gbps full-duplex |
| Core Clock | 156.25 MHz |
| Data Width | 64-bit (8 bytes per cycle) |
| Protocol Overhead | ~5% (Ethernet framing + UDP/IP headers) |

## Documentation

For detailed technical documentation, see:
- **PCIe Subsystem:** `k7325_PCIe_DMA_V2/readme.md` and `k7325_PCIe_DMA_V2/files.md`
- **UDP/IP Subsystem:** `udp_ip_10g_sfp_X1_SFP_A/files.md`  

## Top-Level Design Files

### PCIe DMA Subsystem
- **Top-level:** `Example_Top.vhd` - Integrates PCIe core and channel tester
- **Constraints:** `pcie_7k325.xdc` - Pin assignments and timing constraints
- **Channel Tester:** `chnl_tester.vhd` - Application-level test module  

### 10G UDP/IP Subsystem
- **Top-level:** `udp_transmit_test.v` - Integrates Ethernet MAC and protocol stack
- **Constraints:** `udp_ip_10g.xdc` - Pin assignments and timing constraints  

## License

Please refer to the individual source file headers for licensing information.

## Notes

- The PCIe subsystem uses the RIFFA framework, which provides a standardized interface for FPGA-host communication
- The 10G Ethernet subsystem includes loopback test functionality for validation
- Both subsystems can operate independently or be integrated into a combined design
- The project targets commercial temperature grade (-2 speed grade) operation 

