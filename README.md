# Embedded Sass Host for Ruby

[![build](https://github.com/ntkme/embedded-host-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/ntkme/embedded-host-ruby/actions/workflows/build.yml)

This is a Ruby library that implements the host side of the [Embedded Sass protocol](https://github.com/sass/sass-embedded-protocol).

It exposes a Ruby API for Sass that's backed by a native [Dart Sass](https://sass-lang.com/dart-sass) executable.

## Usage

``` ruby
require "sass"

Sass.render({
  file: "style.scss"
})
```

---

Disclaimer: this is not an official Google product.
