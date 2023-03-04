/**   
 * execute.v
 * -------------------------
 * This is the EXECUTE stage of the pipeline. Bypassing is performed here 
 * alongside execution of instructions that require the ALU functional unit.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module execute(reset, clk, NEXT_PC, EX_CTRL, 
    MEM_CTRL, WB_CTRL, flush, cache_stall, RT, RD, RS_DATA,
    RT_DATA, IMM_DATA, prediction, ALU_FUNCT, MEM_DATA, WB_DATA,
    BYPASS_1, BYPASS_2, REG_ALU_OUT, REG_RT_DATA, WRITE_REG,
    REG_WRITE_REG, REG_MEM_CTRL, REG_WB_CTRL, is_reg_write,
    reg_prediction, REG_PC, REG_RECOVER_TAKEN, REG_RECOVER_NOT_TAKEN);
   
    input reset, clk;
    input [31:0] NEXT_PC;
    input [1:0] EX_CTRL;
    input [3:0] MEM_CTRL;
    input [1:0] WB_CTRL;
    input flush, cache_stall, prediction;
    input [4:0] RT, RD;
    input [31:0] RS_DATA, RT_DATA;
    input signed [31:0] IMM_DATA;
    input [3:0] ALU_FUNCT;
    input [31:0] MEM_DATA, WB_DATA;
    input [1:0] BYPASS_1, BYPASS_2;
    output reg [31:0] REG_ALU_OUT;
    output reg [31:0] REG_RT_DATA;
    output [4:0] WRITE_REG;
    output is_reg_write;
    output reg [4:0] REG_WRITE_REG;
    output reg [3:0] REG_MEM_CTRL;
    output reg [1:0] REG_WB_CTRL;
    output reg reg_prediction;
    output reg [31:0] REG_RECOVER_TAKEN, REG_RECOVER_NOT_TAKEN;
    output reg [31:0] REG_PC;

    wire is_immediate, is_r_format;
    wire [31:0] ALU_OUT;

    //signed declaration needed because ALU peforms comparisons
    wire signed [31:0] ALU_OP_1, ALU_OP_2, ALU_OP_3;
    wire [31:0] PC_INCR;

    //we need an additional wire to represent the current PC + 4.
    //one might think the NEXT_PC signal would suffice, but it doesnt.
    //this is because NEXT_PC might be the PC obtained through a branch
    //that was predicted taken.
    //PC_INCR will be used to restore PC to its proper state in case of
    //misprediction.
    assign PC_INCR = REG_PC + 3'd4;

    assign is_r_format = EX_CTRL[0];
    assign is_immediate = EX_CTRL[1];
    assign is_reg_write = WB_CTRL[1];

    //both RD and RT are valid registers to be written to.
    assign WRITE_REG = (is_r_format == 1'b1) ? RD : RT;

    bypass_path bypass_path_1(
        .BYPASS_PATH_SEL(BYPASS_1),
        .REG_DATA(RS_DATA),
        .MEM_DATA(MEM_DATA),
        .WB_DATA(WB_DATA),
        .RETURN_OP(ALU_OP_1)
    );

    bypass_path bypass_path_2(
        .BYPASS_PATH_SEL(BYPASS_2),
        .REG_DATA(RT_DATA),
        .MEM_DATA(MEM_DATA),
        .WB_DATA(WB_DATA),
        .RETURN_OP(ALU_OP_2)
    );

    //ALU operations don't have to involve just RS and RT. They can also
    //involve RS and Imm, so we need to determine whether it will be RT or
    //Imm that comes into play. This is why we need the is_immediate signal.
    //In the case that the Imm data is needed, ALU_OP_2 is still needed
    //data. Store instruction uses it.
    assign ALU_OP_3 = (is_immediate == 1'b1) ? IMM_DATA : ALU_OP_2;

    //organized by priority
    always @(posedge clk)
        if(reset || flush)
        begin
            REG_PC <= 32'd0;
            REG_MEM_CTRL <= 4'd0;
            REG_WB_CTRL <= 2'd0;
            reg_prediction <= 1'b0;
            REG_ALU_OUT <= 32'd0;
            REG_WRITE_REG <= 32'd0;
            REG_RT_DATA <= 32'd0;
            REG_RECOVER_TAKEN <= 32'd0;
            REG_RECOVER_NOT_TAKEN <= 32'd0;
        end
        else if(cache_stall)
        begin
            REG_PC <= REG_PC;
            REG_MEM_CTRL <= REG_MEM_CTRL;
            REG_WB_CTRL <= REG_WB_CTRL;
            reg_prediction <= reg_prediction;
            REG_ALU_OUT <= REG_ALU_OUT;
            REG_WRITE_REG <= REG_WRITE_REG;
            REG_RT_DATA <= REG_RT_DATA;
            REG_RECOVER_TAKEN <= REG_RECOVER_TAKEN;
            REG_RECOVER_NOT_TAKEN <= REG_RECOVER_NOT_TAKEN;
        end
        else
        begin
            REG_PC <= NEXT_PC;
            REG_MEM_CTRL <= MEM_CTRL;
            REG_WB_CTRL <= WB_CTRL;
            reg_prediction <= prediction;
            REG_ALU_OUT <= ALU_OUT;
            REG_WRITE_REG <= WRITE_REG;
            REG_RT_DATA <= ALU_OP_2;
            //immediate field contains the distance in words between PC + 4
            //and branch target address (target - (pc + 4) = imm)
            REG_RECOVER_TAKEN <= PC_INCR + (IMM_DATA << 3'd4);
            REG_RECOVER_NOT_TAKEN <= PC_INCR;
        end

    ALU ALU_UNIT(
        .OP1(ALU_OP_1),
        .OP2(ALU_OP_3),
        .FUNCT(ALU_FUNCT),
        .OUT(ALU_OUT)
    );

endmodule