module top(
input logic clk, rst,
input logic[1:0] sw, //address for instruction memory
output logic[31:0] ALUResult, //output for pre-lab simulation
output logic[31:0] RD1, RD2, //output for pre-lab simulation
output logic[31:0] prode_register_file, //output for pre-lab simulation
output logic[6:0] display_led //output for in-lab
);

logic[31:0] RD1_reg, RD2_reg;
logic[2:0] ALUControl_reg;

logic[31:0] inst_0 = 32'b0;
logic[31:0] inst_1 = 32'b100100_00101_00100_00001_0000_0000_000; 
//add rf_regs[5] and rf_regs[4] to rf_regs[1];
logic[31:0] inst_2 = 32'b101100_01010_01000_00001_0000_0000_000; 
//sub rf_regs[10] - rf_regs[8] to rf_regs[1];
logic[31:0] inst_ex;
assign inst_ex = (sw==1)? inst_1:(sw==2)? inst_2: inst_0;


register_file r_f(.clk(clk),.rst(rst),
.A1(inst_ex[25:21]),.A2(inst_ex[20:16]),.A3(inst_ex[15:11]),
.WD3(ALUResult),
.WE3(1),
.RD1(RD1),
.RD2(RD2),
.prode(prode_register_file)
);


ALU t1(
.SrcA(RD1),
.SrcB(RD2),
.ALUControl(inst_ex[29:27]),
.ALUResult(ALUResult)
);

display t2(.data_in(prode_register_file), 
.segments(display_led));

endmodule





//for i type
// LW (mem[5] -> rf[1]) and SW (rf[9] -> mem[2])
    logic [31:0] inst_0 = 32'b0;
    logic [31:0] inst_1 = 32'b100011_00000_00001_0000_0000_0000_0101; // LW r1,5(r0)
    logic [31:0] inst_2 = 32'b101011_01001_00000_0000_0000_0000_0010; // SW r9,2(r0)
    logic [31:0] inst_ex;

    assign inst_ex = (sw==1)? inst_1:(sw==2)? inst_2: inst_0;

    // Control signals
    logic RegWrite, MemWrite, MemtoReg, ALUSrc;
    logic [2:0] ALUControl;

    always_comb begin
        case (inst_ex[31:26]) // opcode
            6'b100011: begin // LW
                RegWrite = 1; MemWrite = 0; MemtoReg = 1; ALUSrc = 1; ALUControl = 3'b010;
            end
            6'b101011: begin // SW
                RegWrite = 0; MemWrite = 1; MemtoReg = 0; ALUSrc = 1; ALUControl = 3'b010;
            end
            default: begin
                RegWrite = 0; MemWrite = 0; MemtoReg = 0; ALUSrc = 0; ALUControl = 3'b010;
            end
        endcase
    end

    // Wires
    logic [31:0] SignImm, SrcB, MemRD, WD3;
    logic [4:0]  A3;

    // Instantiate components
    register_file r_f(.clk(clk), .rst(rst),
        .A1(inst_ex[25:21]), .A2(inst_ex[20:16]), .A3(inst_ex[20:16]),
        .WD3(WD3), .WE3(RegWrite),
        .RD1(RD1), .RD2(RD2), .prode(prode_register_file)
    );

    sign_extend s1(.imm(inst_ex[15:0]), .signimm(SignImm));
    mux_alusrc m1(.in0(RD2), .in1(SignImm), .sel(ALUSrc), .out(SrcB));
    ALU alu1(.SrcA(RD1), .SrcB(SrcB), .ALUControl(ALUControl), .ALUResult(ALUResult));
    data_memory mem1(.clk(clk), .WE(MemWrite), .A(ALUResult), .WD(RD2), .RD(MemRD));
    mux_memtoreg m2(.in0(ALUResult), .in1(MemRD), .sel(MemtoReg), .out(WD3));

    // Display register[1] value on 7-seg
    display d1(.data_in(prode_register_file), .segments(display_led));








