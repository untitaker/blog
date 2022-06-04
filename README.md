# blog

This is the code powering [unterwaditzer.net](https://unterwaditzer.net/). It
is a set of Markdown and HTML files compiled with [soupault](https://soupault.app/).

## Build

The build process has only been tested on Linux.

Following additional software needs to be installed:

* `pandoc` for converting RST to HTML
* `pygmentize` for syntax-highlighting source snippets
* `curl`, `tar`, `sed`, `python2`, `virtualenv`

Then, `make build` should build the entire static site to `build/`. It will take care of downloading soupault.
