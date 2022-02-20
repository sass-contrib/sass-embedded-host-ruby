# frozen_string_literal: true

module Sass
  module Logger
    # The {SourceLocation} in {SourceSpan}.
    class SourceLocation
      attr_reader :offset, :line, :column

      def initialize(offset, line, column)
        @offset = offset
        @line = line
        @column = column
      end
    end
  end
end
