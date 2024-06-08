This FPGA project designs a PCI card with two 10 Gbit/s SFP network ports, focusing on UDP data transmission. 

**Key Components:**

1. **AXI 10G Ethernet Core:** Implements the 10G Ethernet MAC and PCS/PMA, handling physical layer communication with the SFP ports. 
2. **UDP/IP Protocol Stack:**  A custom or third-party IP core (provided as a compiled `.dcp` file) that manages the UDP and IP protocols, processing incoming packets and preparing outgoing packets.
3. **Packet FIFOs:** 
    * **UDP Packet FIFO:**  Buffers incoming UDP data packets received from the network.
    * **TX Packet FIFOs:**  Buffers outgoing data packets before transmission through the 10G Ethernet core. 
4. **Clocking:**
    * **clk_wiz_0:** Generates the necessary clock signals for the various components, including the core clock for the Ethernet core and a 100 MHz clock for other components.

**Project Functionality:**

* **Data Reception:** Data is received from the network through the SFP ports and processed by the 10G Ethernet core. The UDP/IP Protocol Stack identifies UDP packets and passes them to the UDP Packet FIFO.
* **Data Transmission:** The design reads data from the UDP Packet FIFO, prepares it for transmission with the UDP/IP Protocol Stack, and sends the formatted packets to the TX Packet FIFO. From there, the data is transmitted through the 10G Ethernet core and out the SFP ports.
* **Control and Status:** The AXI 10G Ethernet core has an AXI4-Lite interface for configuration and status monitoring. This interface is managed by the  `axi_10g_ethernet_0_axi_lite_sm` module.  This module handles tasks like configuring the MDIO interface and checking the link status of the SFP ports.

**Test Module:**

The project includes a top-level module, `udp_transmit_test`, which instantiates and connects all the components. It utilizes a state machine to manage the process of reading incoming UDP packets, sending them back out, and handling acknowledgments. LEDs provide visual indication of link status, block lock, and any UDP errors detected.

**Note:**

The project files indicate that some of the IP cores were originally customized for a different FPGA part. These cores are locked and cannot be modified in the current project. 
