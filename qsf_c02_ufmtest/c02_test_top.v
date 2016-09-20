// ===================================================================
// TITLE : C-02 Initmem test top
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
//   DATE   : 2016/09/19 -> 2016/09/19
//   UPDATE : 
//
// ===================================================================
// *******************************************************************
//   Copyright (C) 2016 J-7SYSTEM WORKS LIMITED. All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

`timescale 1ns / 100ps

module c02_test_top (
	input			CLOCK_50,
	output			OSC_OE,
//	input			RESET_n,
	output			LED,

	output			TXD,
	input			RXD
);

	assign OSC_OE = 1'b1;

    testmem_core u0 (
        .clk_clk       ( CLOCK_50 ),
        .reset_reset_n ( 1'b1 ),
        .uart_rxd      ( RXD ),
        .uart_txd      ( TXD ),
        .coe_initdone  ( LED )
    );



endmodule
