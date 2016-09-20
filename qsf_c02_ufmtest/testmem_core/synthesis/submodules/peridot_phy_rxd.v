// ===================================================================
// TITLE : PERIDOT / UART reciever phy
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

module peridot_phy_rxd (
	// Interface: clk
	input			clk,
	input			reset,

	// Interface: ST out
	output			out_valid,
	output [7:0]	out_data,

	// interface UART
	input			rxd
);


/* ===== �O���ύX�\�p�����[�^ ========== */

	parameter CLOCK_FREQUENCY	= 50000000;
	parameter UART_BAUDRATE		= 115200;
//	parameter UART_BAUDRATE		= 6250000;		// test


/* ----- �����p�����[�^ ------------------ */

	localparam CLOCK_DIVNUM = (CLOCK_FREQUENCY / UART_BAUDRATE) - 1;
	localparam BIT_CAPTURE  = (CLOCK_DIVNUM / 2);


/* ���ȍ~�̃p�����[�^�錾�͋֎~�� */

/* ===== �m�[�h�錾 ====================== */
				/* �����͑S�Đ��_�����Z�b�g�Ƃ���B�����Œ�`���Ă��Ȃ��m�[�h�̎g�p�͋֎~ */
	wire			reset_sig = reset;				// ���W���[�������쓮�񓯊����Z�b�g 

				/* �����͑S�Đ��G�b�W�쓮�Ƃ���B�����Œ�`���Ă��Ȃ��N���b�N�m�[�h�̎g�p�͋֎~ */
	wire			clock_sig = clk;				// ���W���[�������쓮�N���b�N 

	reg [2:0]		rxdin_reg;

	reg [11:0]		divcount_reg;
	reg [3:0]		bitcount_reg;
	reg [7:0]		shift_reg;
	reg [7:0]		outdata_reg;
	reg				outvalid_reg;


/* ���ȍ~��wire�Areg�錾�͋֎~�� */

/* ===== �e�X�g�L�q ============== */



/* ===== ���W���[���\���L�q ============== */

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			rxdin_reg <= 3'b111;
			divcount_reg <= 1'd0;
			bitcount_reg <= 1'd0;
			shift_reg <= 8'h00;
			outvalid_reg <= 1'b0;
			outdata_reg  <= 8'h00;

		end
		else begin
			rxdin_reg <= {rxdin_reg[1:0], rxd};

			if (bitcount_reg == 4'd0) begin
				outvalid_reg <= 1'b0;

				if (rxdin_reg[2:1] == 2'b10) begin
					divcount_reg <= BIT_CAPTURE;
					bitcount_reg <= 4'd10;
				end
			end
			else begin
				if (divcount_reg == 0) begin
					divcount_reg <= CLOCK_DIVNUM;

					if (bitcount_reg == 4'd10) begin			// start bit check
						if (rxdin_reg[2] == 1'b0) begin
							bitcount_reg <= bitcount_reg - 1'd1;
						end
						else begin
							bitcount_reg <= 4'd0;
						end
					end
					else if (bitcount_reg == 4'd1) begin		// stop bit check
						bitcount_reg <= bitcount_reg - 1'd1;

						if (rxdin_reg[2] == 1'b1) begin
							outvalid_reg <= 1'b1;
							outdata_reg  <= shift_reg;
						end
					end
					else begin
						bitcount_reg <= bitcount_reg - 1'd1;
						shift_reg <= {rxdin_reg[2], shift_reg[7:1]};
					end

				end
				else begin
					divcount_reg <= divcount_reg - 1'd1;
				end
			end

		end
	end

	assign out_valid = outvalid_reg;
	assign out_data  = outdata_reg;



endmodule
