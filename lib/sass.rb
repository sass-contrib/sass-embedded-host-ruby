# frozen_string_literal: true

require_relative 'sass/embedded'

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
  class << self
    # @return [CompileResult]
    # @raise [CompileError]
    # @see Embedded#compile
    def compile(path, **kwargs)
      instance.compile(path, **kwargs)
    end

    # @return [CompileResult]
    # @raise [CompileError]
    # @see Embedded#compile_string
    def compile_string(source, **kwargs)
      instance.compile_string(source, **kwargs)
    end

    # @return [String]
    # @see Embedded#info
    def info
      instance.info
    end

    private

    def instance
      if defined? @instance
        @instance = Embedded.new if @instance.closed?
      else
        @instance = Embedded.new
        at_exit do
          @instance.close
        end
      end
      @instance
    end
  end
end
