# lite
![screenshot](https://user-images.githubusercontent.com/3920290/71542771-52265880-2962-11ea-8382-c92f8e10b734.png)

A lightweight text editor written in Lua

## Overview
lite is a lightweight text editor written mostly in Lua — it aims to provide
something practical, pretty, *small* and responsive, implemented as simply as
possible; easy to modify and extend, or to use without doing either.

## Get
Go to the [Releases](#TODO) page to download precompiled binaries for Windows or
Linux. Additional functionality can be added through plugins which are available
from the [plugins repository](#TODO).

## Building
You can build the project yourself on Linux using the provided `build.py`
script. Note that the project does not need to be rebuilt if you are only making
changes to the Lua portion of the code.

## Contributing
Any additional functionality that can be added through a plugin should be done
so as a plugin, after which a pull request to the [plugins repository](#TODO)
can be made. In hopes of remaining lightweight, pull requests adding additional
functionality to the core will likely not be merged. Bug reports and bug fixes
are welcome.

## License
This project is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
