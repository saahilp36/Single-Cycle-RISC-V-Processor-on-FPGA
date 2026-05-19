module top(
    input  logic        clk, rst,
    input  logic [1:0]  sw,                  // Selects the demo instruction/program
    output logic [31:0] ALUResult,           // EX/MEM ALU result for simulation
    output logic [31:0] RD1, RD2,            // ID-stage register reads for simulation
    output logic [31:0] prode_register_file, // register[1] for simulation/display
    output logic [6:0]  display_led
);

    // -------------------------
    // IF stage
    // -------------------------
    logic [31:0] pc_if, pc_next_if, pc_plus4_if, instr_if;

    assign pc_plus4_if = pc_if + 32'd4;

    instruction_cache i_cache(
        .PC(pc_if),
        .sw(sw),
        .Instr(instr_if)
    );

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            pc_if <= 32'b0;
        else if (!stall_id)
            pc_if <= pc_next_if;
    end

    always_comb begin
        if (branch_taken_ex)
            pc_next_if = branch_target_ex;
        else
            pc_next_if = pc_plus4_if;
    end

    // -------------------------
    // IF/ID pipeline register
    // -------------------------
    logic [31:0] if_id_instr, if_id_pc_plus4;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            if_id_instr    <= 32'b0;
            if_id_pc_plus4 <= 32'b0;
        end else if (branch_taken_ex) begin
            if_id_instr    <= 32'b0;
            if_id_pc_plus4 <= 32'b0;
        end else if (!stall_id) begin
            if_id_instr    <= instr_if;
            if_id_pc_plus4 <= pc_plus4_if;
        end else begin
            if_id_instr    <= if_id_instr;
            if_id_pc_plus4 <= if_id_pc_plus4;
        end
    end

    // -------------------------
    // ID stage
    // -------------------------
    logic        reg_write_id, mem_write_id, mem_to_reg_id, alu_src_id, reg_dst_id;
    logic        branch_id, stall_id, if_id_uses_rt;
    logic [2:0]  alu_control_id;
    logic [31:0] sign_imm_id;
    logic [31:0] write_data_wb;
    logic [4:0]  write_reg_wb;
    logic        reg_write_wb;

    always_comb begin
        reg_write_id  = 1'b0;
        mem_write_id  = 1'b0;
        mem_to_reg_id = 1'b0;
        alu_src_id    = 1'b0;
        reg_dst_id    = 1'b0;
        branch_id     = 1'b0;
        alu_control_id = 3'b010;

        case (if_id_instr[31:26])
            6'b100100: begin // ADD rd, rs, rt
                reg_write_id  = 1'b1;
                reg_dst_id    = 1'b1;
                alu_control_id = 3'b010;
            end
            6'b101100: begin // SUB rd, rs, rt
                reg_write_id  = 1'b1;
                reg_dst_id    = 1'b1;
                alu_control_id = 3'b110;
            end
            6'b100011: begin // LW rt, imm(rs)
                reg_write_id  = 1'b1;
                mem_to_reg_id = 1'b1;
                alu_src_id    = 1'b1;
                reg_dst_id    = 1'b0;
                alu_control_id = 3'b010;
            end
            6'b101011: begin // SW rt, imm(rs)
                mem_write_id  = 1'b1;
                alu_src_id    = 1'b1;
                alu_control_id = 3'b010;
            end
            6'b000100: begin // BEQ rs, rt, imm
                branch_id     = 1'b1;
                alu_control_id = 3'b110;
            end
            default: begin
                // NOP
            end
        endcase
    end

    always_comb begin
        case (if_id_instr[31:26])
            6'b100100,
            6'b101100,
            6'b101011,
            6'b000100: if_id_uses_rt = 1'b1;
            default:   if_id_uses_rt = 1'b0;
        endcase
    end

    assign stall_id = id_ex_mem_to_reg &&
                      (id_ex_rt != 5'b0) &&
                      ((id_ex_rt == if_id_instr[25:21]) ||
                       (if_id_uses_rt && (id_ex_rt == if_id_instr[20:16])));

    register_file r_f(
        .clk(clk),
        .rst(rst),
        .A1(if_id_instr[25:21]),
        .A2(if_id_instr[20:16]),
        .A3(write_reg_wb),
        .WD3(write_data_wb),
        .WE3(reg_write_wb),
        .RD1(RD1),
        .RD2(RD2),
        .prode(prode_register_file)
    );

    sign_extend s1(
        .imm(if_id_instr[15:0]),
        .signimm(sign_imm_id)
    );

    // -------------------------
    // ID/EX pipeline register
    // -------------------------
    logic        id_ex_reg_write, id_ex_mem_write, id_ex_mem_to_reg, id_ex_branch;
    logic        id_ex_alu_src, id_ex_reg_dst;
    logic [2:0]  id_ex_alu_control;
    logic [31:0] id_ex_rd1, id_ex_rd2, id_ex_sign_imm, id_ex_pc_plus4;
    logic [4:0]  id_ex_rs, id_ex_rt, id_ex_rd;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            id_ex_reg_write   <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_branch      <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_reg_dst     <= 1'b0;
            id_ex_alu_control <= 3'b010;
            id_ex_rd1         <= 32'b0;
            id_ex_rd2         <= 32'b0;
            id_ex_sign_imm    <= 32'b0;
            id_ex_pc_plus4    <= 32'b0;
            id_ex_rs          <= 5'b0;
            id_ex_rt          <= 5'b0;
            id_ex_rd          <= 5'b0;
        end else if (stall_id || branch_taken_ex) begin
            id_ex_reg_write   <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_branch      <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_reg_dst     <= 1'b0;
            id_ex_alu_control <= 3'b010;
            id_ex_rd1         <= 32'b0;
            id_ex_rd2         <= 32'b0;
            id_ex_sign_imm    <= 32'b0;
            id_ex_pc_plus4    <= 32'b0;
            id_ex_rs          <= 5'b0;
            id_ex_rt          <= 5'b0;
            id_ex_rd          <= 5'b0;
        end else begin
            id_ex_reg_write   <= reg_write_id;
            id_ex_mem_write   <= mem_write_id;
            id_ex_mem_to_reg  <= mem_to_reg_id;
            id_ex_branch      <= branch_id;
            id_ex_alu_src     <= alu_src_id;
            id_ex_reg_dst     <= reg_dst_id;
            id_ex_alu_control <= alu_control_id;
            id_ex_rd1         <= RD1;
            id_ex_rd2         <= RD2;
            id_ex_sign_imm    <= sign_imm_id;
            id_ex_pc_plus4    <= if_id_pc_plus4;
            id_ex_rs          <= if_id_instr[25:21];
            id_ex_rt          <= if_id_instr[20:16];
            id_ex_rd          <= if_id_instr[15:11];
        end
    end

    // -------------------------
    // EX stage
    // -------------------------
    logic [1:0]  forward_a_ex, forward_b_ex;
    logic [31:0] forward_src_a_ex, forward_src_b_ex;
    logic [31:0] alu_src_b_ex, alu_result_ex, branch_target_ex;
    logic [4:0]  write_reg_ex;
    logic        branch_taken_ex;

    always_comb begin
        forward_a_ex = 2'b00;
        forward_b_ex = 2'b00;

        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_write_reg != 5'b0) &&
            (ex_mem_write_reg == id_ex_rs))
            forward_a_ex = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_write_reg != 5'b0) &&
                 (mem_wb_write_reg == id_ex_rs))
            forward_a_ex = 2'b01;

        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_write_reg != 5'b0) &&
            (ex_mem_write_reg == id_ex_rt))
            forward_b_ex = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_write_reg != 5'b0) &&
                 (mem_wb_write_reg == id_ex_rt))
            forward_b_ex = 2'b01;
    end

    always_comb begin
        case (forward_a_ex)
            2'b10:  forward_src_a_ex = ex_mem_alu_result;
            2'b01:  forward_src_a_ex = write_data_wb;
            default: forward_src_a_ex = id_ex_rd1;
        endcase

        case (forward_b_ex)
            2'b10:  forward_src_b_ex = ex_mem_alu_result;
            2'b01:  forward_src_b_ex = write_data_wb;
            default: forward_src_b_ex = id_ex_rd2;
        endcase
    end

    assign branch_target_ex = id_ex_pc_plus4 + (id_ex_sign_imm << 2);
    assign branch_taken_ex  = id_ex_branch && (forward_src_a_ex == forward_src_b_ex);

    mux_alusrc m_alu_src(
        .in0(forward_src_b_ex),
        .in1(id_ex_sign_imm),
        .sel(id_ex_alu_src),
        .out(alu_src_b_ex)
    );

    mux_regdst m_reg_dst(
        .in0(id_ex_rt),
        .in1(id_ex_rd),
        .sel(id_ex_reg_dst),
        .out(write_reg_ex)
    );

    ALU alu1(
        .SrcA(forward_src_a_ex),
        .SrcB(alu_src_b_ex),
        .ALUControl(id_ex_alu_control),
        .ALUResult(alu_result_ex)
    );

    // -------------------------
    // EX/MEM pipeline register
    // -------------------------
    logic        ex_mem_reg_write, ex_mem_mem_write, ex_mem_mem_to_reg;
    logic [31:0] ex_mem_alu_result, ex_mem_write_data;
    logic [4:0]  ex_mem_write_reg;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ex_mem_reg_write  <= 1'b0;
            ex_mem_mem_write  <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_alu_result <= 32'b0;
            ex_mem_write_data <= 32'b0;
            ex_mem_write_reg  <= 5'b0;
        end else begin
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_alu_result <= alu_result_ex;
            ex_mem_write_data <= forward_src_b_ex;
            ex_mem_write_reg  <= write_reg_ex;
        end
    end

    assign ALUResult = ex_mem_alu_result;

    // -------------------------
    // MEM stage
    // -------------------------
    logic [31:0] read_data_mem;

    data_memory mem1(
        .clk(clk),
        .WE(ex_mem_mem_write),
        .A(ex_mem_alu_result),
        .WD(ex_mem_write_data),
        .RD(read_data_mem)
    );

    // -------------------------
    // MEM/WB pipeline register
    // -------------------------
    logic        mem_wb_reg_write, mem_wb_mem_to_reg;
    logic [31:0] mem_wb_read_data, mem_wb_alu_result;
    logic [4:0]  mem_wb_write_reg;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_read_data  <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_write_reg  <= 5'b0;
        end else begin
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_read_data  <= read_data_mem;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_write_reg  <= ex_mem_write_reg;
        end
    end

    // -------------------------
    // WB stage
    // -------------------------
    mux_memtoreg m_mem_to_reg(
        .in0(mem_wb_alu_result),
        .in1(mem_wb_read_data),
        .sel(mem_wb_mem_to_reg),
        .out(write_data_wb)
    );

    assign write_reg_wb  = mem_wb_write_reg;
    assign reg_write_wb  = mem_wb_reg_write;

    display d1(
        .data_in(prode_register_file),
        .segments(display_led)
    );

endmodule
