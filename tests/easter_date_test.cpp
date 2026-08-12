#include "my_test_framework.hpp"
#include <sstream>

TEST_CASE( "test function 'easter_date'" ){

  SECTION( "test for input parameters" ){
    REQUIRE_THROWS( fi::easter_date(-1) );
    REQUIRE_THROWS( fi::easter_date(0) );
    REQUIRE_THROWS( fi::easter_date(533) );
    REQUIRE_NOTHROW( fi::easter_date(1) );
  }

  SECTION( "test for return values" ){
    struct DATA {
      int param;
      MD result;
    };
    auto results = TEST_FUNCTION_RESULTS_CONTAINER<DATA>(datafile, [](const std::string& line, size_t lineN){
      std::istringstream iss(line);
      int p{}, m{}, d{};
      if (!(iss >> p) || !(iss >> m) || !(iss >> d))
        throw std::runtime_error( "invalid format of test data file: '"
                                  +std::string(datafile)
                                  +"'\nline: "
                                  +std::to_string(lineN) );
      return DATA{p, std::make_pair(m, d)};
    });
    for (const auto [param, result]: results) {
      INFO("param = " << param);
      REQUIRE( fi::easter_date(param) == result );
    }
  }

}
