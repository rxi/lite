# lite
![screenshot](https://user-images.githubusercontent.com/3920290/81471642-6c165880-91ea-11ea-8cd1-fae7ae8f0bc4.png)

A lightweight text editor written in Lua

* **[Get lite](https://github.com/rxi/lite/releases/latest)** — Download
  for Windows and Linux
* **[Get plugins](https://github.com/rxi/lite-plugins)** — Add additional
  functionality
* **[Get color themes](https://github.com/rxi/lite-colors)** — Add additional colors
  themes

## Overview
lite is a lightweight text editor written mostly in Lua — it aims to provide
something practical, pretty, *small* and fast, implemented as simply as
possible; easy to modify and extend, or to use without doing either.

## Customization
Additional functionality can be added through plugins which are available from
the [plugins repository](https://github.com/rxi/lite-plugins); additional color
themes can be found in the [colors repository](https://github.com/rxi/lite-colors).
The editor can be customized by making changes to the
[user module](data/user/init.lua).

## Building
You can build the project yourself using [CMake](https://www.cmake.org/) and your
preferred toolchain.

Note that this requires development libraries for [SDL2](https://www.libsdl.org/).
Also keep in mind that the project does not need to be rebuilt if you are only
making changes to the Lua portion of the code.

To generate build files for your default toolchain, just invoke CMake from your
preferred build directory and pass the path to the source:

    cmake path/to/lite-source

On Windows you might have to set the path to your SDL2 files as well:

    cmake -DSDL2_PATH=path/to/sdl2 path/to/lite-source

Once done, you can invoke `make`, open the generated project files, or directly
build utilizing CMake:

    cmake --build . --config Release --target all

To install lite, simply build the `install` target. The destination directory is
set using the CMake variable `CMAKE_INSTALL_PREFIX`.

## Contributing
Any additional functionality that can be added through a plugin should be done
so as a plugin, after which a pull request to the
[plugins repository](https://github.com/rxi/lite-plugins) can be made.

In hopes of remaining lightweight, pull requests adding additional functionality
to the core will likely not be merged. Bug reports and bug fixes are welcome.

## License
This project is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
