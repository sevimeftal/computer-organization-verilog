module ALU_System(
  input[2:0]RF_O1Sel, 
  input[2:0]RF_O2Sel, 
  input[1:0] RF_FunSel,
  input[3:0] RF_RSel,
  input[3:0] RF_TSel,
  input[3:0] ALU_FunSel,
  input[1:0] ARF_OutASel, 
  input[1:0] ARF_OutBSel, 
  input[1:0] ARF_FunSel,
  input[3:0] ARF_RSel,
  input      IR_LH,
  input      IR_Enable,
  input[1:0] IR_Funsel,
  input      Mem_WR,
  input      Mem_CS,
  input[1:0] MuxASel,
  input[1:0] MuxBSel,
  input MuxCSel, 
  input      Clock
  );
  wire [7:0] ARFOutA;

  wire [7:0] AOut;//rf
  wire [7:0] BOut;//rf
  wire [7:0] ALUOut;
  wire [3:0] ALUOutFlag;
  wire [7:0] Address;
  wire [7:0] MemoryOut;
  wire [15:0] IROut;
  reg [7:0] MuxAOut;
  reg [7:0] MuxBOut;
  reg [7:0] MuxCOut;
  
  
    always@ (*)begin//mux
    if(MuxASel == 2'b00)begin
    MuxAOut <= ALUOut;
    end
    else if(MuxASel == 2'b01)begin
    MuxAOut <= MemoryOut;
    end
    else if(MuxASel == 2'b10)begin
    MuxAOut <= IROut[7:0];
    end
    else if(MuxASel == 2'b11)begin
    MuxAOut <= ARFOutA;
    end
    if(MuxBSel == 2'b00)begin
    MuxBOut <= ALUOut;
    end
    else if(MuxBSel == 2'b01)begin
    MuxBOut <= MemoryOut;
    end
    else if(MuxBSel == 2'b10)begin
    MuxBOut <= IROut[7:0];
    end
    else if(MuxBSel == 2'b11)begin
    MuxBOut <= ARFOutA;
    end
        
    if(MuxCSel == 1'b0)begin
        MuxCOut <= AOut;
    end
    else if(MuxCSel == 1'b1)begin
        MuxCOut <= ARFOutA;
    end
    end
    
        // Register File
    part_2b RF(.Clk(Clock), .I(MuxAOut), .O1Sel(RF_OutASel), .O2Sel(RF_OutBSel), .FunSel(RF_FunSel), .RSel(RF_RSel), .TSel(RF_TSel), .O1(AOut), .O2(BOut));

    // Address Register File
    part_2c ARF(.Clk(Clock), .I(MuxBOut), .OutASel(ARF_OutASel), .OutBSel(ARF_OutBSel), .FunSel(ARF_FunSel), .RSel(ARF_RSel), .OutA(ARFOutA), .OutB(Address));

    // IR
    IR_register_16 IR(.E(IR_Enable), .clk(Clock), .signal(IR_LH), .I(MemoryOut), .FunSel(IR_Funsel), .IROut(IROut)); 
    
    // ALU   
    ALU ALU(.clk(Clock), .A(MuxCOut),.B(BOut), .FunSel(ALU_FunSel), .OutALU(ALUOut), .flag_register(ALUOutFlag));    

    //Memory
    Memory Memory(.clock(Clock), .address(Address), .data(ALUOut), .wr(Mem_WR), .cs(Mem_CS), .o(MemoryOut));
    
endmodule