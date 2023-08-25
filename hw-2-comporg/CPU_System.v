module CPUSystem(Clock, Reset,T);
  reg [2:0]RF_O1Sel; 
  reg [2:0]RF_O2Sel; 
  reg [1:0] RF_FunSel;
  reg [3:0] RF_RSel;
  reg [3:0] RF_TSel;
  reg [3:0] ALU_FunSel;
  reg [1:0] ARF_OutASel;
  reg [1:0] ARF_OutBSel;
  reg [1:0] ARF_FunSel;
  reg [3:0] ARF_RSel;
  reg IR_LH;
  reg IR_Enable;
  reg [1:0] IR_Funsel;
  reg Mem_WR;
  reg Mem_CS;
  reg [1:0] MuxASel;
  reg [1:0] MuxBSel;
  reg MuxCSel;
  
  input Clock;
  
  ALU_System alu_system(
   RF_O1Sel, 
   RF_O2Sel, 
    RF_FunSel,
    RF_RSel,
    RF_TSel,
    ALU_FunSel,
    ARF_OutASel, 
    ARF_OutBSel, 
    ARF_FunSel,
    ARF_RSel,
    IR_LH,
    IR_Enable,
    IR_Funsel,
    Mem_WR,
    Mem_CS,
    MuxASel,
    MuxBSel,
    MuxCSel, 
    Clock);
    
   
    input wire Reset;
    input wire [7:0] T;
    assign T = 8'd0;
    reg [7:0]ctr;
    reg CtrReset;
    assign Reset = 0;
    
     always@ (posedge Clock)
           begin 
           if(Reset)
               ctr <= 8'd0;
           else
            if (T == 0)
               ctr <= T + 8'd1;
            else
                ctr = T << 1;
       end
     
     assign T = ctr;
    
    reg [3:0] opCode;
    reg addressMode;
    reg [1:0] RSel;
    reg [7:0] address;
    
    reg [3:0] dstReg; 
    reg [3:0] sReg1, sReg2;
    
 
    reg [1:0] RFOut;//output we will get from rf system
   

    always @(*)
    begin
        case(T)
          0: // T0 first clock cycle, Load IR[7:0]   
            begin
                
                Mem_WR = 0; // Read from RAM
                Mem_CS = 0; // Chip is enable
                
                IR_Enable = 1; // IR is enabled
                IR_LH = 0; // LSB
                IR_Funsel = 2'b01; // Load
                
                ARF_FunSel = 2'b11; // Load and increment
                ARF_OutASel = 2'b11; // Output is Program Counter
                ARF_RSel = 4'b0001; // Enable PC
                
                RF_RSel = 4'b0000; // NO general purpose register is enabled. 
                
                CtrReset = 0;
            end
            
         1:// T0 second clock cycle, Load IR[15:8] 
            begin
                
                Mem_WR = 0; // Read from RAM
                Mem_CS = 0; // Chip is enable
                
                IR_Enable = 1; // IR is enabled
                IR_LH = 1; // MSB
                IR_Funsel = 2'b01; // Load
                
                ARF_FunSel = 2'b11; // Load and increment
                ARF_OutASel = 2'b11; // Output is Program Counter
                ARF_RSel = 4'b0001; // Enable PC
                
                RF_RSel = 4'b0000; // NO general purpose register is enabled.
                
                CtrReset = 0;
            end
        2://decode
            begin
                // IR_Enable = 0;
                opCode = alu_system.IROut[15:12];
                addressMode = alu_system.IROut[10];
                RSel = alu_system.IROut[9:8];
                address = alu_system.IROut[7:0];
                
                dstReg = alu_system.IROut[11:8];
                sReg1 = alu_system.IROut[7:4];
                sReg2 =  alu_system.IROut[3:0];
                    
                case(opCode)//first bits are the same so we compare last three bits
                
                    0:// AND
                    begin
                        ALU_FunSel = 4'b0111;//and operation
                        RF_RSel = dstReg[1:0];//rf register type is decided by the last 2 bits
                        if (dstReg[2] == 0) //destination register is one of the r registers
                        begin
                            RF_FunSel = 2'b01;//load operation
                            if(sReg1[2] == 0 && sReg2[2] == 0) // s registers are also one of the r registers
                            begin
                               RF_O1Sel = {1'b1, sReg1[1:0]};//r registers 3rd bit is 1
                               RF_O2Sel = {1'b1, sReg2[1:0]};
                                MuxCSel = 1'b0;//rf aout, both registers are rf
                            end
                            else
                            begin
                                if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is one of the r registers, sreg2 is one of the arf system registers
                                begin
                                    RFOut = sReg1[1:0];  
                                    ARF_OutASel = sReg2[1:0];//outA register selection depends on arfout which is last 2 bits of regs            
                                end
                                else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is one of the arf system registers, sreg2 is one of the r registers
                                begin
                                    ARF_OutASel = sReg1[1:0];
                                    RFOut = sReg2[1:0];   
                                end
                                                
                                else//both are arf system registers dest rf it is said that we can assume that at most 1 register from ARF will be chosen.
                                begin 
                                end
                               RF_O2Sel = {1'b1, RFOut};
                              
                                MuxCSel = 1'b1;//arf out
                            end
                        end
                        else if(sReg1[2] == 0 && sReg2[2] == 0) // both rf registers destination register is one of the arf system registers
                        begin
                           RF_O1Sel = {1'b1, sReg1[1:0]};
                           RF_O2Sel = {1'b1, sReg2[1:0]};
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];
                            MuxBSel = 2'b00;
                            MuxCSel = 0;
                        end
                        else
                        begin
                            if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is rf, sreg2 is arf
                                begin
                                ARF_OutASel = sReg2[1:0];
                                RFOut = sReg1[1:0];                 
                                end
                            else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is arf, sreg2 is rf
                                begin
                                ARF_OutASel = sReg1[1:0];
                                RFOut = sReg2[1:0];   
                                end
                            else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                               begin
                                end
                           RF_O2Sel = {1'b1, RFOut};
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];
                            MuxBSel = 2'b00;
                            MuxCSel = 1;
                        end
                    end

                    1:// OR
                    begin
                        ALU_FunSel = 4'b1000;//or operation
                        
                        RF_RSel = dstReg[1:0];//rf register type is decided by the last 2 bits
                        if (dstReg[2] == 0) //destination register is one of the r registers
                        begin
                            RF_FunSel = 2'b01;//loads the lsb
                            MuxASel = 2'b00;//output of the alu(and operation) is selected in muxa
                            if(sReg1[2] == 0 && sReg2[2] == 0) // s registers are also one of the r registers
                            begin
                               RF_O1Sel = {1'b1, sReg1[1:0]};//r registers 3rd bit is 1
                               RF_O2Sel = {1'b1, sReg2[1:0]};
                                MuxCSel = 1'b0;//rf aout, both registers are rf
                            end
                            else
                            begin
                                if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is one of the r registers, sreg2 is one of the arf system registers
                                begin
                                    RFOut = sReg1[1:0];  
                                    ARF_OutASel = sReg2[1:0];//outA register selevtion depends on arfout which is last 2 bits of regs            
                                end
                                else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is one of the arf system registers, sreg2 is one of the r registers
                                begin
                                    ARF_OutASel = sReg1[1:0];
                                    RFOut = sReg2[1:0];   
                                end
                                            
                                else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                                begin
                                end
                               RF_O2Sel = {1'b1, RFOut};//outbsel is 3 bits  and rf registers first bit is 1
                              
                                MuxCSel = 1'b1;//arf out
                            end
                        end
                            
                        else
                        begin
                            ARF_FunSel = 2'b01;
                            MuxBSel = 2'b00;//mux b output is aluout
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            if(sReg1[2] == 0 && sReg2[2] == 0) // both rf registers destination register is one of the arf system registers
                            begin
                                   RF_O1Sel = {1'b1, sReg1[1:0]};
                                   RF_O2Sel = {1'b1, sReg2[1:0]};
                                    MuxCSel = 0;//to select from rf
                            end
                            else if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is rf, sreg2 is arf
                            begin
                                ARF_OutASel = sReg2[1:0];
                                RFOut = sReg1[1:0];     
                                MuxCSel = 1'b1;      //to select from arf      
                            end
                            else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is arf, sreg2 is rf
                            begin
                                ARF_OutASel = sReg1[1:0];
                                RFOut = sReg2[1:0];  
                                MuxCSel = 1'b1;   //to select from arf
                            end
                            else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                            begin
                            end
                           RF_O2Sel = {1'b1, RFOut};
                        end
                    end
                    2:// NOT
                    begin
                        ALU_FunSel = 4'b0010;//and operation
                        if(dstReg[2] == 0&& sReg1[2]==0)
                        begin
                           RF_O1Sel = {1'b1, sReg1[1:0]};
                            RF_FunSel = 2'b01;//loads the lsb
                            RF_RSel = dstReg[1:0];
                            MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                        end
                        else if(dstReg[2] == 0 && sReg1[2] == 1)
                        begin 
                            ARF_OutASel = sReg1[1:0];
                            RF_FunSel = 2'b01;//loads the lsb
                            RF_RSel = dstReg[1:0];
                            MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                            MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                        end
                            
                        else if(dstReg[2] == 1 && sReg1[2] == 0)
                        begin
                           RF_O1Sel = {1'b1, sReg1[1:0]};
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            MuxBSel = 2'b00; //muxb output selected to written to arf
                        end
                        else
                        begin
                            ARF_OutASel = sReg1[1:0];
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            MuxBSel = 2'b00; //muxb output selected to written to arf
                            MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                        end
                    end
                    3:// ADD
                        begin
                        ALU_FunSel = 4'b0100;//add operation
                                                
                        RF_RSel = dstReg[1:0];//rf register type is decided by the last 2 bits
                        if (dstReg[2] == 0) //destination register is one of the r registers
                        begin
                            RF_FunSel = 2'b01;//loads the lsb
                            MuxASel = 2'b00;//output of the alu(and operation) is selected in muxa
                                if(sReg1[2] == 0 && sReg2[2] == 0) // s registers are also one of the r registers
                                begin
                                   RF_O1Sel = {1'b1, sReg1[1:0]};//r registers 3rd bit is 1
                                   RF_O2Sel = {1'b1, sReg2[1:0]};
                                    MuxCSel = 1'b0;//rf aout, both registers are rf
                                end
                                else
                                    begin
                                    if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is one of the r registers, sreg2 is one of the arf system registers
                                    begin
                                        RFOut = sReg1[1:0];  
                                        ARF_OutASel = sReg2[1:0];//outA register selevtion depends on arfout which is last 2 bits of regs            
                                    end
                                    else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is one of the arf system registers, sreg2 is one of the r registers
                                    begin
                                        ARF_OutASel = sReg1[1:0];
                                        RFOut = sReg2[1:0];   
                                    end
                                                
                                    else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                                    begin
                                    end
                                   RF_O2Sel = {1'b1, RFOut};//outbsel is 3 bits  and rf registers first bit is 1
                                  
                                    MuxCSel = 1'b1;//arf out
                                end
                            end
                            
                            else
                            begin
                                ARF_FunSel = 2'b01;
                                MuxBSel = 2'b00;//mux b output is aluout
                                ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                                if(sReg1[2] == 0 && sReg2[2] == 0) // both rf registers destination register is one of the arf system registers
                                begin
                                   RF_O1Sel = {1'b1, sReg1[1:0]};
                                   RF_O2Sel = {1'b1, sReg2[1:0]};
                                    MuxCSel = 0;//to select from rf
                                end
                                else if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is rf, sreg2 is arf
                                begin
                                    ARF_OutASel = sReg2[1:0];
                                    RFOut = sReg1[1:0];     
                                    MuxCSel = 1'b1;      //to select from arf      
                                end
                                else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is arf, sreg2 is rf
                                begin
                                    ARF_OutASel = sReg1[1:0];
                                    RFOut = sReg2[1:0];  
                                    MuxCSel = 1'b1;   //to select from arf
                                end
                                else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                                begin
                                end
                           RF_O2Sel = {1'b1, RFOut};
                            end
                    end
                    4:// SUB
                    begin 
                        ALU_FunSel = 4'b0101;//subtract operation
                        
                        RF_RSel = dstReg[1:0];//rf register type is decided by the last 2 bits
                        if (dstReg[2] == 0) //destination register is one of the r registers
                        begin
                            RF_FunSel = 2'b01;//loads the lsb
                            MuxASel = 2'b00;//output of the alu(and operation) is selected in muxa
                            if(sReg1[2] == 0 && sReg2[2] == 0) // s registers are also one of the r registers
                            begin
                               RF_O1Sel = {1'b1, sReg1[1:0]};//r registers 3rd bit is 1
                               RF_O2Sel = {1'b1, sReg2[1:0]};
                                MuxCSel = 1'b0;//rf aout, both registers are rf
                            end
                            else
                            begin
                                if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is one of the r registers, sreg2 is one of the arf system registers
                                begin
                                    RFOut = sReg1[1:0];  
                                    ARF_OutASel = sReg2[1:0];//outA register selevtion depends on arfout which is last 2 bits of regs            
                                end
                                else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is one of the arf system registers, sreg2 is one of the r registers
                                begin
                                    ARF_OutASel = sReg1[1:0];
                                    RFOut = sReg2[1:0];   
                                end
                                            
                                else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                                begin
                                end
                               RF_O2Sel = {1'b1, RFOut};//outbsel is 3 bits  and rf registers first bit is 1
                              
                                MuxCSel = 1'b1;//arf out
                           end
                        end
                        else
                        begin
                            ARF_FunSel = 2'b01;
                            MuxBSel = 2'b00;//mux b output is aluout
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            if(sReg1[2] == 0 && sReg2[2] == 0) // both rf registers destination register is one of the arf system registers
                            begin
                               RF_O1Sel = {1'b1, sReg1[1:0]};
                               RF_O2Sel = {1'b1, sReg2[1:0]};
                                MuxCSel = 0;//to select from rf
                            end
                            else if (sReg1[2] == 0 && sReg2[2] == 1) //sreg1 is rf, sreg2 is arf
                            begin
                                ARF_OutASel = sReg2[1:0];
                                RFOut = sReg1[1:0];     
                                MuxCSel = 1'b1;      //to select from arf      
                            end
                            else if(sReg1[2] == 1 && sReg2[2] == 0) //sreg1 is arf, sreg2 is rf
                            begin
                                ARF_OutASel = sReg1[1:0];
                                RFOut = sReg2[1:0];  
                                MuxCSel = 1'b1;   //to select from arf
                            end
                            else//both are arf system registers, it is said that we can assume that at most 1 register from ARF will be chosen.
                            begin
                            end
                           RF_O2Sel = {1'b1, RFOut};
                        end
                    end
                    5:// LSR
                    begin
                    ALU_FunSel = 4'b1100;//lsr operation
                    if(dstReg[2] == 0&& sReg1[2]==0)
                    begin
                       RF_O1Sel = {1'b1, sReg1[1:0]};
                        RF_FunSel = 2'b01;//loads the lsb
                        RF_RSel = dstReg[1:0];
                        MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                    end
                    else if(dstReg[2] == 0 && sReg1[2] == 1)
                    begin 
                        ARF_OutASel = sReg1[1:0];
                        RF_FunSel = 2'b01;//loads the lsb
                        RF_RSel = dstReg[1:0];
                        MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                        MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                    end
                        
                    else if(dstReg[2] == 1 && sReg1[2] == 0)
                    begin

                       RF_O1Sel = {1'b1, sReg1[1:0]};
                        ARF_FunSel = 2'b01;
                        ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                        MuxBSel = 2'b00; //muxb output selected to written to arf
                    end
                    else
                    begin
                        ARF_OutASel = sReg1[1:0];
                        ARF_FunSel = 2'b01;
                        ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                        MuxBSel = 2'b00; //muxb output selected to written to arf
                        MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                    end
                    end
                    6:// LSL
                    begin
                        ALU_FunSel = 4'b1011;//lsl operation
                        if(dstReg[2] == 0&& sReg1[2]==0)
                        begin
                           RF_O1Sel = {1'b1, sReg1[1:0]};
                            RF_FunSel = 2'b01;//loads the lsb
                            RF_RSel = dstReg[1:0];
                            MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                        end
                        else if(dstReg[2] == 0 && sReg1[2] == 1)
                        begin 
                            ARF_OutASel = sReg1[1:0];
                            RF_FunSel = 2'b01;//loads the lsb
                            RF_RSel = dstReg[1:0];
                            MuxASel = 2'b00;    //output of the alu(and operation) is selected in muxa and loaded onto rf dest reg
                            MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                        end
                            
                        else if(dstReg[2] == 1 && sReg1[2] == 0)
                        begin
                           RF_O1Sel = {1'b1, sReg1[1:0]};
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            MuxBSel = 2'b00; //muxb output selected to written to arf
                        end
                        else
                        begin
                            ARF_OutASel = sReg1[1:0];
                            ARF_FunSel = 2'b01;
                            ARF_RSel = dstReg[1:0];//dest reg is arf and we choose whicg register type it is
                            MuxBSel = 2'b00; //muxb output selected to written to arf
                            MuxCSel = 1'b1;  //to select from arf sreg data goes into alu
                        end
                    end
                    7:// INC
                    begin
                 
                   // ALU_FunSel = 4'b0100; // Is it necessary?
                   case(sReg1[2]) // Source Register
                       0: // RF
                       begin
                         
                           RF_RSel = 4'b0000;
                             case(sReg1[1:0])
                                 2'b00: RF_RSel[3] = 1;
                                 2'b01: RF_RSel[2] = 1;
                                 2'b10: RF_RSel[1] = 1;
                                 2'b11: RF_RSel[0] = 1;
                             endcase      
                          RF_O1Sel = {1'b1, sReg1[1:0]}; // 1.. 
                           RF_FunSel = 2'b11;
                           MuxBSel = 2'b00; // OutALU
                           MuxCSel = 1'b0;
                           // ARF Reg SEL ??
                           
                                                 
                           ARF_RSel = 4'b0000;
                           case(dstReg[1:0])
                               2'b00: ARF_RSel[2] = 1;
                               2'b01: ARF_RSel[3] = 1;
                               2'b10: ARF_RSel[1] = 1;
                               2'b11: ARF_RSel[0] = 1;
                       endcase
                          ARF_FunSel = 2'b01;
                       end
                       1:// ARF
                       begin
                            ARF_RSel = 4'b0000;
                          case(sReg1[1:0])
                              2'b00: ARF_RSel[2] = 1;
                              2'b01: ARF_RSel[3] = 1;
                              2'b10: ARF_RSel[1] = 1;
                              2'b11: ARF_RSel[0] = 1;
                           endcase
                           ARF_FunSel= 2'b11;
                           RF_RSel = 4'b0000;
                           case(dstReg[1:0])
                               2'b00: RF_RSel[3] = 1;
                               2'b01: RF_RSel[2] = 1;
                               2'b10: RF_RSel[1] = 1;
                               2'b11: RF_RSel[0] = 1;
                           endcase
                           RF_FunSel = 2'b01; // Load
                           MuxASel = 2'b11; // ARF OutA
                           ARF_OutASel = sReg1[1:0];
                           
                           // SP <-> AR  
                           if( ARF_OutASel == (2'b00))
                           begin
                               ARF_OutASel = 2'b01;
                           end
                           if( ARF_OutASel == (2'b01))
                           begin
                               ARF_OutASel = 2'b00;
                           end
                                                 
                       end
                   endcase
                                           
                    end
                    8:// DEC
                    begin
                 
                   // ALU_FunSel = 4'b0100; // Is it necessary?
                   case(sReg1[2]) // Source Register
                       0: // RF
                       begin
                         
                           RF_RSel = 4'b0000;
                             case(sReg1[1:0])
                                 2'b00: RF_RSel[3] = 1;
                                 2'b01: RF_RSel[2] = 1;
                                 2'b10: RF_RSel[1] = 1;
                                 2'b11: RF_RSel[0] = 1;
                             endcase      
                          RF_O1Sel = {1'b1, sReg1[1:0]}; // 1.. 
                           RF_FunSel = 2'b10;
                           MuxBSel = 2'b00; // OutALU
                           MuxCSel = 1'b0;
                           // ARF Reg SEL ??
                           
                                                 
                           ARF_RSel = 4'b0000;
                           case(dstReg[1:0])
                               2'b00: ARF_RSel[2] = 1;
                               2'b01: ARF_RSel[3] = 1;
                               2'b10: ARF_RSel[1] = 1;
                               2'b11: ARF_RSel[0] = 1;
                       endcase
                          ARF_FunSel = 2'b01;
                       end
                       1:// ARF
                       begin
                            ARF_RSel = 4'b0000;
                          case(sReg1[1:0])
                              2'b00: ARF_RSel[2] = 1;
                              2'b01: ARF_RSel[3] = 1;
                              2'b10: ARF_RSel[1] = 1;
                              2'b11: ARF_RSel[0] = 1;
                           endcase
                           ARF_FunSel= 2'b10;
                           RF_RSel = 4'b0000;
                           case(dstReg[1:0])
                               2'b00: RF_RSel[3] = 1;
                               2'b01: RF_RSel[2] = 1;
                               2'b10: RF_RSel[1] = 1;
                               2'b11: RF_RSel[0] = 1;
                           endcase
                           RF_FunSel = 2'b01; // Load
                           MuxASel = 2'b11; // ARF OutA
                           ARF_OutASel = sReg1[1:0];
                           
                           // SP <-> AR  
                           if( ARF_OutASel == (2'b00))
                           begin
                               ARF_OutASel = 2'b01;
                           end
                           if( ARF_OutASel == (2'b01))
                           begin
                               ARF_OutASel = 2'b00;
                           end
                                                 
                       end
                   endcase
                                           
                    end
                    9:// BRA
                    begin
                        ARF_FunSel = 2'b01; // Load
                        RF_RSel = 4'b0000; // Registers are not used
                        ARF_RSel = 4'b0001; // Load to PC
                        Mem_CS = 1; // Chip is disabled
                        
                        MuxBSel = 2'b10; // IR[7:0] Address
                    end
                    10:// BNE
                    begin                   
                        if(ALU_System.ALUOutFlag[3] == 1'b0) begin
                            ARF_FunSel = 2'b01; // Load
                            RF_RSel = 4'b0000; // Registers are not used
                            ARF_RSel = 4'b0001; // Load to PC
                            Mem_CS = 1; // Chip is disabled
                            
                            MuxBSel = 2'b10; // IR[7:0] Address
                        end
                    end
                    11:// MOV
                    begin
                        Mem_CS = 1; // Disabled?
                        ALU_FunSel = 4'b0001; // Is it necessary?
                        case(sReg1[2]) // Source Register
                            0: // RF
                            begin
                                case(dstReg[2]) // Destination Register
                                    0: // RF
                                    begin
                                       RF_O2Sel = {1'b1, sReg1[1:0]}; // 1.. 
                                        RF_FunSel = 2'b01; // Load
                                        RF_RSel = 4'b0000;
                                        case(dstReg[1:0])
                                            2'b00: RF_RSel[3] = 1;
                                            2'b01: RF_RSel[2] = 1;
                                            2'b10: RF_RSel[1] = 1;
                                            2'b11: RF_RSel[0] = 1;
                                        endcase
                                        MuxASel = 2'b00; // OutALU
                                    end
                                    1: // ARF
                                    begin
                                       RF_O2Sel = {1'b1, sReg1[1:0]}; // 1.. 
                                        MuxBSel = 2'b00; // OutALU
                                        // ARF Reg SEL ??
                                        ARF_RSel = 4'b0000;
                                        case(dstReg[1:0])
                                            2'b00: ARF_RSel[2] = 1;
                                            2'b01: ARF_RSel[3] = 1;
                                            2'b10: ARF_RSel[1] = 1;
                                            2'b11: ARF_RSel[0] = 1;
                                        endcase
                                    end
                                endcase
                            end
                            1:// ARF
                            begin
                                case(dstReg[2]) // Destination Register
                                    0: // RF
                                    begin
                                        RF_RSel = 4'b0000;
                                        case(dstReg[1:0])
                                            2'b00: RF_RSel[3] = 1;
                                            2'b01: RF_RSel[2] = 1;
                                            2'b10: RF_RSel[1] = 1;
                                            2'b11: RF_RSel[0] = 1;
                                        endcase
                                        RF_FunSel = 2'b01; // Load
                                        MuxASel = 2'b11; // ARF OutA
                                        ARF_OutASel = sReg1[1:0];
                                        
                                        // SP <-> AR  
                                        if( ARF_OutASel == (2'b00))
                                        begin
                                            ARF_OutASel = 2'b01;
                                        end
                                        if( ARF_OutASel == (2'b01))
                                        begin
                                            ARF_OutASel = 2'b00;
                                        end
                                    end
                                    1: // ARF
                                    begin
                                        MuxBSel = 2'b00; // OutALU
                                        MuxCSel = 1'b1; // ARFOutA
                                    end
                                endcase
                            end
                        endcase
                    end
                    12:// LD
                    begin
                        ARF_FunSel = 2'b01; // load
                        ARF_RSel = 4'b0000;// assigning value
                        Mem_CS = 0;
                        Mem_WR = 0;
                        
                        case(RSel)
                            2'b00: RF_RSel = 4'b0001;
                            2'b01: RF_RSel = 4'b0010;
                            2'b10: RF_RSel = 4'b0100;
                            2'b11: RF_RSel = 4'b1000;
                        endcase
                        if (addressMode == 1) //need to select direct or immediate
                            MuxASel = 2'b10;
                        else
                            MuxASel = 2'b01;            
                    end
                    13:// ST
                    begin                            
                       RF_O2Sel = RSel;
                        ALU_FunSel = 4'b0001;
                        Mem_CS = 0;         
                    end
                    14:// PUL
                    begin
                       RF_O2Sel = RSel; // assigning value, sending to O2
                        ALU_FunSel = 4'b0001; // O2 choosen,send to memory  
                        ARF_OutBSel = 2'b01; //SP choosen
                        ARF_FunSel = 2'b11; //increment
                        ARF_RSel = 4'b0001; // SP
                        Mem_CS = 0;
                        Mem_WR = 0; // Read  
                    end
                    15:// PSH
                    begin
                       RF_O2Sel = RSel; // assigning value, sending to O2
                        ALU_FunSel = 4'b0001; // O2 choosen,send to memory  M[SP]<-Rx
                        ARF_OutBSel = 2'b01; //SP choosen
                        ARF_FunSel = 2'b10; //decrement
                        ARF_RSel = 4'b0001; // SP 
                        Mem_CS = 0;
                        Mem_WR = 1;
                    end                          
                endcase
                CtrReset =1;
            end
        endcase
    end
    assign Reset = CtrReset;
endmodule