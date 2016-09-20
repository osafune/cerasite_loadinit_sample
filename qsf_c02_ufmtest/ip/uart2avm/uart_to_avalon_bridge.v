// ===================================================================
// TITLE : PERIDOT / UART to Avalon-MM Bridge
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2014/03/10 -> 2014/03/27
//   UPDATE : 2015/01/06
//
// ===================================================================
// *******************************************************************
//   Copyright (C) 2013-2016, J-7SYSTEM Works.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

`timescale 1ns / 100ps

module uart_to_avalon_bridge (
	// Interface: clk
	input			csi_clk,
	input			rsi_reset,

	// Interface: MM out
	output [31:0]	avm_m1_address,
	input  [31:0]	avm_m1_readdata,
	output			avm_m1_read,
	output			avm_m1_write,
	output [ 3:0]	avm_m1_byteenable,
	output [31:0]	avm_m1_writedata,
	input			avm_m1_waitrequest,
	input			avm_m1_readdatavalid,

	// External Serial Interface 
	input			coe_rxd,
	output			coe_txd
);


/* ===== 外部変更可能パラメータ ========== */

	parameter CLOCK_FREQUENCY	= 50000000;
	parameter UART_BAUDRATE		= 115200;
	parameter BOARD_SERIAL		= {32{8'hff}};


/* ----- 内部パラメータ ------------------ */



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = rsi_reset;			// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = csi_clk;			// モジュール内部駆動クロック 

	wire			avm_in_ready_sig;
	wire			avm_in_valid_sig;
	wire [7:0]		avm_in_data_sig;
	wire			avm_in_startofpacket_sig;
	wire			avm_in_endofpacket_sig;
	wire			avm_out_ready_sig;
	wire			avm_out_valid_sig;
	wire [7:0]		avm_out_data_sig;
	wire			avm_out_startofpacket_sig;
	wire			avm_out_endofpacket_sig;
	wire			phy_out_ready_sig;
	wire			phy_out_valid_sig;
	wire [7:0]		phy_out_data_sig;
	wire			phy_in_ready_sig;
	wire			phy_in_valid_sig;
	wire [7:0]		phy_in_data_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	altera_avalon_packets_to_master #(
		.FAST_VER    (0),
		.FIFO_DEPTHS (2),
		.FIFO_WIDTHU (1)
	)
	inst_pk2trans (
		.clk				(clock_sig),
		.reset_n			(~reset_sig),

		.in_ready			(avm_in_ready_sig),
		.in_valid			(avm_in_valid_sig),
		.in_data			(avm_in_data_sig),
		.in_startofpacket	(avm_in_startofpacket_sig),
		.in_endofpacket		(avm_in_endofpacket_sig),
		.out_ready			(avm_out_ready_sig),
		.out_valid			(avm_out_valid_sig),
		.out_data			(avm_out_data_sig),
		.out_startofpacket	(avm_out_startofpacket_sig),
		.out_endofpacket	(avm_out_endofpacket_sig),

		.address			(avm_m1_address),
		.readdata			(avm_m1_readdata),
		.read				(avm_m1_read),
		.write				(avm_m1_write),
		.byteenable			(avm_m1_byteenable),
		.writedata			(avm_m1_writedata),
		.waitrequest		(avm_m1_waitrequest),
		.readdatavalid		(avm_m1_readdatavalid)
	);


	altera_avalon_st_bytes_to_packets #(
		.CHANNEL_WIDTH (8),
		.ENCODING      (0)
	)
	inst_by2pk (
		.clk				(clock_sig),
		.reset_n			(~reset_sig),

		.out_ready			(avm_in_ready_sig),
		.out_valid			(avm_in_valid_sig),
		.out_data			(avm_in_data_sig),
		.out_channel		(),
		.out_startofpacket	(avm_in_startofpacket_sig),
		.out_endofpacket	(avm_in_endofpacket_sig),

		.in_ready			(phy_out_ready_sig),
		.in_valid			(phy_out_valid_sig),
		.in_data			(phy_out_data_sig)
	);


	altera_avalon_st_packets_to_bytes #(
		.CHANNEL_WIDTH (8),
		.ENCODING      (0)
	)
	inst_pk2by (
		.clk				(clock_sig),
		.reset_n			(~reset_sig),

		.in_ready			(avm_out_ready_sig),
		.in_valid			(avm_out_valid_sig),
		.in_data			(avm_out_data_sig),
		.in_channel			(1'd0),
		.in_startofpacket	(avm_out_startofpacket_sig),
		.in_endofpacket		(avm_out_endofpacket_sig),

		.out_ready			(phy_in_ready_sig),
		.out_valid			(phy_in_valid_sig),
		.out_data			(phy_in_data_sig)
	);


	peridot_bytes_to_uart #(
		.CLOCK_FREQUENCY	(CLOCK_FREQUENCY),
		.UART_BAUDRATE		(UART_BAUDRATE),
		.BOARD_SERIAL		(BOARD_SERIAL)
	)
	inst_by2uart (
		.clk				(clock_sig),
		.reset				(reset_sig),

		.out_ready			(phy_out_ready_sig),
		.out_valid			(phy_out_valid_sig),
		.out_data			(phy_out_data_sig),
		.in_ready			(phy_in_ready_sig),
		.in_valid			(phy_in_valid_sig),
		.in_data			(phy_in_data_sig),

		.uart_rxd			(coe_rxd),
		.uart_txd			(coe_txd)
	);



endmodule
