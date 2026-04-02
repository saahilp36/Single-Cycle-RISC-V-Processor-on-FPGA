module mux_regdst(
    input logic [4:0] in0,             // rt (instr[20:16])
    input logic [4:0] in1,             // rd (instr[15:11])
    input logic sel,                   // RegDst control signal
    output logic [4:0] out
);
    assign out = sel ? in1 : in0;
endmodule
