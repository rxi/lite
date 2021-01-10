project('lite',
        ['c'],
        version: '1.11')

c_compiler = meson.get_compiler('c')
sdl2_dep = c_compiler.find_library('SDL2')
m_dep = c_compiler.find_library('m')
args = '-Wall -O3 -g -std=gnu11 -fno-strict-aliasing '

sources = [
 'src/main.c',
 'src/rencache.c',
 'src/renderer.c',
 'src/api/api.c',
 'src/api/renderer.c',
 'src/api/renderer_font.c',
 'src/api/system.c',
 'src/lib/stb/stb_truetype.c',
 'src/lib/lua52/lapi.c',
 'src/lib/lua52/lauxlib.c',
 'src/lib/lua52/lbaselib.c',
 'src/lib/lua52/lbitlib.c',
 'src/lib/lua52/lcode.c',
 'src/lib/lua52/lcorolib.c',
 'src/lib/lua52/lctype.c',
 'src/lib/lua52/ldblib.c',
 'src/lib/lua52/ldebug.c',
 'src/lib/lua52/ldo.c',
 'src/lib/lua52/ldump.c',
 'src/lib/lua52/lfunc.c',
 'src/lib/lua52/lgc.c',
 'src/lib/lua52/linit.c',
 'src/lib/lua52/liolib.c',
 'src/lib/lua52/llex.c',
 'src/lib/lua52/lmathlib.c',
 'src/lib/lua52/lmem.c',
 'src/lib/lua52/loadlib.c',
 'src/lib/lua52/lobject.c',
 'src/lib/lua52/lopcodes.c',
 'src/lib/lua52/loslib.c',
 'src/lib/lua52/lparser.c',
 'src/lib/lua52/lstate.c',
 'src/lib/lua52/lstring.c',
 'src/lib/lua52/lstrlib.c',
 'src/lib/lua52/ltable.c',
 'src/lib/lua52/ltablib.c',
 'src/lib/lua52/ltm.c',
 'src/lib/lua52/lundump.c',
 'src/lib/lua52/lvm.c',
 'src/lib/lua52/lzio.c'
]

executable('lite',
            sources,
            cpp_args: args + '-DLUA_USE_POSIX',
            include_directories: include_directories('src'),
            dependencies: [sdl2_dep,m_dep],
            install: false)
