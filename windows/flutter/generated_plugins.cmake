# Generated file - plugins are added here by flutter tooling.
list(APPEND FLUTTER_PLUGIN_LIST)
list(APPEND FLUTTER_FFI_PLUGIN_LIST)
foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
endforeach()
