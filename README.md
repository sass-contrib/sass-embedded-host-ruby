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
require 'sass'

Sass.compile('style.scss')
Sass.compile_string('h1 { font-size: 40px; }')
```

---

Disclaimer: this is not an official Google product.
