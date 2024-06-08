`timescale 1ns / 1ps

module udp_transmit_test
(
		input          		key1,
		input               clk,
		input               gtrefclk0_p,
		input               gtrefclk0_n,	
		
		input         	 	sfp_rx_p,
		input          		sfp_rx_n,		
		output wire        	sfp_tx_p,
		output wire         sfp_tx_n,		
		output wire         sfp_tx_disable,		

		output wire [3:0]   led
    );



wire       	app_rx_data_valid;
wire [63:0]	app_rx_data;
wire [7:0]	app_rx_data_keep;
wire 		app_rx_data_last;
wire [15:0] app_rx_data_length;
wire [15:0] app_rx_port_num;


wire        udp_tx_ready;
wire        app_tx_ack;

reg         app_tx_data_request;
reg         app_tx_data_valid;
wire [63:0]  app_tx_data;
reg  [7:0]  app_tx_data_keep;
reg         app_tx_data_last;
reg  [15:0] udp_data_length;
reg         app_tx_data_read;
wire [8:0] udp_packet_fifo_data_cnt;
reg [11:0]  fifo_read_data_cnt;
reg [1:0]   STATE;


wire        	mmcm_locked;
reg [31:0]  	delay_cnt;
wire        	ip_rx_error;
wire        	dst_ip_unreachable;

wire        	mac_tx_valid;
wire [63:0]  	mac_tx_data;
wire [7:0]  	mac_tx_keep;
wire            mac_tx_ready;
wire 		  	mac_tx_last;
wire			mac_tx_user;
		
wire     		mac_rx_valid;
wire [63:0]    	mac_rx_data;
wire [7:0]   	mac_rx_keep;
wire      		mac_rx_last;
wire      		mac_rx_user;

// AXI Lite config I/F
wire                 s_axi_aclk;
wire                 s_axi_aresetn;
wire       [10:0]    s_axi_awaddr;
wire                 s_axi_awvalid;
wire                 s_axi_awready;
wire       [31:0]    s_axi_wdata;
wire                 s_axi_wvalid;
wire                 s_axi_wready;
wire      [1:0]      s_axi_bresp;
wire                 s_axi_bvalid;
wire                 s_axi_bready;
wire       [10:0]    s_axi_araddr;
wire                 s_axi_arvalid;
wire                 s_axi_arready;

wire      [31:0]     s_axi_rdata;
wire      [1:0]      s_axi_rresp;
wire                 s_axi_rvalid;
wire                 s_axi_rready;

wire                 coreclk;
wire                 block_lock;

wire [7:0] 		     pcspma_status;
wire				 signal_detect;
wire				 areset_n;
wire				 s_axi_reset;
wire				 core_reset;
wire				 core_ready;

wire       			udp_rx_error;
reg        			udp_error_flag;

reg	[7:0]	 		cnt;
wire 				reset;	

localparam  WAIT_UDP_DATA = 2'd0;
localparam  WAIT_ACK = 2'd1;
localparam  SEND_UDP_DATA = 2'd2;
localparam  DELAY = 2'd3;


assign    led[0] =  pcspma_status[0];
assign    led[1] =  block_lock;
assign    led[2] =  udp_error_flag;
assign    led[3] =  mmcm_locked;

//assign 	  signal_detect = ~(sfp_los | sfp_mod_detect);

assign    reset  = ~key1;
assign    areset_n  = ~reset & mmcm_locked & pcspma_status[0];


/* always@(posedge coreclk)
	begin
		if(!key1) begin
			cnt <= 8'd0;
			reset <= 1'b0;
		end
		else if(pcspma_status[0])begin
			if(cnt == 8'hff) begin
				cnt <= cnt;
				reset <= 1'b0;
			end		
			else begin
				cnt <= cnt + 1'b1;
				reset <= 1'b1;
			end
		end
	end	 */	
	

wire	clk_100;	

//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out1___100.000______0.000______50.0______130.958_____98.575
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________100.000____________0.010	
clk_wiz_0 clk_wiz_0
   (
    // Clock out ports
    .clk_out1(clk_100),     // output clk_out1
    // Status and control signals
    .reset(reset), // input reset
    .locked(mmcm_locked),       // output locked
   // Clock in ports
    .clk_in1(clk));    // input clk_in1	
	
	
always @(posedge coreclk)
   begin
      if(core_reset) 
		  udp_error_flag <= 1'b0;
	  else if(udp_rx_error)
		  udp_error_flag <= 1'b1;
	  else
		  udp_error_flag <= udp_error_flag;
	end
		
udp_packet_fifo udp_packet_fifo 
(
	  .rst(core_reset), // input rst
	  .wr_clk(coreclk), // input wr_clk
	  .rd_clk(coreclk), // input rd_clk
	  .din(app_rx_data), // input [63 : 0] din
	  .wr_en(app_rx_data_valid), // input wr_en
	  .rd_en(app_tx_data_read), // input rd_en
	  .dout(app_tx_data), // output [63 : 0] dout
	  .full(), // output full
	  .empty(), // output empty
	  .rd_data_count(udp_packet_fifo_data_cnt) // output [8 : 0] rd_data_count
);


always@(posedge coreclk or posedge core_reset)
	begin
		if(core_reset) 
			udp_data_length <= 16'd0;
		else begin 
			if(app_rx_data_valid)
		      udp_data_length <= app_rx_data_length;
			else
				udp_data_length <= udp_data_length;
		end
	end

always@(posedge coreclk or posedge core_reset)
	begin
		if(core_reset) begin
		   app_tx_data_request <= 1'b0;
		   app_tx_data_read <= 1'b0;
		   	app_tx_data_last <= 1'b0;
			app_tx_data_keep <= 8'hff;
			app_tx_data_valid <= 1'b0;
			fifo_read_data_cnt <= 12'd0;
			STATE <= WAIT_UDP_DATA;
		end
		else begin
		   case(STATE)
				WAIT_UDP_DATA:
					begin
						if((udp_packet_fifo_data_cnt > 9'd0) && (~app_rx_data_valid) && udp_tx_ready) begin
						   app_tx_data_request <= 1'b1;
							STATE <= WAIT_ACK;
						end
						else begin
						   app_tx_data_request <= 1'b0;
							STATE <= WAIT_UDP_DATA;
						end
					end
				WAIT_ACK:
					begin
					   if(app_tx_ack) begin
						   app_tx_data_request <= 1'b0;
							app_tx_data_read <= 1'b1;
							app_tx_data_valid <= 1'b1;
							if(udp_data_length <= 8) begin
								app_tx_data_last <= 1'b1;
								app_tx_data_keep <= (8'hff >> (8 - udp_data_length));
								STATE <= DELAY;
							end
							else begin
								fifo_read_data_cnt <= fifo_read_data_cnt + 8;
								STATE <= SEND_UDP_DATA;
							end
						end
						else if(dst_ip_unreachable) begin
							app_tx_data_request <= 1'b0;
							app_tx_data_valid <= 1'b0;
							STATE <= WAIT_UDP_DATA;
						end
						else begin
							app_tx_data_request <= 1'b1;
						  	app_tx_data_read <= 1'b0;
							app_tx_data_valid <= 1'b0;
							STATE <= WAIT_ACK;
						end
					end
				SEND_UDP_DATA:
					begin
						app_tx_data_valid <= 1'b1;
						fifo_read_data_cnt <= fifo_read_data_cnt + 8;
						app_tx_data_read <= 1'b1;
						if((fifo_read_data_cnt + 8) >= udp_data_length) begin		
							app_tx_data_last <= 1'b1;
							app_tx_data_keep <= (8'hff >> (fifo_read_data_cnt + 8 - udp_data_length ));
							STATE <= DELAY;
						end
						else begin																			
							STATE <= SEND_UDP_DATA;
						end						
					end
				DELAY:
					begin
						app_tx_data_read <= 1'b0;
						app_tx_data_valid <= 1'b0;
						app_tx_data_last <= 1'b0;
						app_tx_data_keep <= 8'hff;
						fifo_read_data_cnt <= 12'd0;
						if(app_rx_data_valid)
							STATE <= WAIT_UDP_DATA;
						else
							STATE <= DELAY;
					end
				default: STATE <= WAIT_UDP_DATA;
			endcase
		end
	end
	 
udp_ip_protocol_stack udp_ip_protocol_stack
(
	.LOCAL_PORT_NUM     (16'hf000),
	.LOCAL_IP_ADDRESS   (32'hc0a80a01),
	.LOCAL_MAC_ADDRESS  (48'h000a35000102),
	.ICMP_EN			 (1'b1),
	.ARP_REPLY_EN       (1'b1),
	.ARP_REQUEST_EN 	 (1'b1),
	.ARP_TIMEOUT_VALUE	 (30'd20_000_000),
	.ARP_RETRY_NUM		 (4'd2),

	.core_clk				(coreclk),	
    .reset					(core_reset), 
    .udp_tx_ready			(udp_tx_ready), 
    .app_tx_ack			(app_tx_ack), 
    .app_tx_request		(app_tx_data_request), //app_tx_data_request
    .app_tx_data_valid	(app_tx_data_valid),	
    .app_tx_data		(app_tx_data),
	.app_tx_data_keep   (app_tx_data_keep),
	.app_tx_data_last   (app_tx_data_last),	
    .app_tx_data_length	(udp_data_length), 
    .app_tx_dst_port		(16'hf001), 
    .ip_tx_dst_address	(32'hc0a80a02), 
    .app_rx_data_valid	(app_rx_data_valid), 
    .app_rx_data			(app_rx_data),
	.app_rx_data_keep		(app_rx_data_keep),
	.app_rx_data_last		(app_rx_data_last),
    .app_rx_data_length		(app_rx_data_length), 
    .app_rx_port_num		(app_rx_port_num),
	.udp_rx_error           (udp_rx_error),	
	.mac_tx_data_valid		(mac_tx_valid),
	.mac_tx_data			(mac_tx_data),
	.mac_tx_keep			(mac_tx_keep),
	.mac_tx_ready			(mac_tx_ready),
	.mac_tx_last			(mac_tx_last),
	.mac_tx_user			(mac_tx_user),		
	.mac_rx_data_valid		(mac_rx_valid),
	.mac_rx_data			(mac_rx_data),
	.mac_rx_keep			(mac_rx_keep),
	.mac_rx_last			(mac_rx_last),
	.mac_rx_user			(1'b0),
    .ip_rx_error			(ip_rx_error),	
	.dst_ip_unreachable     (dst_ip_unreachable)
    );

	
wire    	  	s_axis_tx_tvalid;
wire   		  	s_axis_tx_tready;	
wire [63:0]   	s_axis_tx_tdata;	
wire [7:0]   	s_axis_tx_tkeep;	
wire    		s_axis_tx_tlast;	

wire    	  	m_axis_rx_tvalid;
wire   		  	m_axis_rx_tready;	
wire [63:0]   	m_axis_rx_tdata;	
wire [7:0]   	m_axis_rx_tkeep;	
wire    		m_axis_rx_tlast;	
	
	
axis_data_fifo_0 tx_packet_fifo0 
(
  .s_axis_aresetn(~core_reset),          // input wire s_axis_aresetn
  .s_axis_aclk(coreclk),                // input wire s_axis_aclk
  .s_axis_tvalid(mac_tx_valid),            // input wire s_axis_tvalid
  .s_axis_tready(mac_tx_ready),            // output wire s_axis_tready
  .s_axis_tdata(mac_tx_data),              // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(mac_tx_keep),              // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(mac_tx_last),              // input wire s_axis_tlast
  .s_axis_tuser(mac_tx_user),              // input wire [0 : 0] s_axis_tuser
  .m_axis_tvalid(s_axis_tx_tvalid),            // output wire m_axis_tvalid
  .m_axis_tready(s_axis_tx_tready),            // input wire m_axis_tready
  .m_axis_tdata(s_axis_tx_tdata),              // output wire [63 : 0] m_axis_tdata
  .m_axis_tkeep(s_axis_tx_tkeep),              // output wire [7 : 0] m_axis_tkeep
  .m_axis_tlast(s_axis_tx_tlast),              // output wire m_axis_tlast
  .m_axis_tuser(),                          // output wire [0 : 0] m_axis_tuser
  .axis_data_count(),        // output wire [31 : 0] axis_data_count
  .axis_wr_data_count(),  // output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count()  // output wire [31 : 0] axis_rd_data_count
);	


axis_data_fifo_0 rx_packet_fifo0 
(
  .s_axis_aresetn(~core_reset),            // input wire s_axis_aresetn
  .s_axis_aclk(coreclk),                   // input wire s_axis_aclk
  .s_axis_tvalid(m_axis_rx_tvalid),            // input wire s_axis_tvalid
  .s_axis_tready(),            // output wire s_axis_tready
  .s_axis_tdata(m_axis_rx_tdata),              // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(m_axis_rx_tkeep),              // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(m_axis_rx_tlast),              // input wire s_axis_tlast
  .s_axis_tuser(1'b0),              	   // input wire [0 : 0] s_axis_tuser
  .m_axis_tvalid(mac_rx_valid),            // output wire m_axis_tvalid
  .m_axis_tready(1'b1),            		   // input wire m_axis_tready
  .m_axis_tdata(mac_rx_data),              // output wire [63 : 0] m_axis_tdata
  .m_axis_tkeep(mac_rx_keep),              // output wire [7 : 0] m_axis_tkeep
  .m_axis_tlast(mac_rx_last),              // output wire m_axis_tlast
  .m_axis_tuser(mac_rx_user),              // output wire [0 : 0] m_axis_tuser
  .axis_data_count(),        			// output wire [31 : 0] axis_data_count
  .axis_wr_data_count(),  				// output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count()  				// output wire [31 : 0] axis_rd_data_count
);
	
    //--------------------------------------------------------------------------
    // Add reset synchronizers to the asynchronous reset inputs
    //--------------------------------------------------------------------------
    axi_10g_ethernet_0_sync_reset s_axis_reset_gen (
      .clk                             (clk_100),
      .reset_in                        (~areset_n),
      .reset_out                       (s_axi_reset)
      );
 

    axi_10g_ethernet_0_sync_reset core_reset_gen (
      .clk                             (coreclk),
      .reset_in                        (~areset_n),
      .reset_out                       (core_reset)
      ); 
	  
	axi_10g_ethernet_0_sync_block block_lock_sync (
      .data_in                         (block_lock),
      .clk                             (coreclk),
      .data_out                        (core_ready)
   );

   //----------------------------------------------------------------------------
   // Instantiate the Ethernet core
   //----------------------------------------------------------------------------
 axi_10g_ethernet_0 ethernet_core_0 (
      .coreclk_out                     (coreclk),
      .areset_datapathclk_out          (),
      .refclk_p                        (gtrefclk0_p),
      .refclk_n                        (gtrefclk0_n),
      .dclk                            (clk_100),
      .reset                           (reset),
      .resetdone_out                   (),
      .reset_counter_done_out          (),
      .qplllock_out                    (),
      .qplloutclk_out                  (),
      .qplloutrefclk_out               (),
      .txusrclk_out                    (),
      .txusrclk2_out                   (),
      .gttxreset_out                   (),
      .gtrxreset_out                   (),
      .txuserrdy_out                   (),
      .rxrecclk_out                    (),
      .tx_ifg_delay                    (8'd0),
      .tx_statistics_vector            (),
      .tx_statistics_valid             (),
      .rx_statistics_vector            (),
      .rx_statistics_valid             (),
      .s_axis_pause_tdata              (16'd0),
      .s_axis_pause_tvalid             (1'b0),

      .tx_axis_aresetn                 (areset_n),
      .s_axis_tx_tdata                 (s_axis_tx_tdata),
      .s_axis_tx_tvalid                (s_axis_tx_tvalid),
      .s_axis_tx_tlast                 (s_axis_tx_tlast),
      .s_axis_tx_tuser                 (1'b0),
      .s_axis_tx_tkeep                 (s_axis_tx_tkeep),
      .s_axis_tx_tready                (s_axis_tx_tready),

      .rx_axis_aresetn                 (areset_n),
      .m_axis_rx_tdata                 (m_axis_rx_tdata),
      .m_axis_rx_tkeep                 (m_axis_rx_tkeep),
      .m_axis_rx_tvalid                (m_axis_rx_tvalid),
      .m_axis_rx_tuser                 (m_axis_rx_tuser),
      .m_axis_rx_tlast                 (m_axis_rx_tlast),
	  
      .s_axi_aclk                      (clk_100),
      .s_axi_aresetn                   (areset_n),
      .s_axi_awaddr                    (s_axi_awaddr),
      .s_axi_awvalid                   (s_axi_awvalid),
      .s_axi_awready                   (s_axi_awready),
      .s_axi_wdata                     (s_axi_wdata),
      .s_axi_wvalid                    (s_axi_wvalid),
      .s_axi_wready                    (s_axi_wready),
      .s_axi_bresp                     (s_axi_bresp),
      .s_axi_bvalid                    (s_axi_bvalid),
      .s_axi_bready                    (s_axi_bready),
      .s_axi_araddr                    (s_axi_araddr),
      .s_axi_arvalid                   (s_axi_arvalid),
      .s_axi_arready                   (s_axi_arready),
      .s_axi_rdata                     (s_axi_rdata),
      .s_axi_rresp                     (s_axi_rresp),
      .s_axi_rvalid                    (s_axi_rvalid),
      .s_axi_rready                    (s_axi_rready),

      .xgmacint                        (),
      // Serial links
      .txp                             (sfp_tx_p),
      .txn                             (sfp_tx_n),
      .rxp                             (sfp_rx_p),
      .rxn                             (sfp_rx_n),
	  //.sim_speedup_control             (sim_speedup_control),
      .sim_speedup_control             (1'b0),
      .signal_detect                   (1'b1),
      .tx_fault                        (1'b0),
      .tx_disable                      (sfp_tx_disable),
      .pcspma_status                   (pcspma_status)
   );

    //--------------------------------------------------------------------------
    // Instantiate the AXI-LITE Controller
    //--------------------------------------------------------------------------

    axi_10g_ethernet_0_axi_lite_sm axi_lite_controller0 (
      .s_axi_aclk                      (clk_100),
      .s_axi_reset                     (s_axi_reset),

      .pcs_loopback                    (1'b0),
      .enable_vlan                     (1'b0),
      .enable_custom_preamble          (1'b0),

      .block_lock                      (block_lock),
      .enable_gen                      (),

      .s_axi_awaddr                    (s_axi_awaddr),
      .s_axi_awvalid                   (s_axi_awvalid),
      .s_axi_awready                   (s_axi_awready),

      .s_axi_wdata                     (s_axi_wdata),
      .s_axi_wvalid                    (s_axi_wvalid),
      .s_axi_wready                    (s_axi_wready),

      .s_axi_bresp                     (s_axi_bresp),
      .s_axi_bvalid                    (s_axi_bvalid),
      .s_axi_bready                    (s_axi_bready),

      .s_axi_araddr                    (s_axi_araddr),
      .s_axi_arvalid                   (s_axi_arvalid),
      .s_axi_arready                   (s_axi_arready),

      .s_axi_rdata                     (s_axi_rdata),
      .s_axi_rresp                     (s_axi_rresp),
      .s_axi_rvalid                    (s_axi_rvalid),
      .s_axi_rready                    (s_axi_rready)
   );


endmodule
