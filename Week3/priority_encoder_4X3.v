`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/10 19:37:46
// Design Name: 
// Module Name: priority_encoder_4X3
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


module priority_encoder_4X3(D, x, y, V);
    input [3:0] D;
    output x, y, V;
    wire x, y, V;
    
    assign x = D[3] | D[2];
    assign y = D[3] | (~D[2] & D[1]);
    assign V = D[3] | D[2] | D[1] | D[0];

endmodule