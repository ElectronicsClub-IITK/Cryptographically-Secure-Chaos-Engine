`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 22:46:39
// Design Name: 
// Module Name: sigma
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Sigma (
    // 32-bit Inputs
    input [31:0] w1,
    input [31:0] w2,
    input [31:0] w3,
    
    // 5-bit Parameters (Dynamic Wires)
    input [4:0]  p1,
    input [4:0]  p2,
    input [4:0]  p3,
    
    // 32-bit Output
    output [31:0] out
);

    // Intermediate wires to connect modules
    wire [31:0] ror_w1;
    wire [31:0] ror_w2;
    wire [31:0] lsr_w3;
    wire [31:0] first_xor;

    // 1. Right Rotate w1 by p1 (op_select set to 1)
    shifter_rotater stage1 (
        .data_in(w1),
        .shift_amt(p1),
        .op_select(1'b1), 
        .data_out(ror_w1)
    );

    // 2. Right Rotate w2 by p2 (op_select set to 1)
    shifter_rotater stage2 (
        .data_in(w2),
        .shift_amt(p2),
        .op_select(1'b1), 
        .data_out(ror_w2)
    );

    // 3. Right Shift w3 by p3 (op_select set to 0)
    shifter_rotater stage3 (
        .data_in(w3),
        .shift_amt(p3),
        .op_select(1'b0), 
        .data_out(lsr_w3)
    );

    // 4. XOR the first two results: (w1 ROR p1) ^ (w2 ROR p2)
    xor_32bit xor_inst1 (
        .a(ror_w1),
        .b(ror_w2),
        .out(first_xor)
    );

    // 5. XOR the previous result with the third shifted value
    xor_32bit xor_inst2 (
        .a(first_xor),
        .b(lsr_w3),
        .out(out)
    );

endmodule