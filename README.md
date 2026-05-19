# Single-Cycle-RISC-V-Processor-on-FPGA

This version is organized as a simple 5-stage pipelined processor:

- IF: program counter fetches an instruction from `instruction_cache.sv`
- ID: instruction decode, register file reads, and immediate sign extension
- EX: ALU operation and destination-register selection
- MEM: data memory read/write
- WB: ALU or memory result writes back to the register file

The current pipeline supports the existing demo ADD/SUB instructions plus simple
LW/SW and BEQ control paths. It includes:

- EX-stage forwarding from EX/MEM and MEM/WB
- load-use hazard detection with a one-cycle stall
- BEQ branch target calculation and taken-branch flushing
- store-data forwarding through the EX/MEM pipeline register



`instruction_cache.sv` is currently a tiny combinational instruction ROM with
the same interface a real instruction cache can replace later.

Demo switch behavior:

- `sw == 1`: ADD register 5 and register 4 into register 1
- `sw == 2`: SUB register 10 minus register 8 into register 1
- `sw == 3`: runs a small hazard/branch demo: LW, dependent ADD, BEQ, skipped
  SUB, then final ADD
