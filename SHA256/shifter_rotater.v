`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 22:46:39
// Design Name: 
// Module Name: shifter_rotater
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


module shifter_rotater (
    input  [31:0] data_in,
    input  [4:0]  shift_amt,
    input         op_select, // 1: Right Rotate, 0: Right Shift
    output reg [31:0] data_out
);
    always @(*) begin
        if (op_select) begin
            // Right Rotate Logic
            data_out = (data_in >> shift_amt) | (data_in << (32 - shift_amt));
        end else begin
            // Right Shift Logic
            data_out = data_in >> shift_amt;
        end
    end
endmodule
