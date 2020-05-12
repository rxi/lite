# Litecode
![screenshot](https://user-images.githubusercontent.com/3920290/81471642-6c165880-91ea-11ea-8cd1-fae7ae8f0bc4.png)

A lightweight text editor written in Lua

* **[Get lite](https://github.com/rxi/lite/releases/latest)** — Download
  for Windows and Linux
* **[Get plugins](https://github.com/rxi/lite-plugins)** — Add additional
  functionality
* **[Get color themes](https://github.com/rxi/lite-colors)** — Add additional colors
  themes

## Overview
Litecode is a text editor designed to add new features and enhancements to Lite while remaining backwards-compatible.

## Customization
Additional functionality can be added through plugins which are available from
the [plugins repository](https://github.com/rxi/lite-plugins); additional color
themes can be found in the [colors repository](https://github.com/rxi/lite-colors).
The editor can be customized by making changes to the
[user module](data/user/init.lua).

## Building
You can build the project yourself on Linux using the provided `build.sh`
script. Note that the project does not need to be rebuilt if you are only making
changes to the Lua portion of the code.

## Contributing
Any additional functionality that can be added through a plugin should be done
so as a plugin, after which a pull request to the
[plugins repository](https://github.com/rxi/lite-plugins) can be made. In hopes
of remaining lightweight, pull requests adding additional functionality to the
core will likely not be merged. Bug reports and bug fixes are welcome.

## License
This project is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
