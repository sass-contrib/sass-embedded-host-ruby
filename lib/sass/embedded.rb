# frozen_string_literal: true

require_relative 'compiler'
require_relative 'embedded/version'

# The Sass module.
#
# This communicates with Embedded Dart Sass using the Embedded Sass protocol.
#
# @example
#   Sass.compile('style.scss')
#
# @example
#   Sass.compile_string('h1 { font-size: 40px; }')
module Sass
  @instance = nil
  @mutex = Mutex.new

  # rubocop:disable Layout/LineLength
  class << self
    # Compiles the Sass file at +path+ to CSS.
    # @overload compile(path, load_paths: [], charset: true, source_map: false, source_map_include_sources: false, style: :expanded, functions: {}, importers: [], alert_ascii: false, alert_color: nil, logger: nil, quiet_deps: false, verbose: false)
    # @param (see Compiler#compile)
    # @return (see Compiler#compile)
    # @raise (see Compiler#compile)
    # @see Compiler#compile
    def compile(...)
      instance.compile(...)
    end

    # Compiles a stylesheet whose contents is +source+ to CSS.
    # @overload compile_string(source, importer: nil, load_paths: [], syntax: :scss, url: nil, charset: true, source_map: false, source_map_include_sources: false, style: :expanded, functions: {}, importers: [], alert_ascii: false, alert_color: nil, logger: nil, quiet_deps: false, verbose: false)
    # @param (see Compiler#compile_string)
    # @return (see Compiler#compile_string)
    # @raise (see Compiler#compile_string)
    # @see Compiler#compile_string
    def compile_string(...)
      instance.compile_string(...)
    end

    # @param (see Compiler#info)
    # @return (see Compiler#info)
    # @raise (see Compiler#info)
    # @see Compiler#info
    def info
      instance.info
    end

    private

    def instance
      return @instance if @instance

      @mutex.synchronize do
        return @instance if @instance

        instance = Compiler.new

        Process.singleton_class.prepend(Module.new do
          define_method :_fork do
            instance.close
            super()
          end
        end)

        at_exit do
          instance.close
        end

        @instance = instance
      end
    end
  end
  # rubocop:enable Layout/LineLength

  # The {Embedded} module.
  module Embedded
    module_function

    # @deprecated Use {Compiler.new} instead.
    def new
      Compiler.new
    end
  end
end
