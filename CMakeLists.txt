cmake_minimum_required(VERSION 3.31)

project(fullindiction VERSION 1.0.1)

option(FULLINDICTION_BUILD_TESTS "Build fullindiction tests" ${PROJECT_IS_TOP_LEVEL})
option(FULLINDICTION_INSTALL "Enable installation rules" ${PROJECT_IS_TOP_LEVEL})
option(FULLINDICTION_OFFLINEBUILD "Don't download dependencies from internet" ON)

# try to find lua interpreter in system
function(check_lua_version result luafile)
  execute_process(
    COMMAND ${luafile} -e "print(_VERSION)"
    RESULT_VARIABLE result_variable
    OUTPUT_VARIABLE output_variable
  )
  if(result_variable STREQUAL "0")
    if(output_variable MATCHES "^.+([0-9]+\.[0-9]+\.?[0-9]*).+$")
      set(version ${CMAKE_MATCH_1})
      if(version VERSION_GREATER_EQUAL "5.4")
        return()
      endif()
    endif()
  endif()
  set(${result} FALSE PARENT_SCOPE)
endfunction()

find_program(LUA_EXECUTABLE
  NAMES lua lua5.4 lua54 lua5_4 lua5.5 lua55 lua5_5 lua_exe
  PATHS "${CMAKE_CURRENT_BINARY_DIR}"
  VALIDATOR check_lua_version
)

# if lua interpreter notfound, try to download & build
if(NOT LUA_EXECUTABLE)
  if(FULLINDICTION_OFFLINEBUILD)
    message(FATAL_ERROR "lua interpreter not found in system, try to unset 'FULLINDICTION_OFFLINEBUILD' option")
  endif()
  file(DOWNLOAD "https://www.lua.org/ftp/lua-5.5.0.tar.gz"
    "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0.tar.gz"
    EXPECTED_HASH SHA256=57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d
  )
  file(ARCHIVE_EXTRACT INPUT "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0.tar.gz")
  FILE(GLOB lua_sources "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0/src/*.c")
  list(REMOVE_ITEM lua_sources
    "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0/src/lua.c"
    "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0/src/luac.c"
  )
  add_library(lua_lib STATIC ${lua_sources})
  target_compile_features(lua_lib PUBLIC c_std_99)
  add_executable(lua_exe "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0/src/lua.c")
  target_include_directories(lua_exe PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/lua-5.5.0/src")
  target_link_libraries(lua_exe PRIVATE lua_lib)
  if(UNIX AND NOT APPLE)
    target_link_libraries(lua_exe PRIVATE m)
  endif()
  set(LUA_EXECUTABLE "lua_exe")
endif()

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/fullindiction.h"
         "${CMAKE_CURRENT_SOURCE_DIR}/src/fullindiction.cpp"
  COMMAND ${LUA_EXECUTABLE} generate_cpp.lua fullindiction.h fullindiction.cpp
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/generate_cpp.lua"
          "${CMAKE_CURRENT_SOURCE_DIR}/src/fullindiction.lua"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src"
  DEPENDS_EXPLICIT_ONLY
  VERBATIM
)
add_library(fullindiction
  "${CMAKE_CURRENT_SOURCE_DIR}/src/fullindiction.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/fullindiction.cpp"
)
target_compile_features(fullindiction PRIVATE cxx_std_23)
target_include_directories(fullindiction PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>)

if(FULLINDICTION_BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

if(FULLINDICTION_INSTALL)
#...
endif()
