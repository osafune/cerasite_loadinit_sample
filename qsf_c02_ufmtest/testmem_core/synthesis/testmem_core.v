// testmem_core.v

// Generated using ACDS version 16.0 222

`timescale 1 ps / 1 ps
module testmem_core (
		input  wire  clk_clk,       //   clk.clk
		output wire  coe_initdone,  //   coe.initdone
		input  wire  reset_reset_n, // reset.reset_n
		input  wire  uart_rxd,      //  uart.rxd
		output wire  uart_txd       //      .txd
	);

	wire  [31:0] uart_to_avalon_bridge_0_m1_readdata;                   // mm_interconnect_0:uart_to_avalon_bridge_0_m1_readdata -> uart_to_avalon_bridge_0:avm_m1_readdata
	wire         uart_to_avalon_bridge_0_m1_waitrequest;                // mm_interconnect_0:uart_to_avalon_bridge_0_m1_waitrequest -> uart_to_avalon_bridge_0:avm_m1_waitrequest
	wire  [31:0] uart_to_avalon_bridge_0_m1_address;                    // uart_to_avalon_bridge_0:avm_m1_address -> mm_interconnect_0:uart_to_avalon_bridge_0_m1_address
	wire         uart_to_avalon_bridge_0_m1_read;                       // uart_to_avalon_bridge_0:avm_m1_read -> mm_interconnect_0:uart_to_avalon_bridge_0_m1_read
	wire   [3:0] uart_to_avalon_bridge_0_m1_byteenable;                 // uart_to_avalon_bridge_0:avm_m1_byteenable -> mm_interconnect_0:uart_to_avalon_bridge_0_m1_byteenable
	wire         uart_to_avalon_bridge_0_m1_readdatavalid;              // mm_interconnect_0:uart_to_avalon_bridge_0_m1_readdatavalid -> uart_to_avalon_bridge_0:avm_m1_readdatavalid
	wire         uart_to_avalon_bridge_0_m1_write;                      // uart_to_avalon_bridge_0:avm_m1_write -> mm_interconnect_0:uart_to_avalon_bridge_0_m1_write
	wire  [31:0] uart_to_avalon_bridge_0_m1_writedata;                  // uart_to_avalon_bridge_0:avm_m1_writedata -> mm_interconnect_0:uart_to_avalon_bridge_0_m1_writedata
	wire  [31:0] mm_interconnect_0_sysid_qsys_0_control_slave_readdata; // sysid_qsys_0:readdata -> mm_interconnect_0:sysid_qsys_0_control_slave_readdata
	wire   [0:0] mm_interconnect_0_sysid_qsys_0_control_slave_address;  // mm_interconnect_0:sysid_qsys_0_control_slave_address -> sysid_qsys_0:address
	wire  [31:0] mm_interconnect_0_initmem_test_0_s1_readdata;          // initmem_test_0:avs_s1_readdata -> mm_interconnect_0:initmem_test_0_s1_readdata
	wire  [11:0] mm_interconnect_0_initmem_test_0_s1_address;           // mm_interconnect_0:initmem_test_0_s1_address -> initmem_test_0:avs_s1_address
	wire         mm_interconnect_0_initmem_test_0_s1_read;              // mm_interconnect_0:initmem_test_0_s1_read -> initmem_test_0:avs_s1_read
	wire         rst_controller_reset_out_reset;                        // rst_controller:reset_out -> [initmem_test_0:rsi_s1_reset, mm_interconnect_0:uart_to_avalon_bridge_0_reset_reset_bridge_in_reset_reset, sysid_qsys_0:reset_n, uart_to_avalon_bridge_0:rsi_reset]

	initmem initmem_test_0 (
		.avs_s1_address  (mm_interconnect_0_initmem_test_0_s1_address),  //     s1.address
		.avs_s1_read     (mm_interconnect_0_initmem_test_0_s1_read),     //       .read
		.avs_s1_readdata (mm_interconnect_0_initmem_test_0_s1_readdata), //       .readdata
		.csi_s1_clock    (clk_clk),                                      //  clock.clk
		.rsi_s1_reset    (rst_controller_reset_out_reset),               //  reset.reset
		.coe_initdone    (coe_initdone)                                  // export.initdone
	);

	testmem_core_sysid_qsys_0 sysid_qsys_0 (
		.clock    (clk_clk),                                               //           clk.clk
		.reset_n  (~rst_controller_reset_out_reset),                       //         reset.reset_n
		.readdata (mm_interconnect_0_sysid_qsys_0_control_slave_readdata), // control_slave.readdata
		.address  (mm_interconnect_0_sysid_qsys_0_control_slave_address)   //              .address
	);

	uart_to_avalon_bridge #(
		.CLOCK_FREQUENCY (50000000),
		.UART_BAUDRATE   (115200),
		.BOARD_SERIAL    (256'b1111111111111111111111111111111111111111111111110100011001000110010001100100011001000110010001100100011001000110010001100100011001000110010001100100011001000110010001100100011000110011001110010101100000110010001101110100101000000010010101110011011101001010)
	) uart_to_avalon_bridge_0 (
		.csi_clk              (clk_clk),                                  //  clock.clk
		.rsi_reset            (rst_controller_reset_out_reset),           //  reset.reset
		.avm_m1_address       (uart_to_avalon_bridge_0_m1_address),       //     m1.address
		.avm_m1_readdata      (uart_to_avalon_bridge_0_m1_readdata),      //       .readdata
		.avm_m1_read          (uart_to_avalon_bridge_0_m1_read),          //       .read
		.avm_m1_write         (uart_to_avalon_bridge_0_m1_write),         //       .write
		.avm_m1_byteenable    (uart_to_avalon_bridge_0_m1_byteenable),    //       .byteenable
		.avm_m1_writedata     (uart_to_avalon_bridge_0_m1_writedata),     //       .writedata
		.avm_m1_waitrequest   (uart_to_avalon_bridge_0_m1_waitrequest),   //       .waitrequest
		.avm_m1_readdatavalid (uart_to_avalon_bridge_0_m1_readdatavalid), //       .readdatavalid
		.coe_rxd              (uart_rxd),                                 // export.rxd
		.coe_txd              (uart_txd)                                  //       .txd
	);

	testmem_core_mm_interconnect_0 mm_interconnect_0 (
		.clk_0_clk_clk                                             (clk_clk),                                               //                                           clk_0_clk.clk
		.uart_to_avalon_bridge_0_reset_reset_bridge_in_reset_reset (rst_controller_reset_out_reset),                        // uart_to_avalon_bridge_0_reset_reset_bridge_in_reset.reset
		.uart_to_avalon_bridge_0_m1_address                        (uart_to_avalon_bridge_0_m1_address),                    //                          uart_to_avalon_bridge_0_m1.address
		.uart_to_avalon_bridge_0_m1_waitrequest                    (uart_to_avalon_bridge_0_m1_waitrequest),                //                                                    .waitrequest
		.uart_to_avalon_bridge_0_m1_byteenable                     (uart_to_avalon_bridge_0_m1_byteenable),                 //                                                    .byteenable
		.uart_to_avalon_bridge_0_m1_read                           (uart_to_avalon_bridge_0_m1_read),                       //                                                    .read
		.uart_to_avalon_bridge_0_m1_readdata                       (uart_to_avalon_bridge_0_m1_readdata),                   //                                                    .readdata
		.uart_to_avalon_bridge_0_m1_readdatavalid                  (uart_to_avalon_bridge_0_m1_readdatavalid),              //                                                    .readdatavalid
		.uart_to_avalon_bridge_0_m1_write                          (uart_to_avalon_bridge_0_m1_write),                      //                                                    .write
		.uart_to_avalon_bridge_0_m1_writedata                      (uart_to_avalon_bridge_0_m1_writedata),                  //                                                    .writedata
		.initmem_test_0_s1_address                                 (mm_interconnect_0_initmem_test_0_s1_address),           //                                   initmem_test_0_s1.address
		.initmem_test_0_s1_read                                    (mm_interconnect_0_initmem_test_0_s1_read),              //                                                    .read
		.initmem_test_0_s1_readdata                                (mm_interconnect_0_initmem_test_0_s1_readdata),          //                                                    .readdata
		.sysid_qsys_0_control_slave_address                        (mm_interconnect_0_sysid_qsys_0_control_slave_address),  //                          sysid_qsys_0_control_slave.address
		.sysid_qsys_0_control_slave_readdata                       (mm_interconnect_0_sysid_qsys_0_control_slave_readdata)  //                                                    .readdata
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (~reset_reset_n),                 // reset_in0.reset
		.clk            (clk_clk),                        //       clk.clk
		.reset_out      (rst_controller_reset_out_reset), // reset_out.reset
		.reset_req      (),                               // (terminated)
		.reset_req_in0  (1'b0),                           // (terminated)
		.reset_in1      (1'b0),                           // (terminated)
		.reset_req_in1  (1'b0),                           // (terminated)
		.reset_in2      (1'b0),                           // (terminated)
		.reset_req_in2  (1'b0),                           // (terminated)
		.reset_in3      (1'b0),                           // (terminated)
		.reset_req_in3  (1'b0),                           // (terminated)
		.reset_in4      (1'b0),                           // (terminated)
		.reset_req_in4  (1'b0),                           // (terminated)
		.reset_in5      (1'b0),                           // (terminated)
		.reset_req_in5  (1'b0),                           // (terminated)
		.reset_in6      (1'b0),                           // (terminated)
		.reset_req_in6  (1'b0),                           // (terminated)
		.reset_in7      (1'b0),                           // (terminated)
		.reset_req_in7  (1'b0),                           // (terminated)
		.reset_in8      (1'b0),                           // (terminated)
		.reset_req_in8  (1'b0),                           // (terminated)
		.reset_in9      (1'b0),                           // (terminated)
		.reset_req_in9  (1'b0),                           // (terminated)
		.reset_in10     (1'b0),                           // (terminated)
		.reset_req_in10 (1'b0),                           // (terminated)
		.reset_in11     (1'b0),                           // (terminated)
		.reset_req_in11 (1'b0),                           // (terminated)
		.reset_in12     (1'b0),                           // (terminated)
		.reset_req_in12 (1'b0),                           // (terminated)
		.reset_in13     (1'b0),                           // (terminated)
		.reset_req_in13 (1'b0),                           // (terminated)
		.reset_in14     (1'b0),                           // (terminated)
		.reset_req_in14 (1'b0),                           // (terminated)
		.reset_in15     (1'b0),                           // (terminated)
		.reset_req_in15 (1'b0)                            // (terminated)
	);

endmodule
