cmake_minimum_required(VERSION 2.8)

# Suppress dev warning from SDL2 lookup
if(NOT DEFINED CMAKE_SUPPRESS_DEVELOPER_WARNINGS)
    set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS 1 CACHE INTERNAL "No dev warnings")
endif()

project(lite)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

add_subdirectory(data)
add_subdirectory(res)
add_subdirectory(src)

install(FILES LICENSE README.md DESTINATION .)
