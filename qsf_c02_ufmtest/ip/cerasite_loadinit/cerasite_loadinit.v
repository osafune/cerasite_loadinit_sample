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
// +0   : フレームヘッダ / bit31:0, bit30:0, bit29-17:reserve(0), bit16-0:格納ワード数(1～65536) 
// +4   : 初期値 / bit31-0:初期値 
// +8～ : 増分値 / bit7-0:ワード+1の増分値(符号付き8bit), bit15-8:ワード+2の増分値(〃), bit23-16:ワード+3, bit31-24:ワード+4
//        ※増分値データは必ず32bit境界に配置され、余るバイトは読み捨てられる
//
//
// ・即値データフレーム（32bitのワード列）
//
// +0   : フレームヘッダ / bit31:0, bit30:1, bit29-17:reserve(0), bit16-0:格納ワード数(1～65536) 
// +4～ : 即値ワード / bit31-0:データ列 
// 
//
// ・終了データフレーム（初期化データの終了を示す）
//
// +0   : フレームヘッダ / bit31:1, bit30-0:X
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


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam	STATE_START		= 5'd0,
				STATE_LOADCOUNT	= 5'd1,
				STATE_LOADINIT	= 5'd2,
				STATE_ADD0		= 5'd3,
				STATE_ADD1		= 5'd4,
				STATE_ADD2		= 5'd5,
				STATE_ADD3		= 5'd6,
				STATE_DONE		= 5'd7;


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;		// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig /* synthesis keep = 1 */ = clock;		// モジュール内部駆動クロック 

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
	wire			ufm_clk_sig /* synthesis keep = 1 */;			// 分周クロックネット名を保持 
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



/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */
/*
	assign test_ufm_clk = ufm_clk_sig;
	assign test_ufm_address = {ufm_address_sig, 2'b00};
	assign test_ufm_read = ufm_read_reg;
	assign ufm_readdata_sig = test_ufm_readdata;
	assign ufm_readdatavalid_sig = test_ufm_readdatavalid;
	assign ufm_waitres_sig = test_ufm_waitres;
*/

/* ===== モジュール構造記述 ============== */

	/***** 初期値データ復元 *****/

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



	/***** UFMアクセスモジュール(10M02用) *****/

	// 制御信号 

	assign ufm_address_sig = avs_address_sig[13:2];
	assign ufm_readreq_sig = avs_read_sig;
	assign avs_readdata_sig = ufm_readdata_reg;
	assign avs_waitrequest_sig = ufm_waitreq_sig;


	// 8分周クロックを生成 

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			divclock_reg <= 1'd0;
		end
		else begin
			divclock_reg <= divclock_reg + 1'd1;
		end
	end

	assign ufm_clk_sig = divclock_reg[2];
	assign ufm_clkena_sig = (divclock_reg == 3'b000)? 1'b1 : 1'b0;	// クロック周期の中間地点をデータウィンドウにする 


	// UFMリードコントローラ 

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


	// UFMモジュールインスタンス 

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
