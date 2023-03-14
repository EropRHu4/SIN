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
initial begin
    clk = 1'b0;
    rst_n = 0;
    //x = (14'hffe << 2) + 1;
    for (integer i = 0; i < 256; i = i + 1) begin
        x = (i << 2) + 0;
        expected = sin_table[i]; //+0
        //expected = ((sin_table[i] + sin_table[i+1]) >> 1);  //+1
        //expected = ((sin_table[i] + sin_table[i+1]) >> 1); //+2
        //expected = ((sin_table[i] + sin_table[i+1]) >> 1); //+3
        $display("X %0X : INDEX0 %0D, INDEX1 %0D", x, `INDEX0, `INDEX1);
        if (sin != expected)
            $display("ERROR: expected %0X calculated %0X", expected, sin);
  /*      $display("X %0X : INDEX0 %0D, INDEX1 %0D", x, `INDEX0, `INDEX1);
        $display("SLAG1 %0X  %0b", `SLAG1, `SLAG1);
        $display("SLAG2 %0X  %0b", `SLAG2, `SLAG2);
        $display("SIN %0X  %0b", s, s);
        $display("===========================");*/
    end
    #100;
    rst_n = 1;
end

endmodule
