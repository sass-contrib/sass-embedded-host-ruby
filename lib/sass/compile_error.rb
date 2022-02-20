# frozen_string_literal: true

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
  end
end
