# frozen_string_literal: true

module Sass
  # An exception thrown because a Sass compilation failed.
  class CompileError < StandardError
    # @return [String, nil]
    attr_reader :sass_stack

    # @return [Logger::SourceSpan, nil]
    attr_reader :span

    def initialize(message, full_message, sass_stack, span)
      super(message)
      @full_message = full_message
      @sass_stack = sass_stack
      @span = span
    end

    # @return [String]
    def full_message(...)
      return @full_message unless @full_message.nil?

      super(...)
    end
  end
end
