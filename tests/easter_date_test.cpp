#include "my_test_framework.hpp"
#include <ifstream>
#include <sstream>
#include <stdexcept>

TEST_CASE("test function 'easter_date'"){
  struct DATA {
    int param;
    MD result;
  };
  auto initializer = [](std::string_view datafilename)->std::vector<DATA>{
    std::vector<DATA> result;
    std::ifstream istrm(datafilename);
    if (!istrm.is_open()) throw std::runtime_error("can't open "+std::string(datafilename));
    auto lineN = 1u;
    for (std::string line; std::getline(istrm, line); ++lineN) {
      while (line.starts_with(' ') || line.starts_with('\t')) line.erase(0,1) ;
      if (line.empty() || line.starts_with('#')) continue ;
      std::istringstream iss(line);
      int p{}, m{}, d{};
      if (!(iss >> p) || !(iss >> m) || !(iss >> d))
        throw std::runtime_error( "invalid format of test data file: '"
                                  +std::string(datafilename)
                                  +"'\nline: "
                                  +std::to_string(lineN) );
      result.emplace_back(p, {m, d});
    }
    istrm.close();
    return result;
  };
  auto tester = FUNCTION_TESTER<DATA>("easter_date_test.txt", initializer);
  for (const auto& [param, result]: tester)
    REQUIRE( fi::easter_date(param) == result );
}
