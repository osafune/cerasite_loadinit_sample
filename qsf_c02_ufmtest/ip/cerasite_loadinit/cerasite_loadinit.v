// ===================================================================
// TITLE : CERASITE / Memory initial data loader
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
//   DATE   : 2016/09/19 -> 2016/09/19
//   UPDATE :
//
// ===================================================================
// *******************************************************************
//     (C) 2016, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

// �� �g���� 
//
// UFM�ɏ������܂ꂽ�ő�16k�o�C�g�̈��k�������R�[�h��ǂݏo���Adata��32bit���[�h��W�J�Adatavalid���A�T�[�g����B
// �I���t���[�������o�����initdone��'H'�ɃA�T�[�g����B
//
// �g�b�v��SDC�Ɉȉ���ǉ�
//
// create_generated_clock -name ufm_clk -source [get_nets {<�C���X�^���X��>|clock_sig}] -divide_by 8 [get_nets {<�C���X�^���X��>|ufm_clk_sig}]
//
//
// �� UFM�ɏ������ރf�[�^�`�� 
//
// UFM�̐擪�A�h���X���牺�L�f�[�^�t���[����A�����ď������ށB
// �f�[�^�t���[����32bit���[�h�P�ʂ̃f�[�^�u���b�N�B
// �����f�[�^�t���[������ё��l�f�[�^�t���[���͕����g�ݍ��킹�Ĕz�u�ł���B
// �I���f�[�^�t���[���͍Ō�ɂP�����z�u����i�z�u�����ꏊ�œW�J���I������j�B
//
// �E�����f�[�^�t���[���i�P�O�Ƃ̍�����+127�`-128�͈̔͂ɂ����܂郏�[�h��j
//
// +0   : �t���[���w�b�_ / bit31:0, bit30:0, bit29-17:reserve(0), bit16-0:�i�[���[�h��(1�`65536) 
// +4   : �����l / bit31-0:�����l 
// +8�` : �����l / bit7-0:���[�h+1�̑����l(�����t��8bit), bit15-8:���[�h+2�̑����l(�V), bit23-16:���[�h+3, bit31-24:���[�h+4
//        �������l�f�[�^�͕K��32bit���E�ɔz�u����A�]��o�C�g�͓ǂݎ̂Ă���
//
//
// �E���l�f�[�^�t���[���i32bit�̃��[�h��j
//
// +0   : �t���[���w�b�_ / bit31:0, bit30:1, bit29-17:reserve(0), bit16-0:�i�[���[�h��(1�`65536) 
// +4�` : ���l���[�h / bit31-0:�f�[�^�� 
// 
//
// �E�I���f�[�^�t���[���i�������f�[�^�̏I���������j
//
// +0   : �t���[���w�b�_ / bit31:1, bit30-0:X
//


`timescale 1ns / 100ps

module cerasite_loadinit (
/*
	output			test_ufm_clk,
	output [13:0]	test_ufm_address,
	output			test_ufm_read,
	input  [31:0]	test_ufm_readdata,
	input			test_ufm_readdatavalid,
	input			test_ufm_waitres,
*/

	// Interface: clk
	input			clock,			// up to 58MHz
	input			reset,

	// Interface: initial data stream
	output [31:0]	data,
	output			datavalid,
	output			initdone
);


/* ===== �O���ύX�\�p�����[�^ ========== */



/* ----- �����p�����[�^ ------------------ */

	localparam	STATE_START		= 5'd0,
				STATE_LOADCOUNT	= 5'd1,
				STATE_LOADINIT	= 5'd2,
				STATE_ADD0		= 5'd3,
				STATE_ADD1		= 5'd4,
				STATE_ADD2		= 5'd5,
				STATE_ADD3		= 5'd6,
				STATE_DONE		= 5'd7;


/* ���ȍ~�̃p�����[�^�錾�͋֎~�� */

/* ===== �m�[�h�錾 ====================== */
				/* �����͑S�Đ��_�����Z�b�g�Ƃ���B�����Œ�`���Ă��Ȃ��m�[�h�̎g�p�͋֎~ */
	wire			reset_sig = reset;		// ���W���[�������쓮�񓯊����Z�b�g 

				/* �����͑S�Đ��G�b�W�쓮�Ƃ���B�����Œ�`���Ă��Ȃ��N���b�N�m�[�h�̎g�p�͋֎~ */
	wire			clock_sig /* synthesis keep = 1 */ = clock;		// ���W���[�������쓮�N���b�N 

	reg  [4:0]		state_reg;
	reg				readreq_reg;
	reg				imm32_reg;
	reg  [11:0]		wordaddr_reg;
	reg  [15:0]		datacount_reg;
	reg  [31:0]		data_reg;
	reg				datavalid_reg;

	wire [13:0]		avs_address_sig;
	wire			avs_waitrequest_sig;
	wire			avs_read_sig;
	wire [31:0]		avs_readdata_sig;


	reg  [2:0]		divclock_reg;
	wire			ufm_clk_sig /* synthesis keep = 1 */;			// �����N���b�N�l�b�g����ێ� 
	wire			ufm_clkena_sig;

	wire [13:2]		ufm_address_sig;
	reg				ufm_waitreq_reg;
	wire			ufm_waitreq_sig;
	reg				ufm_read_reg;
	wire			ufm_readreq_sig;
	reg				ufm_datawait_reg;
	reg  [31:0]		ufm_readdata_reg;
	wire [31:0]		ufm_readdata_sig;
	wire			ufm_readdatavalid_sig;
	wire			ufm_waitres_sig;



/* ���ȍ~��wire�Areg�錾�͋֎~�� */

/* ===== �e�X�g�L�q ============== */
/*
	assign test_ufm_clk = ufm_clk_sig;
	assign test_ufm_address = {ufm_address_sig, 2'b00};
	assign test_ufm_read = ufm_read_reg;
	assign ufm_readdata_sig = test_ufm_readdata;
	assign ufm_readdatavalid_sig = test_ufm_readdatavalid;
	assign ufm_waitres_sig = test_ufm_waitres;
*/

/* ===== ���W���[���\���L�q ============== */

	/***** �����l�f�[�^���� *****/

	assign avs_address_sig = {wordaddr_reg, 2'b00};
	assign avs_read_sig = readreq_reg;

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			state_reg <= STATE_START;
			readreq_reg <= 1'b0;
			imm32_reg <= 1'b0;
			datavalid_reg <= 1'b0;
		end
		else begin
			case (state_reg)

			STATE_START : begin
				state_reg <= STATE_LOADCOUNT;
				readreq_reg <= 1'b1;
				wordaddr_reg <= 1'd0;
			end

			STATE_LOADCOUNT : begin
				if (!avs_waitrequest_sig) begin
					wordaddr_reg <= wordaddr_reg + 1'd1;

					if (avs_readdata_sig[31] == 1'b1) begin
						state_reg <= STATE_DONE;
						readreq_reg <= 1'b0;
					end
					else begin
						state_reg <= STATE_LOADINIT;
					end

					datacount_reg <= avs_readdata_sig[15:0];
					imm32_reg <= avs_readdata_sig[30];
				end
				else begin
					datavalid_reg <= 1'b0;
				end
			end

			STATE_LOADINIT : begin
				if (!avs_waitrequest_sig) begin
					wordaddr_reg <= wordaddr_reg + 1'd1;

					if (datacount_reg == 16'd1) begin
						state_reg <= STATE_LOADCOUNT;
					end
					else begin
						if (imm32_reg == 1'b0) begin
							state_reg <= STATE_ADD0;
						end
						else begin
							state_reg <= STATE_LOADINIT;
						end
					end

					datacount_reg <= datacount_reg - 1'd1;
					data_reg <= avs_readdata_sig;
					datavalid_reg <= 1'b1;
				end
				else begin
					datavalid_reg <= 1'b0;
				end
			end

			STATE_ADD0 : begin
				if (!avs_waitrequest_sig) begin
					wordaddr_reg <= wordaddr_reg + 1'd1;

					if (datacount_reg == 16'd1) begin
						state_reg <= STATE_LOADCOUNT;
						readreq_reg <= 1'b1;
					end
					else begin
						state_reg <= STATE_ADD1;
						readreq_reg <= 1'b0;
					end

					datacount_reg <= datacount_reg - 1'd1;
					data_reg <= data_reg + {{24{avs_readdata_sig[7]}}, avs_readdata_sig[7:0]};
					datavalid_reg <= 1'b1;
				end
				else begin
					datavalid_reg <= 1'b0;
				end
			end

			STATE_ADD1 : begin
				if (datacount_reg == 16'd1) begin
					state_reg <= STATE_LOADCOUNT;
					readreq_reg <= 1'b1;
				end
				else begin
					state_reg <= STATE_ADD2;
				end

				datacount_reg <= datacount_reg - 1'd1;
				data_reg <= data_reg + {{24{avs_readdata_sig[15]}}, avs_readdata_sig[15:8]};
			end

			STATE_ADD2 : begin
				if (datacount_reg == 16'd1) begin
					state_reg <= STATE_LOADCOUNT;
					readreq_reg <= 1'b1;
				end
				else begin
					state_reg <= STATE_ADD3;
				end

				datacount_reg <= datacount_reg - 1'd1;
				data_reg <= data_reg + {{24{avs_readdata_sig[23]}}, avs_readdata_sig[23:16]};
			end

			STATE_ADD3 : begin
				readreq_reg <= 1'b1;

				if (datacount_reg == 16'd1) begin
					state_reg <= STATE_LOADCOUNT;
				end
				else begin
					state_reg <= STATE_ADD0;
				end

				datacount_reg <= datacount_reg - 1'd1;
				data_reg <= data_reg + {{24{avs_readdata_sig[31]}}, avs_readdata_sig[31:24]};
			end

			STATE_DONE : begin
			end

			endcase

		end
	end

	assign data = data_reg;
	assign datavalid = datavalid_reg;

	assign initdone = (state_reg == STATE_DONE)? 1'b1 : 1'b0;



	/***** UFM�A�N�Z�X���W���[��(10M02�p) *****/

	// ����M�� 

	assign ufm_address_sig = avs_address_sig[13:2];
	assign ufm_readreq_sig = avs_read_sig;
	assign avs_readdata_sig = ufm_readdata_reg;
	assign avs_waitrequest_sig = ufm_waitreq_sig;


	// 8�����N���b�N�𐶐� 

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			divclock_reg <= 1'd0;
		end
		else begin
			divclock_reg <= divclock_reg + 1'd1;
		end
	end

	assign ufm_clk_sig = divclock_reg[2];
	assign ufm_clkena_sig = (divclock_reg == 3'b000)? 1'b1 : 1'b0;	// �N���b�N�����̒��Ԓn�_���f�[�^�E�B���h�E�ɂ��� 


	// UFM���[�h�R���g���[�� 

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			ufm_read_reg <= 1'b0;
			ufm_datawait_reg <= 1'b0;
			ufm_waitreq_reg <= 1'b0;
		end
		else begin
			if (ufm_clkena_sig) begin
				if (ufm_read_reg && !ufm_waitres_sig) begin
					ufm_read_reg <= 1'b0;
				end
				else if (ufm_readreq_sig && !ufm_datawait_reg) begin
					ufm_read_reg <= 1'b1;
				end

				if (ufm_read_reg && !ufm_waitres_sig) begin
					ufm_datawait_reg <= 1'b1;
				end
				else if (ufm_readdatavalid_sig) begin
					ufm_datawait_reg <= 1'b0;
				end
			end

			if (!ufm_waitreq_reg) begin
				ufm_waitreq_reg <= 1'b1;
			end
			else begin
				if (ufm_clkena_sig && ufm_readdatavalid_sig) begin
					ufm_readdata_reg <= ufm_readdata_sig;
					ufm_waitreq_reg <= 1'b0;
				end
			end
		end
	end

	assign ufm_waitreq_sig = (ufm_readreq_sig)? ufm_waitreq_reg : 1'b0;


	// UFM���W���[���C���X�^���X 

	cerasite_ocflash u_ufm (
		.reset_n					(~reset_sig),
		.clock						(ufm_clk_sig),
		.avmm_data_addr				(ufm_address_sig),
		.avmm_data_read				(ufm_read_reg),
		.avmm_data_readdata			(ufm_readdata_sig),
		.avmm_data_waitrequest		(ufm_waitres_sig),
		.avmm_data_readdatavalid	(ufm_readdatavalid_sig),
		.avmm_data_burstcount		(2'd1)
	);



endmodule