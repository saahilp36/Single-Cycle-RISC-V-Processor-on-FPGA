module sign_extend(
    input logic [15:0] imm,            // 16-bit immediate
    output logic [31:0] signimm        // 32-bit sign-extended immediate
);
    assign signimm = {{16{imm[15]}}, imm};  // Replicate sign bit 16 times
endmodule
