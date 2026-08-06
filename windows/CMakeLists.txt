cmake_minimum_required(VERSION 3.14)
project(fl_client LANGUAGES CXX)

set(BINARY_NAME "fl_client")
cmake_policy(SET CMP0063 NEW)
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(CONFIG_PROFILE "production")
include(flutter/generated_plugins.cmake)

add_subdirectory("runner")
