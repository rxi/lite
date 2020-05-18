find_package(SDL2 REQUIRED)

add_library(renderer OBJECT
    rencache.c
    rencache.h
    renderer.c
    renderer.h
)
target_include_directories(renderer PRIVATE
    ${SDL2_INCLUDE_DIR}
)

add_library(stb_ttf OBJECT
    lib/stb/stb_truetype.c
    lib/stb/stb_truetype.h
)

file(GLOB LUA_SOURCES lib/lua52/*.c lib/lua52/*.h)
add_library(lua OBJECT
    ${LUA_SOURCES}
)
if(NOT WIN32)
target_link_libraries(lua PRIVATE m)
endif()

add_library(api OBJECT
    api/api.c
    api/api.h
    api/renderer.c
    api/renderer_font.c
    api/system.c
)
target_include_directories(api PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${SDL2_INCLUDE_DIR}
)

# There's typically no 'dirent.h' on Windows, so provide one
if(WIN32)
    target_include_directories(api PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/dirent
    )
endif()

add_executable(lite WIN32
    main.c
)
target_include_directories(lite PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${SDL2_INCLUDE_DIR}
)
target_link_libraries(lite
    renderer
    api
    stb_ttf
    lua
    res
    ${SDL2_LIBRARY}
)
install(TARGETS lite DESTINATION .)

# Try to install SDL2 dll
if(WIN32)
    string(TOLOWER ${SDL2_LIBRARY} SDL2_LIB)
    string(REGEX REPLACE "\\.lib$" ".dll" SDL2_DLL ${SDL2_LIB})
    if(EXISTS ${SDL2_DLL})
        install(FILES ${SDL2_DLL} DESTINATION .)
    endif()
endif()
