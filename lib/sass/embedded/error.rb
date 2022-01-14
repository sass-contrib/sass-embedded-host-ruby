# frozen_string_literal: true

module Sass
  class Embedded
    class ProtocolError < StandardError; end

    # @deprecated
    # The {Error} raised by {Embedded#render}.
    class RenderError < StandardError
      attr_reader :formatted, :file, :line, :column, :status

      def initialize(message, formatted, file, line, column, status)
        super(message)
        @formatted = formatted
        @file = file
        @line = line
        @column = column
        @status = status
      end

      def backtrace
        return nil if super.nil?

        ["#{@file}:#{@line}:#{@column}"] + super
      end
    end
  end
end
