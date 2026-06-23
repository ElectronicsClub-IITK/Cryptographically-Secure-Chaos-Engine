module multiply(
    input  [7:0] in,
    input  [1:0] sel,   // 00->x1, 01->x2, 10->x3
    output reg [7:0] out
);

reg [7:0] xtime;

always @(*) begin
    // Multiply by 2
    if (in[7])
        xtime = (in << 1) ^ 8'h1B;
    else
        xtime = (in << 1);

    case(sel)
        2'b00: out = in;            // ×1
        2'b01: out = xtime;         // ×2
        2'b10: out = xtime ^ in;    // ×3
        default: out = 8'h00;
    endcase
end

endmodule
