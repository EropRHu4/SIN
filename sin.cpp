#include <iostream>
#include <math.h>
#include <fstream>
//#include <cmath>

constexpr double TwoPow(int x) { return x < 0 ? (1.0 / (1 << -x)) : (1 << x); }
constexpr double MaxFracPart(unsigned int k) { return k ? TwoPow(-(int)k) + MaxFracPart(k - 1) : 0; };

static_assert(TwoPow(-2) == 0.25, "");
static_assert(TwoPow(0)-1+TwoPow(-1) == 0.5, "");
static_assert(TwoPow(0) - 1 + TwoPow(-1) + TwoPow(-2) == 0.75, "");
static_assert(TwoPow(0) - 1 + TwoPow(-1) + TwoPow(-2) + TwoPow(-3) == 0.875, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(3) == 0.875, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(2) == 0.75, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(0) == 0, "");


template <uint8_t INT_PART_BITS, uint8_t FRAC_PART_BITS, uint8_t SIGNED = 0>
class FixedPoint {
    uint16_t X = 0;

public:

    enum {
        //        SIGNED = 1, INT_PART_BITS = 0, FRAC_PART_BITS = 15,
        TOTAL_BITS = SIGNED + INT_PART_BITS + FRAC_PART_BITS,
        SIGN_BIT_MASK = SIGNED ? 1 << (TOTAL_BITS - 1) : 0,
        FRACT_HI_BIT = (1 << (FRAC_PART_BITS - 1)),
        FRACT_MASK = (1 << FRAC_PART_BITS) - 1,
    };
    static_assert(SIGNED <= 1, "");
    static_assert(FRAC_PART_BITS > 0, "");
    static_assert(TOTAL_BITS > 0 && TOTAL_BITS <= std::numeric_limits<uint16_t>::digits, "");

    constexpr FixedPoint() = default;
    constexpr FixedPoint(uint16_t x) : X(x) {
       // if (x > maxV || x < minV)
        //    throw std::range_error("fixed point out of range"); // проверить что в х можно уместить в TOTAL_BITS

    };

    constexpr FixedPoint(double x) {
        constexpr auto maxV = MaxVal();
        constexpr auto minV = MinVal();
        if (x > maxV || x < minV)
            throw std::range_error("fixed point out of range");

        //negative Sign
        uint16_t signBit = (x < 0) ? SIGN_BIT_MASK : 0;
        if (x < 0)
            x = -x;
  
        // перевод целой части в двоичный формат
        uint16_t intPart = int(x) << FRAC_PART_BITS;

        // перевод дробной части в двоичный формат
        uint16_t fractPart = 0;
        double fract = x - int(x);
        uint16_t fractMask = FRACT_HI_BIT;
        for (uint16_t bitNum = 0; bitNum < FRAC_PART_BITS; ++bitNum) {

            fract *= 2;
            if (fract >= 1) {
                fract = fract - 1;
                fractPart |= fractMask;
            }
            fractMask >>= 1;
        }
        X = signBit | intPart | fractPart;
    }

    constexpr operator double () const {
        bool negative = (X & SIGN_BIT_MASK);

        uint16_t int_part = (X & ~SIGN_BIT_MASK) >> FRAC_PART_BITS;
        uint16_t fract_part = X & FRACT_MASK;
        double fract = 0;

        //uint16_t i = 1;
        uint16_t fractMask = FRACT_HI_BIT;
        // перевод дробной части в десятичный формат
        for (uint16_t i = 1; i <= FRAC_PART_BITS; ++i) {
            if (X & fractMask)
                fract = fract + 1.0 / (1 << i);
            fractMask >>= 1;
        }

        double res = int_part + fract;
        return (negative ? -res : res);
    }

    constexpr static double MaxVal() { return TwoPow(INT_PART_BITS) - 1. + MaxFracPart(FRAC_PART_BITS); }
    constexpr static double MinVal() { return SIGNED ? -MaxVal() : 0; }
//    constexpr static double Epsilon() { return ......; }

    constexpr uint16_t GetRaw() const{ return X; }
};
 
template <uint8_t INT_PART_BITS, uint8_t FRAC_PART_BITS, uint8_t SIGNED>
std::ostream& operator<<(std::ostream& out, const FixedPoint<INT_PART_BITS, FRAC_PART_BITS, SIGNED>& obj){
    using FP_Type = FixedPoint<INT_PART_BITS, FRAC_PART_BITS, SIGNED>;
 
    uint16_t mask = 1 << (FP_Type::TOTAL_BITS - 1);
    out << FP_Type::TOTAL_BITS << "b`";
    uint16_t raw = obj.GetRaw();
    while (mask) {
        out << ((mask & raw) ? "1" : "0");
        mask = mask >> 1;
    }
  //  out << "; //" << std::dec << raw << ", 16`h" << std::hex << raw << std::dec << std::endl; // 
    return out;
}


struct SinTable {
    using ArgType = FixedPoint<2, 10>;
    using ArgTypeApprox = FixedPoint<2, 12>;
    using ResultType = FixedPoint<0, 15, 1>;


    SinTable() {
        for (int i = 0; i < 4096; ++i) {
            double x = (i * 4.0) / 4096.0;
            ArgType aX = x;
            double tmp = sin(aX);
            if (tmp > ResultType::MaxVal()) {
                tmp = ResultType::MaxVal();
            }
            Table[i] = tmp;
        }
    }

    ResultType GetSinInterpolated(ArgTypeApprox x) {
        ResultType result;

    }

    ResultType Table[4096];
};
void TestApprox() {
    using ArgType = FixedPoint<2, 10>;
    using ResultType = FixedPoint<0, 15, 1>;
    ResultType sinTable[4096];
    for (int i = 0; i < 4096; ++i) {
        double x = (i * 4.0) / 4096.0;
        ArgType aX = x;
        double tmp = sin(aX);
        if (tmp > ResultType::MaxVal()) {
            tmp = ResultType::MaxVal();
        }

        sinTable[i] = tmp;
    }
}


bool GenerateTable(std::ostream& out) {
    using ArgType = FixedPoint<2, 10>;
    using ResultType = FixedPoint<0, 15, 1>;

    out << "reg [15:0] sin_table [4095:0];" << std::endl;
    for (int i = 0; i < 4096; ++i) {
        double x = (i*4.0) / 4096.0 ;
        ArgType aX = x;
        static_assert(ArgType::MaxVal() == 3.9990234375, "");
        //static_assert(ResultType::MaxVal() == 0.999...., "");
        double y = sin(x);
        double tmp = sin(aX);
        if (tmp > ResultType::MaxVal()) {
            out << "// truncated: " << tmp << " to  " << ResultType::MaxVal() << std::endl;
            tmp = ResultType::MaxVal();
        }

        ResultType aY = tmp;

        out << "sin_table[" << i << "] <= " << aY << "; // sin(" << (double)aX << ") = " << (double)aY << std::endl;
    }
    return true;
}

void Test1() {
    constexpr FixedPoint<2, 10> x(3.9990234);
    constexpr FixedPoint<0, 15, 1> x2(0.875);
    constexpr FixedPoint<0, 15, 1> x3(-0.875);
    constexpr double x2_1 = x2;
    static_assert(x2 == x2_1, "");
    static_assert(0.875 == x2_1, "");
    static_assert(-0.875 == x3, "");

    double eps = 0.001;
    for (int i = 0; i <= 3999; ++i)
    {
        double tmp = i / 1000.0;
        FixedPoint<2, 10> x(tmp);
        if (abs(tmp - x) > eps)
            std::cout << "FAIL:" << tmp << ":" << x << std::endl;
        else
            std::cout << tmp << ":" << (double)x << ":" << x << std::endl;
    }

    std::cout << x2 << "  " << x2_1 << std::endl;
}

int main(){
   // Test1();
    std::ofstream out;         // поток для записи

    out.open("D:memory.txt"); // окрываем файл для записи

    bool ok = GenerateTable(std::cout);
    if (!ok){
        std::cout << "ERROR!!\n";
    }
}
