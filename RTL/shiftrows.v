module shiftrows(
    input  [31:0] in,
    input  [1:0] sel,
    output reg [31:0] out
);

wire [7:0] b0, b1, b2, b3;

assign b0 = in[31:24];
assign b1 = in[23:16];
assign b2 = in[15:8];
assign b3 = in[7:0];

always @(*) begin
    case(sel)
        2'b00: out = {b0, b1, b2, b3};
        2'b01: out = {b1, b2, b3, b0};
        2'b10: out = {b2, b3, b0, b1};
        2'b11: out = {b3, b0, b1, b2};
        default: out = {b0, b1, b2, b3};
    endcase
end

endmodule
