`define DIFF_BITS 2 // разница длин входного значения и индекса в таблице в битах 
`define ARG_SIGNED  0  
`define ARG_INT_PART_BITS  2 
`define ARG_FRAC_PART_BITS  12 

`define RES_SIGNED 1
`define RES_INT_PART_BITS 0
`define RES_FRAC_PART_BITS 15 
`define RES_TOTAL_BITS (`RES_SIGNED + `RES_INT_PART_BITS + `RES_FRAC_PART_BITS) 
`define RES_SIGN_BIT_MASK (`RES_SIGNED ? 1 << (`RES_TOTAL_BITS - 1) : 0) 
 
`define CHISL 1 << 2 //DIFF_BITS
`define INDEX0 (x >> `DIFF_BITS)
`define INDEX1 ((x >> `DIFF_BITS) + 1)
`define SIGN_MASK (1 << 31)
`define LONG_MASK (`SIGN_MASK - 1)
`define SLAG1 ( ({30'b0, {x[1 : 0]}}) * ( (sin_table[`INDEX0] & 16'h8000) ? ( (sin_table[`INDEX0] & ~`RES_SIGN_BIT_MASK ) | `SIGN_MASK ) : sin_table[`INDEX0] ) )
`define SLAG2 ( ({30'b0, {x[1 : 0]}}) * ( (sin_table[`INDEX1] & 16'h8000) ? ( (sin_table[`INDEX1] & ~`RES_SIGN_BIT_MASK ) | `SIGN_MASK ) : sin_table[`INDEX1] ) )

module sin 
#( 

parameter ARG_TOTAL_BITS = `ARG_SIGNED + `ARG_INT_PART_BITS + `ARG_FRAC_PART_BITS, 
parameter ARG_SIGN_BIT_MASK = `ARG_SIGNED ? 1 << (ARG_TOTAL_BITS - 1) : 0, 
parameter ARG_FRACT_HI_BIT = (1 << (`ARG_FRAC_PART_BITS - 1)), 
parameter ARG_FRACT_MASK = (1 << `ARG_FRAC_PART_BITS) - 1, 
parameter ARG_VALUES_COUNT = 1 << (ARG_TOTAL_BITS - 1), // -1 ???
parameter ARG_TOTAL_BITS_MASK = ARG_VALUES_COUNT -1, 
 
/////////////////////////// RES ///////////////////////////// 
 

 

 

parameter RES_FRACT_HI_BIT = (1 << (`RES_FRAC_PART_BITS - 1)), 
parameter RES_FRACT_MASK = (1 << `RES_FRAC_PART_BITS) - 1, 
parameter RES_VALUES_COUNT = 1 << `RES_TOTAL_BITS, 
parameter RES_TOTAL_BITS_MASK = RES_VALUES_COUNT -1, 
 
/////////////////////////// Approx ///////////////////////////// 
parameter APR_SIGNED = `ARG_SIGNED, 
parameter APR_INT_PART_BITS = `ARG_INT_PART_BITS, 
parameter APR_FRAC_PART_BITS = `ARG_FRAC_PART_BITS + `DIFF_BITS, 

parameter APR_TOTAL_BITS = APR_SIGNED + APR_INT_PART_BITS + APR_FRAC_PART_BITS - 2, // -2???
parameter APR_SIGN_BIT_MASK = APR_SIGNED ? 1 << (APR_TOTAL_BITS - 1) : 0, 
parameter APR_FRACT_HI_BIT = (1 << (APR_FRAC_PART_BITS - 1)), 
parameter APR_FRACT_MASK = (1 << APR_FRAC_PART_BITS) - 1, 
parameter APR_VALUES_COUNT = 1 << APR_TOTAL_BITS, 
parameter APR_TOTAL_BITS_MASK = APR_VALUES_COUNT -1

/////////////////////////////////////////////////////////////// 
) 
(  
 
input                 clk,  
input                 rst_n,  
input        [APR_TOTAL_BITS - 1:0]   x,
output  reg [31:0] s,
output reg   [`RES_TOTAL_BITS - 1:0]   sin 
 
    ); 

reg [`RES_TOTAL_BITS - 1 : 0] sin_table [4095 : 0];

initial begin 
   $readmemb("D:/Verilog/SIN/memory.mem", sin_table); 
end 
reg [11:0] ind1 = 0; 
reg [11:0] ind2 = 0; 

//reg [31:0] slag1 = 0; 
//reg [31:0] slag2 = 0; 
//reg [31:0] s = 0; 

reg error = 0;

always @(posedge clk) begin
    if (x > 14'h3ffc)
        error <= 1'b1;
    else if (x == 14'h3ffc)
        sin <= sin_table[`INDEX0];
    else if (x < 14'h3ffc /*&& !rst_n*/) begin
       
//       ind1 <= `INDEX0;
//       ind2 <= `INDEX1;
        // вычисление slag1
/*        if (sin_table[`INDEX0][15]) begin // y0[15]
            slag1 <= (`CHISL - {30'b0,{x[1:0]}}) * (sin_table[`INDEX0] & ~RES_SIGN_BIT_MASK ); 
            slag1[31] <= 1; 
        end
        else
            slag1 <= (`CHISL - {30'b0,{x[1:0]}}) * sin_table[`INDEX0];*/
        //     
//        if (sin_table[`INDEX1][15]) begin //y1[15] SIGN 
//            slag2 <= ({30'b0,{x[1:0]}}) * (sin_table[`INDEX1] & ~RES_SIGN_BIT_MASK); 
//            slag2[31] <= 1; 
//        end
//        else
//            slag2 <= ({30'b0,{x[1:0]}}) * (sin_table[`INDEX1]);
  
        //     
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
    //else begin
        sin <= s[31] ? ((s >> `DIFF_BITS) | `SIGN_MASK) : (s >> `DIFF_BITS);
    //end
end 

endmodule

