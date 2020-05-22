#!/bin/bash

cflags="${CFLAGS} -Wall -O3 -g -std=gnu11 -Isrc -DLUA_USE_POPEN"
lflags="${LDFLAGS} -lSDL2 -lm"

if [[ $* == *windows* ]]; then
  platform="windows"
  outfile="lite.exe"
  compiler="x86_64-w64-mingw32-gcc"
  cflags="$cflags -Iwinlib/SDL2-2.0.10/x86_64-w64-mingw32/include"
  lflags="$lflags -Lwinlib/SDL2-2.0.10/x86_64-w64-mingw32/lib"
  lflags="-lmingw32 -lSDL2main $lflags -mwindows -o $outfile res.res"
  x86_64-w64-mingw32-windres res.rc -O coff -o res.res
else
  platform="unix"
  outfile="lite"
  compiler="gcc"
  lflags="$lflags -o $outfile"
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

if [[ $got_error ]]; then
  exit 1
fi
