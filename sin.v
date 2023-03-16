//Table Args  params
`define ARG_SIGNED  0  
`define ARG_INT_PART_BITS  2 
`define ARG_FRAC_PART_BITS 10
 
//Approximation  params
`define DIFF_BITS 2 // разница длин входного значения и индекса в таблице в битах 

//Result params
`define RES_SIGNED 1
`define RES_INT_PART_BITS 0
`define RES_FRAC_PART_BITS 15 


//Arg derived constants
`define ARG_TOTAL_BITS ( `ARG_SIGNED + `ARG_INT_PART_BITS + `ARG_FRAC_PART_BITS )

//Result derived constants
`define RES_TOTAL_BITS (`RES_SIGNED + `RES_INT_PART_BITS + `RES_FRAC_PART_BITS ) 
`define RES_SIGN_BIT_MASK (`RES_SIGNED ? 1 << (`RES_TOTAL_BITS - 1) : 0) 
 
`define APR_TOTAL_BITS (`ARG_TOTAL_BITS + `DIFF_BITS)
 
 //
`define CHISL (1 << 2) //`DIFF_BITS
`define INDEX0 (x >> `DIFF_BITS)
`define INDEX1 ((x >> `DIFF_BITS) + 1)
`define SIGN_MASK (1 << 31)
`define LONG_MASK (`SIGN_MASK - 1)

///// SLAG1

`define reminder ({30'b0, {x[1 : 0]}})
`define y1Coeff (`CHISL - `reminder)
`define y1Neg (sin_table[`INDEX0] & `RES_SIGN_BIT_MASK)

////// SLAG2
`define y2Coeff (`reminder)
`define y2Neg (sin_table[`INDEX1] & `RES_SIGN_BIT_MASK)

`define SLAG1 ( (`y1Neg != 0) ? ( ((sin_table[`INDEX0] & (~`RES_SIGN_BIT_MASK) ) * `y1Coeff ) | `SIGN_MASK ) : ( sin_table[`INDEX0] * `y1Coeff) )
`define SLAG2 ( (`y2Neg != 0) ? ( ((sin_table[`INDEX1] & (~`RES_SIGN_BIT_MASK) ) * `y2Coeff ) | `SIGN_MASK ) : ( sin_table[`INDEX1] * `y2Coeff) ) 


module sin 
(  
 
input                                   clk,  
input                                   rst_n,  
input         [`APR_TOTAL_BITS - 1:0]   x,
output  reg   [31:0]                    s,
output  reg   [`RES_TOTAL_BITS - 1:0]   sin 
 
    ); 

reg [`RES_TOTAL_BITS - 1 : 0] sin_table [4095 : 0];

initial begin 
   $readmemb("D:/Verilog/SIN/memory.mem", sin_table); 
end 
reg [11:0] ind1 = 0; 
reg [11:0] ind2 = 0; 

//reg [31:0] s = 0; 

reg error = 0;

always @(posedge clk) begin
    if (x > 14'h3ffc)
        error <= 1'b1;
    else if (x == 14'h3ffc)
        sin <= sin_table[`INDEX0];
    else if (x < 14'h3ffc) begin    
        if ((`SLAG1 & `SIGN_MASK) && (`SLAG2 & `SIGN_MASK)) begin 
            s <= (`SLAG1 & `LONG_MASK) + (`SLAG2 & `LONG_MASK); 
            s[31] <= 1; 
        end 
        
        if (!(`SLAG1 & `SIGN_MASK) && !(`SLAG2 & `SIGN_MASK)) begin 
            s <= `SLAG1 + `SLAG2; 
        end
        // 
        if (!(`SLAG1 & `SIGN_MASK) && (`SLAG2 & `SIGN_MASK)) begin 
            if ((`SLAG2 & `LONG_MASK) > (`SLAG1 & `LONG_MASK) ) begin 
                s <= (`SLAG2 & `LONG_MASK) - (`SLAG1 & `LONG_MASK); 
                s[31] <= 1; 
            end
            else begin 
                s <= (`SLAG1 & `LONG_MASK) - (`SLAG2 & `LONG_MASK); 
                s[31] <= 0; 
            end 
        end
        
        if (!(`SLAG2 & `SIGN_MASK) && (`SLAG1 & `SIGN_MASK)) begin 
            if ((`SLAG1 & `LONG_MASK) > (`SLAG2 & `LONG_MASK)) begin 
                s <= (`SLAG1 & `LONG_MASK) - (`SLAG2 & `LONG_MASK); 
                s[31] <= 1; 
            end 
            else begin 
                s <= (`SLAG2 & `LONG_MASK) - (`SLAG1 & `LONG_MASK); 
                s[31] <= 0; 
            end 
        end 
    end 
    sin <= s[31] ? ((s >> `DIFF_BITS) | `RES_SIGN_BIT_MASK) : (s >> `DIFF_BITS);
end 

endmodule
