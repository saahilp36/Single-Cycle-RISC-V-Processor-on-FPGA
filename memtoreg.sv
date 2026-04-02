module mux_memtoreg(
    input logic [31:0] in0,            // ALU Result
    input logic [31:0] in1,            // Memory Data
    input logic sel,                   // MemtoReg control signal
    output logic [31:0] out
);
    assign out = sel ? in1 : in0;
endmodule
