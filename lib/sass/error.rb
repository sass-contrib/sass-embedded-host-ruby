# frozen_string_literal: true

module Sass
  class BaseError < StandardError; end

  class ProtocolError < BaseError; end

  class NotRenderedError < BaseError; end

  class InvalidStyleError < BaseError; end

  class UnsupportedValue < BaseError; end

  # The error returned by {Sass.render}
  class RenderError < BaseError
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
