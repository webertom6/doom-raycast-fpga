//lpm_divide CBX_SINGLE_OUTPUT_FILE="ON" LPM_DREPRESENTATION="SIGNED" LPM_HINT="LPM_REMAINDERPOSITIVE=TRUE" LPM_NREPRESENTATION="SIGNED" LPM_PIPELINE=100 LPM_TYPE="LPM_DIVIDE" LPM_WIDTHD=64 LPM_WIDTHN=64 clock denom numer quotient remain
//VERSION_BEGIN 23.1 cbx_mgl 2024:05:14:17:57:46:SC cbx_stratixii 2024:05:14:17:57:38:SC cbx_util_mgl 2024:05:14:17:57:38:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2024  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.



//synthesis_resources = lpm_divide 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mgg5m
	( 
	clock,
	denom,
	numer,
	quotient,
	remain) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   [63:0]  denom;
	input   [63:0]  numer;
	output   [63:0]  quotient;
	output   [63:0]  remain;

	wire  [63:0]   wire_mgl_prim1_quotient;
	wire  [63:0]   wire_mgl_prim1_remain;

	lpm_divide   mgl_prim1
	( 
	.clock(clock),
	.denom(denom),
	.numer(numer),
	.quotient(wire_mgl_prim1_quotient),
	.remain(wire_mgl_prim1_remain));
	defparam
		mgl_prim1.lpm_drepresentation = "SIGNED",
		mgl_prim1.lpm_nrepresentation = "SIGNED",
		mgl_prim1.lpm_pipeline = 100,
		mgl_prim1.lpm_type = "LPM_DIVIDE",
		mgl_prim1.lpm_widthd = 64,
		mgl_prim1.lpm_widthn = 64,
		mgl_prim1.lpm_hint = "LPM_REMAINDERPOSITIVE=TRUE";
	assign
		quotient = wire_mgl_prim1_quotient,
		remain = wire_mgl_prim1_remain;
endmodule //mgg5m
//VALID FILE
