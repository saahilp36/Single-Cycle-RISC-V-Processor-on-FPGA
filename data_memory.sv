module data_memory(
    input logic clk,
    input logic WE,                    // Write Enable
    input logic [31:0] A,              // Address
    input logic [31:0] WD,             // Write Data
    output logic [31:0] RD             // Read Data
);
    logic [31:0] mem [0:255];          // 256 x 32-bit memory
    
    // Initialize memory with some test values
    initial begin
        for (int i = 0; i < 256; i++) begin
            mem[i] = i * 10;           // Example: mem[0]=0, mem[1]=10, mem[5]=50, etc.
        end
    end
    
    // Write operation (synchronous)
    always_ff @(posedge clk) begin
        if (WE) begin
            mem[A[7:0]] <= WD;         // Use lower 8 bits for 256 addresses
        end
    end
    
    // Read operation (asynchronous/combinational)
    assign RD = mem[A[7:0]];
endmodule
