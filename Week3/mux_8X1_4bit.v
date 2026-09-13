`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/10 20:08:13
// Design Name: 
// Module Name: mux_8X1_4bit
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


module mux_8X1_4bit(I0, I1, I2, I3, I4, I5, I6, I7, S, X);
    input [3:0] I0, I1, I2, I3, I4, I5, I6, I7;
    input [2:0] S;
    output reg [3:0] X;

    always @(*) begin
        case (S)
            3'b000: X = I0;
            3'b001: X = I1;
            3'b010: X = I2;
            3'b011: X = I3;
            3'b100: X = I4;
            3'b101: X = I5;
            3'b110: X = I6;
            3'b111: X = I7;
            default: X = 4'b0000;
        endcase
    end
endmodule