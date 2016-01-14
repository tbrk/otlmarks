OTLMARKS
========

`chromeotl` is a simple program that transforms a bookmarks file exported 
from the Chrome browser into a
[vimoutliner](https://github.com/vimoutliner/vimoutliner) file.

`otlhtml` is a simplistic program that transforms a vimoutliner file 
produced by `chromeotl` into an html file. It does not treat all vimoutliner 
features.

Both scripts require [OCaml](http://ocaml.org) and
[Ocamlnet](http://projects.camlcity.org/projects/ocamlnet.html).

The idea is that you run `chromeotl` to liberate yourself from using 
bookmarks in the Chrome browser, use vimoutliner to manage bookmarks, and 
periodically update a `bookmarks.html` file which can be accessed from any 
browser (both Chrome and Safari, say).

TODO
----
1. Improve the HTML output with CSS to make it prettier.
2. Add Javascript to the HTML output to allow folded navigation.

