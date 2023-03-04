/**   
 * wb.v
 * -------------------------
 * This is the WRITEBACK stage of the pipeline. Register values are sent to DECODE for
 * writing purposes.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module wb(WB_CTRL, ALU_OUT, MEM_OUT, WRITEBACK_DATA, is_reg_write);

    input [1:0] WB_CTRL;
    input [31:0] ALU_OUT, MEM_OUT;
    output [31:0] WRITEBACK_DATA;
    output is_reg_write;

    assign WRITEBACK_DATA = (WB_CTRL[0] == 1'b1) ? MEM_OUT : ALU_OUT;
    assign is_reg_write = WB_CTRL[1];

endmodule