#!/bin/bash
./build.sh release windows
./build.sh release macos
./build.sh release
rm lite.zip 2>/dev/null
cp winlib/SDL2-2.0.10/x86_64-w64-mingw32/bin/SDL2.dll SDL2.dll
strip lite
strip lite-osx
strip lite.exe
strip SDL2.dll
cp lite-osx macos/lite.app/Contents/MacOS/
cp -R data macos/lite.app/Contents/MacOS/
zip lite.zip lite macos/lite.app lite.exe SDL2.dll data -r
