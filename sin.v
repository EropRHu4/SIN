module sin 
#( 
parameter ARG_SIGNED = 0, 
parameter ARG_INT_PART_BITS = 2, 
parameter ARG_FRAC_PART_BITS = 12, 
 
parameter ARG_TOTAL_BITS = ARG_SIGNED + ARG_INT_PART_BITS + ARG_FRAC_PART_BITS, 
parameter ARG_SIGN_BIT_MASK = ARG_SIGNED ? 1 << (ARG_TOTAL_BITS - 1) : 0, 
parameter ARG_FRACT_HI_BIT = (1 << (ARG_FRAC_PART_BITS - 1)), 
parameter ARG_FRACT_MASK = (1 << ARG_FRAC_PART_BITS) - 1, 
parameter ARG_VALUES_COUNT = 1 << (ARG_TOTAL_BITS - 1), // -1 ???
parameter ARG_TOTAL_BITS_MASK = ARG_VALUES_COUNT -1, 
 
/////////////////////////// RES ///////////////////////////// 
 
parameter RES_SIGNED = 1, 
parameter RES_INT_PART_BITS = 0, 
parameter RES_FRAC_PART_BITS = 15, 
 
parameter RES_TOTAL_BITS = RES_SIGNED + RES_INT_PART_BITS + RES_FRAC_PART_BITS, 
parameter RES_SIGN_BIT_MASK = RES_SIGNED ? 1 << (RES_TOTAL_BITS - 1) : 0, 
parameter RES_FRACT_HI_BIT = (1 << (RES_FRAC_PART_BITS - 1)), 
parameter RES_FRACT_MASK = (1 << RES_FRAC_PART_BITS) - 1, 
parameter RES_VALUES_COUNT = 1 << RES_TOTAL_BITS, 
parameter RES_TOTAL_BITS_MASK = RES_VALUES_COUNT -1, 
 
/////////////////////////// Approx ///////////////////////////// 
parameter DIFF_BITS = 2'b10, // разница длин входного значения и индекса в таблице в битах 
parameter APR_SIGNED = ARG_SIGNED, 
parameter APR_INT_PART_BITS = ARG_INT_PART_BITS, 
parameter APR_FRAC_PART_BITS = ARG_FRAC_PART_BITS + DIFF_BITS, 

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
output reg   [RES_TOTAL_BITS - 1:0]   sin  
 
    ); 
 
reg [RES_TOTAL_BITS - 1 : 0] sin_table [4095 : 0]; 
 
reg [ARG_TOTAL_BITS - 1 : 0] index0 = 0; // индекс начала промежутка, куда попадает входное значение 
reg [ARG_TOTAL_BITS - 1 : 0] index1 = 0; // индекс конца промежутка, куда попадает входное значение 
reg [RES_TOTAL_BITS - 1 : 0] mask = 0;   // маска для нахождения остатка от деления, при аппроксимации 
reg [RES_TOTAL_BITS - 1 : 0] reminder = 0; // статок от деления при аппроксимации, нужен для того, чтобы заменить деления битовыми сдвигами 
 
reg [RES_TOTAL_BITS - 1 : 0] y0 = 0; // sin_table[index0] 
reg [RES_TOTAL_BITS - 1 : 0] y1 = 0; // sin_table[index1] 
 
reg [31:0] chisl = 0; //  
reg [31:0] y0Coeff = 0; // коэффициент перед y0 
reg [31:0] y1Coeff = 0; // коэффициент перед y1 

initial begin 
   $readmemh("D:/S-terra/sin/memory.mem", sin_table); 
   index0 <= x >> DIFF_BITS;
end 

reg [31:0] slag1 = 0; 
reg [31:0] slag2 = 0; 
reg [31:0] s = 0; 

always @(posedge clk) begin 
    if (!rst_n) begin 
        //index0 <= x >> DIFF_BITS; 
        y0 <= sin_table[index0]; 
        index1 <= index0 + 1'b1; 
        y1 <= sin_table[index1]; 
        reminder <= {29'b0,{x[1:0]}}; //x & mask;        
        chisl <= 1 << DIFF_BITS; 
        y0Coeff <= chisl - reminder; 
        y1Coeff <= reminder; 
        if (y0[RES_TOTAL_BITS - 1]) begin 
            y0[RES_TOTAL_BITS - 1] = 0; 
            slag1 <= y0Coeff * y0; 
            slag1[31] <= 1; 
        end
        else
            slag1 <= y0Coeff * y0; 
        if (y1[RES_TOTAL_BITS - 1]) begin 
            y1[RES_TOTAL_BITS - 1] = 0; 
            slag2 <= y1Coeff * y1; 
            slag2[31] <= 1; 
        end
        else
            slag2 <= y1Coeff * y1; 
        if (slag1[31] && slag2[31]) begin 
            s <= slag1[30:0] + slag2[30:0]; 
            s[31] <= 1; 
        end 
        if (!slag1[31] && !slag2[31]) begin 
            s <= slag1 + slag2; 
        end 
        if (!slag1[31] && slag2[31]) begin 
            if (slag2[30:0] > slag1[30:0]) begin 
                s <= slag2[30:0] - slag1[30:0]; 
                s[31] <= 1; 
            end
        else begin 
                s <= slag1[30:0] - slag2[30:0]; 
                 s[31] <= 0; 
            end 
        end 
        if (!slag2[31] && slag1[31]) begin 
            if (slag1[30:0] > slag2[30:0]) begin 
                s <= slag1[30:0] - slag2[30:0]; 
                s[31] <= 1; 
            end 
            else begin 
                s <= slag2[30:0] - slag1[30:0]; 
                 s[31] <= 0; 
            end 
        end 
    end 
    else begin
        if (s[31]) begin 
            s <= s >> DIFF_BITS; 
            s[15] <= 1; 
            sin <= s[15:0]; 
        end 
        else begin 
            s <= s >> DIFF_BITS; 
            sin <= s[15:0]; 
        end 
    end
end 

endmodule
