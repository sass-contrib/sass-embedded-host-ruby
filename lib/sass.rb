# frozen_string_literal: true

require_relative 'sass/embedded'

# The Sass module. This communicates with Embedded Dart Sass using
# the Embedded Sass protocol.
module Sass
  class << self
    # The global {.compile} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#compile}.
    #
    # See {Embedded#compile} for supported options.
    #
    # @example
    #   Sass.compile('style.scss')
    # @return [CompileResult]
    # @raise [CompileError]
    # @raise [ProtocolError]
    def compile(path, **kwargs)
      instance.compile(path, **kwargs)
    end

    # The global {.compile_string} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#compile_string}.
    #
    # See {Embedded#compile_string} for supported options.
    #
    # @example
    #   Sass.compile_string('h1 { font-size: 40px; }')
    # @return [CompileResult]
    # @raise [CompileError]
    # @raise [ProtocolError]
    def compile_string(source, **kwargs)
      instance.compile_string(source, **kwargs)
    end

    # @deprecated
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
      Embedded.include_paths
    end

    # The global {.info} method. This instantiates a global {Embedded} instance
    # and calls {Embedded#info}.
    #
    # @raise [ProtocolError]
    def info
      instance.info
    end

    # @deprecated
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
      instance.render(**kwargs)
    end

    private

    def instance
      if @instance.nil?
        @instance = Embedded.new
        at_exit do
          @instance.close
        end
      elsif @instance.closed?
        @instance = Embedded.new
      end
      @instance
    end
  end
end
