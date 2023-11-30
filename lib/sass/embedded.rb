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
  @compiler = nil
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
      compiler.compile(...)
    end

    # Compiles a stylesheet whose contents is +source+ to CSS.
    # @overload compile_string(source, importer: nil, load_paths: [], syntax: :scss, url: nil, charset: true, source_map: false, source_map_include_sources: false, style: :expanded, functions: {}, importers: [], alert_ascii: false, alert_color: nil, logger: nil, quiet_deps: false, verbose: false)
    # @param (see Compiler#compile_string)
    # @return (see Compiler#compile_string)
    # @raise (see Compiler#compile_string)
    # @see Compiler#compile_string
    def compile_string(...)
      compiler.compile_string(...)
    end

    # @param (see Compiler#info)
    # @return (see Compiler#info)
    # @raise (see Compiler#info)
    # @see Compiler#info
    def info
      compiler.info
    end

    private

    def compiler
      return @compiler if @compiler

      @mutex.synchronize do
        return @compiler if @compiler

        compiler = Class.new(Compiler) do
          def initialize
            @dispatcher = self.class.const_get(:ResilientDispatcher).new(Class.new(self.class.const_get(:Dispatcher)) do
              def initialize
                super

                idle_timeout = 10
                @last_accessed_time = current_time

                Thread.new do
                  duration = idle_timeout
                  loop do
                    sleep(duration.negative? ? idle_timeout : duration)
                    evicted = @mutex.synchronize do
                      duration = idle_timeout - (current_time - @last_accessed_time)
                      @id = 0xffffffff if @observers.empty? && duration.negative?
                    end
                    break if evicted
                  end
                  close
                end
              end

              private

              def idle
                super

                @last_accessed_time = current_time
              end

              def current_time
                Process.clock_gettime(Process::CLOCK_MONOTONIC)
              end
            end)
          end
        end.new

        Process.singleton_class.prepend(Module.new do
          define_method :_fork do
            compiler.close
            super()
          end
        end)

        at_exit do
          compiler.close
        end

        @compiler = compiler
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
