cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "soundpool_windux")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "soundpool_windux_plugin")

add_library(${PLUGIN_NAME} SHARED
  "soundpool_windux_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin
set(soundpool_windux_bundled_libraries
  ""
  PARENT_SCOPE
)

file(TO_CMAKE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../target/release/libsoundpool.so" path)

# List of absolute paths to libraries that should be bundled with the plugin
set(soundpool_windux_bundled_libraries
  "${path}"
  PARENT_SCOPE
)
