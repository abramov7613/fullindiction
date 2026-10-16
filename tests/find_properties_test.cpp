#include "my_test_framework.hpp"
#include <sstream>
#include <filesystem>

namespace fs = std::filesystem;

TEST_CASE( "test function 'find_properties'" ){

  SECTION( "test for input parameters" ){
    REQUIRE_THROWS( fi::find_properties(-1, MD{1,1}) );
    REQUIRE_THROWS( fi::find_properties(0, MD{1,1}) );
    REQUIRE_THROWS( fi::find_properties(533, MD{1,1}) );
    REQUIRE_THROWS( fi::find_properties(1, MD{0,1}) );
    REQUIRE_THROWS( fi::find_properties(1, MD{1,0}) );
    REQUIRE_THROWS( fi::find_properties(1, MD{55,1}) );
    REQUIRE_THROWS( fi::find_properties(1, MD{1, -15}) );

    REQUIRE_NOTHROW( fi::find_properties(1, MD{1,1}) );
  }

}
