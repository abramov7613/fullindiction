add_library(catch2
  "${CMAKE_CURRENT_LIST_DIR}/catch_amalgamated.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/catch_amalgamated.hpp"
)
target_compile_features(catch2 PUBLIC cxx_std_23)
target_include_directories(catch2 PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>)
target_compile_definitions(catch2 PUBLIC TEST_ROOT_DIR=${CMAKE_CURRENT_LIST_DIR})

add_executable(easter_date_test
  "${CMAKE_CURRENT_LIST_DIR}/easter_date_test.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/my_test_framework.hpp"
)
target_link_libraries(easter_date_test PRIVATE catch2 fullindiction)

add_executable(find_date_test
  "${CMAKE_CURRENT_LIST_DIR}/find_date_test.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/my_test_framework.hpp"
)
target_link_libraries(find_date_test PRIVATE catch2 fullindiction)

add_test(NAME easter_date_test COMMAND easter_date_test)
add_test(NAME find_date_test COMMAND find_date_test)
