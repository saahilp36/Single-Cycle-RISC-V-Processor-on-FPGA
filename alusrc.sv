module mux_alusrc(
    input logic [31:0] in0,            // Register data (RD2)
    input logic [31:0] in1,            // Sign-extended immediate
    input logic sel,                   // ALUSrc control signal
    output logic [31:0] out
);
    assign out = sel ? in1 : in0;
endmodule
