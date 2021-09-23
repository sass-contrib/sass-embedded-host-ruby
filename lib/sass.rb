# frozen_string_literal: true

# The Sass module. This communicates with Embedded Dart Sass using
# the Embedded Sass protocol.
module Sass
  class << self
    # The global {.include_paths} for Sass files. This is meant for plugins and
    # libraries to register the paths to their Sass stylesheets to that they may
    # be included via `@import` or `@use`. This include path is used by every
    # instance of {Sass::Embedded}. They are lower-precedence than any include
    # paths passed in via the `include_paths` option.
    #
    # If the `SASS_PATH` environment variable is set,
    # the initial value of `include_paths` will be initialized based on that.
    # The variable should be a colon-separated list of path names
    # (semicolon-separated on Windows).
    #
    # @example
    #   Sass.include_paths << File.dirname(__FILE__) + '/sass'
    # @return [Array]
    def include_paths
      @include_paths ||= if ENV['SASS_PATH']
                           ENV['SASS_PATH'].split(File::PATH_SEPARATOR)
                         else
                           []
                         end
    end

    # The global {.info} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#info}.
    #
    # @raise [ProtocolError]
    def info
      embedded.info
    end

    # The global {.render} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#render}.
    #
    # See {file:README.md#options} for supported options.
    #
    # @example
    #   Sass.render(data: 'h1 { font-size: 40px; }')
    # @example
    #   Sass.render(file: 'style.css')
    # @return [Result]
    # @raise [ProtocolError]
    # @raise [RenderError]
    def render(**kwargs)
      embedded.render(**kwargs)
    end

    private

    def embedded
      return @embedded if defined?(@embedded) && !@embedded.closed?

      @embedded = Sass::Embedded.new
    end
  end
end

require_relative 'sass/version'
require_relative 'sass/platform'
require_relative 'sass/compiler'
require_relative 'sass/util'
require_relative 'sass/struct'
require_relative 'sass/result'
require_relative 'sass/error'
require_relative 'sass/transport'
require_relative 'sass/observer'
require_relative 'sass/info'
require_relative 'sass/compile'
require_relative 'sass/embedded'
