#include <iostream>
#include <math.h>
#include <fstream>
#include <cmath>
#include <numbers>

using namespace std::numbers;

constexpr double TwoPow(int x) { return x < 0 ? (1.0 / (1 << -x)) : (1 << x); }
constexpr double MaxFracPart(unsigned int k) { return k ? TwoPow(-(int)k) + MaxFracPart(k - 1) : 0; };

static_assert(TwoPow(-2) == 0.25, "");
static_assert(TwoPow(0)-1+TwoPow(-1) == 0.5, "");
static_assert(TwoPow(0) - 1 + TwoPow(-1) + TwoPow(-2) == 0.75, "");
static_assert(TwoPow(0) - 1 + TwoPow(-1) + TwoPow(-2) + TwoPow(-3) == 0.875, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(3) == 0.875, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(2) == 0.75, "");
static_assert(TwoPow(0) - 1 + MaxFracPart(0) == 0, "");


constexpr double EpsilonRequired = 0.0003;

template <uint8_t INT_PART_BITS_, uint8_t FRAC_PART_BITS_, uint8_t SIGNED_ = 0>
class FixedPoint {
    uint16_t X = 0;

public:

    enum {
        SIGNED = SIGNED_, INT_PART_BITS = INT_PART_BITS_, FRAC_PART_BITS = FRAC_PART_BITS_,
        TOTAL_BITS = SIGNED + INT_PART_BITS + FRAC_PART_BITS,
        SIGN_BIT_MASK = SIGNED ? 1 << (TOTAL_BITS - 1) : 0,
        FRACT_HI_BIT = (1 << (FRAC_PART_BITS - 1)),
        FRACT_MASK = (1 << FRAC_PART_BITS) - 1,
        VALUES_COUNT = 1 << TOTAL_BITS,
        TOTAL_BITS_MASK = VALUES_COUNT -1,
    };

    using Type = FixedPoint<INT_PART_BITS, FRAC_PART_BITS, SIGNED>;

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
        uint16_t signBit = uint16_t( (x < 0) ? SIGN_BIT_MASK : 0);
        if (x < 0)
            x = -x;
  
        // перевод целой части в двоичный формат
        uint16_t intPart = uint16_t(uint16_t(x) << FRAC_PART_BITS);

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
        X = uint16_t(signBit | intPart | fractPart);
    }

    constexpr operator double () const {
        uint16_t int_part = uint16_t((X & (~SIGN_BIT_MASK)) >> FRAC_PART_BITS);
//        uint16_t fract_part = uint16_t(X & FRACT_MASK);
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
        return (IsNegative() ? -res : res);
    }

    constexpr Type Abs()const { return Type(uint16_t(X & ~SIGN_BIT_MASK)); }
    constexpr bool IsNegative()const { return X & SIGN_BIT_MASK; }
    constexpr void MakeNegative() { 
        X |= SIGN_BIT_MASK; 
    }


    constexpr static double HighEdge() { return TwoPow(INT_PART_BITS); }
    constexpr static double MaxVal() { return TwoPow(INT_PART_BITS) - 1. + MaxFracPart(FRAC_PART_BITS); }
    constexpr static double MinVal() { return SIGNED ? -MaxVal() : 0; }
//    constexpr static double Epsilon() { return ......; }
    
//    static_assert(Epsilon() <= EpsilonRequired, "");
    constexpr uint16_t GetRaw() const{ return X; }
};
 
template <typename T1>
constexpr auto Summ(T1 lhs, T1 rhs) {
    bool negativeLhs = lhs.IsNegative();
    bool negativeRhs = rhs.IsNegative();
    bool negativeResut = false;
    uint16_t res=0;
    if (negativeRhs && !negativeLhs){
        negativeResut = (rhs.Abs().GetRaw() > lhs.GetRaw());
        if (negativeResut)
            res = rhs.Abs().GetRaw() - lhs.Abs().GetRaw();
        else
            res = lhs.Abs().GetRaw() - rhs.Abs().GetRaw();
    }
    else if (!negativeRhs && negativeLhs) {
        negativeResut = (rhs.GetRaw() < lhs.Abs().GetRaw());
        if (negativeResut)
            res = lhs.Abs().GetRaw() - rhs.Abs().GetRaw();
        else
            res = rhs.Abs().GetRaw() - lhs.Abs().GetRaw();
    }
    else if (!negativeRhs && !negativeLhs) {
        negativeResut = false;
        res = rhs.Abs().GetRaw() + lhs.Abs().GetRaw();
    }
    else { //if (negativeRhs && negativeLhs)
        negativeResut = true;
        res = rhs.Abs().GetRaw() + lhs.Abs().GetRaw();
    }

    uint16_t sign_mask = (1 << T1::INT_PART_BITS + 1 + T1::FRAC_PART_BITS);
    res = negativeResut ? (res | sign_mask) : res;

    return FixedPoint<T1::INT_PART_BITS + 1, T1::FRAC_PART_BITS, T1::SIGNED>(res);
}


template <uint8_t INT_PART_BITS, uint8_t FRAC_PART_BITS, uint8_t SIGNED>
std::ostream& operator<<(std::ostream& out, const FixedPoint<INT_PART_BITS, FRAC_PART_BITS, SIGNED>& obj){
    using FP_Type = FixedPoint<INT_PART_BITS, FRAC_PART_BITS, SIGNED>;
 
    uint16_t mask = 1 << (FP_Type::TOTAL_BITS - 1);
    out << FP_Type::TOTAL_BITS << "'b";
    uint16_t raw = obj.GetRaw();
    while (mask) {
        out << ((mask & raw) ? "1" : "0");
        mask = mask >> 1;
    }
  //  out << "; //" << std::dec << raw << ", 16`h" << std::hex << raw << std::dec << std::endl; // 
    return out;
}


template <typename ArgType, typename ResultType>
struct SinTable {
//    using ArgType = FixedPoint<2, 10>;
//    using ArgTypeApprox = FixedPoint<2, 12>;
//    using ResultType = FixedPoint<0, 15, 1>;


    constexpr SinTable() {
        for (int i = 0; i < ArgType::VALUES_COUNT; ++i) {
            double x = (i * ArgType::HighEdge()) / ArgType::VALUES_COUNT;
            X_Table[i] = x;
            ArgType aX = x;
            double tmp = sin(aX);
            if (tmp > ResultType::MaxVal()) {
                tmp = ResultType::MaxVal(); //!!!!! truncated
            }
            Table[i] = tmp;
            DeviationTable[i] = tmp - Table[i];
        }
    }

    template <typename ArgTypeApprox>
    constexpr ResultType GetSinInterpolated(ArgTypeApprox x_fp) {
        if (x_fp > ArgType::MaxVal())
            throw std::range_error("ApproxArg is out of range");
        static_assert(ArgTypeApprox::TOTAL_BITS > ArgType::TOTAL_BITS,"FAIL");
        ArgType index0 = uint16_t(x_fp.GetRaw() >> (ArgTypeApprox::TOTAL_BITS - ArgType::TOTAL_BITS));
        ResultType y0 = Table[index0.GetRaw()];
        if (index0.GetRaw() == ArgType::TOTAL_BITS_MASK) //Edge
            return y0;

        ArgType index1 = uint16_t(index0.GetRaw() + 1); 
        ResultType y1 = Table[index1.GetRaw()];

        uint16_t mask = (1 << (ArgTypeApprox::TOTAL_BITS - ArgType::TOTAL_BITS)) - 1;
        uint16_t reminder = uint16_t(x_fp.GetRaw() & mask);

        // double y = x0 + (x - x0) / (x1 - x0) * (y1 - y0);
        uint32_t chisl = 1 << (ArgTypeApprox::TOTAL_BITS - ArgType::TOTAL_BITS);
        uint32_t y0Coeff = chisl - reminder;
        uint32_t y1Coeff = reminder;

        int y0Neg = y0.IsNegative() ? -1 : 1;
        int32_t slag1 = y0Coeff * (y0.Abs().GetRaw()) * y0Neg;

        int y1Neg = y1.IsNegative() ? -1 : 1;
        int32_t slag2 = y1Coeff * (y1.Abs().GetRaw()) * y1Neg;

        int32_t s = slag2 + slag1;
        
        bool sNeg = s < 0 ? 1 : 0;
        s = abs(s);
        s = s >> uint8_t(ArgTypeApprox::TOTAL_BITS - ArgType::TOTAL_BITS);
        if (s >= ResultType::SIGN_BIT_MASK)
            throw std::logic_error("Internal overflow");

        ResultType r = uint16_t(s) ;
        if (sNeg) 
            r.MakeNegative();
        return r;
    }

    ResultType Table[ArgType::VALUES_COUNT];
    double X_Table[ArgType::VALUES_COUNT];
    double DeviationTable[ArgType::VALUES_COUNT];
};


template <typename ApproxArgType, typename ArgType, typename ResultType>
double TestArgs(double arg, SinTable<ArgType, ResultType>& st, double eps)
{
    ApproxArgType x(arg);
    double exact = sin(arg);
    ResultType yA = st.GetSinInterpolated(x);
    double yAd = yA;
    if (abs(yAd - exact) > eps)
        std::cout << "Precision requirement violation: exact = "<< exact << " Interpolated = " << yAd << "(" << (exact - yAd) << ")" << std::endl;
    return yAd;
}

///////////////////////////////////////
template <typename ArgType, typename ResultType, typename ApproxArgType>
void TestApprox() {
     SinTable<ArgType, ResultType> st;
     double eps = 0.0001;

     TestArgs<ApproxArgType>(0, st, eps);
     TestArgs<ApproxArgType>(pi/2, st, eps);
     TestArgs<ApproxArgType>(pi, st, eps);
     TestArgs<ApproxArgType>(pi + 0.5, st, eps); 
     TestArgs<ApproxArgType>(3.141, st, eps);
     TestArgs<ApproxArgType>(3.142, st, eps);
     TestArgs<ApproxArgType>(ArgType::MaxVal(), st, eps);
     try {
         TestArgs<ApproxArgType>(ApproxArgType::MaxVal(), st, eps);
         std::cout << "FAILED: exception expected" << std::endl;
     }
     catch(const std::range_error& ){
         //OK!
     }

     uint16_t halfIndex = (ArgType::VALUES_COUNT/2); //Half of table
     uint16_t aproxHalfIndex = halfIndex << 3;
     for (uint16_t x01u = aproxHalfIndex; x01u < ((halfIndex+1) << 3); ++x01u) {
         ApproxArgType x = x01u;
         double y = TestArgs<ApproxArgType>(x, st, eps);
         std::cout << y << ", ";
     }
     std::cout << std::endl;

     for (double x = 0; x < 3.99914; x+=0.0002) {
         ApproxArgType xA = x;
         double y = TestArgs<ApproxArgType>(xA, st, eps);
//         std::cout << y << ", ";
     }
     std::cout << std::endl;

}

template <typename ArgType, typename ResultType>
bool GenerateTable(std::ostream& out) {
//    using ArgType = FixedPoint<2, 10>;
//    using ResultType = FixedPoint<0, 15, 1>;
    out <<R"(
        `timescale 1ns / 1ps
        //////////////////////////////////////////////////////////////////////////////////
        // AUTO GENERATED FILE - DON`T EDIT
        // Company:  S-Terra
        // Engineer: Egor
        // 
        // Create Date: 28.02.2023 13:12:23
        // Design Name: 
        // Module Name: sin_value
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


        )";
    out << "reg [" << ResultType::TOTAL_BITS - 1 << ":0] sin_table [" << ArgType::VALUES_COUNT << ":0];" << std::endl;

    const double eps = 0.0001;
    SinTable<ArgType, ResultType> st;
    for (size_t i = 0;  auto aY : st.Table) {
        out << "sin_table[" << i << "] <= " << aY << "; // sin(" << st.X_Table[i] << ") = " << sin(st.X_Table[i]);
        if (abs(st.DeviationTable[i]) > eps)
            out << "  - Truncated:" << st.DeviationTable[i];
        out << std::endl;
       
        //                out << "// truncated: " << tmp << " to  " << ResultType::MaxVal() << std::endl;
        ++i;
    }
    
    return true;
}

void Test1() {
    using ResultType = FixedPoint<2, 12, 1>;

    constexpr ResultType x(-3.9990234);
    constexpr ResultType x5(-3.9990234);
    constexpr auto sum = Summ<ResultType>(x, x5);
    constexpr double dSum = sum;
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
        FixedPoint<2, 10> xN(tmp);
        if (abs(tmp - xN) > eps)
            std::cout << "FAIL:" << tmp << ":" << xN << std::endl;
        else
            std::cout << tmp << ":" << (double)xN << ":" << xN << std::endl;
    }

    std::cout << x2 << "  " << x2_1 << std::endl;
}

int main(){
    try {
        //    Test1();
#define WRITE_TO_FILE true
#if WRITE_TO_FILE == true 
        auto out = std::ofstream("D:memory.txt");
#else
        auto out & = std::cout;
#endif

        //bool ok = GenerateTable<FixedPoint<2, 10>, FixedPoint<0, 15, 1>>(out);
        /*if (!ok){
            std::cout << "ERROR!!\n";
        }*/

        TestApprox<FixedPoint<2, 10>, FixedPoint<0, 15, 1>, FixedPoint<2, 13>>();
        return 0;
    }
    catch (const std::exception& err) {
        std::cout << "EROR: " << err.what();
    }
    return -1;
}
