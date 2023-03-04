/**   
 * pipelined_cpu.v
 * -------------------------
 * This is the pipeline.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module pipelined_cpu(reset, clk, INSTRUCTION, ext_cache_stall, EXT_MEM_OUT,
    PC, read_en, write_en, EXT_MEM_IN, EXT_ADDR, ext_reset, ext_clk);

    input reset, clk;
    input [31:0] INSTRUCTION;
    input ext_cache_stall;
    input [31:0] EXT_MEM_OUT;
    output [31:0] PC;
    output read_en, write_en;
    output [31:0] EXT_MEM_IN, EXT_ADDR;
    output ext_reset, ext_clk;

    //processor interconnect
    wire [31:0] IF_REG_PC;
    wire [31:0] IF_REG_INSTRUCTION;
    wire if_reg_prediction;

    wire [31:0] ID_REG_INSTRUCTION;
    wire [31:0] ID_REG_RS_DATA;
    wire [31:0] ID_REG_RT_DATA;
    wire [31:0] ID_REG_IMM_DATA;
    wire [4:0] ID_REG_RT;
    wire [4:0] ID_REG_RD;
    wire [31:0] ID_REG_PC;
    wire [1:0] ID_REG_EX_CTRL;
    wire [3:0] ID_REG_MEM_CTRL;
    wire [1:0] ID_REG_WB_CTRL;
    wire hazard_stall;
    wire [1:0] ID_REG_BYPASS_1;
    wire [1:0] ID_REG_BYPASS_2;
    wire [3:0] ID_REG_ALU_FUNCT;
    wire id_reg_prediction;
   
    wire [4:0] EX_REG_WRITE_REG;
    wire [3:0] EX_REG_MEM_CTRL;
    wire [1:0] EX_REG_WB_CTRL;
    wire [4:0] EX_WRITE_REG;
    wire is_reg_write_ex;
    wire [31:0] EX_REG_ALU_OUT;
    wire [31:0] EX_REG_RT_DATA;
    wire [31:0] EX_REG_PC;
    wire ex_reg_prediction;

    wire [1:0] MEM_REG_WB_CTRL;
    wire [31:0] RECOVER_TAKEN;
    wire [31:0] RECOVER_NOT_TAKEN;
    wire [31:0] MEM_REG_MEM_OUT;
    wire [31:0] MEM_REG_ALU_OUT;
    wire [4:0] MEM_REG_WRITE_REG;
    wire branch_result;
    wire flush;
    wire cache_stall;
    wire bpt_write_enable;
    wire [7:0] BPT_WRITE_ADDR;
    wire [32:0] BPT_DATA_IN;

    wire [31:0] WRITEBACK_DATA;
    wire is_reg_write_wb;

    assign PC = IF_REG_PC;
    assign ext_clk = clk;
    assign ext_reset = reset;

    fetch FETCH_STAGE(
        .reset(reset),
        .clk(clk),
        .INSTRUCTION(INSTRUCTION),
        .hazard_stall(hazard_stall),
        .cache_stall(cache_stall),
        .flush(flush),
        .branch_result(branch_result),
        .RECOVER_TAKEN(RECOVER_TAKEN),
        .RECOVER_NOT_TAKEN(RECOVER_NOT_TAKEN),
        .bpt_write_enable(bpt_write_enable),
        .BPT_WRITE_ADDR(BPT_WRITE_ADDR),
        .BPT_DATA_IN(BPT_DATA_IN),
        .reg_prediction(if_reg_prediction),
        .REG_PC(IF_REG_PC),
        .REG_INSTRUCTION(IF_REG_INSTRUCTION)
    );

    decode DECODE_STAGE(
        .reset(reset),
        .clk(clk),
        .NEXT_PC(IF_REG_PC),
        .INSTRUCTION(IF_REG_INSTRUCTION),
        .is_reg_write_wb(is_reg_write_wb),
        .WRITEBACK_REG(MEM_REG_WRITE_REG),
        .WRITEBACK_DATA(WRITEBACK_DATA),
        .flush(flush),
        .cache_stall(cache_stall),
        .EX_WRITE_REG(EX_WRITE_REG),
        .is_reg_write_ex(is_reg_write_ex),
        .MEM_WRITE_REG(EX_REG_WRITE_REG),
        .is_reg_write_mem(EX_REG_WB_CTRL[1]),
        .prediction(if_reg_prediction),
        .reg_prediction(id_reg_prediction),
        .hazard_stall(hazard_stall),
        .REG_BYPASS_1(ID_REG_BYPASS_1),
        .REG_BYPASS_2(ID_REG_BYPASS_2),
        .REG_ALU_FUNCT(ID_REG_ALU_FUNCT),
        .REG_RT(ID_REG_RT),
        .REG_RD(ID_REG_RD),
        .REG_RS_DATA(ID_REG_RS_DATA),
        .REG_RT_DATA(ID_REG_RT_DATA),
        .REG_IMM_DATA(ID_REG_IMM_DATA),
        .REG_PC(ID_REG_PC),
        .REG_EX_CTRL(ID_REG_EX_CTRL),
        .REG_MEM_CTRL(ID_REG_MEM_CTRL),
        .REG_WB_CTRL(ID_REG_WB_CTRL),
    );

    execute EXECUTE_STAGE(
        .reset(reset),
        .clk(clk),
        .NEXT_PC(ID_REG_PC),
        .EX_CTRL(ID_REG_EX_CTRL),
        .MEM_CTRL(ID_REG_MEM_CTRL),
        .WB_CTRL(ID_REG_WB_CTRL),
        .flush(flush),
        .cache_stall(cache_stall),
        .RT(ID_REG_RT),
        .RD(ID_REG_RD),
        .RS_DATA(ID_REG_RS_DATA),
        .RT_DATA(ID_REG_RT_DATA),
        .IMM_DATA(ID_REG_IMM_DATA),
        .prediction(id_reg_prediction),
        .ALU_FUNCT(ID_REG_ALU_FUNCT),
        .MEM_DATA(EX_REG_ALU_OUT),
        .WB_DATA(WRITEBACK_DATA),
        .BYPASS_1(ID_REG_BYPASS_1),
        .BYPASS_2(ID_REG_BYPASS_2),
        .REG_ALU_OUT(EX_REG_ALU_OUT),
        .REG_RT_DATA(EX_REG_RT_DATA),
        .WRITE_REG(EX_WRITE_REG),
        .REG_WRITE_REG(EX_REG_WRITE_REG),
        .REG_MEM_CTRL(EX_REG_MEM_CTRL),
        .REG_WB_CTRL(EX_REG_WB_CTRL),
        .is_reg_write(is_reg_write_ex),
        .reg_prediction(ex_reg_prediction),
        .REG_PC(EX_REG_PC),
        .REG_RECOVER_TAKEN(RECOVER_TAKEN),
        .REG_RECOVER_NOT_TAKEN(RECOVER_NOT_TAKEN)
    );

    mem MEMORY_STAGE(
        .reset(reset),
        .clk(clk),
        .NEXT_PC(EX_REG_PC),
        .MEM_CTRL(EX_REG_MEM_CTRL),
        .WB_CTRL(EX_REG_WB_CTRL),
        .RT_DATA(EX_REG_RT_DATA),
        .ALU_OUT(EX_REG_ALU_OUT),
        .RECOVER_TAKEN(RECOVER_TAKEN),
        .ext_cache_stall(ext_cache_stall),
        .prediction(ex_reg_prediction),
        .EXT_MEM_OUT(EXT_MEM_OUT),
        .WRITE_REG(EX_REG_WRITE_REG),
        .branch_result(branch_result),
        .flush(flush),
        .cache_stall(cache_stall),
        .REG_MEM_OUT(MEM_REG_MEM_OUT),
        .REG_ALU_OUT(MEM_REG_ALU_OUT),
        .REG_WRITE_REG(MEM_REG_WRITE_REG),
        .REG_WB_CTRL(MEM_REG_WB_CTRL),
        .BPT_WRITE_ADDR(BPT_WRITE_ADDR),
        .bpt_write_enable(bpt_write_enable),
        .BPT_DATA_IN(BPT_DATA_IN),
        .read_en(read_en),
        .write_en(write_en),
        .EXT_MEM_IN(EXT_MEM_IN),
        .EXT_ADDR(EXT_ADDR)
    );

    wb WRITEBACK_STAGE(
        .WB_CTRL(MEM_REG_WB_CTRL),
        .ALU_OUT(MEM_REG_ALU_OUT),
        .MEM_OUT(MEM_REG_MEM_OUT),
        .WRITEBACK_DATA(WRITEBACK_DATA),
        .is_reg_write(is_reg_write_wb) 
    );

endmodule



