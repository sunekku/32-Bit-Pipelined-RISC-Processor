/**   
 * decode_ctrl.v
 * -------------------------
 * These are utility modules for the DECODE stage that enable the generation
 * of control signals for the remaining stages in the pipeline.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITIONS */
module CPU_ctrl(INSTRUCTION, is_reg_write, BRANCH_OP, is_mem_read,
    is_mem_write, is_immediate, is_r_format);

    input [31:0] INSTRUCTION;
    output is_mem_read, is_mem_write, is_r_format;
	 output reg is_immediate, is_reg_write;
    output reg [1:0] BRANCH_OP;

    wire [5:0] OPCODE;

    assign OPCODE = INSTRUCTION[31:26];
    assign is_r_format = (OPCODE == `R_FORMAT) ? 1'b1 : 1'b0;
    assign is_mem_read = (OPCODE == `OPCODE_LW) ? 1'b1 : 1'b0;
    assign is_mem_write = (OPCODE == `OPCODE_SW) ? 1'b1 : 1'b0;

    always @(*)
    begin
        //no need to check for NOP instruction because a NOP is necessarily accompanied by
        //a reset of all control registers.
        if(OPCODE[5:3] == `OPCODE_IMM || OPCODE == `OPCODE_LW || OPCODE == `OPCODE_SW)
            is_immediate = 1'b1;
        else 
            is_immediate = 1'b0;

        if(OPCODE == `OPCODE_BNE)
            BRANCH_OP = `BNE;
        else if(OPCODE == `OPCODE_BEQ)
            BRANCH_OP = `BEQ;
        else
            BRANCH_OP = 2'd0;

        if(OPCODE[5:3] == `OPCODE_IMM || OPCODE == `OPCODE_LW || OPCODE == `R_FORMAT)
            is_reg_write = 1'b1;
        else
            is_reg_write = 1'b0;
    end

endmodule

//create signals for the ALU to use
module ALU_decode(OPCODE, FUNCT, ALU_FUNCT);

    input [5:0] OPCODE, FUNCT;
    output reg [1:0] ALU_FUNCT;

    always @(*)
        case(OPCODE)
            `OPCODE_BEQ: ALU_FUNCT = `SUB;
            `OPCODE_BNE: ALU_FUNCT = `SUB;
            `R_FORMAT:
                case(FUNCT)
                    `R_FORMAT_ADD: ALU_FUNCT = `ADD;
                    `R_FORMAT_SUB: ALU_FUNCT = `SUB;
                    `R_FORMAT_AND: ALU_FUNCT = `AND;
                    `R_FORMAT_OR: ALU_FUNCT = `OR;
                    `R_FORMAT_NOR: ALU_FUNCT = `NOR;
                    `R_FORMAT_SLT: ALU_FUNCT = `SLT;
                    `R_FORMAT_SLLV: ALU_FUNCT = `SLLV;
                    `R_FORMAT_SRLV: ALU_FUNCT = `SRLV;
                    default: ALU_FUNCT = 4'bxxxx;
                endcase
            default:
                if(OPCODE[5:3] == `OPCODE_IMM)
                    case(OPCODE)
                        `OPCODE_ADDI: ALU_FUNCT = `ADD;
                        `OPCODE_ANDI: ALU_FUNCT = `AND;
                        `OPCODE_ORI: ALU_FUNCT = `OR;
                        `OPCODE_XORI: ALU_FUNCT = `XOR;
                        `OPCODE_LUI: ALU_FUNCT = `LU;
                        default: ALU_FUNCT = 4'bxxxx;
                    endcase
                else
                    ALU_FUNCT = `ADD;
        endcase

endmodule

//detect need for bypass.
//signals will be used in the EXECUTE stage to actually perform the bypasses.
module bypass_ctrl(DECODE_RS, DECODE_RT, EXECUTE_RD, MEMORY_RD,
                    is_reg_write_ex, is_reg_write_mem, BYPASS_1, BYPASS_2);
    
    input [4:0] DECODE_RS, DECODE_RT, EXECUTE_RD, MEMORY_RD;
    input is_reg_write_ex, is_reg_write_mem;
    output [1:0] BYPASS_1, BYPASS_2;

    wire bypass_1_ex_mem, bypass_1_mem_wb, bypass_2_ex_mem, bypass_2_mem_wb;

    assign bypass_1_ex_mem = (is_reg_write_ex == 1'b1) && (EXECUTE_RD == DECODE_RS);
    assign bypass_1_mem_wb = (is_reg_write_mem == 1'b1) && (MEMORY_RD == DECODE_RS);

    assign bypass_2_ex_mem = (is_reg_write_ex == 1'b1) && (EXECUTE_RD == DECODE_RT);
    assign bypass_2_mem_wb = (is_reg_write_mem == 1'b1) && (MEMORY_RD == DECODE_RT);

    assign BYPASS_1 = BYPASS(bypass_1_ex_mem, bypass_1_mem_wb);
    assign BYPASS_2 = BYPASS(bypass_2_ex_mem, bypass_2_mem_wb);

    function [1:0] BYPASS;
        input bypass_ex_mem, bypass_mem_wb;
        if(bypass_ex_mem)
            BYPASS = 2'd1;
        else if(bypass_mem_wb)
            BYPASS = 2'd2;
        else
            BYPASS = 2'd0;
    endfunction

endmodule





