module ALU(
    input wire [7:0] A,
    input wire [7:0] B,
    input wire [3:0] FunSel,
    input wire clk,
    output reg [7:0]OutALU,
    output reg [3:0] flag_register
    );
                     
    initial begin
        flag_register = 4'b0000; // initialize flag_register to zero
        OutALU = 0;              // initialize output to zero
    end
                      
    wire [7:0]temp; // declare a wire variable temp for intermediate calculations
    reg [8:0] temp_9bit; // declare a register variable temp_9bit for intermediate calculations

         
    always @(*) begin
        if(FunSel == 4'b0000) begin  // A
            OutALU = A;
        end
        else if(FunSel == 4'b0001) begin // B
            OutALU = B;
        end
        else if(FunSel == 4'b0010) begin // Not A
            OutALU = ~A;
        end
        else if(FunSel == 4'b0011) begin // Not B
            OutALU = ~B;
        end
        else if(FunSel == 4'b0100) begin // A + B
            temp_9bit = A + B + flag_register[2];
            flag_register[2] = temp_9bit[8]; // Carry Flag
            flag_register[0] = (A[7] & B[7] & !temp_9bit[7]) |  (!A[7] & !B[7] & temp_9bit[7]); // Overflow Flag
            OutALU = {temp_9bit[7:0]};
        end
        else if(FunSel == 4'b0101) begin // A - B 
            temp_9bit = A - B;
            flag_register[2] = temp_9bit[8]; // Carry Flag
            flag_register[0] = (A[7] & !B[7] & !temp_9bit[7]) |  (!A[7] & B[7] & temp_9bit[7]); // Overflow Flag
            OutALU = {temp_9bit[7:0]};
        end
        else if(FunSel == 4'b0110) begin // A compare B
            temp_9bit = A - B;  
            OutALU = (temp_9bit[8]== 0 )? 0:A; // If there is a borrow, then A is smaller than B
            flag_register[2] = temp_9bit[8];
        end
        else if(FunSel == 4'b0111) begin // A and B
            OutALU = A & B;
        end
        else if(FunSel == 4'b1000) begin // A or B
            OutALU =A | B;
        end
        else if (FunSel == 4'b1001) begin //A nand B
            OutALU =~(A & B);
        end
        else if(FunSel == 4'b1010) begin //A xor B
            OutALU =A ^ B;
        end
        else if(FunSel == 4'b1011) begin // LSL A
            flag_register[2] = A[7]; // Carry Flag
            OutALU = {A[6:0], 1'b0};
        end
        else if(FunSel == 4'b1100) begin // LSR A
            flag_register[2] = A[0]; // Carry Flag
            OutALU = {1'b0,A[7:1]};
        end
        else if(FunSel == 4'b1101) begin // ASL A
            OutALU = {A[6:0], 1'b0};      
        end
        else if(FunSel == 4'b1110) begin // ASR A
            OutALU = {A[7], A[7:1]};    
        end
        else if(FunSel == 4'b1111) begin // CSR A
            OutALU = {flag_register[2],A[7:1]};
            OutALU[7] = flag_register[2];
            flag_register[2] = A[0];
        end
        flag_register[1] = OutALU[7]; // Negative Flag
        flag_register[3] =  (OutALU == 8'b00000000) ? 1 : 0; // Zero Flag
        end
endmodule
