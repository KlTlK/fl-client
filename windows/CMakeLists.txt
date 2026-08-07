cmake_minimum_required(VERSION 3.14)
project(fl_client LANGUAGES CXX)

set(BINARY_NAME "fl_client")
cmake_policy(VERSION 3.14...3.25)
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(CONFIG_PROFILE "production")

# Helper used by runner/CMakeLists.txt
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

include(flutter/generated_plugins.cmake)

add_subdirectory("runner")
