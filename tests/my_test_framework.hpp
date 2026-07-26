// Using Test Framework from:
//    https://github.com/catchorg/Catch2/releases/download/v3.14.0/catch_amalgamated.cpp
//    https://github.com/catchorg/Catch2/releases/download/v3.14.0/catch_amalgamated.hpp

#include "catch_amalgamated.hpp"
#include "fullindiction.h"
#include <string>
#include <vector>
#include <fstream>
#include <stdexcept>
#include <functional>

namespace fi = fullindiction;
using fi::INDICTION_LENGTH;
using fi::DayProperty;
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

template<typename Data> class TEST_FUNCTION_RESULTS_CONTAINER {
  std::vector<Data> data_;
public:
  TEST_FUNCTION_RESULTS_CONTAINER(std::string_view datafile,
                                  std::function<Data(const std::string&, size_t)> datafile_line_parser)
  {
    std::ifstream istrm(datafile.data());
    if (!istrm.is_open()) throw std::runtime_error("can't open "+std::string(datafile));
    auto lineN = 1u;
    for (std::string line; std::getline(istrm, line); ++lineN) {
      while (line.starts_with(' ') || line.starts_with('\t')) line.erase(0,1) ;
      if (line.empty() || line.starts_with('#')) continue ;
      data_.push_back( datafile_line_parser(line, lineN) );
    }
    istrm.close();
  }
  auto begin() const { return data_.cbegin(); }
  auto end() const { return data_.cend(); }
};
