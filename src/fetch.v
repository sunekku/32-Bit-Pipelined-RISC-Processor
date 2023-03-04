/**   
 * fetch.v
 * -------------------------
 * This is the FETCH stage of the pipeline. Branch predictions are 
 * made here alongside baseline incrementation of the program counter
 * to fetch future instructions. A variety of parameters are propagated
 * along the pipeline from the FETCH stage. Recovery from branch
 * mispredictions is also handled here.
 */

/* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module fetch (reset, clk, INSTRUCTION, hazard_stall, cache_stall, flush, 
    branch_result, RECOVER_TAKEN, RECOVER_NOT_TAKEN, bpt_write_enable, BPT_WRITE_ADDR, 
    BPT_DATA_IN, reg_prediction, REG_PC, REG_INSTRUCTION);

    input reset, clk; 
    input [31:0] INSTRUCTION;
    input hazard_stall, cache_stall, flush;
    input branch_result;
    input [31:0] RECOVER_TAKEN, RECOVER_NOT_TAKEN;  //recovery addresses in case of mispredictions
    input bpt_write_enable;
    input [7:0] BPT_WRITE_ADDR;
    input [32:0] BPT_DATA_IN;
    output reg reg_prediction;
    output reg [31:0] REG_PC, REG_INSTRUCTION;

    reg [31:0] NEXT_PC;
    wire is_branch;

    wire [7:0] BPT_READ_ADDR;
    wire [32:0] BPT_DATA_OUT;

    wire prediction;
    wire [31:0] BRANCH_TARGET;

    assign is_branch = (INSTRUCTION[31:26] == `OPCODE_BEQ) | (INSTRUCTION[31:26] == `OPCODE_BNE);

    always @(*)
        if(flush)   //a flush signal necessarily means that a branch instruction was mispredicted; recovery is needed
            if(branch_result == `TAKEN)
                NEXT_PC = RECOVER_TAKEN;
            else
                NEXT_PC = RECOVER_NOT_TAKEN;
        else
            NEXT_PC = REG_PC + 3'd4;
    
    //perform prediction and update the bpt state machine with a new branch result
    //no need to check if instruction is a branch before making a prediction
    //this is because making a prediction costs no clock cycles, and because we
    //treat the prediction as valid only if the current instruction is a branch
    //see line #91
    bpt BPT (
        .reset(reset),
        .clk(clk),
        .write_enable(bpt_write_enable),
        .WRITE_ADDR(BPT_READ_ADDR),
        .DATA_IN(BPT_DATA_IN),
        .READ_ADDR(BPT_READ_ADDR),
        .DATA_OUT(BPT_DATA_OUT)
    );

    assign BPT_READ_ADDR = REG_PC[5:0];
    assign prediction = BPT_DATA_OUT[0];
    assign BRANCH_TARGET = BPT_DATA_OUT[32:1];

    //truth be told, it doesnt matter whether the order for the flush and 
    //cache stall checks are swapped. the reason is because if a flush signal
    //is missed here because a cache stall was detected first, MEMORY will be held
    //up by the same cache stall, and it is what produces the flush signal, so the
    //flush signal will continue to be asserted. then, when cache stall signal goes off
    //flush will be asserted, and EXECUTE and other stages will be able to detect it.

    //it absolutely matters for hazard stalls though, since MEMORY stage isnt affected by
    //hazard stalls, so extra caution is advised when doing things like this
    always @(posedge clk)
        if(reset)
        begin
            REG_PC <= 32'd0;
            REG_INSTRUCTION <= `NOP;
            reg_prediction <= 1'd0;
        end
        //reset takes priority, so we want the reset and remaining conditions to be
        //mutually exclusive in a cycle
        //everything is similarly organized by priority in this block
        else if(flush)
        begin
            REG_PC <= NEXT_PC;   //NEXT_PC contains the recovered PC
            REG_INSTRUCTION <= `NOP;
            reg_prediction <= 1'd0;
        end
        else if(hazard_stall || cache_stall)
        begin
            REG_PC <= REG_PC;
            REG_INSTRUCTION <= REG_INSTRUCTION;
            reg_prediction <= reg_prediction;
        end
        else if(is_branch && prediction == `TAKEN)
        begin
            REG_PC <= BRANCH_TARGET;
            REG_INSTRUCTION <= INSTRUCTION;
            reg_prediction <= prediction;
        end
        else
        begin
            REG_PC <= NEXT_PC;
            REG_INSTRUCTION <= INSTRUCTION;
            reg_prediction <= prediction;
        end

endmodule
