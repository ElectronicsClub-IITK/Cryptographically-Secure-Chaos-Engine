module mixcolumns(
    input  [31:0] in,
    output [31:0] out
);

wire [7:0] b0, b1, b2, b3;
assign b0 = in[31:24];
assign b1 = in[23:16];
assign b2 = in[15:8];
assign b3 = in[7:0];

wire [7:0] b0x2, b0x3;
wire [7:0] b1x2, b1x3;
wire [7:0] b2x2, b2x3;
wire [7:0] b3x2, b3x3;

multiply m0 (b0, 2'b01, b0x2);
multiply m1 (b0, 2'b10, b0x3);

multiply m2 (b1, 2'b01, b1x2);
multiply m3 (b1, 2'b10, b1x3);

multiply m4 (b2, 2'b01, b2x2);
multiply m5 (b2, 2'b10, b2x3);

multiply m6 (b3, 2'b01, b3x2);
multiply m7 (b3, 2'b10, b3x3);

wire [7:0] o0, o1, o2, o3;

assign o0 = b0x2 ^ b1x3 ^ b2 ^ b3;
assign o1 = b0 ^ b1x2 ^ b2x3 ^ b3;
assign o2 = b0 ^ b1 ^ b2x2 ^ b3x3;
assign o3 = b0x3 ^ b1 ^ b2 ^ b3x2;

assign out = {o0, o1, o2, o3};

endmodule
