// ===================================================================
// TITLE : PERIDOT / Configuration Layer dummy module
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2014/03/10 -> 2014/03/27
//   UPDATE : 2016/01/06
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

`timescale 1ns / 100ps

module peridot_dummy_conf (
	// Interface: clk
	input			clk,
	input			reset,

	// Interface: ST in (Up-stream side)
	input			in_valid,
	input [7:0]		in_data,

	output			out_valid,
	output [7:0]	out_data,

	// Interface: ST in (Down-stream side)
	output			pk_ready,
	input			pk_valid,
	input [7:0]		pk_data,

	input			resp_ready,
	output			resp_valid,
	output [7:0]	resp_data
);


/* ===== 外部変更可能パラメータ ========== */

	parameter BOARD_SERIAL	= {32{8'hff}};


/* ----- 内部パラメータ ------------------ */



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;				// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = clk;				// モジュール内部駆動クロック 

	reg				getparam_reg;
	reg				escape_reg;
	reg				outvalid_reg;
	reg [7:0]		outdata_reg;
	reg				respreq_reg;
	reg				scl_reg;
	reg				sda_reg;
	wire			i2c_scl_sig;
	wire			i2c_sda_sig;
	wire			rom_sda_o_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			getparam_reg <= 1'b0;
			escape_reg <= 1'b0;
			outvalid_reg <= 1'b0;
			outdata_reg <= 8'hx;
			respreq_reg <= 1'b0;
			scl_reg <= 1'b1;
			sda_reg <= 1'b1;
		end
		else begin
			if (in_valid) begin

				// コンフィグコマンド受信 
				if (in_data == 8'h3a) begin
					getparam_reg <= 1'b1;
					outvalid_reg <= 1'b0;
				end

				// エスケープ指示子受信 
				else if (in_data == 8'h3d) begin
					escape_reg <= 1'b1;
					outvalid_reg <= 1'b0;
				end

				// それ以外のバイト 
				else begin
					// コンフィグコマンドの2バイト目 
					if (getparam_reg) begin
						getparam_reg <= 1'b0;
						outvalid_reg <= 1'b0;
						scl_reg <= in_data[4];
						sda_reg <= in_data[5];
					end
					// エスケープ指示子の2バイト目 
					else if (escape_reg) begin
						escape_reg <= 1'b0;
						outdata_reg <= in_data ^ 8'h20;
						outvalid_reg <= 1'b1;
					end
					else begin
						outdata_reg <= in_data;
						outvalid_reg <= 1'b1;
					end
				end
			end
			else begin
				outvalid_reg <= 1'b0;
			end

			// コンフィグコマンドを受信したらレスポンスを発行 
			if (in_valid && getparam_reg) begin
				respreq_reg <= 1'b1;
			end
			else if (resp_ready && respreq_reg) begin
				respreq_reg <= 1'b0;
			end

		end
	end

	assign out_valid = outvalid_reg;
	assign out_data = outdata_reg;

	assign pk_ready = (resp_ready && respreq_reg)? 1'b0 : resp_ready;

	assign resp_data = (resp_ready && respreq_reg)? {2'b00, i2c_sda_sig, scl_reg, 4'h7} : pk_data;
	assign resp_valid = (resp_ready && respreq_reg)? 1'b1 : pk_valid;



	// ボードシリアルROM 

	assign i2c_scl_sig = scl_reg;
	assign i2c_sda_sig = (!sda_reg || !rom_sda_o_sig)? 1'b0 : 1'b1;

	peridot_board_eeprom #(
		.DEVICE_ADDRESS	(7'b1010000),
		.ROMDATA		(BOARD_SERIAL)
	)
	inst_rom (
		.clk			(clock_sig),
		.reset			(reset_sig),

		.i2c_scl_i		(i2c_scl_sig),
		.i2c_sda_i		(i2c_sda_sig),
		.i2c_sda_o		(rom_sda_o_sig)
	);



endmodule
