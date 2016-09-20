// ===================================================================
// TITLE : PERIDOT / UART sender phy
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2015/12/27 -> 2015/12/27
//   UPDATE : 
//
// ===================================================================
// *******************************************************************
//   Copyright (C) 2015, J-7SYSTEM Works.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

`timescale 1ns / 100ps

module peridot_phy_txd (
	// Interface: clk
	input			clk,
	input			reset,

	// Interface: ST in
	output			in_ready,
	input			in_valid,
	input [7:0]		in_data,

	// interface UART
	output			txd
);


/* ===== �O���ύX�\�p�����[�^ ========== */

	parameter CLOCK_FREQUENCY	= 50000000;
	parameter UART_BAUDRATE		= 115200;
//	parameter UART_BAUDRATE		= 12500000;		// test


/* ----- �����p�����[�^ ------------------ */

	localparam CLOCK_DIVNUM = (CLOCK_FREQUENCY / UART_BAUDRATE) - 1;


/* ���ȍ~�̃p�����[�^�錾�͋֎~�� */

/* ===== �m�[�h�錾 ====================== */
				/* �����͑S�Đ��_�����Z�b�g�Ƃ���B�����Œ�`���Ă��Ȃ��m�[�h�̎g�p�͋֎~ */
	wire			reset_sig = reset;				// ���W���[�������쓮�񓯊����Z�b�g 

				/* �����͑S�Đ��G�b�W�쓮�Ƃ���B�����Œ�`���Ă��Ȃ��N���b�N�m�[�h�̎g�p�͋֎~ */
	wire			clock_sig = clk;				// ���W���[�������쓮�N���b�N 

	reg [11:0]		divcount_reg;
	reg [3:0]		bitcount_reg;
	reg [8:0]		txd_reg;


/* ���ȍ~��wire�Areg�錾�͋֎~�� */

/* ===== �e�X�g�L�q ============== */



/* ===== ���W���[���\���L�q ============== */

	assign in_ready = (bitcount_reg == 4'd0)? 1'b1 : 1'b0;
	assign txd = txd_reg[0];

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			divcount_reg <= 1'd0;
			bitcount_reg <= 1'd0;
			txd_reg <= 9'h1ff;

		end
		else begin
			if (bitcount_reg == 4'd0) begin
				if (in_valid) begin
					divcount_reg <= CLOCK_DIVNUM;
					bitcount_reg <= 4'd10;
					txd_reg <= {in_data, 1'b0};
				end
			end
			else begin
				if (divcount_reg == 0) begin
					divcount_reg <= CLOCK_DIVNUM;
					bitcount_reg <= bitcount_reg - 1'd1;
					txd_reg <= {1'b1, txd_reg[8:1]};
				end
				else begin
					divcount_reg <= divcount_reg - 1'd1;
				end
			end

		end
	end



endmodule
