module sin_tb();                                                                                                                                                      
                                                                                                                                                                      
reg clk;                                                                                                                                                              
reg rst_n;                                                                                                                                                            
                                                                                                                                                                      
reg       [13:0]   x;                                                                                                                                                 
reg [15:0] expected;                                                                                                                                                  
wire      [15:0]   sin;                                                                                                                                               
wire [31:0] s;                                                                                                                                                        
                                                                                                                                                                      
                                                                                                                                                                      
sin sinus                                                                                                                                                             
(                                                                                                                                                                     
 .clk    (clk),                                                                                                                                                       
 .rst_n  (rst_n),                                                                                                                                                     
 .x      (x),                                                                                                                                                         
 .sin    (sin)                                                                                                                                                        
);                                                                                                                                                                    
                                                                                                                                                                      
always begin                                                                                                                                                          
#10;                                                                                                                                                                  
clk = ~clk;                                                                                                                                                           
end                                                                                                                                                                   
reg [15 : 0] sin_table [4095 : 0];                                                                                                                                    
                                                                                                                                                                      
initial begin                                                                                                                                                         
    $readmemb("D:/Verilog/SIN/memory.mem", sin_table);                                                                                                                
end                                                                                                                                                                   
                                                                                                                                                                      
parameter TABLE_OFFSET = 3;                                                                                                                                           
                                                                                                                                                                      
task test_all();                                                                                                                                                      
integer i;                                                                                                                                                            
begin                                                                                                                                                                 
  for (i = 0; i < 4095; i = i + 1) begin                                                                                                                              
        x = (i << 2) + TABLE_OFFSET;                                                                                                                                  
                                                                                                                                                                      
        case(TABLE_OFFSET)                                                                                                                                            
            'd0: expected = (('d4*sin_table[i] + 'd0*sin_table[i+1]) >> 'd2);  //+1                                                                                   
            'd1: expected = (('d3*sin_table[i] + 'd1*sin_table[i+1]) >> 'd2);  //+1                                                                                   
            'd2: expected = (('d2*sin_table[i] + 'd2*sin_table[i+1]) >> 'd2); //+2                                                                                    
            'd3: expected = (('d1*sin_table[i] + 'd3*sin_table[i+1]) >> 'd2); //+3                                                                                    
       endcase                                                                                                                                                        
       #41;                                                                                                                                                           
        if (sin != expected) begin                                                                                                                                    
            $display("X %0X : INDEX0 %0D, INDEX1 %0D  Expected %0X  Actual %0X", x, `INDEX0, `INDEX1, expected, sin);                                                 
            $display("ERROR: expected %16b calculated %16b reminder %0X CHISL %0x  - %0X", expected, sin, `reminder, `CHISL, `CHISL - `reminder);                     
            $display("y0Coeff %0X y0Neg %0X SLAG0 %0X", `y0Coeff, `y0Neg, `SLAG0);                                                                                    
            $display("y1Coeff %0X y1Neg %0X SLAG1 %0X", `y1Coeff, `y1Neg, `SLAG1);                                                                                    
            $display("%0x", (sin_table[`INDEX1] & (~`RES_SIGN_BIT_MASK) ) | `SIGN_MASK );                                                                             
            //( (`y1Neg != 0) ? ( (sin_table[`INDEX1] & (~`RES_SIGN_BIT_MASK) ) | `SIGN_MASK ) : sin_table[`INDEX1] )                                                 
                                                                                                                                                                      
//        $display("X %0X : INDEX0 %0D, INDEX1 %0D", x, `INDEX0, `INDEX1);                                                                                            
//            $display("SLAG0 %0X  %0b", `SLAG0, `SLAG0);                                                                                                             
//            $display("SLAG1 %0X  %0b", `SLAG1, `SLAG1);                                                                                                             
                                                                                                                                                                      
//        $display("SIN %0X  %0b", s, s);                                                                                                                             
        end                                                                                                                                                           
    end                                                                                                                                                               
    $display("END ===========================");                                                                                                                      
end                                                                                                                                                                   
                                                                                                                                                                      
endtask                                                                                                                                                               
                                                                                                                                                                      
initial begin                                                                                                                                                         
    clk = 1'b0;                                                                                                                                                       
    test_all();                                                                                                                                                       
    //x = 14'hff4 << 2;                                                                                                                                               
end                                                                                                                                                                   
                                                                                                                                                                      
endmodule                                                                                                                                                             
                                                                                                                                                                                                                                                                                                                     
