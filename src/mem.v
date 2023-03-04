/**   
 * mem.v
 * -------------------------
 * This is the MEMORY stage of the pipeline. Branches are verified here, and 
 * recovery addresses are issued to the FETCH stage in case of misprediction.
 * Data is also written to an external cache here.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module mem(reset, clk, NEXT_PC, MEM_CTRL, WB_CTRL,
    RT_DATA, ALU_OUT, RECOVER_TAKEN, ext_cache_stall, prediction, 
    EXT_MEM_OUT, WRITE_REG, branch_result, flush, cache_stall,
    REG_MEM_OUT, REG_ALU_OUT, REG_WRITE_REG, REG_WB_CTRL,
    BPT_WRITE_ADDR, bpt_write_enable, BPT_DATA_IN, read_en, write_en,
    EXT_MEM_IN, EXT_ADDR);

    input reset, clk;
    input [31:0] NEXT_PC;
    input [3:0] MEM_CTRL;
    input [1:0] WB_CTRL;
    input [31:0] RT_DATA;
    input [31:0] ALU_OUT;
    input [31:0] RECOVER_TAKEN;
    input prediction;
    input [4:0] WRITE_REG;
    input ext_cache_stall; //external mem return
    input [31:0] EXT_MEM_OUT; //external mem return
    output branch_result, cache_stall;
    output reg flush;
    output reg [31:0] REG_MEM_OUT;
    output reg [31:0] REG_ALU_OUT;
    output reg [4:0] REG_WRITE_REG;
    output reg [1:0] REG_WB_CTRL;
    output [7:0] BPT_WRITE_ADDR;
    output bpt_write_enable;
    output [32:0] BPT_DATA_IN;
    //some outputs to external cache
    output read_en, write_en;
    output [31:0] EXT_MEM_IN;
    output [31:0] EXT_ADDR;

    wire [1:0] BRANCH_OP;
    
    wire[31:0] MEM_OUT;
    reg [31:0] REG_PC;

    assign BRANCH_OP = MEM_CTRL[3:2];
    assign is_mem_read = MEM_CTRL[0];
    assign is_mem_write = MEM_CTRL[1];

    //we discard the first two bits because they are all the same, so 
    //indexing with them would not be very productive
    assign BPT_WRITE_ADDR = REG_PC[9:2];
    assign BPT_DATA_IN = {RECOVER_TAKEN, branch_result};
    assign bpt_write_enable = (BRANCH_OP == `BEQ) | (BRANCH_OP == `BNE);

    //interface with external cache
    assign cache_stall = (ext_cache_stall == 1'b1);
    assign MEM_OUT = EXT_MEM_OUT;
    assign EXT_MEM_IN = RT_DATA;
    assign EXT_ADDR = ALU_OUT;
    assign read_en = is_mem_read;
    assign write_en = is_mem_write;

    assign branch_result = ((BRANCH_OP == `BEQ) && (ALU_OUT == 32'd0)) ||
        ((BRANCH_OP == `BNE) && (ALU_OUT != 32'd0));

    //note that the entire pipeline is halted when cache isn't done. this means
    //that none of the outputs we send to external cache need to be registers.
    always @(*)
        if(branch_result != prediction)
            flush = 1'b1;
        else if(branch_result == 1'b1)
            if(NEXT_PC != RECOVER_TAKEN)    //misprediction for address also needs recovery
                flush = 1'b1;
            else
                flush = 1'b0;
        else
            flush = 1'b0;

    always @(posedge clk)
        if(reset)
        begin
            REG_PC <= 0;  
            REG_WB_CTRL <= 0;   
            REG_ALU_OUT <= 0;
            REG_MEM_OUT <= 0;
            REG_WRITE_REG <= 0;
        end
        else if(cache_stall)
        begin
            REG_PC <= REG_PC;  
            REG_WB_CTRL <= REG_WB_CTRL;   
            REG_ALU_OUT <= REG_ALU_OUT;
            REG_MEM_OUT <= REG_MEM_OUT;
            REG_WRITE_REG <= REG_WRITE_REG;
        end
        else
        begin
            REG_PC <= NEXT_PC;  //this may seem wrong, but keep in mind that at this point, flush will
            REG_WB_CTRL <= WB_CTRL; //have been issued if there was a misprediction. 
            REG_ALU_OUT <= ALU_OUT;
            REG_MEM_OUT <= MEM_OUT;
            REG_WRITE_REG <= WRITE_REG;
        end

endmodule