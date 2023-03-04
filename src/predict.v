 /**   
 * predict.v
 * -------------------------
 * This is the branch prediction table.
 */

 /* INCLUDES */
`include "opcode.v"

module bpt(reset, clk, write_enable, WRITE_ADDR,
    DATA_IN, READ_ADDR, DATA_OUT);

    input reset, clk;
    input write_enable;
    input [7:0] WRITE_ADDR, READ_ADDR;
    input [32:0] DATA_IN;
    output [32:0] DATA_OUT;

    reg [31:0] btb [255:0];
    reg [1:0] bpb_curr, bpb_next;
	 
	 wire branch_result;

    reg prediction;

    integer table_row;
    parameter NOT_TAKEN = 2'b00, WEAK_NOT_TAKEN = 2'b01, WEAK_TAKEN = 2'b10, TAKEN = 2'b11;

    assign DATA_OUT = {btb[READ_ADDR], prediction};
    assign branch_result = DATA_IN[0];

    //moore state machine: output depends only on bpb_curr.
    //combinational component
    always @(*)
        if(bpb_curr == NOT_TAKEN || bpb_curr == WEAK_NOT_TAKEN)
            prediction = `NOT_TAKEN;
        else
            prediction = `TAKEN;
    
    //we don't put out a prediction depending on the valuation of 
    //bpb_next: only bpb_curr will be used in the output. 
    always @(branch_result, bpb_curr)
        case(bpb_curr)
            NOT_TAKEN: 
                if(branch_result == `TAKEN)
                    bpb_next = WEAK_NOT_TAKEN;
                else
                    bpb_next = NOT_TAKEN;
            WEAK_NOT_TAKEN: 
                if(branch_result == `TAKEN)
                    bpb_next = WEAK_TAKEN;
                else
                    bpb_next = NOT_TAKEN;
            WEAK_TAKEN: 
                if(branch_result == `TAKEN)
                    bpb_next = TAKEN;
                else
                    bpb_next = WEAK_NOT_TAKEN;
            TAKEN: 
                if(branch_result == `TAKEN)
                    bpb_next = TAKEN;
                else
                    bpb_next = WEAK_TAKEN; 
            default: bpb_next = 2'bxx;    
        endcase

    //sequential component
    always @(posedge clk)
        if(reset)
            bpb_curr <= 2'd0;
        else if(write_enable)
            bpb_curr <= bpb_next;

    //register updates
    always @(posedge clk)
        if(reset)
        begin
            for(table_row = 0; table_row < 256; table_row = table_row + 1)
                btb[table_row] = 32'd0;
        end
        else if(write_enable)
            btb[WRITE_ADDR] = DATA_IN[32:1];
    
endmodule


