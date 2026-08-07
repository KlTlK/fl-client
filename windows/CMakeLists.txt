cmake_minimum_required(VERSION 3.14)
project(fl_client LANGUAGES CXX)

set(BINARY_NAME "fl_client")
cmake_policy(VERSION 3.14...3.25)
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(CONFIG_PROFILE "production")

include(flutter/generated_plugins.cmake)

add_subdirectory("runner")
