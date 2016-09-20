// ===================================================================
// TITLE : PERIDOT / AvalonST bytes to UART (dummy psconf included)
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2015/12/27 -> 2016/01/11
//   UPDATE :
//
// ===================================================================
// *******************************************************************
//   Copyright (C) 2016, J-7SYSTEM Works.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

module peridot_bytes_to_uart(
	output [9:0]	test_infifo_usedw,

	// Interface: clk
	input			clk,
	input			reset,

	// Interface: ST out 
	input			out_ready,
	output			out_valid,
	output [7:0]	out_data,

	// Interface: ST in 
	output			in_ready,
	input			in_valid,
	input  [7:0]	in_data,

	// External Physicaloid Serial Interface 
	input			uart_rxd,
	output			uart_txd
);


/* ===== �O���ύX�\�p�����[�^ ========== */

	parameter CLOCK_FREQUENCY	= 50000000;
	parameter UART_BAUDRATE		= 115200;
	parameter BOARD_SERIAL		= {32{8'hff}};


/* ----- �����p�����[�^ ------------------ */



/* ���ȍ~�̃p�����[�^�錾�͋֎~�� */

/* ===== �m�[�h�錾 ====================== */
				/* �����͑S�Đ��_�����Z�b�g�Ƃ���B�����Œ�`���Ă��Ȃ��m�[�h�̎g�p�͋֎~ */
	wire			reset_sig = reset;				// ���W���[�������쓮�񓯊����Z�b�g 

				/* �����͑S�Đ��G�b�W�쓮�Ƃ���B�����Œ�`���Ă��Ȃ��N���b�N�m�[�h�̎g�p�͋֎~ */
	wire			clock_sig = clk;				// ���W���[�������쓮�N���b�N 

	wire			outready_sig;
	wire [7:0]		infifo_data_sig;
	wire			infifo_wrreq_sig;
	wire [9:0]		infifo_usedw_sig;
	wire [7:0]		infifo_q_sig;
	wire			infifo_rdack_sig;
	wire			infifo_empty_sig;

	wire			conf_ready_sig;
	wire			conf_valid_sig;
	wire [7:0]		conf_data_sig;

	wire			rxd_valid_sig;
	wire [7:0]		rxd_data_sig;
	wire			rxd_sig;

	wire			txd_ready_sig;
	wire			txd_valid_sig;
	wire [7:0]		txd_data_sig;
	wire			txd_sig;


/* ���ȍ~��wire�Areg�錾�͋֎~�� */

/* ===== �e�X�g�L�q ============== */

	assign test_infifo_usedw = infifo_usedw_sig;


/* ===== ���W���[���\���L�q ============== */

	assign outready_sig = out_ready;
	assign out_valid = ~infifo_empty_sig;
	assign out_data = infifo_q_sig;

	assign in_ready = conf_ready_sig;
	assign conf_valid_sig = in_valid;
	assign conf_data_sig = in_data;

	assign rxd_sig = uart_rxd;
	assign uart_txd = txd_sig;


	///// AvalonST�o�C�g�X�g���[���w /////

	// UART��MFIFO 

	assign infifo_rdack_sig = (!infifo_empty_sig && outready_sig)? 1'b1 : 1'b0;

	peridot_uart_infifo
	inst_infifo (
		.aclr				(reset_sig),
		.clock				(clock_sig),

		.wrreq				(infifo_wrreq_sig),
		.data				(infifo_data_sig),
		.usedw				(infifo_usedw_sig),

		.rdreq				(infifo_rdack_sig),
		.q					(infifo_q_sig),
		.empty				(infifo_empty_sig)
	);



	///// ����M�����w /////

	// �_�~�[�R���t�B�O���[�V�������C�� 

	peridot_dummy_conf #(
		.BOARD_SERIAL		(BOARD_SERIAL)
	)
	inst_dc (
		.clk				(clock_sig),
		.reset				(reset_sig),

		.in_valid			(rxd_valid_sig),
		.in_data			(rxd_data_sig),
		.out_valid			(infifo_wrreq_sig),
		.out_data			(infifo_data_sig),

		.pk_ready			(conf_ready_sig),
		.pk_valid			(conf_valid_sig),
		.pk_data			(conf_data_sig),
		.resp_ready			(txd_ready_sig),
		.resp_valid			(txd_valid_sig),
		.resp_data			(txd_data_sig)
	);


	// UART��M 

	peridot_phy_rxd #(
		.CLOCK_FREQUENCY	(CLOCK_FREQUENCY),
		.UART_BAUDRATE		(UART_BAUDRATE)
	)
	inst_rxd (
		.clk				(clock_sig),
		.reset				(reset_sig),

		.out_valid			(rxd_valid_sig),
		.out_data			(rxd_data_sig),

		.rxd				(rxd_sig)
	);


	// UART���M 

	peridot_phy_txd #(
		.CLOCK_FREQUENCY	(CLOCK_FREQUENCY),
		.UART_BAUDRATE		(UART_BAUDRATE)
	)
	inst_txd (
		.clk				(clock_sig),
		.reset				(reset_sig),

		.in_ready			(txd_ready_sig),
		.in_valid			(txd_valid_sig),
		.in_data			(txd_data_sig),

		.txd				(txd_sig)
	);



endmodule
