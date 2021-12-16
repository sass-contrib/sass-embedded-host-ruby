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

      def self.from_proto(source_location)
        return nil if source_location.nil?

        SourceLocation.new(source_location.offset,
                           source_location.line,
                           source_location.column)
      end
    end
  end
end
