// ===================================================================
// TITLE : PERIDOT / Dummy board serial-rom
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2016/01/01 -> 2016/01/06
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

`timescale 1ns / 100ps

module peridot_board_eeprom (
	output [7:0]	test_senddata,
	output			test_senddatavalid,

	// Interface: clk
	input			clk,
	input			reset,

	// Interface: Condit (I2C)
	input			i2c_scl_i,
	input			i2c_sda_i,
	output			i2c_sda_o
);


/* ===== 外部変更可能パラメータ ========== */

	parameter DEVICE_ADDRESS	= 7'b1010000;
	parameter ROMDATA			= {32{8'hff}};


/* ----- 内部パラメータ ------------------ */

	localparam	STATE_IDLE		= 5'd0,
				STATE_DEVSEL1	= 5'd1,
				STATE_SETADDR	= 5'd2,
				STATE_REPSTART	= 5'd3,
				STATE_DEVSEL2	= 5'd4,
				STATE_READBYTE	= 5'd5,
				STATE_WRITEBYTE	= 5'd6;


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;				// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = clk;				// モジュール内部駆動クロック 

	wire			condi_start_sig;
	wire			condi_stop_sig;
	wire			done_byte_sig;
	wire			done_ack_sig;
	wire [7:0]		senddata_sig;
	wire			senddatavalid_sig;
	wire [7:0]		recievedata_sig;
	wire			recieveack_sig;
	reg				sendack_reg;

	reg  [4:0]		state_reg;
	reg  [4:0]		bytecount_reg;
	wire [7:0]		romdatasel_sig [0:31];


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */

	assign test_senddata = senddata_sig;
	assign test_senddatavalid = senddatavalid_sig;


/* ===== モジュール構造記述 ============== */

	// I2Cシリアルインターフェース 

	peridot_i2c_serial
	u0 (
		.clk				(clock_sig),
		.reset				(reset_sig),
		.i2c_scl_i			(i2c_scl_i),
		.i2c_scl_o			(),
		.i2c_sda_i			(i2c_sda_i),
		.i2c_sda_o			(i2c_sda_o),
		.condi_start		(condi_start_sig),
		.condi_stop			(condi_stop_sig),
		.done_byte			(done_byte_sig),
		.ackwaitrequest		(1'b0),
		.done_ack			(done_ack_sig),
		.send_bytedata		(senddata_sig),
		.send_bytedatavalid	(senddatavalid_sig),
		.recieve_bytedata	(recievedata_sig),
		.send_ackdata		(sendack_reg),
		.recieve_ackdata	(recieveack_sig)
	);



	// EEPROMエミュレーションFSM 

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			state_reg <= STATE_IDLE;
			sendack_reg <= 1'b0;
			bytecount_reg <= 1'd0;
		end
		else begin
			if (condi_stop_sig) begin
				state_reg <= STATE_IDLE;
				sendack_reg <= 1'b0;
			end
			else begin
				case (state_reg)

				STATE_IDLE : begin
					if (condi_start_sig) begin
						state_reg <= STATE_DEVSEL1;
					end
				end


				// カレントアドレスセット 

				STATE_DEVSEL1 : begin
					if (done_byte_sig) begin
						if (recievedata_sig[7:1] == DEVICE_ADDRESS && !recievedata_sig[0]) begin
							state_reg <= STATE_SETADDR;
							sendack_reg <= 1'b1;
						end
						else begin
							state_reg <= STATE_IDLE;
							sendack_reg <= 1'b0;
						end
					end
				end
				STATE_SETADDR : begin
					if (done_byte_sig) begin
						state_reg <= STATE_REPSTART;
						bytecount_reg <= recievedata_sig[4:0];
					end
				end


				// データリードライト 

				STATE_REPSTART : begin
					if (condi_start_sig) begin
						state_reg <= STATE_DEVSEL2;
					end
				end
				STATE_DEVSEL2 : begin
					if (done_byte_sig) begin
						if (recievedata_sig[7:1] == DEVICE_ADDRESS) begin
							sendack_reg <= 1'b1;

							if (recievedata_sig[0]) begin
								state_reg <= STATE_READBYTE;
							end
							else begin
								state_reg <= STATE_WRITEBYTE;
							end
						end
						else begin
							state_reg <= STATE_IDLE;
							sendack_reg <= 1'b0;
						end
					end
				end
				STATE_READBYTE : begin
					if (done_ack_sig) begin
						sendack_reg <= 1'b0;
					end

					if (done_byte_sig) begin
						bytecount_reg <= bytecount_reg + 1'd1;
					end
				end
				STATE_WRITEBYTE : begin			// データライトはダミー 
				end

				endcase
			end

		end
	end


	// EEPROMデータ読み出し 

	generate
		genvar i;
		for (i=0 ; i<32 ; i=i+1) begin : loop
			assign romdatasel_sig[i] = ROMDATA[i*8+7 : i*8];
		end
	endgenerate

	assign senddatavalid_sig = (recieveack_sig && state_reg == STATE_READBYTE)? 1'b1 : 1'b0;
	assign senddata_sig = romdatasel_sig[bytecount_reg];



endmodule
