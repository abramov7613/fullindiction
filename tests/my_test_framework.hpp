// Using Test Framework from:
//    https://github.com/catchorg/Catch2/releases/download/v3.14.0/catch_amalgamated.cpp
//    https://github.com/catchorg/Catch2/releases/download/v3.14.0/catch_amalgamated.hpp

#include "catch_amalgamated.hpp"
#include "fullindiction.h"

namespace fi = fullindiction;
using fi::INDICTION_LENGTH;
using MD = fi::MonthDay ;

namespace Catch {
    template<>
    struct StringMaker<MD> {
        static std::string convert( MD const& val ) {
            return "{" + std::to_string(val.first) + ',' + std::to_string(val.second) + '}' ;
        }
    };
    template<>
    struct StringMaker<std::vector<MD>> {
        static std::string convert( std::vector<MD> const& val ) {
            std::string result;
            for (const auto& e: val) result += StringMaker<MD>::convert(e) + ' ' ;
            return result;
        }
    };
}
