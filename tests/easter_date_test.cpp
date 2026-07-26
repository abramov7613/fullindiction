#include "my_test_framework.hpp"
#include <sstream>

TEST_CASE("test function 'easter_date'"){
  struct DATA {
    int param;
    MD result;
  };
  constexpr std::string_view datafile = "easter_date_test.txt";
  auto tester = FUNCTION_TESTER<DATA>(datafile, [datafile](const std::string& line, size_t lineN){
    std::istringstream iss(line);
    int p{}, m{}, d{};
    if (!(iss >> p) || !(iss >> m) || !(iss >> d))
      throw std::runtime_error( "invalid format of test data file: '"
                                +std::string(datafile)
                                +"'\nline: "
                                +std::to_string(lineN) );
    return DATA{p, std::make_pair(m, d)};
  });
  for (const auto [param, result]: tester) {
    INFO("param = " << param);
    REQUIRE( fi::easter_date(param) == result );
  }
}
