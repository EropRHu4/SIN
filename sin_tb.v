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
 .s      (s),                                                                                                                               
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
                                                                                                                                            
parameter TABLE_OFFSET = 0;                                                                                                                 
                                                                                                                                            
task test_all();                                                                                                                            
integer i;                                                                                                                                  
begin                                                                                                                                       
  for (i = 0; i < 4096; i = i + 1) begin                                                                                                    
        x = (i << 2) + TABLE_OFFSET;                                                                                                        
                                                                                                                                            
        case(TABLE_OFFSET)                                                                                                                  
            'd0: expected = (('d4*sin_table[i] + 'd0*sin_table[i+1]) >> 'd2);  //+1                                                         
            'd1: expected = (('d3*sin_table[i] + 'd1*sin_table[i+1]) >> 'd2);  //+1                                                         
            'd2: expected = (('d2*sin_table[i] + 'd2*sin_table[i+1]) >> 'd2); //+2                                                          
            'd3: expected = (('d1*sin_table[i] + 'd3*sin_table[i+1]) >> 'd2); //+3                                                          
       endcase                                                                                                                              
       #41;                                                                                                                                 
        $display("X %0X : INDEX0 %0D, INDEX1 %0D  Expected %0X  Actual %0X", x, `INDEX0, `INDEX1, expected, sin);                           
        if (sin != expected)                                                                                                                
            $display("ERROR: expected %16b calculated %16b", expected, sin);                                                                
//        $display("X %0X : INDEX0 %0D, INDEX1 %0D", x, `INDEX0, `INDEX1);                                                                  
//            $display("SLAG1 %0X  %0b", `SLAG1, `SLAG1);                                                                                   
//            $display("SLAG2 %0X  %0b", `SLAG2, `SLAG2);                                                                                   
                                                                                                                                            
//        $display("SIN %0X  %0b", s, s);                                                                                                   
    end                                                                                                                                     
    $display("END ===========================");                                                                                            
end                                                                                                                                         
                                                                                                                                            
endtask                                                                                                                                     
                                                                                                                                            
initial begin                                                                                                                               
    clk = 1'b0;                                                                                                                             
    //test_all();                                                                                                                           
    //x = 14'hff4 << 2;                                                                                                                     
end                                                                                                                                         
                                                                                                                                            
endmodule                                                                                                                                   
                                                                                                                                            
