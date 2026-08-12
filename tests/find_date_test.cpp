#include "my_test_framework.hpp"
#include <sstream>
#include <filesystem>

namespace fs = std::filesystem;

TEST_CASE("test function 'find_date'"){

  std::string datafile = fs::path(fs::path(TEST_ROOT_DIR) / __FILE__).lexically_normal().replace_extension("txt").string();

  SECTION( "test for input parameters" ){
    REQUIRE_THROWS( fi::find_date(-1, fi::PASHA) );
    REQUIRE_THROWS( fi::find_date(0, fi::PASHA) );
    REQUIRE_THROWS( fi::find_date(533, fi::PASHA) );
    REQUIRE_THROWS( fi::find_date(1, fi::SIZE_) );
    REQUIRE_THROWS( fi::find_date(1, static_cast<fi::DayProperty>(-1)) );
    REQUIRE_NOTHROW( fi::find_date(1, fi::PASHA) );
    REQUIRE_NOTHROW( fi::find_date(1, static_cast<fi::DayProperty>(0)) );
  }

  SECTION( "test for return values" ){
    struct DATA {
      int param1;
      int param2;
      MD result;
    };
    auto results = TEST_FUNCTION_RESULTS_CONTAINER<DATA>(datafile, [&](const std::string& line, size_t lineN){
      std::istringstream iss(line);
      int p1{}, p2{}, m{}, d{};
      if (!(iss >> p1) || !(iss >> p2) || !(iss >> m) || !(iss >> d))
        throw std::runtime_error( "invalid format of test data file: '"
                                  +datafile
                                  +"'\nline: "
                                  +std::to_string(lineN) );
      return DATA{p1, p2, std::make_pair(m, d)};
    });
    for (const auto [param1, param2, result]: results) {
      INFO("param1 = " << param1 << "; param2 = " << param2);
      REQUIRE( fi::find_date(param1, static_cast<DayProperty>(param2)) == result );
    }
  }
}
