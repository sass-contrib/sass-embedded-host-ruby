# frozen_string_literal: true

module Sass
  # An exception thrown because a Sass compilation failed.
  class CompileError < StandardError
    attr_accessor :sass_stack, :span

    def initialize(message, full_message, sass_stack, span)
      super(message)
      @full_message = full_message == '' ? nil : full_message.dup
      @sass_stack = sass_stack
      @span = span
    end

    def full_message(*args, **kwargs)
      if @full_message.nil?
        super(*args, **kwargs)
      else
        @full_message
      end
    end
  end
end
