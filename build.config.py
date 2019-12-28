import os

cflags = [ "-Wall", "-O3", "-g", "-DLUA_USE_POPEN" ]
lflags = [ "-lSDL2", "-lm" ]
include = [ "src" ]
output = "lite"


if "sanitize" in opt:
    log("address sanitizer enabled")
    cflags += [ "-fsanitize=address" ]
    lflags += [ "-fsanitize=address" ]


if "windows" in opt:
    compiler = "x86_64-w64-mingw32-gcc"
    output += ".exe"
    cflags += [ "-Iwinlib/SDL2-2.0.10/x86_64-w64-mingw32/include" ]
    lflags += [ "-Lwinlib/SDL2-2.0.10/x86_64-w64-mingw32/lib" ]
    lflags  = [ "-lmingw32", "-lSDL2main" ] + lflags
    lflags += [ "-lwinmm" ]
    lflags += [ "-mwindows" ]
    lflags += [ "res.res" ]

    def pre():
      os.system("x86_64-w64-mingw32-windres res.rc -O coff -o res.res")

    def post():
      os.remove("res.res")
