# frozen_string_literal: true

module Sass
  class Value
    # Sass's map type.
    class Map < Sass::Value
      def initialize(contents = {}) # rubocop:disable Lint/MissingSuper
        @contents = contents.freeze
      end

      attr_reader :contents

      def separator
        contents.empty? ? nil : ','
      end

      def assert_map(_name = nil)
        self
      end

      def to_map
        self
      end

      def to_a
        contents.to_a.map { |entry| Sass::Value::List.new(entry, separator: ' ') }
      end

      def at(index)
        if index.is_a? Numeric
          index = index.floor
          index = to_a.length + index if index.negative?
          return nil if index.negative? || index >= to_a.length

          to_a[index]
        else
          contents[index]
        end
      end

      def ==(other)
        (other.is_a?(Sass::Value::Map) && other.contents == contents) ||
          (contents.empty? && other.is_a?(Sass::Value::List) && other.to_a.empty?)
      end

      def hash
        @hash ||= contents.hash
      end

      private

      def to_a_length
        contents.length
      end
    end
  end
end
