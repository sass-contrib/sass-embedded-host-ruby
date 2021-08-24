# Embedded Sass Host for Ruby

[![build](https://github.com/ntkme/embedded-host-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/ntkme/embedded-host-ruby/actions/workflows/build.yml)
[![gem](https://badge.fury.io/rb/sass-embedded.svg)](https://rubygems.org/gems/sass-embedded)

This is a Ruby library that implements the host side of the [Embedded Sass protocol](https://github.com/sass/sass-embedded-protocol).

It exposes a Ruby API for Sass that's backed by a native [Dart Sass](https://sass-lang.com/dart-sass) executable.

## Install

``` sh
gem install sass-embedded
```

## Usage

``` ruby
require "sass"

Sass.render(file: "style.scss")
```

## Options

`Sass.render(**kwargs)` supports the following options:

- [`data`](https://sass-lang.com/documentation/js-api#data)
- [`file`](https://sass-lang.com/documentation/js-api#file)
- [`indented_syntax`](https://sass-lang.com/documentation/js-api#indentedsyntax)
- [`include_paths`](https://sass-lang.com/documentation/js-api#includepaths)
- [`output_style`](https://sass-lang.com/documentation/js-api#outputstyle)
- [`indent_type`](https://sass-lang.com/documentation/js-api#indenttype)
- [`indent_width`](https://sass-lang.com/documentation/js-api#indentwidth)
- [`linefeed`](https://sass-lang.com/documentation/js-api#linefeed)
- [`source_map`](https://sass-lang.com/documentation/js-api#sourcemap)
- [`out_file`](https://sass-lang.com/documentation/js-api#outfile)
- [`omit_source_map_url`](https://sass-lang.com/documentation/js-api#omitsourcemapurl)
- [`source_map_contents`](https://sass-lang.com/documentation/js-api#sourcemapcontents)
- [`source_map_embed`](https://sass-lang.com/documentation/js-api#sourcemapembed)
- [`source_map_root`](https://sass-lang.com/documentation/js-api#sourcemaproot)
- [`functions`](https://sass-lang.com/documentation/js-api#functions)
- [`importer`](https://sass-lang.com/documentation/js-api#importer)

---

Disclaimer: this is not an official Google product.
