/**   
 * decode.v
 * -------------------------
 * This is the DECODE stage of the pipeline. Control signals are issued 
 * here. Additionally, register file access is handled here
 * instead of in the EXECUTE stage to reduce the length of the critical path
 * in the EXECUTE stage.
 */

 /* INCLUDES */
`include "opcode.v"

/* MODULE DEFINITION */
module decode(reset, clk, NEXT_PC, INSTRUCTION, is_reg_write_wb, 
    WRITEBACK_REG, WRITEBACK_DATA, flush, cache_stall, EX_WRITE_REG,
    is_reg_write_ex, MEM_WRITE_REG, is_reg_write_mem, prediction, 
    reg_prediction, hazard_stall, REG_BYPASS_1, REG_BYPASS_2, 
    REG_ALU_FUNCT, REG_RT, REG_RD, REG_RS_DATA, REG_RT_DATA, REG_IMM_DATA, 
    REG_PC, REG_EX_CTRL, REG_MEM_CTRL, REG_WB_CTRL);

    input reset, clk;
    input [31:0] NEXT_PC, INSTRUCTION;
    input is_reg_write_ex, is_reg_write_mem, is_reg_write_wb;
    input [4:0] EX_WRITE_REG, MEM_WRITE_REG, WRITEBACK_REG;
    input [31:0] WRITEBACK_DATA;
    input flush, cache_stall, prediction;
    output hazard_stall;
    output reg [4:0] REG_RT, REG_RD;
    output reg [31:0] REG_RS_DATA, REG_RT_DATA;
    output reg signed [31:0] REG_IMM_DATA;
    output reg [1:0] REG_BYPASS_1, REG_BYPASS_2;
    output reg [3:0] REG_ALU_FUNCT;
    output reg [31:0] REG_PC;
    output reg [1:0] REG_EX_CTRL;
    output reg [3:0] REG_MEM_CTRL;
    output reg [1:0] REG_WB_CTRL;
    output reg reg_prediction;

    wire is_r_format;
    wire is_mem_read, is_mem_write, is_reg_write, is_immediate; //is_immediate is alusrc_flag
    wire [1:0] BRANCH_OP, ALU_OP;

    wire [5:0] OPCODE, FUNCT;
    wire [3:0] ALU_FUNCT;
    
    wire [4:0] RS;
    wire [4:0] RT;
    wire [4:0] RD;

    wire [1:0] BYPASS_1, BYPASS_2;

    bypass_ctrl BYPASS_CTRL(
        .DECODE_RS(RS),
        .DECODE_RT(RT),
        .EXECUTE_RD(EX_WRITE_REG),
        .MEMORY_RD(MEM_WRITE_REG),
        .is_reg_write_ex(is_reg_write_ex),
        .is_reg_write_mem(is_reg_write_mem),
        .BYPASS_1(BYPASS_1),
        .BYPASS_2(BYPASS_2)
    );

    //stall logic is very simple because the abundance of forwarding paths means that
    //the only data hazard that necessitates a stall in this pipeline is when a read
    //follows a load instruction.
    //note that we need to check both RS and RT because a transfer can occur for either.
    assign hazard_stall = ((REG_MEM_CTRL[1] == 1'b1) && ((REG_RT == RS) || (REG_RT == RT)));

    //we place the register management unit here to reduce the length of the critical path
    //in the EXECUTE stage.
    reg [31:0] REG_FILE [31:0];

    integer register;

    always @(posedge clk)
        if(reset)
            for(register = 0; register < 32; register = register + 1)
                REG_FILE[register] <= 32'd0;
        else
            if(is_reg_write_wb)
                REG_FILE[register] <= WRITEBACK_DATA;
    
    assign RS = INSTRUCTION[25:21];
    assign RT = INSTRUCTION[20:16];
    assign RD = INSTRUCTION[15:11];

    //organized again by signal priority
    always @(posedge clk)
        if(reset || flush)
        begin
            REG_PC <= 32'd0;
            REG_RT <= 5'd0;
            REG_RD <= 5'd0;
            REG_RT_DATA <= 32'd0;
            REG_RS_DATA <= 32'd0;
            REG_IMM_DATA <= 32'd0;
            REG_BYPASS_1 <= 2'd0;
            REG_BYPASS_2 <= 2'd0;
        end
        else if(hazard_stall || cache_stall)
        begin
            REG_PC <= REG_PC;
            REG_RT <= REG_RT;
            REG_RD <= REG_RD;
            REG_RT_DATA <= REG_RT_DATA;
            REG_RS_DATA <= REG_RS_DATA;
            REG_IMM_DATA <= REG_IMM_DATA;
            REG_BYPASS_1 <= REG_BYPASS_1;
            REG_BYPASS_2 <= REG_BYPASS_2;
        end
        else
        begin
            REG_PC <= NEXT_PC;
            REG_IMM_DATA <= INSTRUCTION;
            REG_RT <= RT;
            REG_RD <= RD;
            //a consequence of handling the regfile here is that we need a path from WRITEBACK
            //to DECODE. otherwise we miss register data this cycle, because the regfile is updates
            //at the end of the clock cycle, so we cannot make use of its contents if WRITEBACK data
            //is needed right this instant unless we create this path between WRITEBACK and DECODE.
            //if this were handled in EXECUTE these checks wouldn't be necessary.
            if(is_reg_write_wb && (WRITEBACK_REG == RS))
                REG_RS_DATA <= WRITEBACK_DATA;
            else
                REG_RS_DATA = REG_FILE[RS];
            if(is_reg_write_wb && (WRITEBACK_REG == RT))
                REG_RT_DATA <= WRITEBACK_DATA;
            else
                REG_RT_DATA = REG_FILE[RT];
            if(INSTRUCTION[15]) //sign extension because the immediate is signed data
                REG_IMM_DATA <= {16'hFFFF, INSTRUCTION[15:0]};
            else 
                REG_IMM_DATA <= {16'h0, INSTRUCTION[15:0]};
            REG_BYPASS_1 <= BYPASS_1;
            REG_BYPASS_2 <= BYPASS_2;
        end

    assign OPCODE = INSTRUCTION[31:26];
    assign FUNCT = INSTRUCTION[5:0];

    ALU_decode ALU_DECODE(
        .OPCODE(OPCODE),
        .FUNCT(FUNCT),
        .ALU_FUNCT(ALU_FUNCT)
    );

    CPU_ctrl CPU_CTRL(
        .INSTRUCTION(INSTRUCTION),
        .is_reg_write(is_reg_write),
        .BRANCH_OP(BRANCH_OP),
        .is_mem_read(is_mem_read),
        .is_mem_write(is_mem_write),
        .is_immediate(is_immediate),
        .is_r_format(is_r_format)
    );

    //in order of priority
    always @(posedge clk)
        if(reset || flush || hazard_stall)  //we turn off all control signals to save power, since they wont be needed
        begin                               //when theres a stall due to hazard
            REG_EX_CTRL <= 2'd0;
            REG_MEM_CTRL <= 4'd0;
            REG_WB_CTRL <= 2'd0;
            REG_ALU_FUNCT <= 4'd0;
            reg_prediction <= 1'd0;
        end
        else if(cache_stall)
        begin
            REG_EX_CTRL <= REG_EX_CTRL;
            REG_MEM_CTRL <= REG_MEM_CTRL;
            REG_WB_CTRL <= REG_WB_CTRL;
            REG_ALU_FUNCT <= REG_ALU_FUNCT;
            reg_prediction <= reg_prediction;
        end
        else
        begin
            REG_EX_CTRL[0] <= is_r_format;
            REG_EX_CTRL[1] <= is_immediate;
            REG_MEM_CTRL[0] <= is_mem_read;
            REG_MEM_CTRL[1] <= is_mem_write;
            REG_MEM_CTRL[3:2] <= BRANCH_OP;
            REG_WB_CTRL[0] <= is_mem_read;
            REG_WB_CTRL[1] <= is_reg_write;
            REG_ALU_FUNCT <= ALU_FUNCT;
            reg_prediction <= prediction;
        end

endmodule
    







