#!/bin/bash

# Useful files from your list
useful_files=(
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.xpr"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/imports/udp_ip_10g_sfp/udp_transmit_test.v"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/imports/example/axi_10g_ethernet_0_sync_reset.v"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/imports/example/axi_10g_ethernet_0_axi_lite_sm.v"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/imports/example/axi_10g_ethernet_0_sync_block.v"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/bd_efdb.bd"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/bd_efdb.bxml"
    #"./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_0/bd_efdb_xmac_0.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_0/synth/bd_efdb_xmac_0_clocks.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_0/synth/bd_efdb_xmac_0.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_0/synth/bd_efdb_xmac_0_ooc.xdc"
#    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_1/bd_efdb_xpcs_0.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_1/synth/bd_efdb_xpcs_0_clocks.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_1/synth/bd_efdb_xpcs_0_ooc.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axi_10g_ethernet_0/bd_0/ip/ip_1/synth/bd_efdb_xpcs_0.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci"
#    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axis_data_fifo_0/axis_data_fifo_0.xci"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/axis_data_fifo_0/axis_data_fifo_0.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/udp_packet_fifo/udp_packet_fifo.xci"
#    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/sources_1/ip/udp_packet_fifo/udp_packet_fifo.xml"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.srcs/constrs_1/new/udp_ip_10g.xdc"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/synth_325T/runme.log"
#    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/synth_325T/udp_transmit_test.dcp"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/synth_325T/udp_transmit_test_utilization_synth.rpt"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/impl_1/udp_transmit_test_route_status.rpt"
    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/impl_1/udp_transmit_test_timing_summary_routed.rpt"
#    "./udp_ip_10g_sfp/udp_ip_10g_sfp.runs/impl_1/udp_transmit_test.bit"
    "./udp_ip_10g_sfp/vivado.log"
)

# Loop through the files
for file in "${useful_files[@]}"; do
    # Get file size in KB
    file_size=$(du -k "$file" | awk '{print $1}')

    # Print filename, size, and content
    echo "$file (Size: $file_size KB)"
    cat "$file"
    echo "" # Add an empty line for separation
done

#**Explanation:**

# 1. **`#!/bin/bash`:**  This line tells the system to use Bash as the interpreter for the script.
# 2. **`useful_files=( ... )`:** This creates an array named `useful_files` and fills it with the list of files you want to process.
# 3. **`for file in "${useful_files[@]}"; do ... done`:** This loop iterates through each element in the `useful_files` array.
# 4. **`echo "$file"`:** This prints the current filename.
# 5. **`cat "$file"`:** This displays the content of the current file.
# 6. **`echo ""`:** This adds an empty line after each file's content to improve readability.

# **How to use:**

# 1. Save this script (e.g., as `show_files.sh`).
# 2. Make the script executable: `chmod +x show_files.sh`
# 3. Run the script: `./show_files.sh`

# This will output the filename and content of each file in the `useful_files` array. 
