# frozen_string_literal: true

module Sass
  class Value
    # Sass's string type.
    class String < Sass::Value
      def initialize(text = '', quoted: true) # rubocop:disable Lint/MissingSuper
        @text = text.freeze
        @quoted = quoted
      end

      attr_reader :text

      def quoted?
        @quoted
      end

      def sass_index_to_string_index(sass_index, name = nil)
        index = sass_index.assert_number(name).assert_integer(name)
        raise error('String index may not be 0', name) if index.zero?

        if index.abs > text.length
          raise error("Invalid index #{sass_index} for a string with #{text.length} characters",
                      name)
        end

        index.negative? ? text.length + index : index - 1
      end

      def ==(other)
        other.is_a?(Sass::Value::String) && other.text == text
      end

      def hash
        @hash ||= text.hash
      end

      def assert_string(_name = nil)
        self
      end
    end
  end
end
