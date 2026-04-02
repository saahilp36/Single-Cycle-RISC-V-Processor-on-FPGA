module register_file(
    input  logic        clk, rst,
    input  logic [4:0]  A1, A2, A3,     
    input  logic [31:0] WD3,            
    input  logic        WE3,            
    output logic [31:0] RD1,            
    output logic [31:0] RD2,            
    output logic [31:0] prode           
);

    logic [31:0] registers [31:0];      

    assign RD1   = registers[A1];
    assign RD2   = registers[A2];
    assign prode = registers[1];

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (int i = 0; i < 32; i++)
                registers[i] <= i;
        end else begin
            if (WE3 && (A3 != 0))
                registers[A3] <= WD3;
        end
    end

endmodule

