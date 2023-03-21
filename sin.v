`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.02.2023 14:51:37
// Design Name: 
// Module Name: sin
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Index bits
`define ARG_SIGNED  0            // знаковый/беззнаковый тип
`define ARG_INT_PART_BITS  2     // количество бит отвечающих за целую часть 
`define ARG_FRAC_PART_BITS 10    // количество бит отвечающих дробную часть
 
//Approximation  params
`define DIFF_BITS 2              // разница длин входного значения и индекса в таблице в битах 

//Result bits
`define RES_SIGNED 1             // знаковый/беззнаковый тип
`define RES_INT_PART_BITS 0      // количество бит отвечающих за целую часть 
`define RES_FRAC_PART_BITS 15    // количество бит отвечающих дробную часть


//Arg derived constants
`define ARG_TOTAL_BITS ( `ARG_SIGNED + `ARG_INT_PART_BITS + `ARG_FRAC_PART_BITS )      // Количество бит в индексе в таблице
`define TABLE_SIZE (1 << `ARG_TOTAL_BITS)                                              // количество элементов в таблице (2^ARG_TOTAL_BITS = 4096)
`define MAX_TABLE_INDEX ((1 << `ARG_TOTAL_BITS) -1)                                    // максимальный индекс в таблице


//Result derived constants
`define RES_TOTAL_BITS (`RES_SIGNED + `RES_INT_PART_BITS + `RES_FRAC_PART_BITS )       // Количество бит в результате
`define RES_SIGN_BIT_MASK (`RES_SIGNED ? 1 << (`RES_TOTAL_BITS - 1) : 0)               // маска для выставления старшего бита результата в зависимости от знака
 
`define APR_TOTAL_BITS (`ARG_TOTAL_BITS + `DIFF_BITS)                                  // Количество бит во входном значении
`define MAX_APR_VAL (`MAX_TABLE_INDEX << `DIFF_BITS)                                   // Максимальное значение входного значения, которое может поместиться в таблицу
 
 //
`define CHISL (1 << `DIFF_BITS)             // 
`define INDEX0 (x >> `DIFF_BITS)            // первый индекс промежутка, куда попадает входное значение
`define INDEX1 ((x >> `DIFF_BITS) + 1)      // второй индекс промежутка, куда попадает входное значение
`define SIGN_MASK (1 << 31)                 // маска для установления старшего бита(знака) в 32 битном регистре
`define LONG_MASK (`SIGN_MASK - 1)          // маска для проверки старшего бита(знака) в 32 битном регистре
 
`define reminder ({30'b0, {x[1 : 0]}})      // остаток входного значения после его сдвига

////////////////// Разложение аппроксимации синуса на слагаемые
///// SLAG0
`define y0Coeff (`CHISL - `reminder)  
`define y0Neg (sin_table[`INDEX0] & `RES_SIGN_BIT_MASK)
`define Y0Neg_x_COEF0  (((sin_table[`INDEX0] & (~`RES_SIGN_BIT_MASK) ) * `y0Coeff ) | `SIGN_MASK)
`define Y0_x_COEF0       (sin_table[`INDEX0]                           * `y0Coeff )

////// SLAG1
`define y1Coeff (`reminder)
`define y1Neg (sin_table[`INDEX1] & `RES_SIGN_BIT_MASK)

`define Y1Neg_x_COEF1  (((sin_table[`INDEX1] & (~`RES_SIGN_BIT_MASK) ) * `y1Coeff ) | `SIGN_MASK)
`define Y1_x_COEF1       (sin_table[`INDEX1]                           * `y1Coeff )

`define SLAG0 ( (`y0Neg != 0) ? `Y0Neg_x_COEF0 : `Y0_x_COEF0)
`define SLAG1 ( (`y1Neg != 0) ? `Y1Neg_x_COEF1 : `Y1_x_COEF1) 


module sin 
(  
 
input                                   clk,  
input                                   rst_n,  
input         [`APR_TOTAL_BITS - 1:0]   x,                               // входное 14 битное значение
output  reg   [`RES_TOTAL_BITS - 1:0]   sin                              // значение синуса
 
    ); 

reg [`RES_TOTAL_BITS - 1 : 0] sin_table [`TABLE_SIZE - 1 : 0];           // таблица со значениями синуса

initial begin 
   $readmemb("D:/Verilog/SIN/memory.mem", sin_table); 
end 

reg [31:0] s = 0;                                                         // 32 битный результат (на случай переполнения) вычисления синуса

reg error = 0;                                                            // флаг ошибки

always @(posedge clk) begin
    if (x > `MAX_APR_VAL)                                                 // проверка, если входное значение превышает максимальный индекс в таблице
        error <= 1'b1;
    else if (x == `MAX_APR_VAL)                                           // проверка, если входное значение совпадает с максимальным индексом в таблице
        sin <= sin_table[`INDEX0];
    else if (x < `MAX_APR_VAL) begin
//////// вычисление s в зависимости от знака SLAG1 и SLAG2 //////////////
        if ((`SLAG0 & `SIGN_MASK) && (`SLAG1 & `SIGN_MASK)) begin 
            s <= (`SLAG0 & `LONG_MASK) + (`SLAG1 & `LONG_MASK); 
            s[31] <= 1; 
        end 
        
        if (!(`SLAG0 & `SIGN_MASK) && !(`SLAG1 & `SIGN_MASK)) begin 
            s <= `SLAG0 + `SLAG1; 
        end
        // 
        if (!(`SLAG0 & `SIGN_MASK) && (`SLAG1 & `SIGN_MASK)) begin 
            if ((`SLAG1 & `LONG_MASK) > (`SLAG0 & `LONG_MASK) ) begin 
                s <= (`SLAG1 & `LONG_MASK) - (`SLAG0 & `LONG_MASK); 
                s[31] <= 1; 
            end
            else begin 
                s <= (`SLAG0 & `LONG_MASK) - (`SLAG1 & `LONG_MASK); 
                s[31] <= 0; 
            end 
        end
        
        if (!(`SLAG1 & `SIGN_MASK) && (`SLAG0 & `SIGN_MASK)) begin 
            if ((`SLAG0 & `LONG_MASK) > (`SLAG1 & `LONG_MASK)) begin 
                s <= (`SLAG0 & `LONG_MASK) - (`SLAG1 & `LONG_MASK); 
                s[31] <= 1; 
            end 
            else begin 
                s <= (`SLAG1 & `LONG_MASK) - (`SLAG0 & `LONG_MASK); 
                s[31] <= 0; 
            end 
        end 
    end 
    sin <= s[31] ? ((s >> `DIFF_BITS) | `RES_SIGN_BIT_MASK) : (s >> `DIFF_BITS);
end 

endmodule
