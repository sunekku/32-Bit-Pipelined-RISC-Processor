`define NOP 32'h0
`define	OPCODE_BEQ 6'b000100
`define	OPCODE_BNE 6'b000101
`define	BEQ 2'b01
`define BNE 2'b10

`define R_FORMAT 6'b000000
`define OPCODE_LW 6'b100011
`define	OPCODE_SW 6'b101011
`define OPCODE_IMM 3'b001

`define	ADD	4'b0010
`define	SUB 4'b0011
`define	AND 4'b0000
`define	OR 4'b0001
`define	SLT	4'b0100
`define	NOR	4'b0101
`define	XOR	4'b0110
`define	LU	4'b0111
`define	SLLV 4'b1000
`define	SRLV 4'b1001	

`define	R_FORMAT_AND 6'b100100
`define	R_FORMAT_OR	6'b100101
`define	R_FORMAT_ADD 6'b100000
`define	R_FORMAT_SUB 6'b100010
`define	R_FORMAT_SLT 6'b101010
`define	R_FORMAT_NOR 6'b100111
`define	R_FORMAT_SLLV 6'b000100
`define	R_FORMAT_SRLV 6'b000110

`define	OPCODE_ADDI 6'b001000
`define	OPCODE_ANDI 6'b001100
`define	OPCODE_ORI 6'b001101
`define	OPCODE_XORI 6'b001110
`define	OPCODE_LUI 6'b001111

`define TAKEN 1'b1
`define NOT_TAKEN 1'b0