# 32-Bit-Pipelined-RISC-Processor
32-bit, 5-stage pipelined RISC processor with full forwarding, hazard detection, and branch prediction. Includes FETCH, DECODE, EXECUTE, MEMORY, and WRITEBACK stages. Implements branch prediction using 2-bit saturating counter and 256-entry branch target buffer. Logic utilization is 3% on the DE1-SoC's Cyclone V (807 ALMs).

## Architectural Diagram
TBD: Drawing things is gyuh

## Supported Instructions
### R-Format:
ADD, SUB, AND, OR, SLT, NOR, SLRV, SLLV

### I-Format:
ADDI, ANDI, ORI, XORI, LUI

### Branch:
BNE, BEQ

### Memory:
SW, LW

See https://student.cs.uwaterloo.ca/~isg/res/mips/opcodes for full details on instruction encoding.

