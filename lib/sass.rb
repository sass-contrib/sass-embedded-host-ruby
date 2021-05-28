# frozen_string_literal: true

# The Sass module
module Sass
  class << self
    # The global include_paths for Sass files. This is meant for plugins and
    # libraries to register the paths to their Sass stylesheets to that they may
    # be `@imported`. This include path is used by every instance of
    # {Sass::Embedded}. They are lower-precedence than any include paths passed
    # in via the `:include_paths` option.
    #
    # If the `SASS_PATH` environment variable is set,
    # the initial value of `include_paths` will be initialized based on that.
    # The variable should be a colon-separated list of path names
    # (semicolon-separated on Windows).
    #
    # @example
    #   Sass.include_paths << File.dirname(__FILE__) + '/sass'
    # @return [Array<String, Pathname>]
    def include_paths
      @include_paths ||= if ENV['SASS_PATH']
                           ENV['SASS_PATH'].split(File::PATH_SEPARATOR)
                         else
                           []
                         end
    end

    def info
      embedded.info
    end

    # The global render method. This method automatically instantiates a
    # global {Sass::Embedded} instance when invoked the first time and call
    # `:render` method on the instance thereafter.
    # @example
    #   Sass.render(options)
    # @return [Hash]
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
require_relative 'sass/error'
require_relative 'sass/platform'
require_relative 'sass/util'
require_relative 'sass/transport'
require_relative 'sass/context'
require_relative 'sass/embedded'
