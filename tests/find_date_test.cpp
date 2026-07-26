#include "my_test_framework.hpp"
#include <sstream>

TEST_CASE("test function 'find_date'"){
  struct DATA {
    int param1;
    int param2;
    MD result;
  };
  constexpr std::string_view datafile = "find_date_test.txt";
  auto tester = FUNCTION_TESTER<DATA>(datafile, [datafile](const std::string& line, size_t lineN){
    std::istringstream iss(line);
    int p1{}, p2{}, m{}, d{};
    if (!(iss >> p1) || !(iss >> p2) || !(iss >> m) || !(iss >> d))
      throw std::runtime_error( "invalid format of test data file: '"
                                +std::string(datafile)
                                +"'\nline: "
                                +std::to_string(lineN) );
    return DATA{p1, p2, std::make_pair(m, d)};
  });
  for (const auto [param1, param2, result]: tester) {
    INFO("param1 = " << param1 << "; param2 = " << param2);
    REQUIRE( fi::find_date(param1, static_cast<fi::DayProperty>(param2)) == result );
  }
}
