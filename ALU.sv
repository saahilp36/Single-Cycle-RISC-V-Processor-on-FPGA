module ALU(
    input  logic [31:0] SrcA, SrcB,       // Operand inputs
    input  logic [2:0]  ALUControl,       // ALU operation select
    output logic [31:0] ALUResult         // Output result
);

    always_comb begin
        case (ALUControl)
            3'b010: ALUResult = SrcA + SrcB;  // ADD
            3'b110: ALUResult = SrcA - SrcB;  // SUB
            default: ALUResult = 32'b0;       // Default case
        endcase
    end

endmodule
