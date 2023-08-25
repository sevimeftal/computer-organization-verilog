`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2023 04:36:33 PM
// Design Name: 
// Module Name: Modules
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

// The module takes as input a clock signal (clk), a enable signal (E), an n-bit input signal (I), 
// and a 2-bit function select signal (FunSel).
// The module outputs an n-bit signal (Q) that represents the register output.
// The parameter n specifies the number of bits in the register.

module register_n_bit  #(parameter n = 8)(
    input E, clk, [n-1:0] I,
    [1:0] FunSel, output [n-1:0] Q);
    // Define a register X with n bits, which holds the register value.
    reg [n-1:0] X;
    // Always block that is sensitive to the positive edge of the clock signal.
    always @(*) begin
       // If the enable signal is high, execute the selected function on the register value.
        if (E == 1'b1) begin
            case (FunSel)
                2'b00: X <= 0;
                2'b01: X <= I;
                2'b10: X <= X - 1;
                2'b11: X <= X + 1;
                default: X <= X; 
            endcase
        end
    end
      // Assign the value of X to the output signal Q.
    assign Q = X;
endmodule

// signal is L/H
module IR_register_16(
    input E, clk, signal, [7:0] I, [1:0] FunSel, output [15:0] IROut
);
    // If signal is 0, concatenate IROut[15:8] and I to form the 16-bit input IROut O.therwise, concatenate I and IROut[7:0] to form the 16-bit input IROut
    register_n_bit #(16) regis(E, clk, (signal == 0) ? {IROut[15:8], I} : {I, IROut[7:0]}, FunSel, IROut);
 
endmodule


module part_2b(input Clk, [7:0] I ,[2:0]O1Sel, O2Sel, [1:0] FunSel, [3:0]RSel,TSel, output reg [7:0] O1, O2);
    // Register outputs
    wire [7:0] reg_1;
    wire [7:0] reg_2;
    wire [7:0] reg_3;
    wire [7:0] reg_4;
    wire [7:0] temp_1;
    wire [7:0] temp_2;
    wire [7:0] temp_3;
    wire [7:0] temp_4;
    initial begin
    O1= 0;
    O2 = 0;
    end
    
        // Registers according to control inputs TSel and RSel
        register_n_bit#(8) result5(.E(TSel[3]), .Q(temp_1),
                       .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result6(.E(TSel[2]), .Q(temp_2),
                       .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result7(.E(TSel[1]), .Q(temp_3),
                       .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result8(.E(TSel[0]), .Q(temp_4),
                        .FunSel(FunSel), .clk(Clk), .I(I)); 
        register_n_bit#(8) result1(.E(RSel[3]), .Q(reg_1),
                        .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result2(.E(RSel[2]), .Q(reg_2),
                        .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result3(.E(RSel[1]), .Q(reg_3),
                        .FunSel(FunSel), .clk(Clk), .I(I));
        register_n_bit#(8) result4(.E(RSel[0]), .Q(reg_4),
                        .FunSel(FunSel), .clk(Clk), .I(I));  
                        
                        
        always @(*) begin
        case(O2Sel)//output O2 depends on O2Sel
            3'b000: O2 = temp_1;
            3'b001: O2 = temp_2;
            3'b010: O2 = temp_3;
            3'b011: O2 = temp_4;
            3'b100: O2 = reg_1;
            3'b101: O2 = reg_2;
            3'b110: O2 = reg_3;
            3'b111: O2 = reg_4;
        endcase
                
        case(O1Sel)//output O1 depends on O1Sel
            3'b000: O1 = temp_1;
            3'b001: O1 = temp_2;
            3'b010: O1 = temp_3;
            3'b011: O1 = temp_4;
            3'b100: O1 = reg_1;
            3'b101: O1 = reg_2;
            3'b110: O1 = reg_3;
            3'b111: O1 = reg_4;
         endcase
         end
         
endmodule

module part_2c(input Clk, [7:0] I ,[1:0]OutASel, OutBSel, FunSel, [3:0]RSel, output reg [7:0] OutA, OutB);
    // Register output
    wire [7:0] AR;
    wire [7:0] SP;
    wire [7:0] PCPrev;
    wire [7:0] PC;

    // Declare wires to select which register's output to use
    wire select_AR, select_PC, select_SP, select_PCPrev;
    assign select_PC = RSel[0];
    assign select_AR = RSel[1];
    assign select_SP = RSel[2];
    assign select_PCPrev = RSel[3];

    // Instantiate four instances of the register module to create four registers
    // The output of each register is connected to one of the four wires declared above

    register_n_bit#(8) result1(.E(select_AR), .Q(AR),
                    .FunSel(FunSel), .clk(Clk), .I(I));
    register_n_bit#(8) result2(.E(select_SP), .Q(SP),
                    .FunSel(FunSel), .clk(Clk), .I(I));
    register_n_bit#(8) result3(.E(select_PCPrev), .Q(PCPrev),
                    .FunSel(FunSel), .clk(Clk), .I(I));
    register_n_bit#(8) result4(.E(select_PC), .Q(PC),
                    .FunSel(FunSel), .clk(Clk), .I(I));  
                    
 always @(*) begin
    case(OutASel) //OutA depends on OutASel
        2'b00:OutA = PCPrev;
        2'b01:OutA = SP;
        2'b10:OutA = AR;
        2'b11:OutA = PC;
    endcase
    case(OutBSel) //OutB depends on OutBSel
        2'b00:OutB = PCPrev;
        2'b01:OutB = SP;
        2'b10:OutB = AR;
        2'b11:OutB = PC;
    endcase
end
                   
endmodule
