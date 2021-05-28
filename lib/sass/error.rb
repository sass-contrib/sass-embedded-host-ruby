# frozen_string_literal: true

module Sass
  class SassError < StandardError; end

  class ProtocolError < SassError; end

  # The error returned by {Embedded#render}.
  class RenderError < SassError
    attr_accessor :formatted, :file, :line, :column, :status

    def initialize(message, formatted, file, line, column, status)
      @formatted = formatted
      @file = file
      @line = line
      @column = column
      @status = status
      super(message)
    end

    def backtrace
      return nil if super.nil?

      ["#{@file}:#{@line}:#{@column}"] + super
    end
  end
end
