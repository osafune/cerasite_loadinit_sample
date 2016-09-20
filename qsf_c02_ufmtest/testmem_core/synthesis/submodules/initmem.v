// ===================================================================
// TITLE : CERASITE / Memory initialize test
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

`timescale 1ns / 100ps

module initmem (

	// Interface: clk
	input			csi_s1_clock,			// up to 58MHz
	input			rsi_s1_reset,

	// Interface: avs (ROM)
	input  [11:0]	avs_s1_address,
	input			avs_s1_read,
	output [31:0]	avs_s1_readdata,		// 読み出しは１クロックレイテンシ 

	// Interface: condit
	output			coe_initdone
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = rsi_s1_reset;		// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = csi_s1_clock;		// モジュール内部駆動クロック 

	reg  [11:0]		wordnum_reg;
	wire [31:0]		loaddata_sig;
	wire			loaddatavalid_sig;
	wire [9:0]		memaddr_sig;
	wire [31:0]		memdata_sig;
	wire			memwren_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	// 初期化モジュールインスタンス 

	cerasite_loadinit
	u_load (
		.clock		( clock_sig ),
		.reset		( reset_sig ),
		.data		( loaddata_sig ),
		.datavalid	( loaddatavalid_sig ),
		.initdone	( coe_initdone )
	);

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			wordnum_reg <= 1'd0;
		end
		else begin
			if (loaddatavalid_sig) begin
				wordnum_reg <= wordnum_reg + 1'd1;
			end
		end
	end

	assign memaddr_sig = wordnum_reg[9:0];
	assign memdata_sig = loaddata_sig[31:0];
	assign memwren_sig = loaddatavalid_sig;


	// メモリインスタンス (32bit×1024ワード) 

	test_mem 
	u_rom (
		.rdclock	( clock_sig ),
		.rdclocken	( 1'b1 ),
		.rdaddress	( avs_s1_address[11:2] ),
		.q			( avs_s1_readdata ),

		.wrclock	( clock_sig ),
		.wrclocken	( 1'b1 ),
		.wraddress	( memaddr_sig ),
		.data		( memdata_sig ),
		.wren		( memwren_sig )
	);



endmodule
