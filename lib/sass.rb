# frozen_string_literal: true

require_relative 'sass/compile_error'
require_relative 'sass/compile_result'
require_relative 'sass/embedded'
require_relative 'sass/embedded/async'
require_relative 'sass/embedded/channel'
require_relative 'sass/embedded/compiler'
require_relative 'sass/embedded/dispatcher'
require_relative 'sass/embedded/host'
require_relative 'sass/embedded/host/function_registry'
require_relative 'sass/embedded/host/importer_registry'
require_relative 'sass/embedded/host/logger_registry'
require_relative 'sass/embedded/host/value_protofier'
require_relative 'sass/embedded/protofier'
require_relative 'sass/embedded/structifier'
require_relative 'sass/embedded/varint'
require_relative 'sass/embedded/version'
require_relative 'sass/embedded_protocol'
require_relative 'sass/logger'
require_relative 'sass/logger/source_location'
require_relative 'sass/logger/source_span'
require_relative 'sass/script_error'
require_relative 'sass/value'
require_relative 'sass/value/list'
require_relative 'sass/value/argument_list'
require_relative 'sass/value/boolean'
require_relative 'sass/value/color'
require_relative 'sass/value/function'
require_relative 'sass/value/fuzzy_math'
require_relative 'sass/value/map'
require_relative 'sass/value/null'
require_relative 'sass/value/number'
require_relative 'sass/value/number/unit'
require_relative 'sass/value/string'

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
