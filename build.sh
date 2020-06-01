#!/usr/bin/env bash

cflags="-Wall -O3 -g -std=gnu11 -fno-strict-aliasing -Isrc"
lflags="-lm"

if [[ $* == *windows* ]]; then
  platform="windows"
  outfile="lite.exe"
  compiler="x86_64-w64-mingw32-gcc"
  cflags="$cflags -DLUA_USE_POPEN -Iwinlib/SDL2-2.0.10/x86_64-w64-mingw32/include"
  lflags="$lflags -lSDL2 -Lwinlib/SDL2-2.0.10/x86_64-w64-mingw32/lib"
  lflags="-lmingw32 -lSDL2main $lflags -mwindows -o $outfile res.res"
  x86_64-w64-mingw32-windres res.rc -O coff -o res.res
else
  platform="unix"
  outfile="lite"
  compiler="cc"
  cflags="$cflags -DLUA_USE_POSIX"
  lflags="$lflags -o $outfile"
  if command -v pkgconf >/dev/null; then
    cflags="$cflags $(pkgconf --cflags --silence-errors sdl2)"
    lflags="$lflags $(pkgconf --libs --silence-errors sdl2)"
  else
    lflags="$lflags -lSDL2"
  fi
fi

if command -v ccache >/dev/null; then
  compiler="ccache $compiler"
fi


echo "compiling ($platform)..."
for f in `find src -name "*.c"`; do
  $compiler -c $cflags $f -o "${f//\//_}.o"
  if [[ $? -ne 0 ]]; then
    got_error=true
  fi
done

if [[ ! $got_error ]]; then
  echo "linking..."
  $compiler *.o $lflags
fi

echo "cleaning up..."
rm *.o
rm res.res 2>/dev/null
echo "done"
