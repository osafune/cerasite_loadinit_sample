// ===================================================================
// TITLE : CERASITE / Memory initial data loader
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
//   DATE   : 2016/09/19 -> 2016/09/19
//   UPDATE : 2016/09/28
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

// ■ 使い方 
//
// UFMに書き込まれた最大16kバイトの圧縮初期化コードを読み出し、dataに32bitワードを展開、datavalidをアサートする。
// 終了フレームを検出するとinitdoneを'H'にアサートする。
//
// トップのSDCに以下を追加
//
// create_generated_clock -name ufm_clk -source [get_nets {<インスタンス名>|clock_sig}] -divide_by 8 [get_nets {<インスタンス名>|ufm_clk_sig}]
//
//
// ■ UFMに書き込むデータ形式 
//
// UFMの先頭アドレスから下記データフレームを連続して書き込む。
// データフレームは32bitワード単位のデータブロック。
// 差分データフレームおよび即値データフレームは複数組み合わせて配置できる。
// 終了データフレームは最後に１つだけ配置する（配置した場所で展開を終了する）。
//
// ・差分データフレーム（１つ前との差分が+127～-128の範囲におさまるワード列）
//
// +0   : フレームヘッダ / bit31-29:000, bit28-17:reserve(0), bit16-0:格納ワード数(1～65536) 
// +4   : 初期値 / bit31-0:初期値 
// +8～ : 増分値 / bit7-0:ワード+1の増分値(符号付き8bit), bit15-8:ワード+2の増分値(〃), bit23-16:ワード+3, bit31-24:ワード+4
//        ※増分値データは必ず32bit境界に配置され、余るバイトは読み捨てられる
//
//
// ・即値データフレーム（32bitの即値ワード列）
//
// +0   : フレームヘッダ / bit31-29:010, bit28-17:reserve(0), bit16-0:格納ワード数(1～65536) 
// +4～ : 即値ワード / bit31-0:データ列 
//
//
// ・リピートデータフレーム（32bitのワードを繰り返す）
//
// +0   : フレームヘッダ / bit31-29:011, bit28-17:reserve(0), bit16-0:リピート数(1～65536) 
// +4   : リピートワード / bit31-0:データ列 
//
//
// ・終了データフレーム（初期化データの終了を示す）
//
// +0   : フレームヘッダ / bit31:1, bit30-0:X
//


`timescale 1ns / 100ps

module cerasite_loadinit (
	// Interface: clk
	input			clock,			// up to 58MHz
	input			reset,

	// Interface: initial data stream
	output [31:0]	data,
	output			datavalid,
	output			initdone
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam	STATE_START		= 5'd0,
				STATE_LOADCOUNT	= 5'd1,
				STATE_LOADINIT	= 5'd2,
				STATE_REPEAT	= 5'd3,
				STATE_ADD0		= 5'd4,
				STATE_ADD1		= 5'd5,
				STATE_ADD2		= 5'd6,
				STATE_ADD3		= 5'd7,
				STATE_DONE		= 5'd8;

	localparam	STATE_UFM_IDLE	= 5'd0,
				STATE_UFM_READ	= 5'd1,
				STATE_UFM_DATA	= 5'd2,
				STATE_UFM_DONE	= 5'd3;



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;		// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig /* synthesis keep = 1 */ = clock;		// モジュール内部駆動クロック 

	reg  [4:0]		state_reg;
	reg				readreq_reg;
	reg				imm32_reg;
	reg				rep_reg;
	reg  [11:0]		wordaddr_reg;
	reg  [15:0]		datacount_reg;
	reg  [31:0]		data_reg;
	reg				datavalid_reg;

	wire [13:0]		avs_address_sig;
	wire			avs_read_sig;
	wire			avs_waitrequest_sig;
	wire [31:0]		avs_readdata_sig;

	reg  [2:0]		divclock_reg;
	wire			ufm_clk_sig /* synthesis keep = 1 */;			// 分周クロックネット名を保持 
	reg				avs_readreq_reg;
	reg				avs_waitres_reg;
	reg  [4:0]		ufmstate_reg;
	reg  [31:0]		readdata_reg;

	wire [13:2]		ufm_address_sig;
	wire			ufm_read_sig;
	wire			ufm_waitreq_sig;
	wire [31:0]		ufm_readdata_sig;
	wire			ufm_readdatavalid_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	/***** 初期値データ復元 *****/

	assign avs_address_sig = {wordaddr_reg, 2'b00};
	assign avs_read_sig = readreq_reg;

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			state_reg <= STATE_START;
			readreq_reg <= 1'b0;
			imm32_reg <= 1'b0;
			rep_reg <= 1'b0;
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
					rep_reg <= avs_readdata_sig[29];
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
							if (rep_reg == 1'b0) begin
								state_reg <= STATE_LOADINIT;
							end
							else begin
								state_reg <= STATE_REPEAT;
								readreq_reg <= 1'b0;
							end
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

			STATE_REPEAT : begin
				if (datacount_reg == 16'd1) begin
					state_reg <= STATE_LOADCOUNT;
					readreq_reg <= 1'b1;
				end

				datacount_reg <= datacount_reg - 1'd1;
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



	/***** UFMアクセスモジュール(10M02用) *****/

	// 8分周クロックを生成 

	assign ufm_clk_sig = divclock_reg[2];

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			divclock_reg <= 1'd0;
		end
		else begin
			divclock_reg <= divclock_reg + 1'd1;
		end
	end


	// AVS側制御信号(Normally wait) 

	assign avs_waitrequest_sig = (avs_read_sig)? avs_waitres_reg : 1'b0;
	assign avs_readdata_sig = readdata_reg;

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			avs_readreq_reg <= 1'b0;
			avs_waitres_reg <= 1'b1;
		end
		else begin
			if (!avs_readreq_reg && ufmstate_reg == STATE_UFM_IDLE) begin
				avs_readreq_reg <= avs_read_sig;
			end
			else if (avs_readreq_reg && ufmstate_reg == STATE_UFM_DONE) begin
				avs_readreq_reg <= 1'b0;
			end

			if (avs_readreq_reg && ufmstate_reg == STATE_UFM_DONE) begin
				avs_waitres_reg <= 1'b0;
			end
			else begin
				avs_waitres_reg <= 1'b1;
			end
		end
	end


	// UFM側リードコントローラ 

	assign ufm_address_sig = avs_address_sig[13:2];
	assign ufm_read_sig = (ufmstate_reg == STATE_UFM_READ)? 1'b1 : 1'b0;

	always @(posedge ufm_clk_sig or posedge reset_sig) begin
		if (reset_sig) begin
			ufmstate_reg <= STATE_UFM_IDLE;
		end
		else begin
			case (ufmstate_reg)

			STATE_UFM_IDLE : begin
				if (avs_readreq_reg) begin
					ufmstate_reg <= STATE_UFM_READ;
				end
			end

			STATE_UFM_READ : begin
				if (!ufm_waitreq_sig) begin
					ufmstate_reg <= STATE_UFM_DATA;
				end
			end

			STATE_UFM_DATA : begin
				if (ufm_readdatavalid_sig) begin
					ufmstate_reg <= STATE_UFM_DONE;
					readdata_reg <= ufm_readdata_sig;
				end
			end

			STATE_UFM_DONE : begin
				if (!avs_readreq_reg) begin
					ufmstate_reg <= STATE_UFM_IDLE;
				end
			end

			endcase
		end
	end


	// UFMモジュールインスタンス 

	cerasite_ocflash
	u_ufm (
		.clock						( ufm_clk_sig ),
		.avmm_data_addr				( ufm_address_sig ),
		.avmm_data_read				( ufm_read_sig ),
		.avmm_data_readdata			( ufm_readdata_sig ),
		.avmm_data_waitrequest		( ufm_waitreq_sig ),
		.avmm_data_readdatavalid	( ufm_readdatavalid_sig ),
		.avmm_data_burstcount		( 2'd1 ),
		.reset_n					( ~reset_sig )
	);



endmodule
