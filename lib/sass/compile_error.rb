# frozen_string_literal: true

require_relative 'logger/source_span'

module Sass
  # The {CompileError} raised by {Embedded#compile} or {Embedded#compile_string}.
  class CompileError < StandardError
    attr_accessor :sass_message, :sass_stack, :span

    def initialize(message, sass_message, sass_stack, span)
      super(message)
      @sass_message = sass_message
      @sass_stack = sass_stack
      @span = span
    end

    def self.from_proto(compile_failure)
      CompileError.new(compile_failure.formatted,
                       compile_failure.message,
                       compile_failure.stack_trace,
                       Logger::SourceSpan.from_proto(compile_failure.span))
    end
  end
end
