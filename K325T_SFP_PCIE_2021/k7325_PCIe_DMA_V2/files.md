# File Summary:

This project implements a PCIe DMA demonstration using a Xilinx Kintex-7 FPGA (xc7k325tffg676-2). Here's a breakdown of the key files:

**Project & Hardware Definition:**

* **./PCIE_DMA_Demo.xpr (42kB):** The primary Vivado project file. It defines the target FPGA, sets `Example_Top.vhd` as the top-level design, configures simulation settings, and points to the active constraints file (`pcie_7k325.xdc`).
* **./PCIE_DMA_Demo.hw/hw_1/hw.xml (2kB):**  Specifies hardware configuration details, including the FPGA bitstream (`2021_K325T.mcs`), physical constraints (`2021_K325T.prm`), and the use of an MT25QL256 SPI flash memory chip.
* **./PCIE_DMA_Demo.hw/PCIE_DMA_Demo.lpr (343B):** A project file for Xilinx Lab Tools, likely used for on-hardware debugging and interaction with the FPGA.

**Constraints:**

* **./PCIE_DMA_Demo.src/pcie_7k325.xdc (7kB):** The *active* constraints file for this project. It defines pin assignments for the PCIe core, clocking details (including a 100MHz PCIe reference clock), and configures the SPI interface for bitstream loading (4-bit mode at 50 MHz).
* **./PCIE_DMA_Demo.src/system.xdc (7kB):** While *disabled* in the project, this file likely contains useful documentation and a potential starting point for constraint modifications.
* **./.Xil/Example_Top_propImpl.xdc (1kB):** Post-implementation constraints applied to the design, these set the location of the PCIe core, GTXE2 transceiver channels, and operating voltage conditions.

**Design Source Code:**

* **./Example_Top.vhd:** This is the top-level design file, responsible for instantiating and connecting the PCIe core and the `chnl_tester` module. It configures the system for a single PCIe channel (x4 width) and 64-bit data transfers.
* **./PCIE_DMA_Demo.src/chnl_tester.vhd (4kB):** This module interacts with the DMA engine of the PCIe core through the `CHNL_RX` and `CHNL_TX` interfaces. It implements a data transfer loop, sending data from the FPGA to the host and then back again, showcasing the DMA functionality.

**Summary of Example_Top.vhd:**

1. **Instantiates `gvi_pcie_gen2x4_wrapper`:** This component represents the PCIe Gen2 x4 core. The top level connects it to the external PCIe pins, provides the reference clock, and handles the reset signal.
2. **Instantiates `chnl_tester`:**  This module is connected to the PCIe core's channel interface signals (`CHNL_RX_*` and `CHNL_TX_*`), enabling data transfers.
3. **Connects signals:** The top level meticulously connects the signals between the PCIe core and the channel tester, ensuring data flow and control.
4. **Simple Debug:** A basic debug counter (`count`) is implemented and connected to the `Dbg_LED` output, likely for simple visual feedback during operation.

**Overall, this project provides a functional example of how to implement PCIe DMA transfers on a Xilinx Kintex-7 FPGA.** The `chnl_tester` module serves as a demonstration of the DMA capabilities, while the rest of the project sets up the necessary hardware and software environment for PCIe communication. 




**Revised Understanding:**

* The `system.xdc` file is not actually used in the project. The constraints are defined in `pcie_7k325.xdc`.
* The `.xpr` file confirms that `Example_Top.vhd` is the top-level design module.
* There are many Verilog and VHDL files that were not initially included in the "important files" list but are crucial for understanding the DMA engine and PCIe core.

**Next Steps:**

1. **Find `Example_Top.vhd`:** This is the highest priority. Without it, it's difficult to see how the DMA engine, channel tester, and PCIe core are integrated.
2. **Analyze DMA Engine (Verilog files in `riffa`):**  Understand the individual modules and how they work together to achieve DMA functionality.
3. **Examine PCIe Endpoint Core (VHDL files in `ep_core`):**  Study the core's implementation and its interface to the rest of the system. 

By focusing on these additional files and finding the missing `Example_Top.vhd`, you'll gain a much better understanding of the project's structure and how its different parts interact. 



## Summary of the PCIe Endpoint Source code

The source code in `ep_core` implements a PCI endpoint core using Xilinx 7-series FPGAs and the PCIe 2.1 hard block. Here is a summary of the functionalities implemented in the source code:

**Core Modules:**

* **pcie_k7_gen2x4_pipe_clock.v:**
    - This Verilog module implements the clocking logic for the PCIe endpoint core.
    - It generates various clocks, including PCLK (PCIe core clock), USERCLK1, USERCLK2, RXUSRCLK, and DCLK using an MMCM.
    - Selects between different clock frequencies based on the negotiated link speed and user configuration.

* **pcie_k7_gen2x4_gtp_pipe_drp.v and pcie_k7_gen2x4_pipe_drp.v:**
    - These modules manage the Dynamic Reconfiguration Port (DRP) for configuring the transceiver (GTP or GTX).
    - They handle reading from and writing to the transceiver configuration registers.
    - Implements a Finite State Machine (FSM) to control the DRP access sequence.

* **pcie_k7_gen2x4_pipe_sync.v:**
    - This Verilog module implements the synchronization logic for the transceiver lanes.
    - Controls TX and RX phase alignment, delay bypass, and delay resets for achieving data synchronization.

* **pcie_k7_gen2x4_axi_basic_tx_thrtl_ctl.vhd:**
    - This VHDL module implements the transmit throttle controller for the AXI interface.
    - It monitors the transmit buffer availability and link status to preemptively throttle the user design to prevent data loss.
    - Grants permission to the PCIe block to send configuration responses and handles low power transitions.

* **pcie_k7_gen2x4_axi_basic_tx_pipeline.vhd:**
    - This VHDL module implements the AXI transmit data pipeline.
    - It converts data from AXI protocol to the TRN protocol used by the PCIe block.
    - Generates TRN SOF/EOF signals, manages TREADY/TDST_RDY handshaking, and handles link status changes.

* **pcie_k7_gen2x4_pcie_bram_top_7x.vhd, pcie_k7_gen2x4_pcie_brams_7x.vhd, and pcie_k7_gen2x4_pcie_bram_7x.vhd:**
    - These VHDL modules implement a hierarchy of BRAM wrappers for managing data storage in the TX and RX paths.
    - `pcie_bram_top_7x` calculates the required number of BRAMs and instantiates the lower-level `pcie_brams_7x`.
    - `pcie_brams_7x` instantiates multiple `pcie_bram_7x` modules based on data width and other configuration parameters.
    - `pcie_bram_7x` provides a wrapper for accessing a single BRAM instance with write and read ports.

* **pcie_k7_gen2x4_gtp_pipe_reset.v and pcie_k7_gen2x4_pipe_reset.v:**
    - These Verilog modules control the reset sequences for the transceiver and PCIe core.
    - Implement FSMs to ensure proper reset timings and sequencing.

* **pcie_k7_gen2x4_pcie_7x.vhd:**
    - This VHDL module instantiates the Xilinx PCIe 2.1 hard block with various configuration parameters.
    - Connects the BRAM, AXI interface, and PIPE interface signals to the PCIe hard block.

* **pcie_k7_gen2x4_axi_basic_top.vhd:**
    - This VHDL module serves as the top-level wrapper for the AXI interface to the PCIe block.
    - Instantiates the AXI RX and TX modules (`axi_basic_rx` and `axi_basic_tx`).

* **pcie_k7_gen2x4_pcie_pipe_lane.vhd:**
    - This VHDL module implements per-lane pipeline logic for the PIPE interface.
    - Pipelines RX and TX data, status, and control signals for each lane.

* **pcie_k7_gen2x4_gtp_cpllpd_ovrd.v and pcie_k7_gen2x4_gtx_cpllpd_ovrd.v:**
    - These Verilog modules implement overrides for the CPLL power-down and reset signals.
    - Used to ensure proper initialization and reset timings.

* **pcie_k7_gen2x4_gt_top.vhd:**
    - This VHDL module serves as the top-level wrapper for the GTX/GTP transceiver.
    - Instantiates the transceiver, PIPE wrapper, and RX valid filter.
    - Handles transceiver initialization, configuration, and data transfers.

* **pcie_k7_gen2x4_pipe_user.v:**
    - This Verilog module implements per-lane user logic for the PIPE interface.
    - Controls transceiver reset overrides, generates OOB clock, and filters status signals.

* **pcie_k7_gen2x4_gt_wrapper.v:**
    - This Verilog module wraps the GTXE2_CHANNEL/GTHE2_CHANNEL/GTPE2_CHANNEL and GTXE2_COMMON/GTHE2_COMMON/GTPE2_COMMON modules for each lane and quad.
    - Configures the transceiver for PCIe operation and handles data transfers.

* **pcie_k7_gen2x4_pipe_rate.v and pcie_k7_gen2x4_gtp_pipe_rate.v:**
    - These Verilog modules implement the logic for managing the data rate changes for the transceiver.
    - Control PLL selection, rate selection, and DRP configurations.

* **pcie_k7_gen2x4_qpll_wrapper.v:**
    - This Verilog module wraps the QPLL for PCIe operation.
    - Handles clock generation and DRP configuration for the QPLL.

* **pcie_k7_gen2x4_axi_basic_rx_null_gen.vhd:**
    - This VHDL module generates null packets for use in discontinue situations on the AXI RX interface.

* **pcie_k7_gen2x4_pcie_pipe_misc.vhd:**
    - This VHDL module implements miscellaneous PIPE pipeline logic for signals like TX receiver detection, reset, rate, de-emphasis, margin, and swing.

* **pcie_k7_gen2x4_qpll_drp.v:**
    - This Verilog module implements the DRP logic for configuring the QPLL.

* **pcie_k7_gen2x4_pcie_pipe_pipeline.vhd:**
    - This VHDL module instantiates the `pcie_pipe_lane` and `pcie_pipe_misc` modules for each lane.

* **pcie_k7_gen2x4_pipe_eq.v:**
    - This Verilog module implements the equalization logic for the transceiver.
    - Configures TX and RX equalization settings based on link speed and user configurations.

* **pcie_k7_gen2x4_pcie2_top.vhd:**
    - This VHDL module serves as an intermediate wrapper for instantiating the `core_top` module.

* **pcie_k7_gen2x4_gt_rx_valid_filter_7x.vhd:**
    - This VHDL module implements a filter for the RX valid signal from the transceiver.
    - Ensures proper RX data validation by considering electrical idle and other status signals.

* **pcie_k7_gen2x4_core_top.vhd:**
    - This VHDL module serves as the top-level wrapper for the entire PCIe core.
    - Instantiates the AXI bridge, PCIe 2.1 hard block, PIPE pipeline, and GTX/GTP transceiver.
    - Handles system-level initialization and configuration.

* **pcie_k7_gen2x4_gt_common.v:**
    - This Verilog module implements the shared logic for the QPLL, including DRP configuration and clock generation.

* **pcie_k7_gen2x4_rxeq_scan.v:**
    - This Verilog module implements the RX equalization eye scan logic.
    - Adjusts RX equalization settings based on the eye scan results.

* **pcie_k7_gen2x4_qpll_reset.v:**
    - This Verilog module manages the reset sequence for the QPLL.

* **pcie_k7_gen2x4.vhd:**
    - This VHDL module instantiates the `pcie2_top` module with specific configuration parameters.
    - Serves as the top-level module for the PCIe endpoint core.

**Overall Functionality:**

The source code implements a complete PCIe endpoint core with an AXI interface, BRAM-based data storage, transceiver configuration, and synchronization logic. The core supports multiple link speeds (Gen1, Gen2, and Gen3), lane widths, and clock frequencies based on user configuration and negotiated link parameters. The code includes debug features and simulation speedup options for efficient development and verification.


## Summary of the RIFFA PCIe source code:

The provided Verilog code implements a RIFFA endpoint for PCIe communication, facilitating data transfer between a host PC and an FPGA.  Here's a breakdown of the functionality:

**Top-level Integration:**

* `riffa_top_pcie_7x_v2_1.v` is the top-level module. 
    * It instantiates the Xilinx 7 Series PCIe core (`pcie_k7_gen2x4`), the RIFFA application logic (`pcie_app_7x`), and an optional external clock module (`pcie_k7_gen2x4_pipe_clock`).
    * This module connects the PCIe core, external clock, and application logic, providing the necessary signals for data transfer, configuration, and flow control.
    * It handles the system clock and reset signals, generating a wider reset signal for the rest of the design.
    * The user clock heartbeat is implemented for monitoring system operation.

**Data Transfer:**

* **Transmit Path:**
    * `tx_port_64.v` and `tx_port_32.v` are transmit ports for 64-bit and 32-bit data widths, respectively. 
        * They receive data from the TX engine and buffer it for transfer to the RIFFA channel.
        * They implement scatter-gather functionality, reading from a scatter-gather list buffer (`sg_list_reader_64.v` and `sg_list_reader_32.v`) and sending data in multiple requests if needed.
        * `tx_port_channel_gate_64.v` and `tx_port_channel_gate_32.v` manage the channel interface, capturing transaction events and sending them to the TX engine through FIFOs.
        * `tx_port_monitor_64.v` and `tx_port_monitor_32.v` monitor the channel events, filtering them and passing data to the `tx_port_buffer_64.v` and `tx_port_buffer_32.v` modules.
        * `tx_port_writer.v` controls the flow of requests to the TX engine, breaking down transactions into individual transfers based on maximum payload size, page boundaries, and data availability.
    * `tx_engine_128.v`, `tx_engine_64.v`, and `tx_engine_32.v` are TX engines for different data widths.
        * They handle the formatting of PCIe packets and send them to the PCIe core.
        * `tx_engine_upper_128.v`, `tx_engine_upper_64.v`, and `tx_engine_upper_32.v` format read/write requests into packets and buffer them in a FIFO.
        * `tx_engine_lower_128.v`, `tx_engine_lower_64.v`, and `tx_engine_lower_32.v` handle completion requests and read pre-formatted data from the FIFO, multiplexing them onto the PCIe core interface.
        * `tx_engine_selector.v` selects which channel's data to transmit next.
        * `tx_qword_aligner_128.v` and `tx_qword_aligner_64.v` align the data to conform to Altera's quad-word alignment requirements.
* **Receive Path:**
    * `rx_port_128.v`, `rx_port_64.v`, and `rx_port_32.v` are receive ports for different data widths. 
        * They receive data from the RX engine and buffer it for transfer to the RIFFA channel.
        * They use FIFOs (`sync_fifo.v` and `async_fifo_fwft.v`) to manage incoming data and provide a first-word fall-through interface.
        * They implement scatter-gather functionality with the same `sg_list_requester.v` module used in the transmit path.
        * `fifo_packer_128.v`, `fifo_packer_64.v`, and `fifo_packer_32.v` pack incoming data into the FIFOs based on their data enable signals.
        * `rx_port_requester_mux.v` prioritizes read requests from different modules (main channel and scatter-gather requesters).
        * `rx_port_reader.v` manages the receive lifecycle, issuing read requests and handling transaction completion.
        * `rx_port_channel_gate.v` synchronizes channel signals across clock domains.
    * `rx_engine_128.v`, `rx_engine_64.v`, and `rx_engine_32.v` are RX engines for different data widths. 
        * They handle the reception and parsing of incoming PCIe packets.
        * They route memory read/write requests and completion data to the appropriate modules.
        * `reorder_queue.v` reorders completion packets based on their tags to ensure in-order delivery.

**Configuration and Interrupts:**

* `riffa_endpoint_128.v`, `riffa_endpoint_64.v`, and `riffa_endpoint_32.v` manage the overall RIFFA endpoint functionality for different data widths.
    * They instantiate and connect the RX engine, TX engine, and interrupt controller.
    * They handle the processing of configuration requests from the host PC through a memory-mapped interface.
* `interrupt.v` manages the interrupt vector and controller. 
    * `interrupt_controller.v` handles the generation of both legacy and MSI interrupts.

**Additional Modules:**

* `common_functions.v` contains common functions used for parameter calculations, such as `clog2` and `clog2s`.
* `ram_1clk_1w_1r.v` and `ram_2clk_1w_1r.v` are simple RAM modules for single-clock and dual-clock operation.
* `ff.v` is a simple D flip-flop.
* `syncff.v` uses back-to-back flip-flops to mitigate metastable issues when crossing clock domains.
* `cross_domain_signal.v` provides cross-domain synchronization for signals.

**Overall:**

The code implements a comprehensive RIFFA endpoint for PCIe, with support for multiple channels, scatter-gather DMA, interrupts, and configuration. It provides a flexible and efficient solution for data transfer between a host PC and an FPGA.
