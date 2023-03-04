/**   
 * execute_utils.v
 * -------------------------
 * These are utility modules for the EXECUTE stage that enable the generation
 * of ALU output and forwarding.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITIONS */
module bypass_path(BYPASS_PATH_SEL, REG_DATA, MEM_DATA, WB_DATA, RETURN_OP);
    
    input [31:0] REG_DATA, MEM_DATA, WB_DATA;
    input [1:0] BYPASS_PATH_SEL;
    output reg [31:0] RETURN_OP;

    always @(*)
        case(BYPASS_PATH_SEL)
            2'd0: RETURN_OP = REG_DATA;
            2'd1: RETURN_OP = MEM_DATA;
            2'd2: RETURN_OP = WB_DATA;
            default: RETURN_OP = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;  //this case should never be reached
        endcase                                                         //this is here to prevent latch synthesis

endmodule

module ALU(OP1, OP2, FUNCT, OUT);

    input signed [31:0] OP1, OP2;
    input [3:0] FUNCT;
    output reg signed [31:0] OUT;

	 always @(*)
		 case(FUNCT)
			  `ADD: OUT = OP1 + OP2;
			  `SUB: OUT = OP1 - OP2;
			  `AND: OUT = OP1 & OP2;
			  `OR: OUT = OP1 | OP2;
			  `NOR: OUT = ~(OP1 & OP2);
			  `XOR: OUT = OP1 ^ OP2;
			  `LU: OUT = {OP2[15:0], 16'd0};
			  `SLT: OUT = (OP1 < OP2) ? 32'd1 : 32'd0;
			  `SLLV: OUT = OP1 << OP2[5:0];
			  `SRLV: OUT = OP1 >> OP2[5:0];
			  default: OUT = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; //anti latch
		 endcase

endmodule