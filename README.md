# blog

This is the code powering [unterwaditzer.net](https://unterwaditzer.net/). It
is a set of Markdown and HTML files compiled with [soupault](https://soupault.app/).

The CSS is based on the [default theme "moment" of an old version of Liquid Luck](https://github.com/avelino/liquidluck/tree/master/liquidluck/_themes/default) but has diverged a lot since then.

## Build

The build process has only been tested on Linux.

Following additional software needs to be installed:

* `curl`, `tar`, `sed`
* [`uv`](https://docs.astral.sh/uv/)

Then, `make build` should build the entire static site to `build/`. It will take care of downloading soupault.
