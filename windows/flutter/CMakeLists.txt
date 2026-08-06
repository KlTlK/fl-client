# Generated - do not edit.
cmake_minimum_required(VERSION 3.14)
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat")
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" CACHE STRING "")
set(AOT_LIBRARY "${PROJECT_DIR}/build/windows/app.so" CACHE STRING "")

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h" "flutter_windows.h" "flutter_messenger.h"
  "flutter_plugin_registrar.h" "flutter_texture_registrar.h")
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE "${EPHEMERAL_DIR}")
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat"
      windows-x64 $<CONFIG>
  VERBATIM)
add_custom_target(flutter_assemble DEPENDS "${FLUTTER_LIBRARY}" ${FLUTTER_LIBRARY_HEADERS})
