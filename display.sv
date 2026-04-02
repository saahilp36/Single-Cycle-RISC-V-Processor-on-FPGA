module display(
    input  logic [31:0] data_in,     // 32-bit input (from prode)
    output logic [6:0]  segments     // 7-bit output to LED display
);
    logic [3:0] digit;

    // Extract the least significant nibble (0–9 expected)
    assign digit = (data_in[3:0] > 4'd9) ? 4'd0 : data_in[3:0];

    // Common cathode 7-seg encoding: {a,b,c,d,e,f,g}
    always_comb begin
        case (digit)
            4'd0: segments = 7'b1000000; // 0
            4'd1: segments = 7'b1111001; // 1
            4'd2: segments = 7'b0100100; // 2
            4'd3: segments = 7'b0110000; // 3
            4'd4: segments = 7'b0011001; // 4
            4'd5: segments = 7'b0010010; // 5
            4'd6: segments = 7'b0000010; // 6
            4'd7: segments = 7'b1111000; // 7
            4'd8: segments = 7'b0000000; // 8
            4'd9: segments = 7'b0010000; // 9
            default: segments = 7'b1111111; // blank/off
        endcase
    end

endmodule
