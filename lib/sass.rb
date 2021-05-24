# frozen_string_literal: true

module Sass
  # The global include_paths for Sass files. This is meant for plugins and
  # libraries to register the paths to their Sass stylesheets to that they may
  # be `@imported`. This include path is used by every instance of
  # {Sass::Embedded::Compiler}. They are lower-precedence than any include
  # paths passed in via the `:include_paths` option.
  #
  # If the `SASS_PATH` environment variable is set,
  # the initial value of `include_paths` will be initialized based on that.
  # The variable should be a colon-separated list of path names
  # (semicolon-separated on Windows).
  #
  # @example
  #   Sass.include_paths << File.dirname(__FILE__ + '/sass')
  # @return [Array<String, Pathname>]
  def self.include_paths
    @include_paths ||= if ENV['SASS_PATH']
                         ENV['SASS_PATH'].split(File::PATH_SEPARATOR)
                       else
                         []
                       end
  end

  def self.render(options)
    unless defined? @compiler
      @compiler = Sass::Embedded::Compiler.new
      at_exit do
        @compiler.close
      end
    end
    @compiler.render options
  end
end

require_relative 'sass/version'
require_relative 'sass/error'
require_relative 'sass/platform'
require_relative 'sass/util'
require_relative 'sass/embedded/transport'
require_relative 'sass/embedded/compiler'
