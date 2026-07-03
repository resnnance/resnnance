# Setup cmake minimum version
cmake_minimum_required(VERSION 3.1...3.15)

if(${CMAKE_VERSION} VERSION_LESS 3.15)
    cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

project(snn)
include(cmake/macros.cmake)
include(cmake/test_macros.cmake)
enable_testing()

add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})

add_sources(
    src/simtick.vhd
    src/network.vhd
    src/memory.vhd
    {% for layer in layers %}
    {% for template in layer.templates -%}
    src/layers/{{ layer.label }}/{{ layer.label }}_{{ template }}.vhd
    {% endfor -%}
    {%- endfor %}
)

add_subdirectory(test)
add_custom_target(index COMMAND ghdl -i --workdir=${CMAKE_BINARY_DIR} ${VHDL_SOURCES})
