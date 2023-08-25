module Counter(
    input Clock,
    input clear,
    output reg [2:0] out);
    
    initial out = 0;

    always@ (posedge Clock)
        begin 
        if(clear)
            out <= 3'd0;
        else
            out <= out + 3'd1;
    end
endmodule