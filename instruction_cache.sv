module instruction_cache(
    input  logic [31:0] PC,
    input  logic [1:0]  sw,
    output logic [31:0] Instr
);

    localparam logic [31:0] NOP = 32'b0;

    localparam logic [31:0] ADD_R1_R5_R4 =
        32'b100100_00101_00100_00001_0000_0000_000;
    localparam logic [31:0] ADD_R2_R1_R4 =
        32'b100100_00001_00100_00010_0000_0000_000;
    localparam logic [31:0] SUB_R1_R10_R8 =
        32'b101100_01010_01000_00001_0000_0000_000;
    localparam logic [31:0] LW_R1_5_R0 =
        32'b100011_00000_00001_0000_0000_0000_0101;
    localparam logic [31:0] SW_R9_2_R0 =
        32'b101011_00000_01001_0000_0000_0000_0010;
    localparam logic [31:0] BEQ_R2_R2_SKIP_ONE =
        32'b000100_00010_00010_0000_0000_0000_0001;

    always_comb begin
        Instr = NOP;

        case (sw)
            2'b01: begin
                case (PC[7:2])
                    6'd0: Instr = ADD_R1_R5_R4;
                    default: Instr = NOP;
                endcase
            end
            2'b10: begin
                case (PC[7:2])
                    6'd0: Instr = SUB_R1_R10_R8;
                    default: Instr = NOP;
                endcase
            end
            2'b11: begin
                case (PC[7:2])
                    6'd0: Instr = LW_R1_5_R0;
                    6'd1: Instr = ADD_R2_R1_R4;
                    6'd2: Instr = BEQ_R2_R2_SKIP_ONE;
                    6'd3: Instr = SUB_R1_R10_R8;
                    6'd4: Instr = ADD_R1_R5_R4;
                    default: Instr = NOP;
                endcase
            end
            default: Instr = NOP;
        endcase
    end

endmodule
